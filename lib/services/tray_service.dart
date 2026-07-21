import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../generated/l10n/app_localizations.dart';
import '../main.dart' show navigatorKey, quitApp;
import '../providers/providers.dart';
import 'google_drive_sync_service.dart';

/// Runs the desktop system tray icon (Windows/Linux) / menu bar icon (macOS)
/// so background services (auto-backup, deadline notifications) can keep
/// running while the window is hidden, per [closeToTrayProvider].
class TrayService with TrayListener {
  TrayService(this._container, this._syncService);

  final ProviderContainer _container;
  final GoogleDriveSyncService _syncService;

  bool _initialized = false;
  StreamSubscription<bool>? _authStateSubscription;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    trayManager.addListener(this);
    await trayManager.setIcon(Platform.isWindows ? 'app_icon.ico' : 'app_icon.png');
    await trayManager.setToolTip('DAW Project Manager');
    // Localized labels need a BuildContext, which isn't ready until the
    // first frame — build the real menu right after that.
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_rebuildMenu()));
    // The tray's GoogleDriveSyncService is a separate instance from the one
    // the sign-in UI uses, so it doesn't see sign-in/out unless notified.
    _authStateSubscription =
        GoogleDriveSyncService.authStateStream.listen(_handleAuthStateChanged);
  }

  Future<void> _handleAuthStateChanged(bool signedIn) async {
    if (signedIn && !_syncService.isSignedIn) {
      await _syncService.restoreSession();
    } else if (!signedIn && _syncService.isSignedIn) {
      _syncService.forgetLocalSession();
    }
    await _rebuildMenu();
  }

  AppLocalizations? get _l10n {
    final context = navigatorKey.currentContext;
    if (context == null) return null;
    return AppLocalizations.of(context);
  }

  /// Formats when the last backup happened, for the tray's status line.
  /// Exposed for testing.
  static String formatLastBackupLabel(DateTime timestamp) =>
      DateFormat('MMM d, HH:mm').format(timestamp.toLocal());

  Future<void> _rebuildMenu() async {
    final l10n = _l10n;
    if (l10n == null) return;

    final project = _container.read(activeProjectProvider);
    final paused = _container.read(workTimerPausedProvider);

    DateTime? lastUpload;
    try {
      lastUpload = await _syncService.getLastBackupUploadTimestamp();
    } catch (_) {}

    final items = <MenuItem>[
      MenuItem(key: 'show', label: l10n.trayShowWindow),
      MenuItem.separator(),
      MenuItem(
        key: 'backup_status',
        label: lastUpload != null
            ? l10n.trayLastBackup(formatLastBackupLabel(lastUpload))
            : l10n.trayNeverBackedUp,
        disabled: true,
      ),
      MenuItem(
        key: 'backup_now',
        label: l10n.trayBackupNow,
        disabled: !_syncService.isSignedIn,
      ),
    ];

    if (project != null) {
      items.add(MenuItem.separator());
      items.add(MenuItem(
        key: 'toggle_session',
        label: paused ? l10n.trayResumeSession : l10n.trayPauseSession,
      ));
    }

    items.add(MenuItem.separator());
    items.add(MenuItem(key: 'quit', label: l10n.menuQuit));

    await trayManager.setContextMenu(Menu(items: items));
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _runManualBackup() async {
    try {
      final profileRepo = await _container.read(profileRepositoryProvider.future);
      final projectRepo = await _container.read(repositoryProvider.future);
      await _syncService.uploadDatabase(
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        uploadAutoDetectedSongs: false,
      );
    } catch (e) {
      if (kDebugMode) print('[TrayService] Manual backup failed: $e');
    }
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(_showWindow());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(_rebuildMenu().then((_) => trayManager.popUpContextMenu()));
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        unawaited(_showWindow());
        break;
      case 'backup_now':
        unawaited(_runManualBackup());
        break;
      case 'toggle_session':
        final notifier = _container.read(workTimerProvider.notifier);
        if (_container.read(workTimerPausedProvider)) {
          notifier.resume();
        } else {
          notifier.pause();
        }
        break;
      case 'quit':
        unawaited(quitApp());
        break;
    }
  }

  Future<void> dispose() async {
    await _authStateSubscription?.cancel();
    _authStateSubscription = null;
    trayManager.removeListener(this);
  }
}
