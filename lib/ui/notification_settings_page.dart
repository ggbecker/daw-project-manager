import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/notification_preferences.dart';
import '../services/deadline_notification_service.dart';
import '../providers/providers.dart';

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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(_preferences?.notificationHour ?? 9).toString().padLeft(2, '0')}:${(_preferences?.notificationMinute ?? 0).toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: (_hasPermission && (_preferences?.enabled ?? true))
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (_hasPermission && (_preferences?.enabled ?? true))
                  Icon(
                    Icons.access_time,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
            enabled: _hasPermission && (_preferences?.enabled ?? true),
            onTap: (_hasPermission && (_preferences?.enabled ?? true))
                ? () => _showTimePicker(context)
                : null,
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

          // Debug section (only visible in debug mode)
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          '🧪 Debug Mode',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Test notifications to verify timezone and scheduling:',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.notifications_active),
                            label: const Text('Send Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _hasPermission
                                ? () async {
                                    try {
                                      await _notificationService.sendTestNotification();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('✅ Test notification sent!'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('❌ Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.schedule),
                            label: const Text('Schedule +30s'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _hasPermission
                                ? () async {
                                    try {
                                      await _notificationService.scheduleTestNotification(secondsFromNow: 30);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('✅ Test notification scheduled for 30 seconds! Check console logs.'),
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('❌ Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.info_outline),
                            label: const Text('Show Debug Info'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade500,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final pending = await _notificationService.getPendingNotifications();
                              final enabled = await _notificationService.areNotificationsEnabled();
                              
                              if (mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('🐛 Debug Information'),
                                    content: SingleChildScrollView(
                                      child: SelectableText(
                                        '📊 Notification System Status\n'
                                        '══════════════════════════════════\n'
                                        '✓ Notifications enabled: $enabled\n'
                                        '📬 Pending notifications: ${pending.length}\n\n'
                                        'Pending notifications:\n'
                                        '${pending.isEmpty ? "No notifications scheduled" : pending.map((n) => "• ${n.title}\n  ${n.body}").join("\n\n")}',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Re-schedule All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _hasPermission
                                ? () async {
                                    try {
                                      if (kDebugMode) {
                                        print('\n🔄 Re-scheduling all notifications...');
                                      }
                                      
                                      final projectRepo = await ref.read(repositoryProvider.future);
                                      final projects = projectRepo.getAllProjects();
                                      
                                      if (kDebugMode) {
                                        print('📦 Total projects: ${projects.length}');
                                      }
                                      
                                      await _notificationService.scheduleAllDeadlineNotifications(
                                        projects: projects,
                                      );
                                      
                                      final pending = await _notificationService.getPendingNotifications();
                                      
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('✅ Scheduled ${pending.length} notifications (check console for details)'),
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (kDebugMode) {
                                        print('❌ Error re-scheduling: $e');
                                      }
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('❌ Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade300, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '⚠️ EMULATOR WARNING',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scheduled notifications often DON\'T WORK on Android emulators!\n\n'
                            '✅ TEST ON A REAL DEVICE for accurate results!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '📋 Check console logs for detailed information.\n'
                      '⚡ Disable battery optimization for best results.\n'
                      '🔔 Ensure notifications are enabled in settings.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final currentHour = _preferences?.notificationHour ?? 9;
    final currentMinute = _preferences?.notificationMinute ?? 0;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _preferences = _preferences?.copyWith(
          notificationHour: picked.hour,
          notificationMinute: picked.minute,
        ) ?? NotificationPreferences(
          notificationHour: picked.hour,
          notificationMinute: picked.minute,
        );
      });
    }
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
