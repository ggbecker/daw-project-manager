import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/music_project.dart';
import '../models/notification_preferences.dart';
import '../utils/app_paths.dart';
import 'deadline_notification_service.dart';

/// Background service for checking deadlines and scheduling notifications
class NotificationBackgroundService {
  static const String _taskName = 'checkDeadlines';
  static const String _uniqueName = 'deadline_check';

  /// Initialize the background service
  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      // Schedule periodic check (once per day)
      await Workmanager().registerPeriodicTask(
        _uniqueName,
        _taskName,
        frequency: const Duration(hours: 24),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        initialDelay: const Duration(minutes: 15), // Start after 15 minutes
      );

      if (kDebugMode) print('Notification background service initialized');
    } catch (e) {
      if (kDebugMode) print('Error initializing background service: $e');
    }
  }

  /// Cancel the background service
  static Future<void> cancel() async {
    if (!Platform.isAndroid) return;

    try {
      await Workmanager().cancelByUniqueName(_uniqueName);
      if (kDebugMode) print('Notification background service cancelled');
    } catch (e) {
      if (kDebugMode) print('Error cancelling background service: $e');
    }
  }

  /// Manually trigger a deadline check (for testing or immediate updates)
  static Future<void> triggerCheck() async {
    if (!Platform.isAndroid) return;

    try {
      await checkDeadlinesAndScheduleNotifications();
    } catch (e) {
      if (kDebugMode) print('Error triggering manual check: $e');
    }
  }

  /// Check deadlines and schedule notifications
  static Future<void> checkDeadlinesAndScheduleNotifications() async {
    if (!Platform.isAndroid) return;

    try {
      if (kDebugMode) print('Checking deadlines for notifications...');

      // Initialize notification service
      final notificationService = DeadlineNotificationService();
      await notificationService.initialize();

      // Get notification preferences
      final preferences = await notificationService.getPreferences();
      if (!preferences.enabled) {
        if (kDebugMode) print('Notifications disabled, skipping check');
        return;
      }

      // Get all projects with deadlines
      // We need to access the Hive database
      await ensureHiveInitialized();
      
      final projectsBox = await Hive.openBox<MusicProject>('music_projects');
      final projects = projectsBox.values.toList();

      // Filter projects with deadlines
      final projectsWithDeadlines = projects.where((p) => p.deadline != null).toList();

      if (kDebugMode) {
        print('Found ${projectsWithDeadlines.length} projects with deadlines');
      }

      // Schedule notifications for each project
      for (final project in projectsWithDeadlines) {
        await notificationService.scheduleNotificationsForProject(project, preferences);
      }

      if (kDebugMode) {
        final pending = await notificationService.getPendingNotifications();
        print('Scheduled ${pending.length} notifications');
      }
    } catch (e) {
      if (kDebugMode) print('Error checking deadlines: $e');
    }
  }
}

/// Callback dispatcher for background tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == NotificationBackgroundService._taskName) {
      try {
        await NotificationBackgroundService.checkDeadlinesAndScheduleNotifications();
        return Future.value(true);
      } catch (e) {
        if (kDebugMode) print('Background task error: $e');
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}
