// Stub for platforms without dart:io (e.g. web) or when not on macOS.
// Never imports macos_secure_bookmarks so Windows/Linux builds stay clean.

/// Result of resolving a path or bookmark: [path] to use, [resourceToStop] for cleanup (null on stub).
typedef ResolveResult = ({String path, dynamic resourceToStop});

/// Resolves [pathOrBookmark] to a file path. On stub this is the identity; [resourceToStop] is null.
/// [isFolder] is used on macOS when resolving a bookmark (isDirectory parameter).
Future<ResolveResult> resolvePathOrBookmark(String pathOrBookmark, {bool isFolder = false}) async =>
    (path: pathOrBookmark, resourceToStop: null);

/// No-op: no security-scoped access on this platform.
Future<void> startAccessingSecurityScoped(dynamic resourceToStop) async {}

/// No-op: no security-scoped access on this platform.
Future<void> stopAccessingSecurityScoped(dynamic resourceToStop) async {}

/// Creates a bookmark for [path]. On non-macOS returns the path as-is for storage.
Future<String> createBookmarkForPath(String path) async => path;

/// Launches the resolved path. Stub (e.g. web): no local file launch, returns false.
Future<bool> launchResolvedPath(String path, bool isFolder) async => false;

/// Stub (e.g. web): no filesystem to check, so nothing is launchable.
bool launchTargetExists(String path) => false;

/// Stub (e.g. web): no process launching, returns false.
Future<bool> launchWithBinary(String binaryPath, String projectPath) async => false;
