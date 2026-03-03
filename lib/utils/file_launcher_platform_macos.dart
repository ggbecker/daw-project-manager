// macOS implementation: uses security-scoped bookmarks.
// Imported only when dart.library.io exists (VM). Contains macos_secure_bookmarks
// so Windows/Linux builds may still compile this file; the plugin often
// compiles on all platforms with no-op native code on non-macOS.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'package:url_launcher/url_launcher.dart';

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

/// Checks existence and launches the path with url_launcher.
Future<bool> launchResolvedPath(String path, bool isFolder) async {
  final entity = isFolder ? Directory(path) : File(path);
  if (!await entity.exists()) {
    if (kDebugMode) print('[FileLauncher] ERROR: Path does not exist: $path');
    return false;
  }
  final uri = Uri.file(path);
  if (kDebugMode) print('[FileLauncher] Launching URI: $uri');
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (kDebugMode) print('[FileLauncher] Launch result: $launched');
  return launched;
}
