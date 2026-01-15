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
import '../services/google_drive_sync_service.dart';
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
    } catch (e) {
      if (kDebugMode) print('Error loading sync status: $e');
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

  Future<void> _syncWithGoogleDrive() async {
    try {
      setState(() {
        _isSyncing = true;
        _syncStatus = AppLocalizations.of(context)!.syncing;
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
      final result = await _syncService.syncDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      setState(() {
        _syncStatus = AppLocalizations.of(context)!.syncCompleted(
          result.projectsAdded,
          result.projectsUpdated,
          result.releasesAdded,
          result.releasesUpdated,
        );
        _lastSyncTime = DateTime.now();
      });

      // Invalidate providers to refresh UI
      ref.invalidate(allProjectsStreamProvider);
      ref.invalidate(releasesProvider);
      ref.invalidate(scanRootsProvider);
      ref.invalidate(currentProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.syncCompleted(
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
        _syncStatus = AppLocalizations.of(context)!.errorSyncing(e.toString());
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSyncing(e.toString())),
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
      await _syncService.uploadDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

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
    } catch (e) {
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
        _syncStatus = AppLocalizations.of(context)!.backupDownloaded(
          result.projectsAdded,
          result.projectsUpdated,
          result.releasesAdded,
          result.releasesUpdated,
        );
        _lastSyncTime = DateTime.now();
      });

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
                                        icon: const Icon(Icons.sync, size: 18),
                                        label: Text(AppLocalizations.of(context)!.syncNow),
                                        onPressed: _isSyncing ? null : () => _syncWithGoogleDrive(),
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
                                          icon: const Icon(Icons.sync, size: 18),
                                          label: Text(AppLocalizations.of(context)!.syncNow),
                                          onPressed: _isSyncing ? null : () => _syncWithGoogleDrive(),
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
          child: const Text('Cancel'),
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _codeController.text),
          child: Text(AppLocalizations.of(context)!.continueButton),
        ),
      ],
    );
  }
}

