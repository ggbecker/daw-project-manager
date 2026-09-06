import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class ShallowScanResult {
  final FileSystemEntity file;
  /// Absolute path of the folder this file represents.
  final String folderPath;
  /// Absolute path of the parent folder (null for depth-1 results).
  final String? parentFolderPath;

  const ShallowScanResult({
    required this.file,
    required this.folderPath,
    this.parentFolderPath,
  });
}

class ScannerService {
  static const supportedExtensions = {
    '.als', // Ableton Live
    '.alp', // Ableton Live (alternative)
    '.bwproject', // Bitwig Studio
    '.cpr', // Cubase
    '.flp', // FL Studio
    '.logicx', // Logic Pro (bundle on macOS)
    '.maschine', // Maschine
    '.maschine2', // Maschine 2
    '.npr', // Nuendo
    '.ptx', // Pro Tools
    '.pts', // Pro Tools (session)
    '.rpp', // Reaper
    '.song', // Studio One
    '.tracktionedit', // Tracktion Waveform (edit file)
    '.tracktion', // Tracktion Waveform (project file)
    '.cwp', // Cakewalk Project
    '.wrk', // Cakewalk Sonar (legacy)
    '.bun', // Cakewalk Bundle
    '.luna', // Universal Audio LUNA (package bundle)
    '.mgd', // MAGDA
    '.ardour', // Ardour
    '.band', // GarageBand (bundle on macOS/iOS)
    '.xrns', // Renoise
    '.mmp', // LMMS (uncompressed)
    '.mmpz', // LMMS (gzip-compressed)
    '.aup3', // Audacity (SQLite-based, Audacity 3+)
    '.qtr', // Qtractor
    '.rg', // Rosegarden
    '.reason', // Reason
    '.rns', // Reason (legacy)
    '.dpproj', // Digital Performer
    '.sesx', // Adobe Audition (multitrack session)
    '.vip', // Samplitude / Sequoia (Magix)
    '.acd', // ACID Pro (Magix)
    '.mx8', // Mixcraft 8
    '.mx9', // Mixcraft 9
    '.mx10', // Mixcraft 10
    '.zpj', // Zrythm
  };

  // Extensions that are directories ("package bundles") rather than a single
  // file — checked before the plain-file extension lookup wherever a
  // directory entry is encountered during scanning.
  static const _bundleExtensions = {'.logicx', '.luna', '.band'};

  static bool _isBundleDirectory(String path) {
    final lower = path.toLowerCase();
    return _bundleExtensions.any((ext) => lower.endsWith(ext));
  }

  /// Whether [path] is a DAW project stored as a directory "package bundle"
  /// (Logic Pro `.logicx`, Universal Audio LUNA `.luna`, GarageBand `.band`)
  /// rather than a single file. These are directories on disk but the OS
  /// opens them like a file — so `open`ing one on macOS launches the DAW
  /// instead of revealing its contents.
  static bool isBundlePath(String path) => _isBundleDirectory(path);

  /// The folder to reveal in the system file manager for a project located
  /// at [projectPath]. A single-file project resolves to the file's parent
  /// directory; a package-bundle project *also* resolves to the bundle's
  /// parent, because revealing (or opening) the `.logicx`/`.luna`/`.band`
  /// bundle itself just launches the DAW. Only a genuine loose-files project
  /// folder returns itself.
  static String projectContainingFolder(String projectPath) {
    if (isBundlePath(projectPath)) return p.dirname(projectPath);
    return FileSystemEntity.isDirectorySync(projectPath)
        ? projectPath
        : p.dirname(projectPath);
  }

  static const _backupFolderNames = {
    'backup',               // Ableton Live, FL Studio, Cubase
    'auto-backups',         // Bitwig Studio
    'session file backups', // Pro Tools
    'history',              // Studio One
    'autosave',             // Cakewalk
    'auto save',            // FL Studio (alternate)
  };

  bool _isInBackupFolder(String path) {
    final segments = p.split(path);
    return segments.any((s) => _backupFolderNames.contains(s.toLowerCase()));
  }

  /// Cubase / Nuendo auto-saves land in the same folder as the project
  /// but with "_AutoSave" appended to the base name.
  bool _isCubaseAutoSave(String path) {
    final base = p.basenameWithoutExtension(path).toLowerCase();
    return base.contains('_autosave');
  }

  /// Finds the best representative DAW file directly inside [dir].
  /// Prefers a file whose stem matches the folder name; falls back to the
  /// most recently modified file. Returns null if no DAW file is found.
  Future<FileSystemEntity?> _bestFileInFolder(Directory dir) async {
    final folderName = p.basename(dir.path).toLowerCase();
    FileSystemEntity? best;
    DateTime? bestModified;

    await for (final entity in dir.list(recursive: false, followLinks: false)) {
      if (entity is! File) {
        // Some DAWs (Logic Pro, LUNA, GarageBand) save as a directory bundle
        // rather than a single file.
        if (entity is Directory && _isBundleDirectory(entity.path)) {
          final stat = await entity.stat();
          final stem = p.basenameWithoutExtension(entity.path).toLowerCase();
          if (best == null || stem == folderName || stat.modified.isAfter(bestModified!)) {
            best = entity;
            bestModified = stat.modified;
          }
        }
        continue;
      }
      final ext = p.extension(entity.path).toLowerCase();
      if (!supportedExtensions.contains(ext)) continue;
      if (_isInBackupFolder(entity.path)) continue;
      if ((ext == '.cpr' || ext == '.npr') && _isCubaseAutoSave(entity.path)) continue;

      final stat = await entity.stat();
      final stem = p.basenameWithoutExtension(entity.path).toLowerCase();
      if (best == null) {
        best = entity;
        bestModified = stat.modified;
      } else if (stem == folderName) {
        best = entity;
        bestModified = stat.modified;
        break; // exact name match wins immediately
      } else if (stat.modified.isAfter(bestModified!)) {
        best = entity;
        bestModified = stat.modified;
      }
    }
    return best;
  }

