import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/music_project.dart';
import '../utils/mobile_utils.dart';

/// Locates the most recently modified audio file in a project's mixdown/bounce
/// folder, for use as a fallback preview when no song has been set manually.
///
/// Desktop-only — always returns null on mobile.
class MixdownDetectorService {
  MixdownDetectorService._();

  static const Set<String> _audioExtensions = {
    '.wav', '.mp3', '.flac', '.aif', '.aiff', '.aac', '.m4a', '.ogg',
  };

  /// Per-DAW folder names to check, in priority order.
  /// Values match the `dawType` strings produced by metadata_extractor.dart.
  /// Exposed publicly so settings UI can explain the defaults to the user.
  static const Map<String, List<String>> dawFolders = {
    'Ableton Live':  ['Bounces', 'Mixdown', 'Exports', 'Export'],
    'Logic Pro':     ['Bounces'],          // inside .logicx bundle (handled separately)
    'Cubase':        ['Mixdown'],
    'Nuendo':        ['Mixdown'],
    'Studio One':    ['Mixdown', 'Mix', 'Exports'],
    'Pro Tools':     ['Bounced Files', 'Bounce', 'Audio Files'],
    'Reaper':        ['Renders', 'Render', 'Mixdown'],
    'FL Studio':     ['Mixdown', 'Exports', 'Export'],
    'Bitwig Studio': ['bounce', 'Bounces', 'Mixdown', 'Exports'],
    'Maschine':      ['Exports', 'Export', 'Mixdown'],
    'Waveform':      ['Exports', 'Mixdown'],
    'Sonar':         ['Mixdown', 'Audio'],
  };

  /// Checked for any DAW not in the map above, and appended as final fallbacks
  /// for DAWs that are in the map (covers custom folder setups).
  /// Exposed publicly so settings UI can explain the defaults to the user.
  static const List<String> fallbackFolders = [
    'Mixdown', 'Bounces', 'Renders', 'Exports',
    'bounce',  'Render',  'Export',
  ];

  /// Returns the most recently modified audio file found in the project's
  /// mixdown folder, or null if nothing is found.
  ///
  /// [customFolders] are optional user-defined subfolder names, checked
  /// first and in order, before the DAW-specific and generic defaults.
  static File? findLatestMixdown(MusicProject project, {List<String>? customFolders}) {
    if (MobileUtils.isMobile()) return null;
    if (project.filePath.isEmpty) return null;

    for (final dir in _candidateDirs(project, customFolders: customFolders)) {
      if (!dir.existsSync()) continue;

      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) =>
              _audioExtensions.contains(p.extension(f.path).toLowerCase()))
          .toList();

      if (files.isEmpty) continue;

      files.sort((a, b) =>
          b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files.first;
    }

    return null;
  }

  /// Returns the newest audio file in the same directory as [currentPath] if it
  /// is strictly newer than [currentPath] itself and is a different file.
  /// Returns null if [currentPath] is already the newest, doesn't exist, or on mobile.
  ///
  /// [ignoredPath] is a path the user has previously rejected ("Keep Current").
  /// If the newest file matches it, the prompt is suppressed until a genuinely
  /// different (even newer) file appears.
  static File? findNewerFileInSameFolder(String currentPath, {String? ignoredPath}) {
    if (MobileUtils.isMobile()) return null;
    final current = File(currentPath);
    if (!current.existsSync()) return null;
    final currentModified = current.lastModifiedSync();
    final files = current.parent
        .listSync()
        .whereType<File>()
        .where((f) => _audioExtensions.contains(p.extension(f.path).toLowerCase()))
        .toList();
    if (files.isEmpty) return null;
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    final newest = files.first;
    if (p.equals(newest.path, current.path)) return null;
    if (ignoredPath != null && p.equals(newest.path, ignoredPath)) return null;
    if (newest.lastModifiedSync().isAfter(currentModified)) return newest;
    return null;
  }

  static List<Directory> _candidateDirs(MusicProject project, {List<String>? customFolders}) {
    final projectFile = File(project.filePath);
    final projectDir = projectFile.parent.path;
    final dirs = <String>[];

    // User-defined folders are checked first, in the given order
    if (customFolders != null) {
      for (final name in customFolders) {
        if (name.isEmpty) continue;
        dirs.add(p.join(projectDir, name));
      }
    }

    // Logic Pro: .logicx is a macOS bundle — Bounces lives inside it
    if (project.dawType == 'Logic Pro' &&
        project.filePath.toLowerCase().endsWith('.logicx')) {
      dirs.add(p.join(project.filePath, 'Bounces'));
    }

    // DAW-specific folders
    final dawSpecific = project.dawType != null
        ? (dawFolders[project.dawType!] ?? fallbackFolders)
        : fallbackFolders;

    for (final name in dawSpecific) {
      dirs.add(p.join(projectDir, name));
    }

    // Always append generic fallbacks (deduplicated)
    for (final name in fallbackFolders) {
      final path = p.join(projectDir, name);
      if (!dirs.contains(path)) dirs.add(path);
    }

    return dirs.map(Directory.new).toList();
  }
}
