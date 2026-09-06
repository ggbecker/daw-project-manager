// Shared dart:io implementation for every native platform — imported only when
// dart.library.io exists (VM), with the web stub taking its place otherwise.
// It covers macOS security-scoped bookmarks, the Windows ShellExecuteW
// workaround, and the Linux direct-binary launch, each guarded by a Platform
// check. Contains macos_secure_bookmarks so Windows/Linux builds may still
// compile this file; the plugin often compiles on all platforms with no-op
// native code on non-macOS.

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:win32/win32.dart' as win32;

final SecureBookmarks _secureBookmarks = SecureBookmarks();

/// Result shape matching the stub for consistent API.
typedef ResolveResult = ({String path, dynamic resourceToStop});

/// Resolves [pathOrBookmark]. If it's a bookmark, returns path and the resolved
/// [FileSystemEntity] for start/stop. Otherwise returns path and null.
Future<ResolveResult> resolvePathOrBookmark(String pathOrBookmark, {bool isFolder = false}) async {
  if (!Platform.isMacOS) {
    return (path: pathOrBookmark, resourceToStop: null);
  }
  try {
    final resolved = await _secureBookmarks.resolveBookmark(pathOrBookmark, isDirectory: isFolder);
    final path = resolved.path;
    if (kDebugMode) print('[FileLauncher] Resolved macOS bookmark to: $path');
    return (path: path, resourceToStop: resolved);
  } catch (e) {
    if (kDebugMode) print('[FileLauncher] Not a bookmark or failed to resolve: $e');
    return (path: pathOrBookmark, resourceToStop: null);
  }
}

Future<void> startAccessingSecurityScoped(dynamic resourceToStop) async {
  if (!Platform.isMacOS || resourceToStop == null) return;
  await _secureBookmarks.startAccessingSecurityScopedResource(resourceToStop as FileSystemEntity);
}

Future<void> stopAccessingSecurityScoped(dynamic resourceToStop) async {
  if (!Platform.isMacOS || resourceToStop == null) return;
  await _secureBookmarks.stopAccessingSecurityScopedResource(resourceToStop as FileSystemEntity);
}

/// Creates a security-scoped bookmark for [path]. On non-macOS returns path.
Future<String> createBookmarkForPath(String path) async {
  if (!Platform.isMacOS) return path;
  final file = File(path);
  if (!await file.exists()) return path;
  return _secureBookmarks.bookmark(file);
}

/// Whether [path] needs the direct-ShellExecuteW workaround below instead of
/// going through url_launcher, on Windows.
///
/// url_launcher_windows unescapes %-encoded file:// URLs before calling
/// ShellExecuteW (to support UTF-8 paths), and ShellExecuteW then reparses the
/// still-"file://"-prefixed string as a URL. Two kinds of character survive
/// `Uri.file`'s encoding only to be misread on that second pass:
///
/// - '#' comes back from '%23' and is read as a fragment delimiter, silently
///   truncating the path there.
/// - '%' comes back from '%25', and ShellExecuteW's URL-to-path conversion
///   percent-decodes a *second* time. A literal '%' followed by two hex digits
///   — common in files saved straight from a download link, e.g.
///   "My%20Track.cpr" — decodes into something else entirely, so the launch
///   either fails or, worse, opens a different project that happens to match
///   the decoded name (verified against ShellExecuteW/PathCreateFromUrlW:
///   "100%25off.cpr" resolves to "100%off.cpr", "My%20Track.cpr" to
///   "My Track.cpr").
///
/// Either character anywhere in the path — folder names included — is enough.
/// '%' is matched on its own rather than only as a '%'-plus-two-hex-digits
/// pair: the workaround is the more correct route for any path, so there is
/// nothing to gain from being precise about which '%' are dangerous.
/// Everything else keeps going through url_launcher unchanged.
@visibleForTesting
bool windowsNeedsDirectShellExecute(String path) =>
    Platform.isWindows && (path.contains('#') || path.contains('%'));