  /// Folder-based shallow scan. Each immediate subfolder of [rootPath] that
  /// contains a DAW file becomes one project. With [maxDepth] == 2, each
  /// sub-subfolder also becomes a project linked to its parent folder.
  Stream<ShallowScanResult> scanDirectoryShallow(
    String rootPath, {
    int maxDepth = 1,
    List<String> ignoredPaths = const [],
  }) async* {
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) return;

    final ignoredBases = ignoredPaths.map((x) => p.normalize(x)).toList();
    bool isIgnored(String path) {
      final cand = p.normalize(path);
      for (final base in ignoredBases) {
        if (cand == base) return true;
        final prefix = base.endsWith(p.separator) ? base : base + p.separator;
        if (cand.startsWith(prefix)) return true;
      }
      return false;
    }

    await for (final depth1 in rootDir.list(recursive: false, followLinks: false)) {
      if (depth1 is! Directory) continue;
      if (isIgnored(depth1.path)) continue;

      final best1 = await _bestFileInFolder(depth1);
      if (best1 != null) {
        yield ShallowScanResult(file: best1, folderPath: depth1.path, parentFolderPath: null);
      }

      if (maxDepth >= 2) {
        await for (final depth2 in depth1.list(recursive: false, followLinks: false)) {
          if (depth2 is! Directory) continue;
          if (isIgnored(depth2.path)) continue;

          final best2 = await _bestFileInFolder(depth2);
          if (best2 != null) {
            yield ShallowScanResult(
              file: best2,
              folderPath: depth2.path,
              parentFolderPath: depth1.path,
            );
          }
        }
      }
    }
  }

  Stream<FileSystemEntity> scanDirectory(
    String rootPath, {
    List<String> ignoredPaths = const [],
  }) async* {
    if (kDebugMode) debugPrint('[ScannerService] scanDirectory($rootPath): checking exists()...');
    final rootDir = Directory(rootPath);
    final rootExists = await rootDir.exists();
    if (kDebugMode) debugPrint('[ScannerService] scanDirectory($rootPath): exists() -> $rootExists');
    if (!rootExists) return;

    // Normalize ignore paths for fast prefix matching.
    final ignoredBases = ignoredPaths.map((p0) => p.normalize(p0)).toList();
    bool isIgnoredPath(String candidatePath) {
      final cand = p.normalize(candidatePath);
      for (final base in ignoredBases) {
        if (cand == base) return true;
        final prefix = base.endsWith(p.separator) ? base : base + p.separator;
        if (cand.startsWith(prefix)) return true;
      }
      return false;
    }

    // Manual traversal so we can skip ignored directories efficiently.
    final stack = <Directory>[rootDir];
    while (stack.isNotEmpty) {
      final dir = stack.removeLast();
      if (isIgnoredPath(dir.path)) {
        continue;
      }

      if (kDebugMode) debugPrint('[ScannerService] listing ${dir.path}...');
      var entityCount = 0;
      final stream = dir.list(recursive: false, followLinks: false);
      await for (final entity in stream) {
        entityCount++;
        if (isIgnoredPath(entity.path)) {
          continue;
        }

        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (!supportedExtensions.contains(ext)) continue;

          // Ignore auto-backup copies created by various DAWs.
          if (_isInBackupFolder(entity.path)) continue;

          // Cubase / Nuendo auto-saves stay in the project folder but include
          // "_AutoSave" in the filename instead of using a subfolder.
          if ((ext == '.cpr' || ext == '.npr') && _isCubaseAutoSave(entity.path)) {
            continue;
          }

          yield entity;
        } else if (entity is Directory) {
          // Some DAWs (Logic Pro, LUNA, GarageBand) present projects as
          // directory bundles rather than a single file.
          if (_isBundleDirectory(entity.path)) {
            yield entity;
            continue;
          }

          // Continue traversal
          stack.add(entity);
        }
      }
      if (kDebugMode) {
        debugPrint('[ScannerService] finished listing ${dir.path}: $entityCount entries');
      }
    }
  }
}

/// The subset of [foundPaths] that weren't already in [knownPaths] before
/// the scan started — i.e. genuinely new since the repository last saw this
/// root, as opposed to a file just being re-confirmed as still present.
///
/// Used to flag newly-discovered projects (see `recentlyDiscoveredProjectsProvider`)
/// for both the light background scan at app launch and a user-triggered
/// rescan, now that neither blocks the UI while it runs — without this, a
/// project that silently appears mid-scan would be indistinguishable from
/// one that was already there.
Set<String> newlyFoundPaths(
  Iterable<String> foundPaths,
  Set<String> knownPaths,
) {
  return foundPaths.where((path) => !knownPaths.contains(path)).toSet();
}

