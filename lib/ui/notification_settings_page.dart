import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/notification_preferences.dart';
import '../services/deadline_notification_service.dart';

/// Page for configuring deadline notification preferences
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends ConsumerState<NotificationSettingsPage> {
  final _notificationService = DeadlineNotificationService();
  NotificationPreferences? _preferences;
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _checkPermissions();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await _notificationService.getPreferences();
      if (mounted) {
        setState(() {
          _preferences = prefs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _notificationService.areNotificationsEnabled();
    if (mounted) {
      setState(() => _hasPermission = hasPermission);
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await _notificationService.requestPermissions();
    if (mounted) {
      setState(() => _hasPermission = granted);
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.notificationPermissionDenied),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.settings,
              onPressed: () {
                // Open app settings
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    try {
      await _notificationService.savePreferences(_preferences!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.notificationSettingsSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorSavingSettings)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.notificationSettings),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)!.notificationsOnlyOnAndroid),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.notificationSettings),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notificationSettings),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreferences,
            tooltip: AppLocalizations.of(context)!.save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Permission status
          if (!_hasPermission)
            Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: Text(AppLocalizations.of(context)!.notificationPermissionRequired),
                subtitle: Text(AppLocalizations.of(context)!.notificationPermissionDescription),
                trailing: ElevatedButton(
                  onPressed: _requestPermissions,
                  child: Text(AppLocalizations.of(context)!.enable),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Enable/Disable notifications
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.enableDeadlineNotifications),
            subtitle: Text(AppLocalizations.of(context)!.receiveRemindersForDeadlines),
            value: _preferences?.enabled ?? true,
            onChanged: _hasPermission
                ? (value) {
                    setState(() {
                      _preferences = _preferences?.copyWith(enabled: value) ??
                          NotificationPreferences(enabled: value);
                    });
                  }
                : null,
          ),

          const Divider(),

          // Notification time
          ListTile(
            title: Text(AppLocalizations.of(context)!.notificationTime),
            subtitle: Text(
              AppLocalizations.of(context)!.timeToReceiveNotifications,
            ),
            trailing: DropdownButton<int>(
              value: _preferences?.notificationHour ?? 9,
              items: List.generate(24, (index) => index)
                  .map((hour) => DropdownMenuItem(
                        value: hour,
                        child: Text('${hour.toString().padLeft(2, '0')}:00'),
                      ))
                  .toList(),
              onChanged: _hasPermission && (_preferences?.enabled ?? true)
                  ? (value) {
                      if (value != null) {
                        setState(() {
                          _preferences = _preferences?.copyWith(notificationHour: value) ??
                              NotificationPreferences(notificationHour: value);
                        });
                      }
                    }
                  : null,
            ),
          ),

          const Divider(),

          // Reminder days
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.reminderDays,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.selectDaysBeforeDeadline,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildReminderChip(1),
                    _buildReminderChip(3),
                    _buildReminderChip(7),
                    _buildReminderChip(14),
                    _buildReminderChip(30),
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // Notify on deadline day
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.notifyOnDeadlineDay),
            subtitle: Text(AppLocalizations.of(context)!.receiveNotificationOnDeadlineDay),
            value: _preferences?.notifyOnDeadlineDay ?? true,
            onChanged: _hasPermission && (_preferences?.enabled ?? true)
                ? (value) {
                    setState(() {
                      _preferences = _preferences?.copyWith(notifyOnDeadlineDay: value) ??
                          NotificationPreferences(notifyOnDeadlineDay: value);
                    });
                  }
                : null,
          ),

          const SizedBox(height: 32),

          // Help text
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.howItWorks,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.deadlineNotificationsHelp,
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderChip(int days) {
    final isSelected = _preferences?.reminderDays.contains(days) ?? false;
    final isEnabled = _hasPermission && (_preferences?.enabled ?? true);

    return FilterChip(
      label: Text(days == 1 ? '1 day' : '$days days'),
      selected: isSelected,
      onSelected: isEnabled
          ? (selected) {
              setState(() {
                final currentDays = List<int>.from(_preferences?.reminderDays ?? [1, 3, 7, 14]);
                if (selected) {
                  currentDays.add(days);
                } else {
                  currentDays.remove(days);
                }
                currentDays.sort();
                _preferences = _preferences?.copyWith(reminderDays: currentDays) ??
                    NotificationPreferences(reminderDays: currentDays);
              });
            }
          : null,
    );
  }
}
