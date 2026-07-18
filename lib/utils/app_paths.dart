import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'mobile_utils.dart';

/// Static flag to track if Hive has been initialized
bool _hiveInitialized = false;

/// Initializes Hive only once to prevent multiple initializations and lock conflicts
/// This should be called before any Hive operations
Future<void> ensureHiveInitialized() async {
  if (_hiveInitialized) {
    if (kDebugMode) print('Hive already initialized, skipping...');
    return;
  }

  // Under `flutter test`, never fall back to the real on-disk app-data
  // directory. This flag only tracks "has *this* function called
  // Hive.init()", not whether Hive itself is already initialized — so the
  // first test (in a process that may run many test files) to reach this
  // function via some provider's fire-and-forget _load() would otherwise
  // silently call Hive.init(realAppDataPath), redirecting every later
  // Hive.openBox() in that process to the developer's actual app data,
  // even if an earlier test file had already called Hive.init(tempDir)
  // itself. A test that needs Hive must call Hive.init(tempDir) itself
  // (see HiveTestHelper.setUp); anything else silently no-ops here instead
  // of touching real user data.
  if (Platform.environment['FLUTTER_TEST'] == 'true') {
    _hiveInitialized = true;
    return;
  }

  try {
    final appDataPath = await getLocalAppDataPath();
    Hive.init(appDataPath);
    _hiveInitialized = true;
    if (kDebugMode) print('Hive initialized at: $appDataPath');
  } catch (e) {
    if (kDebugMode) print('Error initializing Hive: $e');
    // If init fails, try to continue anyway - might be already initialized
    _hiveInitialized = true;
  }
}

/// Gets the LocalAppData directory path for the application.
/// On Windows, this returns %LocalAppData%\daw_project_manager
/// On other platforms, it returns the application support directory.
Future<String> getLocalAppDataPath() async {
  if (Platform.isWindows) {
    // On Windows, use LOCALAPPDATA environment variable
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final appDir = Directory(path.join(localAppData, 'daw_project_manager'));
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      return appDir.path;
    }
    // Fallback to application support directory if LOCALAPPDATA is not available
    final appSupportDir = await getApplicationSupportDirectory();
    return appSupportDir.path;
  } else {
    // On other platforms, use application support directory
    final appSupportDir = await getApplicationSupportDirectory();
    return appSupportDir.path;
  }
}

/// Gets the path for release files storage
Future<String> getReleaseFilesPath(String releaseId) async {
  final basePath = await getLocalAppDataPath();
  return path.join(basePath, 'release_files', releaseId);
}

/// Gets the path for release artwork storage
Future<String> getReleaseArtworkPath() async {
  final basePath = await getLocalAppDataPath();
  return path.join(basePath, 'release_artwork');
}

/// Gets the path for preview songs storage
/// On mobile, this uses the application documents directory for persistence
/// On desktop, this uses the app data directory
Future<String> getPreviewSongsPath() async {
  if (MobileUtils.isMobile()) {
    // On mobile, use application documents directory for persistent storage
    // This ensures preview songs are not deleted by the system
    final appDocDir = await getApplicationDocumentsDirectory();
    final previewSongsDir = Directory(path.join(appDocDir.path, 'preview_songs'));
    if (!await previewSongsDir.exists()) {
      await previewSongsDir.create(recursive: true);
    }
    return previewSongsDir.path;
  } else {
    // On desktop, use app data directory
    final basePath = await getLocalAppDataPath();
    final previewSongsDir = Directory(path.join(basePath, 'preview_songs'));
    if (!await previewSongsDir.exists()) {
      await previewSongsDir.create(recursive: true);
    }
    return previewSongsDir.path;
  }
}

/// Gets the path where placeholder project files for the demo/screenshot
/// profile are created, so real DAW project files exist on disk (avoiding
/// the "source file not found" warning) without touching the user's own
/// project folders.
Future<String> getDemoProjectsPath() async {
  final basePath = await getLocalAppDataPath();
  final demoProjectsDir = Directory(path.join(basePath, 'demo_projects'));
  if (!await demoProjectsDir.exists()) {
    await demoProjectsDir.create(recursive: true);
  }
  return demoProjectsDir.path;
}

