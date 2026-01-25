import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignInException, GoogleSignInExceptionCode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../services/google_drive_sync_service.dart' show GoogleDriveSyncService, UploadCancelledException;
import '../models/backup_progress.dart';
import '../providers/providers.dart';
import '../repository/profile_repository.dart';
import '../repository/project_repository.dart';
import '../utils/mobile_utils.dart';
import '../generated/l10n/app_localizations.dart';
import 'dashboard_page.dart';

class GoogleDriveSyncPage extends ConsumerStatefulWidget {
  const GoogleDriveSyncPage({super.key});

  @override
  ConsumerState<GoogleDriveSyncPage> createState() => _GoogleDriveSyncPageState();
}

class _GoogleDriveSyncPageState extends ConsumerState<GoogleDriveSyncPage> {
  final GoogleDriveSyncService _syncService = GoogleDriveSyncService();
  bool _isSyncing = false;
  String? _syncStatus;
  DateTime? _lastSyncTime;

  bool _isSignedIn = false;
  bool _isCheckingSession = false;
  bool _hasNewerBackupAvailable = false;
  DateTime? _remoteBackupTime;

  @override
  void initState() {
    super.initState();
    // Only check session status once when page is first created
    // The session state persists for the entire app session
    _checkSessionStatusOnce();
    _loadSyncStatus();
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  /// Check session status once when page is created
  /// Session state persists for entire app session - no need to check again
  Future<void> _checkSessionStatusOnce() async {
    if (_isCheckingSession) return;
    
    setState(() {
      _isCheckingSession = true;
    });

    try {
      // Initialize GoogleSignIn (required in 7.x)
      // This will attempt lightweight auth only once per app session
      if (Platform.isAndroid) {
        await _syncService.initialize();
      }
      
      // Initialize credentials storage
      await _syncService.initializeCredentialsStorage();
      
      // On desktop, try to restore session silently first (using saved credentials)
      // This avoids redirecting to browser if we already have valid tokens
      if (!Platform.isAndroid && !Platform.isIOS) {
        try {
          final restored = await _syncService.restoreSession();
          if (mounted) {
            setState(() {
              _isSignedIn = restored;
              _isCheckingSession = false;
              if (restored) {
                _syncStatus = AppLocalizations.of(context)!.sessionActive;
              } else {
                _syncStatus = null;
              }
            });
          }
          return; // Exit early if we restored (or failed to restore) on desktop
        } catch (e) {
          if (kDebugMode) print('Error restoring session on desktop: $e');
          // Continue to check isSignedIn as fallback
        }
      }
      
      // Check if already signed in (without prompting)
      // Wait a bit for lightweight authentication to complete (if it happens on first init)
      if (Platform.isAndroid) {
        await Future.delayed(const Duration(milliseconds: 1500));
      }
      
      final isSignedIn = await _syncService.checkSignedInStatus();
      
      if (mounted) {
        setState(() {
          _isSignedIn = isSignedIn;
          _isCheckingSession = false;
          if (isSignedIn) {
            _syncStatus = AppLocalizations.of(context)!.signedIn;
            // Try to restore session silently
            _syncService.restoreSession().then((restored) {
              if (mounted) {
                setState(() {
                  if (restored) {
                    _syncStatus = AppLocalizations.of(context)!.sessionActive;
                  } else {
                    _syncStatus = AppLocalizations.of(context)!.signedIn;
                  }
                });
              }
            }).catchError((e) {
              if (kDebugMode) print('Error restoring session: $e');
            });
          } else {
            _syncStatus = null;
          }
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error checking session status: $e');
      if (mounted) {
        setState(() {
          _isSignedIn = false;
          _isCheckingSession = false;
          _syncStatus = null;
        });
      }
    }
  }
  
  /// Check if user is already signed in (without prompting)
  /// This is called when user explicitly clicks sign in button
  /// On desktop, automatically restore session from saved credentials
  /// On mobile, just check session status
  Future<void> _checkSessionStatus() async {
    // If already signed in, don't check again
    if (_isSignedIn) {
      if (kDebugMode) print('Already signed in, skipping session check');
      return;
    }
    
    await _checkSessionStatusOnce();
  }

  Future<void> _loadSyncStatus() async {
    try {
      final lastSync = await _syncService.getLastSyncTime();
      if (lastSync != null) {
        setState(() {
          _lastSyncTime = lastSync;
        });
      }
      
      // Check if newer backup is available (only if signed in and on mobile)
      if (_isSignedIn && (Platform.isAndroid || Platform.isIOS)) {
        await _checkForNewerBackup();
      }
    } catch (e) {
      if (kDebugMode) print('Error loading sync status: $e');
    }
  }

  /// Check if a newer backup is available on Drive
  Future<void> _checkForNewerBackup() async {
    try {
      final backupInfo = await _syncService.getBackupInfo();
      if (mounted) {
        setState(() {
          _hasNewerBackupAvailable = backupInfo['isNewer'] == true;
          _remoteBackupTime = backupInfo['remoteTimestamp'] as DateTime?;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error checking for newer backup: $e');
      if (mounted) {
        setState(() {
          _hasNewerBackupAvailable = false;
          _remoteBackupTime = null;
        });
      }
    }
  }

  Future<void> _signInToGoogleDrive() async {
    try {
      setState(() {
        _isSyncing = true;
        _syncStatus = null;
      });

      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile sign-in
        await _syncService.initialize();
        final success = await _syncService.signIn();

        if (success) {
          // Wait a bit for authenticationEvents to process
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Verify sign-in status after authentication
          final verifiedSignedIn = await _syncService.checkSignedInStatus();
          
          setState(() {
            _isSignedIn = verifiedSignedIn;
            _isSyncing = false;
          });

          if (verifiedSignedIn) {
            // On Android, don't create initial backup automatically
            // User can manually upload backup if needed
            setState(() {
              _syncStatus = AppLocalizations.of(context)!.successfullySignedInToGoogleDrive;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.successfullySignedInToGoogleDriveMessage),
                  backgroundColor: Colors.green,
                ),
              );
            }

            await _loadSyncStatus();
          } else {
            setState(() {
              _syncStatus = AppLocalizations.of(context)!.signInCancelledOrFailed;
              _isSyncing = false;
            });
          }
        } else {
          setState(() {
            _isSignedIn = false;
            _syncStatus = AppLocalizations.of(context)!.signInCancelledOrFailed;
            _isSyncing = false;
          });
        }
      } else {
        // Desktop sign-in
        setState(() {
          _isSyncing = true;
          _syncStatus = null;
        });

        try {
          // Get authorization URL
          final authUrl = await _syncService.getDesktopAuthorizationUrl();

          // Launch browser for authorization
          final launched = await launchUrl(
            authUrl,
            mode: LaunchMode.externalApplication,
          );

          if (!launched) {
            setState(() {
              _syncStatus = AppLocalizations.of(context)!.failedToLaunchBrowser;
              _isSyncing = false;
            });
            return;
          }

          // Show dialog to enter authorization code
          final code = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (context) => _AuthorizationCodeDialog(),
          );

          if (code == null || code.isEmpty) {
            setState(() {
              _syncStatus = AppLocalizations.of(context)!.signInCancelled;
              _isSyncing = false;
            });
            return;
          }

          // Exchange code for tokens
          final authClient = await _syncService.signInDesktopWithCode(code);

          if (authClient == null) {
            setState(() {
              _syncStatus = AppLocalizations.of(context)!.failedToExchangeAuthorizationCode;
              _isSyncing = false;
            });
            return;
          }

          // Set up Drive API
          _syncService.driveApi = drive.DriveApi(authClient);
          _syncService.desktopAuthClient = authClient;
          await _syncService.ensureAppDataFolder();

          setState(() {
            _isSignedIn = true;
            _isSyncing = false;
          });

          // On desktop, don't create initial backup automatically
          // User can manually upload backup if needed
          setState(() {
            _syncStatus = AppLocalizations.of(context)!.successfullySignedInToGoogleDrive;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.successfullySignedInToGoogleDriveMessage),
                backgroundColor: Colors.green,
              ),
            );
          }

          await _loadSyncStatus();
        } catch (e) {
          setState(() {
            _syncStatus = AppLocalizations.of(context)!.errorSigningIn(e.toString());
            _isSyncing = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.errorSigningIn(e.toString())),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error during sign-in: $e');
      
      String errorMessage = AppLocalizations.of(context)!.unknownError;
      String errorDetails = e.toString();

      if (e is GoogleSignInException) {
        errorMessage = AppLocalizations.of(context)!.googleSignInError;
        errorDetails = e.description ?? e.toString();
        
        if (e.code == GoogleSignInExceptionCode.unknownError) {
          if (e.description?.contains('[28444]') ?? false) {
            errorDetails = AppLocalizations.of(context)!.developerConsoleNotSetUp;
          }
        }
      } else if (e is PlatformException) {
        errorMessage = AppLocalizations.of(context)!.platformError;
        errorDetails = e.message ?? e.toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage: $errorDetails'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      setState(() {
        _isSyncing = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _signOutFromGoogleDrive() async {
    try {
      setState(() {
        _isSyncing = true;
        _syncStatus = null;
      });

      await _syncService.signOut();

      setState(() {
        _isSignedIn = false;
        _syncStatus = AppLocalizations.of(context)!.signedOutFromGoogleDrive;
        _lastSyncTime = null;
      });
    } catch (e) {
      setState(() {
        _syncStatus = AppLocalizations.of(context)!.errorSigningOut(e.toString());
      });
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  /// Check for new backup (doesn't download - just checks if one is available)
  Future<void> _checkForBackupManually() async {
    try {
      setState(() {
        _isSyncing = true;
        _syncStatus = AppLocalizations.of(context)!.checkingForBackup;
      });

      await _checkForNewerBackup();
      
      if (_hasNewerBackupAvailable) {
        setState(() {
          _syncStatus = AppLocalizations.of(context)!.newerBackupAvailable;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.newerBackupAvailable),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: AppLocalizations.of(context)!.download,
                onPressed: () => _downloadBackupFromDrive(),
              ),
            ),
          );
        }
      } else {
        setState(() {
          _syncStatus = AppLocalizations.of(context)!.backupUpToDate;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.backupUpToDate),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _syncStatus = AppLocalizations.of(context)!.errorCheckingBackup(e.toString());
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorCheckingBackup(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  /// Upload backup to Google Drive (manual)
  Future<void> _uploadBackupToDrive() async {
    try {
      // Check if remote backup is newer before uploading
      final backupInfo = await _syncService.getBackupInfo();
      if (backupInfo['isNewer'] == true) {
        // Show confirmation dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(AppLocalizations.of(context)!.confirmUpload),
            content: Text(AppLocalizations.of(context)!.remoteBackupIsNewer),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context)!.uploadBackup),
              ),
            ],
          ),
        );
        
        if (confirmed != true) {
          return; // User cancelled
        }
      }
      
      setState(() {
        _isSyncing = true;
        _syncStatus = AppLocalizations.of(context)!.uploadingBackup;
      });

      final profileRepo = await ref.read(profileRepositoryProvider.future);
      final currentProfileId = profileRepo.getCurrentProfileId();
      
      if (currentProfileId == null) {
        setState(() {
          _syncStatus = AppLocalizations.of(context)!.errorNoProfileSelected;
        });
        return;
      }

      final projectRepo = await ref.read(repositoryProvider.future);
      
      // Show progress dialog on desktop
      if (!MobileUtils.isMobile()) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _BackupProgressDialog(
            progressStream: _syncService.progressStream,
            syncService: _syncService,
          ),
        );
      }
      
      await _syncService.uploadDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      // Close progress dialog if it's open
      if (!MobileUtils.isMobile() && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      setState(() {
        _syncStatus = AppLocalizations.of(context)!.backupUploadedSuccessfully;
        _lastSyncTime = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.backupUploadedSuccessfullyMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on UploadCancelledException catch (_) {
      // User cancelled - close dialog and show info message (no error)
      if (!MobileUtils.isMobile() && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      setState(() {
        _syncStatus = 'Upload cancelled';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup upload cancelled by user'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Other errors - close dialog and show error
      if (!MobileUtils.isMobile() && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      setState(() {
        _syncStatus = AppLocalizations.of(context)!.errorUploadingBackup(e.toString());
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorUploadingBackup(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  /// Download backup from Google Drive (manual)
  Future<void> _downloadBackupFromDrive() async {
    setState(() {
      _isSyncing = true;
      _syncStatus = AppLocalizations.of(context)!.downloadingBackup;
    });

    try {
      final profileRepo = await ref.read(profileRepositoryProvider.future);
      
      // On mobile, allow download even without active profile (will activate first profile after download)
      // On desktop, require active profile
      if (!Platform.isAndroid && !Platform.isIOS) {
        final currentProfileId = profileRepo.getCurrentProfileId();
        if (currentProfileId == null) {
          setState(() {
            _syncStatus = AppLocalizations.of(context)!.errorNoProfileSelected;
          });
          return;
        }
      }

      // Download remote data
      Map<String, dynamic> remoteData;
      try {
        remoteData = await _syncService.downloadDatabase();
      } catch (e) {
        if (e.toString().contains('Database file not found')) {
          // No backup file exists yet - this is normal for first-time setup
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.noBackupFileFound),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
          }
          setState(() {
            _syncStatus = AppLocalizations.of(context)!.noBackupFileFoundStatus;
          });
          return;
        }
        rethrow;
      }
      
      // Ask user for confirmation if local data exists
      final projectRepo = await ref.read(repositoryProvider.future);
      final hasLocalData = projectRepo.projectsBox.isNotEmpty || projectRepo.releasesBox.isNotEmpty;
      
      bool downloadPreviewSongs = true; // Default to true
      
      if (hasLocalData) {
        final dialogResult = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (ctx) => _DownloadBackupDialog(
            downloadPreviewSongs: downloadPreviewSongs,
          ),
        );
        
        if (dialogResult == null || dialogResult['confirm'] != true) {
          setState(() {
            _syncStatus = AppLocalizations.of(context)!.downloadCancelled;
          });
          return;
        }
        
        downloadPreviewSongs = dialogResult['downloadPreviewSongs'] as bool? ?? true;
      }

      // Merge remote data with local (this will overwrite local with remote)
      final result = await _syncService.mergeData(
        remoteData: remoteData,
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        downloadPreviewSongs: downloadPreviewSongs,
      );

      // On mobile, if no profile is active, activate the first profile from backup
      if (Platform.isAndroid || Platform.isIOS) {
        final currentProfileId = profileRepo.getCurrentProfileId();
        if (currentProfileId == null) {
          final allProfiles = profileRepo.getAllProfiles();
          if (allProfiles.isNotEmpty) {
            final firstProfile = allProfiles.first;
            await profileRepo.setCurrentProfileId(firstProfile.id);
            if (kDebugMode) {
              print('Mobile: Activated first profile from backup: ${firstProfile.name} (${firstProfile.id})');
            }
          }
        }
      }

      setState(() {
        _syncStatus = AppLocalizations.of(context)!.backupDownloadedDetailed(
          result.projectsAdded,
          result.projectsUpdated,
          result.releasesAdded,
          result.releasesUpdated,
          result.previewSongsDownloaded,
          result.previewSongsUpdated,
        );
        _lastSyncTime = DateTime.now();
        _hasNewerBackupAvailable = false; // Reset after successful download
      });
      
      // Re-check for newer backup after download (in case another backup was uploaded)
      if (Platform.isAndroid || Platform.isIOS) {
        await _checkForNewerBackup();
      }

      // CRITICAL: Don't invalidate repositoryProvider - it will lose the box reference!
      // The repository already has the correct box reference, we just need to restart the stream
      // Invalidate only the stream providers to force them to re-read from the box
      ref.invalidate(allProjectsStreamProvider);
      ref.invalidate(releasesProvider);
      ref.invalidate(scanRootsProvider);
      
      // Also invalidate currentProfileProvider to ensure profile state is refreshed
      ref.invalidate(currentProfileProvider);
      
      // Wait a bit for stream to restart
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Force a read from the repository to ensure data is loaded
      try {
        await ref.read(repositoryProvider.future);
      } catch (e) {
        if (kDebugMode) print('Error reading repository after download: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.backupDownloaded(
              result.projectsAdded,
              result.projectsUpdated,
              result.releasesAdded,
              result.releasesUpdated,
            )),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _syncStatus = AppLocalizations.of(context)!.errorDownloadingBackup(e.toString());
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorDownloadingBackup(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MobileUtils.isMobile();
    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(AppLocalizations.of(context)!.googleDriveSync),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: Column(
        children: [
          // Window title bar (desktop only)
          if (!isMobile && !kDebugMode && !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux))
            GestureDetector(
              onPanStart: (_) => windowManager.startDragging(),
              onDoubleTap: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.restore();
                } else {
                  windowManager.maximize();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                height: 40,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                      tooltip: AppLocalizations.of(context)!.back,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        AppLocalizations.of(context)!.googleDriveSync,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.titleMedium?.color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux))
                      const WindowButtons(),
                  ],
                ),
              ),
            ),
          // Debug mode back button (Windows desktop only)
          if (!isMobile && kDebugMode && Platform.isWindows)
            Container(
              color: Theme.of(context).cardColor,
              height: 40,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
                    onPressed: () => Navigator.pop(context),
                    tooltip: AppLocalizations.of(context)!.back,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      AppLocalizations.of(context)!.googleDriveSync,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleMedium?.color,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: MobileUtils.getResponsivePadding(context),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Google Drive Sync section
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isSignedIn) ...[
                          FutureBuilder<String?>(
                            future: _syncService.getCurrentUserEmail(),
                            builder: (context, emailSnapshot) {
                              if (emailSnapshot.hasData && emailSnapshot.data != null) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    AppLocalizations.of(context)!.signedInAs(emailSnapshot.data!),
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          if (_lastSyncTime != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                AppLocalizations.of(context)!.lastSync(
                                  DateFormat.yMMMd().add_jm().format(_lastSyncTime!),
                                ),
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ),
                          // Show remote backup time if available
                          if (_remoteBackupTime != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                AppLocalizations.of(context)!.remoteBackupTime(
                                  DateFormat.yMMMd().add_jm().format(_remoteBackupTime!),
                                ),
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ),
                          // Always reserve space for backup notification on mobile (prevent UI shift)
                          if (Platform.isAndroid || Platform.isIOS)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 8.0),
                              height: _hasNewerBackupAvailable ? null : 0,
                              child: _hasNewerBackupAvailable
                                  ? Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        border: Border.all(color: Colors.orange.shade300, width: 1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.cloud_download, color: Colors.orange.shade700, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              AppLocalizations.of(context)!.newerBackupAvailable,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.orange.shade900,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                        ],
                        // Use Wrap on mobile, Row on desktop
                        isMobile
                            ? Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (!_isSignedIn)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.login),
                                        label: Text(AppLocalizations.of(context)!.signInToGoogleDrive),
                                        onPressed: (_isSyncing || _isCheckingSession) ? null : () => _signInToGoogleDrive(),
                                      ),
                                    )
                                  else ...[
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.refresh, size: 18),
                                        label: Text(AppLocalizations.of(context)!.checkForBackup),
                                        onPressed: _isSyncing ? null : () => _checkForBackupManually(),
                                      ),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.cloud_upload, size: 18),
                                        label: Text(AppLocalizations.of(context)!.uploadBackup),
                                        onPressed: _isSyncing ? null : () => _uploadBackupToDrive(),
                                      ),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.cloud_download, size: 18),
                                        label: Text(AppLocalizations.of(context)!.downloadBackup),
                                        onPressed: _isSyncing ? null : () => _downloadBackupFromDrive(),
                                      ),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: TextButton.icon(
                                        icon: const Icon(Icons.logout, size: 18),
                                        label: Text(AppLocalizations.of(context)!.signOut),
                                        onPressed: _isSyncing ? null : () => _signOutFromGoogleDrive(),
                                      ),
                                    ),
                                  ],
                                  if (_isSyncing)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              )
                            : Row(
                                children: [
                                  if (!_isSignedIn)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.login),
                                      label: Text(AppLocalizations.of(context)!.signInToGoogleDrive),
                                      onPressed: (_isSyncing || _isCheckingSession) ? null : () => _signInToGoogleDrive(),
                                    )
                                  else ...[
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.refresh, size: 18),
                                          label: Text(AppLocalizations.of(context)!.checkForBackup),
                                          onPressed: _isSyncing ? null : () => _checkForBackupManually(),
                                        ),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.cloud_upload, size: 18),
                                          label: Text(AppLocalizations.of(context)!.uploadBackup),
                                          onPressed: _isSyncing ? null : () => _uploadBackupToDrive(),
                                        ),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.cloud_download, size: 18),
                                          label: Text(AppLocalizations.of(context)!.downloadBackup),
                                          onPressed: _isSyncing ? null : () => _downloadBackupFromDrive(),
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(Icons.logout, size: 18),
                                          label: Text(AppLocalizations.of(context)!.signOut),
                                          onPressed: _isSyncing ? null : () => _signOutFromGoogleDrive(),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (_isSyncing) ...[
                                    const SizedBox(width: 16),
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ],
                                ],
                              ),
                        if (_syncStatus != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _syncStatus!,
                            style: TextStyle(
                              fontSize: 14,
                              color: _syncStatus!.contains('Error') || _syncStatus!.contains('Failed')
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for confirming backup download with option to download preview songs
class _DownloadBackupDialog extends StatefulWidget {
  final bool downloadPreviewSongs;
  
  const _DownloadBackupDialog({
    required this.downloadPreviewSongs,
  });

  @override
  State<_DownloadBackupDialog> createState() => _DownloadBackupDialogState();
}

class _DownloadBackupDialogState extends State<_DownloadBackupDialog> {
  late bool _downloadPreviewSongs;

  @override
  void initState() {
    super.initState();
    _downloadPreviewSongs = widget.downloadPreviewSongs;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(AppLocalizations.of(context)!.downloadBackup),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.downloadBackupConfirmation,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _downloadPreviewSongs,
            onChanged: (value) {
              setState(() {
                _downloadPreviewSongs = value ?? true;
              });
            },
            title: Text(AppLocalizations.of(context)!.downloadPreviewSongs),
            subtitle: Text(
              AppLocalizations.of(context)!.downloadPreviewSongsExplanation,
            ),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, {'confirm': false}),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'confirm': true,
            'downloadPreviewSongs': _downloadPreviewSongs,
          }),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text(AppLocalizations.of(context)!.replaceLocalData),
        ),
      ],
    );
  }
}

