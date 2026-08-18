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

import 'launch_diagnostics.dart';
import 'windows_file_association.dart';

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
/// ShellExecuteW to misinterpret. Returns ShellExecuteW's raw return value
/// rather than a bool: per the Win32 docs anything greater than 32 is
/// success, and the codes at or below it say *why* it failed, which is the
/// single most useful thing a "nothing happened" bug report can carry (see
/// [LaunchDiagnostics.describeShellExecuteResult]).
int _shellExecuteOpen(String path) {
  final operation = 'open'.toNativeUtf16();
  final file = path.toNativeUtf16();
  try {
    return win32.ShellExecute(
      0,
      operation,
      file,
      nullptr,
      nullptr,
      win32.SW_SHOWNORMAL,
    );
  } finally {
    calloc.free(operation);
    calloc.free(file);
  }
}

/// Checks existence and launches the path with url_launcher, except for
/// Windows paths containing '#' or '%' which go through [_shellExecuteOpen]
/// instead — see [windowsNeedsDirectShellExecute] for why.
///
/// Records each decision to [LaunchDiagnostics] as it goes. On Windows it
/// also reads the registered handler for the file's extension, whatever the
/// outcome: a launch that reports success but opens nothing looks identical
/// from here to one that works, and the association is what tells them
/// apart.
Future<bool> launchResolvedPath(String path, bool isFolder) async {
  final entity = isFolder ? Directory(path) : File(path);
  final exists = await entity.exists();
  LaunchDiagnostics.record('resolved path', {
    'isFolder': isFolder,
    'exists': exists,
    ...LaunchDiagnostics.describePath(path),
    'path': path,
  });

  if (Platform.isWindows && !isFolder) {
    final ext = LaunchDiagnostics.describePath(path)['ext'] as String;
    LaunchDiagnostics.record(
      'windows file association',
      WindowsFileAssociation.describe(ext),
    );
  }

  if (!exists) {
    if (kDebugMode) print('[FileLauncher] ERROR: Path does not exist: $path');
    LaunchDiagnostics.record('FAILED: path does not exist');
    return false;
  }

  if (windowsNeedsDirectShellExecute(path)) {
    final code = _shellExecuteOpen(path);
    final launched = code > 32;
    if (kDebugMode) print('[FileLauncher] Launched via ShellExecuteW: $path ($launched)');
    LaunchDiagnostics.record('ShellExecuteW returned', {
      'code': code,
      'meaning': LaunchDiagnostics.describeShellExecuteResult(code),
      'launched': launched,
    });
    return launched;
  }

  final uri = Uri.file(path);
  if (kDebugMode) print('[FileLauncher] Launching URI: $uri');
  LaunchDiagnostics.record('url_launcher launchUrl', {'uri': uri});
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (kDebugMode) print('[FileLauncher] Launch result: $launched');
    LaunchDiagnostics.record(
      launched ? 'url_launcher returned true' : 'FAILED: url_launcher returned false',
    );
    return launched;
  } catch (e, stack) {
    // launchUrl throws (rather than returning false) when the platform
    // channel itself rejects the call — on Windows that is what a
    // ShellExecuteW failure surfaces as, so this branch is the likely one
    // behind a "Failed to launch" with no other symptom.
    if (kDebugMode) print('[FileLauncher] launchUrl threw: $e');
    LaunchDiagnostics.record('FAILED: url_launcher threw', {
      'error': e,
      'type': e.runtimeType,
    });
    LaunchDiagnostics.record('stack', {'trace': stack});
    return false;
  }
}

/// Runs [binaryPath] directly with [projectPath] as its sole argument —
/// used on Linux when the user has registered a launch-command override for
/// a DAW (see Settings), bypassing `xdg-open`/the MIME-association database
/// entirely. Detached so the DAW process outlives this app if it's closed.
Future<bool> launchWithBinary(String binaryPath, String projectPath) async {
  LaunchDiagnostics.record('launchWithBinary', {
    'binary': binaryPath,
    'binaryExists': File(binaryPath).existsSync(),
    'project': projectPath,
  });
  try {
    await Process.start(
      binaryPath,
      [projectPath],
      mode: ProcessStartMode.detached,
    );
    LaunchDiagnostics.record('launchWithBinary: process started');
    return true;
  } catch (e, stack) {
    if (kDebugMode) print('[FileLauncher] launchWithBinary failed: $e');
    LaunchDiagnostics.record('FAILED: launchWithBinary threw', {
      'error': e,
      'type': e.runtimeType,
    });
    LaunchDiagnostics.record('stack', {'trace': stack});
    return false;
  }
}
