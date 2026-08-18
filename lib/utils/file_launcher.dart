import 'package:flutter/foundation.dart';

// Conditional import: stub on web (no dart:io), macOS/VM implementation on desktop.
// The VM implementation uses macos_secure_bookmarks only when Platform.isMacOS.
import 'file_launcher_platform_stub.dart'
    if (dart.library.io) 'file_launcher_platform_macos.dart' as platform;
import 'launch_diagnostics.dart';

/// Utilities for launching files and folders in the system file manager.
///
/// On macOS (sandboxed), [pathOrBookmark] can be either:
/// - A **path string** (e.g. from a non-sandbox context or fallback).
/// - A **bookmark string** (from [createBookmarkForPath] after the user's first pick).
/// Store the bookmark in your DB/prefs and pass it here for persistent access.
///
/// On Windows/Linux, [pathOrBookmark] is always treated as a path.
class FileLauncher {
  /// Open a folder or file with persistent access handling for macOS.
  /// [pathOrBookmark] is a path (Windows/Linux) or path/bookmark (macOS).
  static Future<bool> launch(String pathOrBookmark, {bool isFolder = false}) async {
    dynamic resourceToStop;
    try {
      final result = await platform.resolvePathOrBookmark(pathOrBookmark, isFolder: isFolder);
      resourceToStop = result.resourceToStop;

      if (resourceToStop != null) {
        await platform.startAccessingSecurityScoped(resourceToStop);
      }

      return await platform.launchResolvedPath(result.path, isFolder);
    } catch (e, stack) {
      if (kDebugMode) print('[FileLauncher] Error: $e');
      LaunchDiagnostics.record('FAILED: FileLauncher.launch threw', {
        'error': e,
        'type': e.runtimeType,
      });
      LaunchDiagnostics.record('stack', {'trace': stack});
      return false;
    } finally {
      if (resourceToStop != null) {
        await platform.stopAccessingSecurityScoped(resourceToStop);
      }
    }
  }

  /// Open a folder in the system file manager.
  /// Pass a path or (on macOS) a bookmark string for the folder.
  static Future<bool> openFolder(String pathOrBookmark) async =>
      launch(pathOrBookmark, isFolder: true);

  /// Open a file with the default system application.
  static Future<bool> openFile(String pathOrBookmark) async =>
      launch(pathOrBookmark, isFolder: false);

  /// Launch a project file (DAW project, audio file, etc.).
  static Future<bool> launchProject(String pathOrBookmark) async =>
      launch(pathOrBookmark, isFolder: false);

  /// Launch [projectPath] via a specific [binaryPath] directly, bypassing
  /// the OS default-application handler entirely. Linux-only in practice —
  /// see the "Launch in DAW" binary override in Settings.
  static Future<bool> launchWithBinary(
    String binaryPath,
    String projectPath,
  ) async {
    try {
      return await platform.launchWithBinary(binaryPath, projectPath);
    } catch (e, stack) {
      if (kDebugMode) print('[FileLauncher] Error: $e');
      LaunchDiagnostics.record('FAILED: launchWithBinary threw', {
        'error': e,
        'type': e.runtimeType,
      });
      LaunchDiagnostics.record('stack', {'trace': stack});
      return false;
    }
  }

  /// Creates a bookmark for [path] for use on macOS (sandbox).
  /// On other platforms returns [path] unchanged.
  ///
  /// **First-pick flow on macOS:** when the user picks a file/folder, call this
  /// and store the returned string (not the path) in your DB/prefs. Then use
  /// that string with [openFolder], [openFile], or [launchProject].
  static Future<String> createBookmarkForPath(String path) async =>
      platform.createBookmarkForPath(path);
}
