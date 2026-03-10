import 'dart:io';

import 'package:path/path.dart' as p;

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
  };

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

  Stream<FileSystemEntity> scanDirectory(
    String rootPath, {
    List<String> ignoredPaths = const [],
  }) async* {
    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) return;

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

      final stream = dir.list(recursive: false, followLinks: false);
      await for (final entity in stream) {
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
          // Logic Pro projects present as .logicx bundles (directories)
          if (entity.path.toLowerCase().endsWith('.logicx')) {
            yield entity;
            continue;
          }

          // Continue traversal
          stack.add(entity);
        }
      }
    }
  }
}


