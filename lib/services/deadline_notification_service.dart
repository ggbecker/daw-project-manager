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
      
      if (kDebugMode) {
        print('\n🌍 ═══════════════════════════════════════════');
        print('🌍 TIMEZONE INITIALIZATION');
        print('🌍 ═══════════════════════════════════════════');
        print('📱 System timezone name: ${DateTime.now().timeZoneName}');
        print('📱 System time: ${DateTime.now()}');
        print('📱 System UTC time: ${DateTime.now().toUtc()}');
        print('📱 System offset: ${DateTime.now().timeZoneOffset}');
        print('📱 System offset hours: ${DateTime.now().timeZoneOffset.inHours}');
        print('📱 System offset minutes: ${DateTime.now().timeZoneOffset.inMinutes}');
      }
      
      // Get local timezone with detailed logging
      final String? timeZoneName = await _getLocalTimeZone();
      if (timeZoneName != null) {
        final location = tz.getLocation(timeZoneName);
        tz.setLocalLocation(location);
        
        // Verify timezone offset matches system
        final systemOffset = DateTime.now().timeZoneOffset;
        final systemOffsetHours = systemOffset.inHours;
        final locationOffset = location.currentTimeZone.offset;
        final locationOffsetHours = locationOffset ~/ 3600; // Convert seconds to hours
        
        if (kDebugMode) {
          print('🌍 Selected timezone: $timeZoneName');
          print('🕐 Current time in timezone: ${tz.TZDateTime.now(tz.local)}');
          print('⏰ System offset: $systemOffset ($systemOffsetHours hours)');
          print('⏰ Configured offset: $locationOffset seconds ($locationOffsetHours hours)');
        }
        
        // Check offset mismatch (allow 1 hour difference for DST)
        final offsetDiff = (locationOffsetHours - systemOffsetHours).abs();
        if (offsetDiff > 1) {
          if (kDebugMode) {
            print('⚠️ ⚠️ ⚠️ WARNING: TIMEZONE OFFSET MISMATCH! ⚠️ ⚠️ ⚠️');
            print('   System reports: $systemOffsetHours hours');
            print('   Configured timezone has: $locationOffsetHours hours');
            print('   Difference: $offsetDiff hours');
            print('   ⚠️ NOTIFICATIONS WILL APPEAR AT WRONG TIMES!');
          }
        } else {
          if (kDebugMode) {
            print('✅ Timezone configured correctly');
            print('   Offset difference: $offsetDiff hours (acceptable for DST)');
          }
        }
        
        if (kDebugMode) {
          print('🌍 ═══════════════════════════════════════════\n');
        }
      } else {
        // Fallback to UTC
        if (kDebugMode) {
          print('⚠️ Could not determine timezone, using UTC');
          print('🌍 ═══════════════════════════════════════════\n');
        }
        tz.setLocalLocation(tz.getLocation('UTC'));
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
      if (kDebugMode) print('✅ Deadline notification service initialized');
    } catch (e) {
      if (kDebugMode) print('❌ Error initializing deadline notifications: $e');
    }
  }

  /// Get local timezone name with robust offset-based detection
  Future<String?> _getLocalTimeZone() async {
    try {
      // Get system offset
      final systemOffset = DateTime.now().timeZoneOffset;
      final offsetHours = systemOffset.inHours;
      final offsetMinutes = systemOffset.inMinutes % 60;
      
      if (kDebugMode) {
        print('🌍 System timezone name: ${DateTime.now().timeZoneName}');
        print('⏱️ System timezone offset: $systemOffset (${offsetHours >= 0 ? '+' : ''}$offsetHours:${offsetMinutes.toString().padLeft(2, '0')})');
        print('📅 Current system time: ${DateTime.now()}');
        print('🌐 UTC time: ${DateTime.now().toUtc()}');
      }
      
      // Map offset to real IANA timezone (better DST support than Etc/GMT)
      final timezoneMap = {
        0: 'UTC',
        1: 'Europe/Paris',      // UTC+1 (CET/CEST)
        -1: 'Atlantic/Azores',   // UTC-1
        2: 'Europe/Berlin',      // UTC+2 (CEST)
        -2: 'Atlantic/South_Georgia', // UTC-2
        3: 'Europe/Moscow',      // UTC+3
        -3: 'America/Sao_Paulo', // UTC-3 (BRT)
        4: 'Asia/Dubai',         // UTC+4
        -4: 'America/New_York',  // UTC-4 (EDT) or UTC-5 (EST)
        5: 'Asia/Karachi',       // UTC+5
        -5: 'America/Chicago',   // UTC-5 (CDT) or UTC-6 (CST)
        -6: 'America/Denver',    // UTC-6 (MDT) or UTC-7 (MST)
        -7: 'America/Los_Angeles', // UTC-7 (PDT) or UTC-8 (PST)
        8: 'Asia/Shanghai',      // UTC+8
        -8: 'Pacific/Pitcairn',  // UTC-8
        9: 'Asia/Tokyo',         // UTC+9
        -9: 'Pacific/Gambier',   // UTC-9
        10: 'Australia/Sydney',  // UTC+10 (AEDT) or UTC+11 (AEST)
        -10: 'Pacific/Honolulu', // UTC-10
      };
      
      // Try to use timezone based on offset
      final suggestedTimezone = timezoneMap[offsetHours];
      if (suggestedTimezone != null) {
        try {
          final location = tz.getLocation(suggestedTimezone);
          final locationOffset = location.currentTimeZone.offset;
          final locationOffsetHours = locationOffset ~/ 3600;
          
          if (kDebugMode) {
            print('🔄 Mapped offset $offsetHours to timezone: $suggestedTimezone');
            print('   Location offset: $locationOffset seconds ($locationOffsetHours hours)');
          }
          
          return suggestedTimezone;
        } catch (e) {
          if (kDebugMode) print('⚠️ Could not use suggested timezone $suggestedTimezone: $e');
        }
      }
      
      // Fallback to Etc/GMT based on offset
      // Note: Etc/GMT uses inverted sign: GMT+1 = Etc/GMT-1
      if (offsetHours == 0) {
        return 'UTC';
      } else if (offsetHours > 0) {
        final etcTimezone = 'Etc/GMT-$offsetHours';
        if (kDebugMode) print('🔄 Fallback to: $etcTimezone');
        return etcTimezone;
      } else {
        final etcTimezone = 'Etc/GMT+${-offsetHours}';
        if (kDebugMode) print('🔄 Fallback to: $etcTimezone');
        return etcTimezone;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error getting timezone: $e');
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
  Future<void> scheduleAllDeadlineNotifications({List<MusicProject>? projects}) async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      final preferences = await getPreferences();
      if (!preferences.enabled) {
        // Cancel all scheduled notifications if disabled
        await _notifications.cancelAll();
        if (kDebugMode) print('🔕 Notifications disabled, cancelled all');
        return;
      }

      // Cancel existing notifications first
      await _notifications.cancelAll();

      if (kDebugMode) {
        print('\n🔔 ═══════════════════════════════════════════');
        print('🔔 SCHEDULING DEADLINE NOTIFICATIONS');
        print('🔔 ═══════════════════════════════════════════');
        print('⏰ Notification time: ${preferences.notificationHour.toString().padLeft(2, '0')}:${preferences.notificationMinute.toString().padLeft(2, '0')}');
        print('📅 Reminder days: ${preferences.reminderDays}');
        print('🔔 Notify on deadline day: ${preferences.notifyOnDeadlineDay}');
      }

      if (projects == null || projects.isEmpty) {
        if (kDebugMode) print('⚠️ No projects provided to schedule notifications');
        return;
      }

      int totalProjects = 0;
      int totalScheduled = 0;
      int skippedFinished = 0;
      int skippedNoDeadline = 0;

      for (final project in projects) {
        if (project.deadline == null) {
          skippedNoDeadline++;
          continue;
        }

        if (project.status?.toLowerCase() == 'finished' || 
            project.status?.toLowerCase() == 'finalizado') {
          skippedFinished++;
          continue;
        }

        totalProjects++;
        await scheduleNotificationsForProject(project, preferences);
      }

      // Count actual scheduled notifications
      final pending = await _notifications.pendingNotificationRequests();
      totalScheduled = pending.length;

      if (kDebugMode) {
        print('\n📊 ═══════════════════════════════════════════');
        print('📊 SCHEDULING SUMMARY');
        print('📊 ═══════════════════════════════════════════');
        print('✓ Total projects with deadlines: $totalProjects');
        print('⏭️ Skipped (finished): $skippedFinished');
        print('⏭️ Skipped (no deadline): $skippedNoDeadline');
        print('📬 Total notifications scheduled: $totalScheduled');
        print('📊 ═══════════════════════════════════════════\n');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error scheduling notifications: $e');
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
      
      if (kDebugMode) {
        print('\n🔔 Checking project: ${project.displayName}');
        print('   Status: ${project.status}');
        print('   Deadline: $deadline');
      }
      
      // Don't schedule if project is finished
      if (project.status?.toLowerCase() == 'finished' || 
          project.status?.toLowerCase() == 'finalizado') {
        if (kDebugMode) print('   ⏭️ Skipping: Project is finished');
        return;
      }
      
      // Don't schedule if deadline is in the past
      if (deadline.isBefore(now)) {
        if (kDebugMode) print('   ⏭️ Skipping: Deadline is in the past');
        return;
      }

      // Calculate days until deadline (using midnight comparison)
      final nowMidnight = DateTime(now.year, now.month, now.day);
      final deadlineMidnight = DateTime(deadline.year, deadline.month, deadline.day);
      final daysUntilDeadline = deadlineMidnight.difference(nowMidnight).inDays;

      if (kDebugMode) {
        print('   📅 Days until deadline: $daysUntilDeadline');
        print('   ⏰ Notification time: ${preferences.notificationHour.toString().padLeft(2, '0')}:${preferences.notificationMinute.toString().padLeft(2, '0')}');
        print('   📬 Reminder days configured: ${preferences.reminderDays}');
      }

      int scheduledCount = 0;

      // Schedule notification for each reminder day
      for (final reminderDays in preferences.reminderDays) {
        if (kDebugMode) {
          print('   🔍 Checking $reminderDays days before deadline:');
        }
        
        if (daysUntilDeadline >= reminderDays) {
          // Calculate when to show the notification
          final notificationDate = deadline.subtract(Duration(days: reminderDays));
          
          // Set time to configured hour and minute
          final notificationTime = DateTime(
            notificationDate.year,
            notificationDate.month,
            notificationDate.day,
            preferences.notificationHour,
            preferences.notificationMinute,
          );

          if (kDebugMode) {
            print('      Notification would be at: $notificationTime');
            print('      Current time: $now');
            print('      Is in future? ${notificationTime.isAfter(now)}');
          }

          // Only schedule if notification time is in the future
          if (notificationTime.isAfter(now)) {
            await _scheduleNotification(
              project: project,
              scheduledTime: notificationTime,
              daysRemaining: reminderDays,
            );
            scheduledCount++;
            if (kDebugMode) {
              print('      ✅ Scheduled for $notificationTime');
            }
          } else {
            if (kDebugMode) {
              print('      ⏭️ Skipped: Time already passed');
            }
          }
        } else {
          if (kDebugMode) {
            print('      ⏭️ Skipped: Deadline is less than $reminderDays days away');
          }
        }
      }

      // Schedule notification for deadline day if enabled
      if (preferences.notifyOnDeadlineDay) {
        if (kDebugMode) {
          print('   🔍 Checking deadline day notification:');
        }
        
        // Check if today is the deadline day OR if deadline is tomorrow but we can still schedule for it
        if (daysUntilDeadline <= 1) {
          final notificationTime = DateTime(
            deadline.year,
            deadline.month,
            deadline.day,
            preferences.notificationHour,
            preferences.notificationMinute,
          );

          if (kDebugMode) {
            print('      Notification would be at: $notificationTime');
            print('      Current time: $now');
            print('      Is in future? ${notificationTime.isAfter(now)}');
          }

          if (notificationTime.isAfter(now)) {
            await _scheduleNotification(
              project: project,
              scheduledTime: notificationTime,
              daysRemaining: 0,
            );
            scheduledCount++;
            if (kDebugMode) {
              print('      ✅ Scheduled for deadline day at $notificationTime');
            }
          } else {
            if (kDebugMode) {
              print('      ⏭️ Skipped: Time already passed');
            }
          }
        } else {
          if (kDebugMode) {
            print('      ⏭️ Skipped: Deadline is not today');
          }
        }
      }

      if (kDebugMode) {
        print('   📊 Total notifications scheduled: $scheduledCount');
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
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      // Convert to TZ DateTime
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
      
      // Check if we can use exact alarms
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      bool canUseExactAlarms = false;
      AndroidScheduleMode scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      
      if (androidImpl != null) {
        try {
          canUseExactAlarms = await androidImpl.canScheduleExactNotifications() ?? false;
          scheduleMode = canUseExactAlarms 
              ? AndroidScheduleMode.exactAllowWhileIdle 
              : AndroidScheduleMode.inexactAllowWhileIdle;
        } catch (e) {
          if (kDebugMode) print('⚠️ Could not check exact alarm permission: $e');
        }
      }
      
      if (kDebugMode) {
        print('\n🔔 ═════════ SCHEDULING NOTIFICATION ═════════');
        print('   📌 Notification ID: $notificationId');
        print('   📝 Project: ${project.displayName}');
        print('   ⏰ Days remaining: $daysRemaining');
        print('   📅 Original DateTime: $scheduledTime');
        print('   🌍 Timezone: ${tz.local.name}');
        print('   ⏰ TZDateTime: $tzScheduledTime');
        print('   🕐 Current TZDateTime: ${tz.TZDateTime.now(tz.local)}');
        print('   ⏱️ Seconds until notification: ${tzScheduledTime.difference(tz.TZDateTime.now(tz.local)).inSeconds}');
        print('   🎯 Schedule mode: $scheduleMode');
        print('   🔐 Exact alarms permission: $canUseExactAlarms');
        if (!canUseExactAlarms) {
          print('   ⚠️ ⚠️ ⚠️ USING INEXACT MODE ⚠️ ⚠️ ⚠️');
          print('   ⚠️ Notification may appear with 5-10 min delay');
        } else {
          print('   ✅ Using exact mode - will appear at exact time');
        }
        print('🔔 ═════════════════════════════════════════\n');
      }

      // Schedule the notification
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: project.id, // Pass project ID for deep linking
      );

      if (kDebugMode) {
        print('   ✅ Notification scheduled successfully!');
        print('Scheduled notification for ${project.displayName}: $daysRemaining days, at $scheduledTime');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error scheduling individual notification: $e');
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

  /// Get detailed debug information about pending notifications
  Future<String> getDebugInfo() async {
    if (!Platform.isAndroid || !_isInitialized) return 'Not on Android or not initialized';

    try {
      final pending = await _notifications.pendingNotificationRequests();
      final preferences = await getPreferences();
      
      // Check permissions
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      bool? notificationsEnabled;
      bool? exactAlarmPermission;
      
      if (androidImpl != null) {
        notificationsEnabled = await androidImpl.areNotificationsEnabled();
        try {
          // This will throw if exact alarm permission is not granted
          exactAlarmPermission = await androidImpl.canScheduleExactNotifications();
        } catch (e) {
          exactAlarmPermission = null;
        }
      }
      
      final buffer = StringBuffer();
      buffer.writeln('📊 Notification System Status');
      buffer.writeln('═' * 40);
      buffer.writeln('✓ Service Initialized: $_isInitialized');
      buffer.writeln('✓ Enabled in settings: ${preferences.enabled}');
      buffer.writeln('⏰ Time: ${preferences.notificationHour.toString().padLeft(2, '0')}:${preferences.notificationMinute.toString().padLeft(2, '0')}');
      buffer.writeln('📅 Reminder days: ${preferences.reminderDays.join(", ")}');
      buffer.writeln('🔔 Notify on deadline day: ${preferences.notifyOnDeadlineDay}');
      
      buffer.writeln('\n🔐 Permissions:');
      buffer.writeln('   Notifications: ${notificationsEnabled ?? "unknown"}');
      buffer.writeln('   Exact Alarms: ${exactAlarmPermission ?? "unknown"}');
      
      buffer.writeln('\n📍 Timezone Info:');
      buffer.writeln('   System: ${DateTime.now().timeZoneName}');
      buffer.writeln('   Configured: ${tz.local.name}');
      buffer.writeln('   Offset: ${DateTime.now().timeZoneOffset}');
      
      buffer.writeln('\n🕐 Current Times:');
      buffer.writeln('   Local: ${DateTime.now()}');
      buffer.writeln('   TZ Local: ${tz.TZDateTime.now(tz.local)}');
      buffer.writeln('   UTC: ${DateTime.now().toUtc()}');
      
      buffer.writeln('\n📬 Pending Notifications: ${pending.length}');
      buffer.writeln('─' * 40);
      
      if (pending.isEmpty) {
        buffer.writeln('No notifications scheduled.');
        buffer.writeln('\n💡 TIP: If you scheduled notifications but');
        buffer.writeln('they don\'t appear here, check:');
        buffer.writeln('  1. Notification permissions are granted');
        buffer.writeln('  2. Exact alarm permission is granted');
        buffer.writeln('  3. Battery optimization is disabled for this app');
      } else {
        for (final notification in pending) {
          buffer.writeln('\n📌 ID: ${notification.id}');
          buffer.writeln('   Title: ${notification.title ?? "N/A"}');
          buffer.writeln('   Body: ${notification.body ?? "N/A"}');
          buffer.writeln('   Payload: ${notification.payload ?? "N/A"}');
        }
      }
      
      return buffer.toString();
    } catch (e) {
      return 'Error getting debug info: $e';
    }
  }

  /// Send a test notification immediately (for debugging)
  Future<void> sendTestNotification() async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      if (kDebugMode) {
        print('🧪 Sending test notification...');
        print('📍 Current timezone: ${tz.local.name}');
        print('🕐 Current time: ${tz.TZDateTime.now(tz.local)}');
        print('⏰ System time: ${DateTime.now()}');
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

      // Send immediate notification
      await _notifications.show(
        999999, // Test notification ID
        '🧪 Test Notification',
        'This is a test notification sent at ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}. Timezone: ${DateTime.now().timeZoneName}',
        notificationDetails,
        payload: 'test',
      );

      if (kDebugMode) {
        print('✅ Test notification sent successfully!');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error sending test notification: $e');
      rethrow;
    }
  }

  /// Schedule a test notification in the future (for debugging)
  Future<void> scheduleTestNotification({int secondsFromNow = 30}) async {
    if (!Platform.isAndroid || !_isInitialized) return;

    try {
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = now.add(Duration(seconds: secondsFromNow));
      
      // Check if we can use exact alarms
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      bool canUseExactAlarms = false;
      AndroidScheduleMode scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      
      if (androidImpl != null) {
        try {
          canUseExactAlarms = await androidImpl.canScheduleExactNotifications() ?? false;
          scheduleMode = canUseExactAlarms 
              ? AndroidScheduleMode.exactAllowWhileIdle 
              : AndroidScheduleMode.inexactAllowWhileIdle;
        } catch (e) {
          if (kDebugMode) print('⚠️ Could not check exact alarm permission: $e');
        }
      }
      
      if (kDebugMode) {
        print('\n🧪 ═══════════════════════════════════════════');
        print('🧪 SCHEDULING TEST NOTIFICATION');
        print('🧪 ═══════════════════════════════════════════');
        print('📍 System Timezone: ${DateTime.now().timeZoneName}');
        print('🌍 Configured Timezone: ${tz.local.name}');
        print('⏱️ Offset: ${now.timeZoneOffset}');
        print('🕐 Current System Time: ${DateTime.now()}');
        print('🕐 Current TZ Time: $now');
        print('⏰ Will notify at TZ Time: $scheduledTime');
        print('⏰ Will notify at System Time: ${DateTime.now().add(Duration(seconds: secondsFromNow))}');
        print('⏱️ In $secondsFromNow seconds');
        print('🎯 Schedule mode: $scheduleMode (exact alarms: $canUseExactAlarms)');
        if (!canUseExactAlarms) {
          print('⚠️ Using inexact mode - notification may appear with slight delay');
        }
        print('🧪 ═══════════════════════════════════════════\n');
      }

      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        'deadline_reminders',
        'Deadline Reminders',
        channelDescription: 'Notifications for project deadlines',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          'Scheduled for ${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}:${scheduledTime.second.toString().padLeft(2, '0')}. '
          'Timezone: ${tz.local.name}. Mode: $scheduleMode',
        ),
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      // Schedule the notification
      await _notifications.zonedSchedule(
        999998, // Test notification ID
        '🧪 Test Notification ($secondsFromNow sec)',
        'If you see this, notifications are working! Scheduled at ${now.hour}:${now.minute}:${now.second}',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'test',
      );

      if (kDebugMode) {
        print('✅ Test notification scheduled successfully!');
        print('   ID: 999998');
        print('   Scheduled for: $scheduledTime');
        print('   Current pending notifications: ${(await _notifications.pendingNotificationRequests()).length}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error scheduling test notification: $e');
      rethrow;
    }
  }

  /// Request notification permissions (Android 13+)
  /// Note: Exact alarm permission is optional - notifications will work in inexact mode without it
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return false;

    try {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        // Request notification permission (required)
        final granted = await androidImpl.requestNotificationsPermission();
        
        // Check exact alarm permission (optional - for exact timing)
        final canScheduleExactAlarms = await androidImpl.canScheduleExactNotifications();
        if (canScheduleExactAlarms == false) {
          if (kDebugMode) {
            print('⚠️ Exact alarm permission not granted.');
            print('💡 Notifications will use inexact mode (may have slight delay).');
            print('💡 To get exact timing, grant "Alarms & reminders" permission in app settings.');
          }
        }
        
        if (kDebugMode) {
          print('✅ Notification permissions: ${granted ?? false}');
          print('🎯 Exact alarm permissions: ${canScheduleExactAlarms ?? false}');
        }
        
        // Return true if basic notification permission is granted
        // Exact alarm permission is optional
        return granted ?? false;
      }
      return true; // Pre-Android 13, permissions granted by default
    } catch (e) {
      if (kDebugMode) print('❌ Error requesting notification permissions: $e');
      return false;
    }
  }
  
  /// Request exact alarm permission (opens system settings on Android 12+)
  Future<void> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;
    
    try {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestExactAlarmsPermission();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error requesting exact alarm permission: $e');
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
