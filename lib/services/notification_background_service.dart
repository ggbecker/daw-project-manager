import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/music_project.dart';
import '../models/notification_preferences.dart';
import '../utils/app_paths.dart';
import 'deadline_notification_service.dart';

/// Service for checking deadlines and scheduling notifications
/// This is called when the app starts and when projects are updated
class NotificationBackgroundService {
  /// Initialize the notification scheduling
  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    try {
      // Schedule notifications on app start
      await triggerCheck();
      
      if (kDebugMode) print('Notification scheduling initialized');
    } catch (e) {
      if (kDebugMode) print('Error initializing notification scheduling: $e');
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
