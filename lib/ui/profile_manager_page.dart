import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'widgets/desktop_title_bar.dart';
import '../models/profile.dart';
import '../providers/providers.dart';
import '../repository/project_repository.dart';
import '../services/demo_data_service.dart';
import '../services/scanner_service.dart';
import '../utils/app_paths.dart';
import '../utils/mobile_utils.dart';
import '../generated/l10n/app_localizations.dart';
import 'profile_view_page.dart';
import '../services/backup_service.dart';
import '../services/crash_logger.dart';
import 'package:share_plus/share_plus.dart';
import 'google_drive_sync_page.dart';
import 'widgets/theme_switcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/language_switcher.dart';

// TODO: Set this back to `kDebugMode` once promotional screenshots are done.
// The demo-data generator/remover is normally a debug-only tool, but it's
// temporarily enabled in release builds too so it can be used to seed a
// screenshot-ready profile from a release build.
const bool _showTestingDatabaseTools = kDebugMode;

class ProfileManagerPage extends ConsumerStatefulWidget {
  const ProfileManagerPage({super.key});

  @override
  ConsumerState<ProfileManagerPage> createState() => _ProfileManagerPageState();
}

class _ProfileManagerPageState extends ConsumerState<ProfileManagerPage> {
  @override
  void initState() {
    super.initState();
  }


  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _showCreateProfileDialog() async {
    final nameController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.createNewProfile),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.profileName,
            hintText: AppLocalizations.of(context)!.profileName,
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(ctx, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, nameController.text.trim());
              }
            },
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _createProfile(result);
    }
  }

  Future<void> _createProfile(String name) async {
    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      await profileRepo.createProfile(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileCreated(name))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToCreateProfile(e.toString()))),
        );
      }
    }
  }

  Future<void> _switchProfile(String profileId) async {
    // Save provider references and container before any navigation that might unmount the widget
    final profileRepo = await ref.read(profileRepositoryProvider.future);
    if (!mounted) return;
    final profileSwitchingNotifier = ref.read(profileSwitchingProvider.notifier);
    final container = ProviderScope.containerOf(context);
    
    try {
      await profileRepo.setCurrentProfileId(profileId);
      
      // Set profile switching state to show "Switching Profiles..." message
      profileSwitchingNotifier.setSwitching(true);
      
      // Navigate back to dashboard first so it can show the loading overlay
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Invalidate all related providers to reload with new profile (using saved container)
      container.invalidate(repositoryProvider);
      container.invalidate(allProjectsStreamProvider);
      container.invalidate(releasesProvider);
      container.invalidate(scanRootsProvider);
      container.invalidate(currentProfileProvider);
      
      // Wait a bit for providers to invalidate
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Wait for repository to reload with new profile (using saved container)
      final repo = await container.read(repositoryProvider.future);
      
      if (kDebugMode) {
        print('Profile switched to: $profileId');
        print('Repository reloaded with ${repo.projectsBox.length} projects, ${repo.releasesBox.length} releases');
      }
      
      // Trigger scan for the new profile's root folders (same as dashboard scan)
      await _scanProfileRoots(repo);
      
      // Mark profile switching as complete (using saved notifier)
      profileSwitchingNotifier.complete();
      
      // The dashboard will automatically show the updated projects
    } catch (e) {
      // Mark profile switching as complete even on error (using saved notifier)
      profileSwitchingNotifier.complete();
      // Error will be visible in the dashboard if needed
      if (kDebugMode) {
        print('Error switching profile: $e');
      }
    }
  }

  Future<void> _scanProfileRoots(ProjectRepository repo) async {
    final scanner = ScannerService();
    int foundCount = 0;
    final ignoredPaths = repo.getIgnoredPaths().map((p) => p.path).toList(growable: false);

    // Scan all root folders for the current profile (same logic as dashboard)
    // Use lightweight scan (fast, no full metadata extraction)
    final scanTime = DateTime.now();
    for (final root in repo.getRoots()) {
      final entities = <FileSystemEntity>[];
      await for (final entity in scanner.scanDirectory(root.path, ignoredPaths: ignoredPaths)) {
        entities.add(entity);
      }
      if (entities.isNotEmpty) {
        await repo.upsertManyFromFileSystemEntities(entities, fullMetadata: false);
        foundCount += entities.length;
      }
      // Update lastScanAt timestamp for this root
      await repo.updateRootLastScanAt(root.id, scanTime);
    }
    
    // The dashboard will automatically show the updated projects
    // No need to show a message here as the scan state change will trigger UI updates
  }

  Future<String> _getProfilePhotosPath() async {
    final basePath = await getLocalAppDataPath();
    return path.join(basePath, 'profile_photos');
  }

  Future<void> _pickProfilePhoto(Profile profile) async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final sourcePath = result.files.single.path!;
      final sourceFile = File(sourcePath);
      
      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.selectedFileDoesNotExist)),
          );
        }
        return;
      }

      try {
        // Get profile photos directory
        final photosDirPath = await _getProfilePhotosPath();
        final photosDir = Directory(photosDirPath);
        
        // Create directory if it doesn't exist
        if (!await photosDir.exists()) {
          await photosDir.create(recursive: true);
        }

        // Copy file to profile photos directory with profile ID as name
        final fileExtension = path.extension(sourcePath);
        final destPath = path.join(photosDir.path, '${profile.id}$fileExtension');
        await sourceFile.copy(destPath);

        // Update profile with photo path
        final profileRepo = await ref.read(profileRepositoryProvider.future);
        final updatedProfile = profile.copyWith(photoPath: destPath);
        await profileRepo.updateProfile(updatedProfile);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.profilePhotoUpdated)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToSaveProfilePhoto(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _removeProfilePhoto(Profile profile) async {
    if (profile.photoPath != null) {
      try {
        final photoFile = File(profile.photoPath!);
        if (await photoFile.exists()) {
          await photoFile.delete();
        }
        
        final profileRepo = await ref.read(profileRepositoryProvider.future);
        final updatedProfile = profile.copyWith(clearPhotoPath: true);
        await profileRepo.updateProfile(updatedProfile);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.profilePhotoRemoved)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToRemoveProfilePhoto(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _editProfile(Profile profile) async {
    final editController = TextEditingController(text: profile.name);
    
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.editProfile),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.profileName,
                hintText: AppLocalizations.of(context)!.profileName,
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.pop(ctx, value.trim());
                }
              },
            ),
            const SizedBox(height: 16),
            // Profile photo preview and controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (profile.photoPath != null && File(profile.photoPath!).existsSync())
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(profile.photoPath!),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          width: 80,
                          height: 80,
                          child: Icon(Icons.broken_image),
                        );
                      },
                    ),
                  )
                else
                  const SizedBox(
                    width: 80,
                    height: 80,
                    child: Icon(Icons.person, size: 40),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.photo),
                  label: Text(AppLocalizations.of(context)!.changePhoto),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _pickProfilePhoto(profile);
                  },
                ),
                if (profile.photoPath != null)
                  TextButton.icon(
                    icon: const Icon(Icons.delete),
                    label: Text(AppLocalizations.of(context)!.remove),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _removeProfilePhoto(profile);
                    },
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx, newName);
              }
            },
            child: Text(AppLocalizations.of(context)!.saveName),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != profile.name) {
      try {
        final profileRepo = await ref.read(profileRepositoryProvider.future);
        final updatedProfile = profile.copyWith(name: result);
        await profileRepo.updateProfile(updatedProfile);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.profileRenamed(result))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToRenameProfile(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _deleteProfile(Profile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.deleteProfile),
        content: Text(AppLocalizations.of(context)!.deleteProfileMessage(profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final profileRepo = await ref.read(profileRepositoryProvider.future);
        await profileRepo.deleteProfile(profile.id);
        
        // Invalidate repository provider to reload with new profile
        ref.invalidate(repositoryProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.profileDeleted(profile.name))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToDeleteProfile(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _showProfileContextMenu(BuildContext context, Profile profile, Offset position, bool isCurrent, int totalProfiles) async {
    final l10n = AppLocalizations.of(context)!;
    
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'view',
          child: Row(
            children: [
              const Icon(Icons.visibility, size: 20),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.viewProfile),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 20),
              const SizedBox(width: 8),
              Text(l10n.tooltipEditProfileName),
            ],
          ),
        ),
        if (!isCurrent)
          PopupMenuItem<String>(
            value: 'switch',
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, size: 20),
                const SizedBox(width: 8),
                Text(l10n.switchProfile),
              ],
            ),
          ),
        if (totalProfiles > 1)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 20, color: Colors.red.shade300),
                const SizedBox(width: 8),
                Text(l10n.delete, style: TextStyle(color: Colors.red.shade300)),
              ],
            ),
          ),
      ],
      color: Theme.of(context).cardColor,
    );

    if (result != null && mounted) {
      switch (result) {
        case 'view':
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfileViewPage(profileId: profile.id),
            ),
          );
          break;
        case 'edit':
          await _editProfile(profile);
          break;
        case 'switch':
          await _switchProfile(profile.id);
          break;
        case 'delete':
          await _deleteProfile(profile);
          break;
      }
    }
  }

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

  Future<void> _shareDiagnosticLog() async {
    final files = await CrashLogger.existingLogFiles();
    if (files.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.shareDiagnosticLogEmpty)),
        );
      }
      return;
    }
    await Share.shareXFiles(files.map((f) => XFile(f.path)).toList());
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

  /// Creates (or refreshes) a dedicated demo profile with a large, varied
  /// catalog of fake projects/releases/playlists for promotional
  /// screenshots, and switches to it — the user's real data is never
  /// touched, since it lives in a separate profile-scoped Hive box set.
  Future<void> _generateTestingDatabase() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.generateTestingDatabase),
        content: Text(AppLocalizations.of(context)!.generateTestingDatabaseMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);

      final demoProfile = await DemoDataService().generate(profileRepo);
      await profileRepo.setCurrentProfileId(demoProfile.id);

      // Invalidate providers so the app picks up the demo profile immediately.
      ref.invalidate(repositoryProvider);
      ref.invalidate(allProjectsStreamProvider);
      ref.invalidate(releasesProvider);
      ref.invalidate(scanRootsProvider);
      ref.invalidate(currentProfileProvider);

      await Future.delayed(const Duration(milliseconds: 100));
      await ref.read(repositoryProvider.future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.testingDatabaseGenerated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToGenerateTestingDatabase(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (kDebugMode) print('Error generating testing database: $e');
    }
  }

  /// Permanently deletes the "Demo — Screenshots" profile (if it exists),
  /// including its generated preview audio files. If it was the active
  /// profile, the app switches back to another one automatically.
  Future<void> _removeTestingDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeTestingDatabase),
        content: Text(AppLocalizations.of(context)!.removeTestingDatabaseMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade300),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.removeTestingDatabase),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      final removed = await DemoDataService().remove(profileRepo);

      // Invalidate providers in case the active profile changed as a result.
      ref.invalidate(repositoryProvider);
      ref.invalidate(allProjectsStreamProvider);
      ref.invalidate(releasesProvider);
      ref.invalidate(scanRootsProvider);
      ref.invalidate(currentProfileProvider);

      await Future.delayed(const Duration(milliseconds: 100));
      await ref.read(repositoryProvider.future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(removed
                ? AppLocalizations.of(context)!.testingDatabaseRemoved
                : AppLocalizations.of(context)!.noTestingDatabaseFound),
            backgroundColor: removed ? Colors.green : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToRemoveTestingDatabase(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (kDebugMode) print('Error removing testing database: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(allProfilesProvider);
    final currentProfileAsync = ref.watch(currentProfileProvider);
    final isMobile = MobileUtils.isMobile();

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(AppLocalizations.of(context)!.profileManager),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: Column(
        children: [
          DesktopTitleBar(
            title: AppLocalizations.of(context)!.profileManager,
            showBack: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: MobileUtils.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Backup/Restore section - Desktop only (mobile uses Google Drive only)
                  if (!MobileUtils.isMobile()) ...[
                    Card(
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.backupAndRestore,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          // Use Wrap on mobile, Row on desktop
                          isMobile
                              ? Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.upload_file),
                                      label: Text(AppLocalizations.of(context)!.exportBackup),
                                      onPressed: () => _exportBackup(),
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.download),
                                      label: Text(AppLocalizations.of(context)!.importBackup),
                                      onPressed: () => _showImportDialog(),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.upload_file),
                                      label: Text(AppLocalizations.of(context)!.exportBackup),
                                      onPressed: () => _exportBackup(),
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.download),
                                      label: Text(AppLocalizations.of(context)!.importBackup),
                                      onPressed: () => _showImportDialog(),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                  ],
                  // Settings section (Language, Theme, Support) - Mobile only
                  if (MobileUtils.isMobile()) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.settings,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            // Project Filters section
                            Text(
                              AppLocalizations.of(context)!.filters,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            Consumer(
                              builder: (context, ref, _) {
                                final finishedMode = ref.watch(showFinishedProjectsProvider);
                                final finishedNotifier = ref.read(showFinishedProjectsProvider.notifier);
                                return SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(AppLocalizations.of(context)!.hideFinished),
                                  value: finishedMode == 1,
                                  onChanged: (v) => v
                                      ? finishedNotifier.setHideFinished(true)
                                      : finishedNotifier.setHideFinished(false),
                                );
                              },
                            ),
                            Consumer(
                              builder: (context, ref, _) {
                                final showDeadlines = ref.watch(showOnlyWithDeadlineProvider);
                                return SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(AppLocalizations.of(context)!.showOnlyDeadlines),
                                  value: showDeadlines,
                                  onChanged: (v) => ref
                                      .read(showOnlyWithDeadlineProvider.notifier)
                                      .setShowOnlyWithDeadline(v),
                                );
                              },
                            ),
                            Consumer(
                              builder: (context, ref, _) {
                                final phaseFilter = ref.watch(phaseFilterProvider);
                                final customPhases = ref.watch(customPhasesProvider);
                                final l10n = AppLocalizations.of(context)!;
                                return Row(
                                  children: [
                                    const Icon(Icons.filter_list, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(l10n.filterByPhase)),
                                    DropdownButton<String?>(
                                      value: phaseFilter,
                                      underline: const SizedBox.shrink(),
                                      hint: Text(l10n.allPhases),
                                      items: [
                                        DropdownMenuItem(value: null, child: Text(l10n.allPhases)),
                                        ...customPhases.map((phase) => DropdownMenuItem(
                                          value: phase,
                                          child: Text(phase),
                                        )),
                                      ],
                                      onChanged: (v) => ref.read(phaseFilterProvider.notifier).setPhase(v),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const Divider(height: 32),
                            // Language selector
                            Row(
                              children: [
                                const Icon(Icons.language, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.language,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const LanguageSwitcher(),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Theme selector
                            Row(
                              children: [
                                const Icon(Icons.palette, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.theme,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const ThemeSwitcher(),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Support button
                            Row(
                              children: [
                                const Icon(Icons.card_giftcard, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.support,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.card_giftcard, size: 18),
                                  label: Text(AppLocalizations.of(context)!.support),
                                  onPressed: () async {
                                    try {
                                      final uri = Uri.parse('https://www.paypal.com/donate/?hosted_button_id=QHVVZ3LAF39BL');
                                      
                                      // Try to launch URL directly - canLaunchUrl can be unreliable on mobile
                                      // Use externalApplication mode to open in browser
                                      final launched = await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                      
                                      if (!launched && mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(AppLocalizations.of(context)!.couldNotOpenBrowser('https://www.paypal.com/donate/?hosted_button_id=QHVVZ3LAF39BL')),
                                            duration: const Duration(seconds: 5),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(AppLocalizations.of(context)!.errorOpeningBrowser(e.toString())),
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                      if (kDebugMode) print('Error launching support URL: $e');
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Share diagnostic log — helps debug crashes that
                            // only happen after the app has been backgrounded
                            Row(
                              children: [
                                const Icon(Icons.bug_report_outlined, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.shareDiagnosticLog,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.ios_share, size: 18),
                                  label: Text(AppLocalizations.of(context)!.shareDiagnosticLog),
                                  onPressed: _shareDiagnosticLog,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  // Generate/Remove Testing Database buttons — see _showTestingDatabaseTools above
                  if (_showTestingDatabaseTools) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.science, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.generateTestingDatabase,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.science, size: 18),
                                  label: Text(AppLocalizations.of(context)!.generateTestingDatabase),
                                  onPressed: _generateTestingDatabase,
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Icon(Icons.delete_sweep, size: 24, color: Colors.red.shade300),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.removeTestingDatabase,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  icon: Icon(Icons.delete_sweep, size: 18, color: Colors.red.shade300),
                                  label: Text(
                                    AppLocalizations.of(context)!.removeTestingDatabase,
                                    style: TextStyle(color: Colors.red.shade300),
                                  ),
                                  onPressed: _removeTestingDatabase,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade300,
                                    side: BorderSide(color: Colors.red.shade300),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Google Drive Sync section - Link to dedicated page
                  Card(
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cloud, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.googleDriveSync,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.googleDriveSyncDescription,
                            style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.settings),
                            label: Text(AppLocalizations.of(context)!.manageGoogleDriveSync),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const GoogleDriveSyncPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Profiles list
                  if (profilesAsync.hasValue)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.profiles,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(AppLocalizations.of(context)!.createNewProfile),
                          onPressed: _showCreateProfileDialog,
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (profilesAsync.hasValue)
                    profilesAsync.value!.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                AppLocalizations.of(context)!.noProfilesFound,
                                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: profilesAsync.value!.length,
                            itemBuilder: (context, index) {
                              final profile = profilesAsync.value![index];
                              final isCurrentProfile = currentProfileAsync.hasValue &&
                                  currentProfileAsync.value?.id == profile.id;
                              return GestureDetector(
                                onDoubleTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProfileViewPage(profileId: profile.id),
                                    ),
                                  );
                                },
                                child: Card(
                                  color: isCurrentProfile
                                      ? Theme.of(context).colorScheme.primaryContainer
                                      : Theme.of(context).cardColor,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: isMobile
                                      ? _buildMobileProfileTile(context, profile, isCurrentProfile)
                                      : ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          minVerticalPadding: 0,
                                          dense: false,
                                          isThreeLine: false,
                                          leading: profile.photoPath != null && File(profile.photoPath!).existsSync()
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(4),
                                                  child: Image.file(
                                                    File(profile.photoPath!),
                                                    width: 48,
                                                    height: 48,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const SizedBox(
                                                        width: 48,
                                                        height: 48,
                                                        child: Icon(Icons.person),
                                                      );
                                                    },
                                                  ),
                                                )
                                              : const SizedBox(
                                                  width: 48,
                                                  height: 48,
                                                  child: Icon(Icons.person),
                                                ),
                                          title: Text(profile.name),
                                          titleAlignment: ListTileTitleAlignment.center,
                                          subtitle: isCurrentProfile
                                              ? Text(
                                                  AppLocalizations.of(context)!.active,
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                )
                                              : const SizedBox(height: 0),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (!isCurrentProfile)
                                                TextButton(
                                                  onPressed: () => _switchProfile(profile.id),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Theme.of(context).colorScheme.primary,
                                                  ),
                                                  child: Text(AppLocalizations.of(context)!.switchProfile),
                                                ),
                                              IconButton(
                                                icon: const Icon(Icons.visibility),
                                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                                tooltip: AppLocalizations.of(context)!.viewProfile,
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => ProfileViewPage(profileId: profile.id),
                                                    ),
                                                  );
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                tooltip: AppLocalizations.of(context)!.editProfile,
                                                onPressed: () => _editProfile(profile),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete, color: Colors.red.shade300),
                                                tooltip: AppLocalizations.of(context)!.deleteProfile,
                                                onPressed: () => _deleteProfile(profile),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileProfileTile(BuildContext context, Profile profile, bool isCurrentProfile) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              profile.photoPath != null && File(profile.photoPath!).existsSync()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(profile.photoPath!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(Icons.person),
                          );
                        },
                      ),
                    )
                  : const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.person),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (isCurrentProfile)
                      Text(
                        AppLocalizations.of(context)!.active,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!isCurrentProfile)
                ElevatedButton.icon(
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: Text(AppLocalizations.of(context)!.switchProfile),
                  onPressed: () => _switchProfile(profile.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.visibility, size: 18),
                label: Text(AppLocalizations.of(context)!.viewProfile),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileViewPage(profileId: profile.id),
                    ),
                  );
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: Text(AppLocalizations.of(context)!.editProfile),
                onPressed: () => _editProfile(profile),
              ),
              OutlinedButton.icon(
                icon: Icon(Icons.delete, size: 18, color: Colors.red.shade300),
                label: Text(
                  AppLocalizations.of(context)!.deleteProfile,
                  style: TextStyle(color: Colors.red.shade300),
                ),
                onPressed: () => _deleteProfile(profile),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade300,
                  side: BorderSide(color: Colors.red.shade300),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

