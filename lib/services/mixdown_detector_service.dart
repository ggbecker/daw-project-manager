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
  static const Map<String, List<String>> _dawFolders = {
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
  static const List<String> _fallbackFolders = [
    'Mixdown', 'Bounces', 'Renders', 'Exports',
    'bounce',  'Render',  'Export',
  ];

  /// Returns the most recently modified audio file found in the project's
  /// mixdown folder, or null if nothing is found.
  ///
  /// [customFolder] is an optional user-defined subfolder name to check first.
  static File? findLatestMixdown(MusicProject project, {String? customFolder}) {
    if (MobileUtils.isMobile()) return null;
    if (project.filePath.isEmpty) return null;

    for (final dir in _candidateDirs(project, customFolder: customFolder)) {
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
  static File? findNewerFileInSameFolder(String currentPath) {
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
    if (newest.lastModifiedSync().isAfter(currentModified)) return newest;
    return null;
  }

  static List<Directory> _candidateDirs(MusicProject project, {String? customFolder}) {
    final projectFile = File(project.filePath);
    final projectDir = projectFile.parent.path;
    final dirs = <String>[];

    // User-defined folder is checked first
    if (customFolder != null && customFolder.isNotEmpty) {
      dirs.add(p.join(projectDir, customFolder));
    }

    // Logic Pro: .logicx is a macOS bundle — Bounces lives inside it
    if (project.dawType == 'Logic Pro' &&
        project.filePath.toLowerCase().endsWith('.logicx')) {
      dirs.add(p.join(project.filePath, 'Bounces'));
    }

    // DAW-specific folders
    final dawSpecific = project.dawType != null
        ? (_dawFolders[project.dawType!] ?? _fallbackFolders)
        : _fallbackFolders;

    for (final name in dawSpecific) {
      dirs.add(p.join(projectDir, name));
    }

    // Always append generic fallbacks (deduplicated)
    for (final name in _fallbackFolders) {
      final path = p.join(projectDir, name);
      if (!dirs.contains(path)) dirs.add(path);
    }

    return dirs.map(Directory.new).toList();
  }
}
