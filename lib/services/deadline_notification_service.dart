import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_preferences.dart';
import '../models/music_project.dart';
import '../repository/project_repository.dart';
import '../utils/app_paths.dart';

/// Service for managing deadline notifications
class DeadlineNotificationService {
  static final DeadlineNotificationService _instance = DeadlineNotificationService._internal();
  factory DeadlineNotificationService() => _instance;
  DeadlineNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  Box<NotificationPreferences>? _preferencesBox;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Only initialize on Android
    if (!Platform.isAndroid) {
      if (kDebugMode) print('Deadline notifications only supported on Android');
      return;
    }

    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      
      // Get local timezone
      final String? timeZoneName = await _getLocalTimeZone();
      if (timeZoneName != null) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      }

      // Initialize Flutter Local Notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Initialize preferences storage
      await ensureHiveInitialized();
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(NotificationPreferencesAdapter());
      }
      _preferencesBox = await Hive.openBox<NotificationPreferences>('notification_preferences');

      _isInitialized = true;
      if (kDebugMode) print('Deadline notification service initialized');
    } catch (e) {
      if (kDebugMode) print('Error initializing deadline notifications: $e');
    }
  }

  /// Get local timezone name
  Future<String?> _getLocalTimeZone() async {
    try {
      // Try to get timezone from platform
      // Fallback to common timezones
      return DateTime.now().timeZoneName;
    } catch (e) {
      if (kDebugMode) print('Error getting timezone: $e');
      return null;
    }
  }

  /// Handle notification tap - opens project details
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      if (kDebugMode) print('Notification tapped with projectId: ${response.payload}');
      // The payload contains the project ID
      // This will be handled by the main app navigation
      _onNotificationTapCallback?.call(response.payload!);
    }
  }

  /// Callback for when notification is tapped
  Function(String projectId)? _onNotificationTapCallback;

  /// Set callback for notification taps
  void setOnNotificationTapCallback(Function(String projectId) callback) {
    _onNotificationTapCallback = callback;
  }

  /// Get notification preferences
  Future<NotificationPreferences> getPreferences() async {
    if (_preferencesBox == null) {
      await initialize();
    }
    
    if (_preferencesBox != null && _preferencesBox!.isNotEmpty) {
      return _preferencesBox!.values.first;
    }
    
    // Return default preferences
    return NotificationPreferences.getDefault();
  }

  /// Save notification preferences
  Future<void> savePreferences(NotificationPreferences preferences) async {
    if (_preferencesBox == null) {
      await initialize();
    }
    
    if (_preferencesBox != null) {
      await _preferencesBox!.clear();
      await _preferencesBox!.add(preferences);
      
      // Reschedule all notifications with new preferences
      await scheduleAllDeadlineNotifications();
      
      if (kDebugMode) print('Notification preferences saved');
    }
  }

  /// Check for projects with upcoming deadlines and schedule notifications
  Future<void> scheduleAllDeadlineNotifications() async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      final preferences = await getPreferences();
      if (!preferences.enabled) {
        // Cancel all scheduled notifications if disabled
        await _notifications.cancelAll();
        if (kDebugMode) print('Notifications disabled, cancelled all');
        return;
      }

      // Cancel existing notifications first
      await _notifications.cancelAll();

      // Get all projects from repository
      // Note: This requires access to ProjectRepository
      // We'll need to pass this in or make it accessible

      if (kDebugMode) {
        print('Scheduling deadline notifications...');
        print('Reminder days: ${preferences.reminderDays}');
      }
    } catch (e) {
      if (kDebugMode) print('Error scheduling notifications: $e');
    }
  }

  /// Schedule notifications for a specific project
  Future<void> scheduleNotificationsForProject(
    MusicProject project,
    NotificationPreferences preferences,
  ) async {
    if (!Platform.isAndroid || !_isInitialized) return;
    if (!preferences.enabled) return;
    if (project.deadline == null) return;

    try {
      final now = DateTime.now();
      final deadline = project.deadline!;
      
      // Don't schedule if deadline is in the past
      if (deadline.isBefore(now)) {
        return;
      }

      // Calculate days until deadline
      final daysUntilDeadline = deadline.difference(now).inDays;

      // Schedule notification for each reminder day
      for (final reminderDays in preferences.reminderDays) {
        if (daysUntilDeadline >= reminderDays) {
          // Calculate when to show the notification
          final notificationDate = deadline.subtract(Duration(days: reminderDays));
          
          // Set time to configured hour
          final notificationTime = DateTime(
            notificationDate.year,
            notificationDate.month,
            notificationDate.day,
            preferences.notificationHour,
            0,
          );

          // Only schedule if notification time is in the future
          if (notificationTime.isAfter(now)) {
            await _scheduleNotification(
              project: project,
              scheduledTime: notificationTime,
              daysRemaining: reminderDays,
            );
          }
        }
      }

      // Schedule notification for deadline day if enabled
      if (preferences.notifyOnDeadlineDay && daysUntilDeadline == 0) {
        final notificationTime = DateTime(
          deadline.year,
          deadline.month,
          deadline.day,
          preferences.notificationHour,
          0,
        );

        if (notificationTime.isAfter(now)) {
          await _scheduleNotification(
            project: project,
            scheduledTime: notificationTime,
            daysRemaining: 0,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error scheduling notifications for project ${project.id}: $e');
    }
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required MusicProject project,
    required DateTime scheduledTime,
    required int daysRemaining,
  }) async {
    try {
      // Create unique notification ID from project ID and days remaining
      final notificationId = '${project.id}_$daysRemaining'.hashCode;

      // Build notification message
      final String title;
      final String body;
      
      if (daysRemaining == 0) {
        title = 'Deadline Today!';
        body = 'Today is the deadline for "${project.displayName}"';
      } else if (daysRemaining == 1) {
        title = 'Deadline Tomorrow!';
        body = '1 day left for "${project.displayName}"';
      } else {
        title = 'Upcoming Deadline';
        body = '$daysRemaining days left for "${project.displayName}"';
      }

      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        'deadline_reminders',
        'Deadline Reminders',
        channelDescription: 'Notifications for project deadlines',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      // Schedule the notification
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: project.id, // Pass project ID for deep linking
      );

      if (kDebugMode) {
        print('Scheduled notification for ${project.displayName}: $daysRemaining days, at $scheduledTime');
      }
    } catch (e) {
      if (kDebugMode) print('Error scheduling individual notification: $e');
    }
  }

  /// Cancel all notifications for a specific project
  Future<void> cancelNotificationsForProject(String projectId) async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      final preferences = await getPreferences();
      
      // Cancel notifications for each reminder day
      for (final reminderDays in preferences.reminderDays) {
        final notificationId = '${projectId}_$reminderDays'.hashCode;
        await _notifications.cancel(notificationId);
      }
      
      // Cancel deadline day notification
      final deadlineDayId = '${projectId}_0'.hashCode;
      await _notifications.cancel(deadlineDayId);
      
      if (kDebugMode) print('Cancelled notifications for project: $projectId');
    } catch (e) {
      if (kDebugMode) print('Error cancelling notifications: $e');
    }
  }

  /// Get list of pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!Platform.isAndroid || !_isInitialized) return [];
    return await _notifications.pendingNotificationRequests();
  }

  /// Request notification permissions (Android 13+)
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return false;

    try {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }
      return true; // Pre-Android 13, permissions granted by default
    } catch (e) {
      if (kDebugMode) print('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!Platform.isAndroid) return false;

    try {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final enabled = await androidImpl.areNotificationsEnabled();
        return enabled ?? false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('Error checking notification status: $e');
      return false;
    }
  }
}