/// Dialog for entering authorization code (Desktop)
class _AuthorizationCodeDialog extends StatefulWidget {
  @override
  State<_AuthorizationCodeDialog> createState() => _AuthorizationCodeDialogState();
}

class _AuthorizationCodeDialogState extends State<_AuthorizationCodeDialog> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.enterAuthorizationCode),
      content: TextField(
        controller: _codeController,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.authorizationCode,
          hintText: AppLocalizations.of(context)!.pasteCodeFromBrowser,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _codeController.text),
          child: Text(AppLocalizations.of(context)!.continueButton),
        ),
      ],
    );
  }
}

/// Dialog for showing backup upload progress
class _BackupProgressDialog extends StatefulWidget {
  final Stream<BackupProgress> progressStream;
  final GoogleDriveSyncService syncService;

  const _BackupProgressDialog({
    required this.progressStream,
    required this.syncService,
  });

  @override
  State<_BackupProgressDialog> createState() => _BackupProgressDialogState();
}

class _BackupProgressDialogState extends State<_BackupProgressDialog> {
  bool _isCancelling = false;

  String _getStageText(BackupProgressStage stage, BuildContext context) {
    switch (stage) {
      case BackupProgressStage.collectingData:
        return 'Collecting data...';
      case BackupProgressStage.uploadingPreviewSongs:
        return 'Uploading preview songs...';
      case BackupProgressStage.uploadingDatabase:
        return 'Uploading database...';
      case BackupProgressStage.completed:
        return 'Completed!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Row(
        children: [
          const Icon(Icons.cloud_upload, size: 24),
          const SizedBox(width: 8),
          Text(_isCancelling ? 'Cancelling...' : 'Uploading Backup'),
        ],
      ),
      content: StreamBuilder<BackupProgress>(
        stream: widget.progressStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 150,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final progress = snapshot.data!;
          final percentage = (progress.progress * 100).toStringAsFixed(0);

          return SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stage indicator
                Text(
                  _isCancelling ? 'Cancelling upload...' : _getStageText(progress.stage, context),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isCancelling ? Colors.orange : null,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Current item
                Text(
                  _isCancelling ? 'Please wait while we stop the upload...' : progress.currentItem,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Progress indicator
                if (progress.totalItems > 0)
                  Text(
                    '${progress.currentIndex} / ${progress.totalItems}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                const SizedBox(height: 8),
                
                // Progress bar
                LinearProgressIndicator(
                  value: progress.progress,
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                
                // Percentage
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        StreamBuilder<BackupProgress>(
          stream: widget.progressStream,
          builder: (context, snapshot) {
            // Only show cancel button if not completed or cancelling
            if (!snapshot.hasData || 
                snapshot.data!.stage == BackupProgressStage.completed ||
                _isCancelling) {
              return const SizedBox.shrink();
            }
            
            return TextButton(
              onPressed: () {
                setState(() {
                  _isCancelling = true;
                });
                widget.syncService.cancelUpload();
                // Don't close dialog here - let the exception handling close it
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            );
          },
        ),
      ],
    );
  }
}

