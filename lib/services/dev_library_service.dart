import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/app_paths.dart';

/// One candidate app-data directory the startup picker can open.
class DevLibrary {
  /// Directory name, e.g. `daw_project_manager` or `daw_project_manager_dev`.
  final String dirName;

  /// True for the directory a shipping release uses — the real library.
  final bool isRelease;

  /// Whether the directory exists on disk yet. A missing one is still offered:
  /// picking it creates it, which is how you start a clean library.
  final bool exists;

  /// Number of `*_projects` Hive boxes, i.e. profiles that hold projects.
  final int projectBoxCount;

  final int totalBytes;
  final DateTime? lastModified;

  const DevLibrary({
    required this.dirName,
    required this.isRelease,
    required this.exists,
    this.projectBoxCount = 0,
    this.totalBytes = 0,
    this.lastModified,
  });
}

/// Finds and remembers which app-data directory a dev build should open.
///
/// Everything here works off directory and file metadata only. It deliberately
/// never opens a Hive box: the whole point is to run *before* Hive has been
/// pointed anywhere, and opening a box would both defeat that and risk the
/// very "unknown typeId" failure the picker exists to avoid.
class DevLibraryService {
  const DevLibraryService._();

  /// Where the remembered choice is stored — deliberately beside the
  /// candidate directories rather than inside one of them, since which one is
  /// in play is exactly what it records.
  static const String selectionFileName =
      '$defaultAppDataDirName.selected-library';

  /// The directory the candidate libraries — and this build's remembered
  /// choice — live directly under: `%LOCALAPPDATA%` on Windows, the OS
  /// application-support directory elsewhere.
  ///
  /// Must not depend on the current library selection: the choice is written
  /// here before one is made and read back here afterwards, so a moving root
  /// silently loses it (and left "Ask again next launch" permanently
  /// disabled). See [getAppSupportRoot].
  static Future<Directory> resolveRoot() => getAppSupportRoot();

  /// Every candidate library under [root], release first, then the dev one,
  /// then any others (per-pull-request directories left by a tester build).
  ///
  /// The release and dev directories are always present in the result even
  /// when absent from disk, so a fresh checkout still offers both.
  static List<DevLibrary> discover(Directory root) {
    final found = <String, DevLibrary>{};

    if (root.existsSync()) {
      for (final entity in root.listSync()) {
        if (entity is! Directory) continue;
        final name = p.basename(entity.path);
        if (name != defaultAppDataDirName &&
            !name.startsWith('${defaultAppDataDirName}_')) {
          continue;
        }
        found[name] = _inspect(entity, name);
      }
    }

    for (final name in [defaultAppDataDirName, '${defaultAppDataDirName}_dev']) {
      found.putIfAbsent(name, () => _resolveKnownLibrary(root, name));
    }

    final ordered = found.values.toList()
      ..sort((a, b) {
        if (a.isRelease != b.isRelease) return a.isRelease ? -1 : 1;
        final aDev = a.dirName.endsWith('_dev');
        final bDev = b.dirName.endsWith('_dev');
        if (aDev != bDev) return aDev ? -1 : 1;
        return a.dirName.compareTo(b.dirName);
      });
    return ordered;
  }

  /// Builds the entry for a library [name] that wasn't found as a
  /// `<root>/<name>` subdirectory during the listing pass.
  ///
  /// On macOS/Linux the *release* library's Hive boxes sit directly in the
  /// application-support directory — which is [root] itself — rather than in a
  /// `daw_project_manager/` subdirectory (Windows does use a subdirectory).
  /// So the release library never shows up in the subdir listing on those
  /// platforms and would always read as "does not exist yet". Resolve it
  /// against [root] here, and only call it real if it actually holds Hive
  /// boxes ([root] always exists — path_provider creates it).
  static DevLibrary _resolveKnownLibrary(Directory root, String name) {
    final isRelease = name == defaultAppDataDirName;
    final dir = (isRelease && !Platform.isWindows)
        ? root
        : Directory(p.join(root.path, name));

    if (!dir.existsSync()) {
      return DevLibrary(dirName: name, isRelease: isRelease, exists: false);
    }
    final inspected = _inspect(dir, name);
    if (p.equals(dir.path, root.path) && inspected.totalBytes == 0) {
      // `root` exists but holds no library yet — keep the "will be created
      // empty" affordance rather than claiming a phantom library.
      return DevLibrary(dirName: name, isRelease: isRelease, exists: false);
    }
    return inspected;
  }

  static DevLibrary _inspect(Directory dir, String name) {
    var projectBoxes = 0;
    var bytes = 0;
    DateTime? newest;
    try {
      for (final file in dir.listSync().whereType<File>()) {
        final fileName = p.basename(file.path);
        if (!fileName.endsWith('.hive')) continue;
        if (fileName.endsWith('_projects.hive') || fileName == 'projects.hive') {
          projectBoxes++;
        }
        final stat = file.statSync();
        bytes += stat.size;
        if (newest == null || stat.modified.isAfter(newest)) {
          newest = stat.modified;
        }
      }
    } catch (_) {
      // An unreadable directory is still offered, just without its stats.
    }
    return DevLibrary(
      dirName: name,
      isRelease: name == defaultAppDataDirName,
      exists: true,
      projectBoxCount: projectBoxes,
      totalBytes: bytes,
      lastModified: newest,
    );
  }

  /// The remembered choice, or null when none is stored or it is unusable.
  static String? readSelection(Directory root) {
    try {
      final file = File(p.join(root.path, selectionFileName));
      if (!file.existsSync()) return null;
      final name = file.readAsStringSync().trim();
      return name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  /// Stores [dirName], or clears the choice when null so the picker asks again.
  static void writeSelection(Directory root, String? dirName) {
    try {
      final file = File(p.join(root.path, selectionFileName));
      if (dirName == null) {
        if (file.existsSync()) file.deleteSync();
        return;
      }
      file.writeAsStringSync(dirName);
    } catch (_) {
      // Not being able to remember the choice only costs one extra prompt.
    }
  }

  static String formatBytes(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes < kb) return '$bytes B';
    if (bytes < mb) return '${(bytes / kb).toStringAsFixed(0)} KB';
    return '${(bytes / mb).toStringAsFixed(1)} MB';
  }
}
