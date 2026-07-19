// macOS implementation: uses security-scoped bookmarks.
// Imported only when dart.library.io exists (VM). Contains macos_secure_bookmarks
// so Windows/Linux builds may still compile this file; the plugin often
// compiles on all platforms with no-op native code on non-macOS.

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
/// ShellExecuteW (to support UTF-8 paths). That reintroduces literal '#'
/// characters into the still-"file://"-prefixed string, which ShellExecuteW
/// then reparses as a URL, treating '#' as a fragment delimiter and silently
/// truncating the path there. Only paths containing '#' hit this, so
/// everything else keeps going through url_launcher unchanged.
@visibleForTesting
bool windowsNeedsDirectShellExecute(String path) =>
    Platform.isWindows && path.contains('#');

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

/// Checks existence and launches the path with url_launcher, except for
/// Windows paths containing '#' which go through [_shellExecuteOpen] instead
/// — see [windowsNeedsDirectShellExecute] for why.
Future<bool> launchResolvedPath(String path, bool isFolder) async {
  final entity = isFolder ? Directory(path) : File(path);
  if (!await entity.exists()) {
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