/// Calls ShellExecuteW directly with the raw filesystem path — never a
/// `file://` URI — so there is no percent-encode/unescape round-trip for
/// ShellExecuteW to misinterpret. Per the Win32 docs, a return value greater
/// than 32 indicates success.
bool _shellExecuteOpen(String path) {
  final operation = 'open'.toNativeUtf16();
  final file = path.toNativeUtf16();
  try {
    final result = win32.ShellExecute(
      0,
      operation,
      file,
      nullptr,
      nullptr,
      win32.SW_SHOWNORMAL,
    );
    return result > 32;
  } finally {
    calloc.free(operation);
    calloc.free(file);
  }
}

/// Whether [path] points at something the OS can open — a regular file *or* a
/// directory.
///
/// A macOS DAW "package" project (`.logicx`, `.luna`, `.band`) is a directory
/// on disk even though Finder and `open` treat it like a file, so a plain
/// `File(path).exists()` check wrongly rejects it and the launch never even
/// starts. Both entity kinds are accepted regardless of the caller's
/// `isFolder` hint — that hint only ever mattered for macOS bookmark
/// resolution upstream, not here.
///
/// Also used for the "Launch in DAW" executable override: a configured macOS
/// DAW path is a `.app` bundle, which is likewise a directory on disk.
bool launchTargetExists(String path) =>
    File(path).existsSync() || Directory(path).existsSync();

/// Whether [binaryPath] is a macOS application bundle (`Foo.app`), which is a
/// directory that must be launched via `open -a` rather than executed
/// directly.
@visibleForTesting
bool isMacOsAppBundlePath(String binaryPath) {
  final trimmed = binaryPath.endsWith('/')
      ? binaryPath.substring(0, binaryPath.length - 1)
      : binaryPath;
  return trimmed.toLowerCase().endsWith('.app');
}

/// Checks existence and launches the path with url_launcher, except for
/// Windows paths containing '#' or '%' which go through [_shellExecuteOpen]
/// instead — see [windowsNeedsDirectShellExecute] for why.
Future<bool> launchResolvedPath(String path, bool isFolder) async {
  if (!launchTargetExists(path)) {
    if (kDebugMode) print('[FileLauncher] ERROR: Path does not exist: $path');
    return false;
  }

  if (windowsNeedsDirectShellExecute(path)) {
    final launched = _shellExecuteOpen(path);
    if (kDebugMode) print('[FileLauncher] Launched via ShellExecuteW: $path ($launched)');
    return launched;
  }

  final uri = Uri.file(path);
  if (kDebugMode) print('[FileLauncher] Launching URI: $uri');
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (kDebugMode) print('[FileLauncher] Launch result: $launched');
  return launched;
}

/// Runs [binaryPath] with [projectPath] as its sole argument, bypassing the
/// OS default-application handler (`xdg-open` / file association) entirely.
/// Used when the user has registered a "Launch in DAW" executable override
/// for a DAW (see Settings > DAW Locations) — on Linux where there's usually
/// no working association, and on Windows/macOS as a fallback when the
/// standard launch fails.
///
/// A macOS `.app` is a bundle directory, not an executable, so it goes
/// through `open -a <app> <project>` and the exit code tells us whether the
/// app could be launched. Everything else (Windows `.exe`, a Linux binary or
/// AppImage, a raw macOS executable) is started detached so the DAW outlives
/// this app if it's closed.
Future<bool> launchWithBinary(String binaryPath, String projectPath) async {
  try {
    if (Platform.isMacOS && isMacOsAppBundlePath(binaryPath)) {
      final result = await Process.run(
        'open',
        ['-a', binaryPath, projectPath],
      );
      if (result.exitCode != 0 && kDebugMode) {
        print('[FileLauncher] open -a failed (${result.exitCode}): ${result.stderr}');
      }
      return result.exitCode == 0;
    }
    await Process.start(
      binaryPath,
      [projectPath],
      mode: ProcessStartMode.detached,
    );
    return true;
  } catch (e) {
    if (kDebugMode) print('[FileLauncher] launchWithBinary failed: $e');
    return false;
  }
}
