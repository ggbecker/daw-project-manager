import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../repository/project_repository.dart';
import '../services/backup_service.dart';
import '../utils/mobile_utils.dart';
import 'notification_settings_page.dart';
import 'phases_settings_page.dart';
import 'project_folders_settings_page.dart';
import 'widgets/desktop_title_bar.dart';

/// Settings hub: local data management (backup/restore) plus links out to the
/// other settings pages (project folders, phases, notifications). Reached
/// from the desktop "Settings" button/rail action — this is the destination
/// that button always conceptually meant, it previously opened
/// ProjectFoldersSettingsPage directly instead of a proper hub.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // --- Backup/restore — moved here from ProfileManagerPage verbatim, as the
  // "Data Management" section of this hub. ---

  Future<void> _exportBackup() async {
    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      final currentProfileId = profileRepo.getCurrentProfileId();
      if (currentProfileId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.noProfileSelected)),
          );
        }
        return;
      }

      final projectRepo = await ref.read(repositoryProvider.future);
      if (!mounted) return;

      final file = await BackupService.exportBackup(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        profileId: currentProfileId,
        exportDialogTitle: AppLocalizations.of(context)!.exportBackupDialogTitle,
      );

      if (file != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.backupExportedSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToExportBackup(e.toString()))),
        );
      }
    }
  }

  String _getImportButtonText(ImportMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ImportMode.merge:
        return l10n.mergeWithCurrentProfile;
      case ImportMode.replace:
        return l10n.replaceCurrentProfile;
      case ImportMode.createNewProfile:
        return l10n.create;
    }
  }

  Future<void> _showImportDialog() async {
    ImportMode? selectedMode = ImportMode.merge; // Default to merge mode
    final profileNameController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(AppLocalizations.of(context)!.importBackup),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.importBackupMessage),
                const SizedBox(height: 16),
                RadioListTile<ImportMode>(
                  title: Text(AppLocalizations.of(context)!.mergeWithCurrentProfile),
                  value: ImportMode.merge,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    setState(() {
                      selectedMode = value;
                    });
                  },
                ),
                RadioListTile<ImportMode>(
                  title: Text(AppLocalizations.of(context)!.replaceCurrentProfile),
                  value: ImportMode.replace,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    setState(() {
                      selectedMode = value;
                    });
                  },
                ),
                RadioListTile<ImportMode>(
                  title: Text(AppLocalizations.of(context)!.createNewProfileForImport),
                  value: ImportMode.createNewProfile,
                  groupValue: selectedMode,
                  onChanged: (value) {
                    setState(() {
                      selectedMode = value;
                    });
                  },
                ),
                if (selectedMode == ImportMode.createNewProfile) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: profileNameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.profileName,
                      hintText: AppLocalizations.of(context)!.profileName,
                    ),
                    autofocus: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedMode == ImportMode.createNewProfile) {
                  final name = profileNameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(ctx)!.pleaseEnterProfileName)),
                    );
                    return;
                  }
                  Navigator.pop(ctx, {
                    'mode': selectedMode,
                    'profileName': name,
                  });
                } else {
                  Navigator.pop(ctx, {
                    'mode': selectedMode,
                  });
                }
              },
              style: selectedMode == ImportMode.replace
                  ? ElevatedButton.styleFrom(backgroundColor: Colors.red)
                  : null,
              child: Text(_getImportButtonText(selectedMode!)),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final mode = result['mode'] as ImportMode;
      final profileName = result['profileName'] as String?;
      await _importBackup(importMode: mode, newProfileName: profileName);
    }
  }

  Future<void> _importBackup({
    required ImportMode importMode,
    String? newProfileName,
  }) async {
    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      if (!mounted) return;
      final currentProfileId = profileRepo.getCurrentProfileId();

      // For createNewProfile mode, we don't need currentProfileId or projectRepo yet
      ProjectRepository? projectRepo;
      if (importMode != ImportMode.createNewProfile) {
        if (currentProfileId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.noProfileSelected)),
            );
          }
          return;
        }
        projectRepo = await ref.read(repositoryProvider.future);
        if (!mounted) return;
      }

      final importResult = await BackupService.importBackup(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        currentProfileId: currentProfileId,
        importMode: importMode,
        newProfileName: newProfileName,
        importDialogTitle: AppLocalizations.of(context)!.importBackupDialogTitle,
        invalidBackupFormatMessage: AppLocalizations.of(context)!.invalidBackupFileFormat,
        profileNameRequiredMessage: AppLocalizations.of(context)!.profileNameRequiredForNewProfile,
        currentProfileRequiredMessage: AppLocalizations.of(context)!.currentProfileRequired,
      );

      if (importResult.cancelled) {
        return;
      }

      if (mounted) {
        String message;
        if (importMode == ImportMode.createNewProfile && importResult.newProfileId != null) {
          message = AppLocalizations.of(context)!.backupImportedToNewProfile(
            newProfileName ?? '',
            importResult.projectsCount,
            importResult.rootsCount,
            importResult.releasesCount,
          );
        } else {
          message = AppLocalizations.of(context)!.backupImportedSuccessfully(
            importResult.projectsCount,
            importResult.rootsCount,
            importResult.releasesCount,
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToImportBackup(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MobileUtils.isMobile();

    return Scaffold(
      body: Column(
        children: [
          DesktopTitleBar(title: l10n.settings, showBack: true),
          Expanded(
            child: ListView(
              padding: MobileUtils.getResponsivePadding(context),
              children: [
                // Backup/Restore — desktop only, mobile relies on Google Drive sync.
                if (!isMobile) ...[
                  Card(
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.backupAndRestore,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.upload_file),
                                label: Text(l10n.exportBackup),
                                onPressed: () => _exportBackup(),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.download),
                                label: Text(l10n.importBackup),
                                onPressed: () => _showImportDialog(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Links to the other settings pages.
                Card(
                  color: Theme.of(context).cardColor,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(l10n.roots),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProjectFoldersSettingsPage()),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.timeline_outlined),
                        title: Text(l10n.phases),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PhasesSettingsPage()),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications_outlined),
                        title: Text(l10n.notificationSettings),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationSettingsPage()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
