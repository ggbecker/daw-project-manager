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

  /// Audio file extensions (leading dot, lowercase) the app treats as a
  /// playable "song": mixdown auto-detection, the preview-song picker,
  /// drag-and-drop, release-file typing, waveform rendering. Every one of
  /// these decodes on macOS/iOS via AVFoundation and on desktop via the
  /// bundled ffmpeg fallback — including AIFF (`.aif` / `.aiff`).
  static const Set<String> audioExtensions = {
    '.wav', '.mp3', '.flac', '.aif', '.aiff', '.aac', '.m4a', '.ogg',
  };

  /// [audioExtensions] without the leading dot, for
  /// `FilePicker.allowedExtensions` which wants bare extensions.
  static final List<String> audioPickerExtensions = audioExtensions
      .map((e) => e.substring(1))
      .toList(growable: false);

  // Matches this app's own Drive-download filenames — "<uuid>_preview.<ext>" —
  // written by GoogleDriveSyncService.downloadPreviewSongFile into a single
  // "preview_songs" cache directory shared by every project. That directory is
  // not a per-project export folder, so a "same folder" scan must never run
  // against it: it would surface other projects' downloaded previews as false
  // "newer export found" hits.
  static final RegExp _driveDownloadFileRe = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}_preview\.',
    caseSensitive: false,
  );

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
    'LUNA':          ['Exported Files'],
  };

  /// Checked for any DAW not in the map above, and appended as final fallbacks
  /// for DAWs that are in the map (covers custom folder setups).
  /// Exposed publicly so settings UI can explain the defaults to the user.
  static const List<String> fallbackFolders = [
    'Mixdown', 'Bounces', 'Renders', 'Exports',
    'bounce',  'Render',  'Export',
  ];

  /// Key used in [findLatestMixdown]'s `customFoldersByDaw` map for projects
  /// whose `dawType` is null or not one of [dawFolders]' keys — mirrors how
  /// those projects already fall back to [fallbackFolders].
  static const String otherDawKey = '_other';

  /// Returns the most recently modified audio file found in the project's
  /// mixdown folder, or null if nothing is found.
  ///
  /// [customFolders] are optional user-defined subfolder names, checked
  /// first and in order, before the DAW-specific and generic defaults.
  /// [customFoldersByDaw] are optional user-defined additions scoped to a
  /// single DAW (keyed by the same strings as [dawFolders], or
  /// [otherDawKey]) — checked after [customFolders] but before that DAW's
  /// hardcoded defaults, so a user addition takes priority over the guess.
  static File? findLatestMixdown(
    MusicProject project, {
    List<String>? customFolders,
    Map<String, List<String>>? customFoldersByDaw,
  }) {
    if (MobileUtils.isMobile()) return null;
    if (project.filePath.isEmpty) return null;

    for (final dir in _candidateDirs(
      project,
      customFolders: customFolders,
      customFoldersByDaw: customFoldersByDaw,
    )) {
      if (!dir.existsSync()) continue;

      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) =>
              audioExtensions.contains(p.extension(f.path).toLowerCase()))
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
  /// Returns null if [currentPath] is already the newest, doesn't exist, is on
  /// mobile, or lives in the shared Drive-download preview cache (that folder
  /// holds every project's downloaded preview, not just this project's exports).
  ///
  /// [ignoredPath] is a path the user has previously rejected ("Keep Current").
  /// If the newest file matches it, the prompt is suppressed until a genuinely
  /// different (even newer) file appears.
  static File? findNewerFileInSameFolder(String currentPath, {String? ignoredPath}) {
    if (MobileUtils.isMobile()) return null;
    if (_driveDownloadFileRe.hasMatch(p.basename(currentPath))) return null;
    final current = File(currentPath);
    if (!current.existsSync()) return null;
    final currentModified = current.lastModifiedSync();
    final files = current.parent
        .listSync()
        .whereType<File>()
        .where((f) => audioExtensions.contains(p.extension(f.path).toLowerCase()))
        .toList();
    if (files.isEmpty) return null;
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    final newest = files.first;
    if (p.equals(newest.path, current.path)) return null;
    if (ignoredPath != null && p.equals(newest.path, ignoredPath)) return null;
    if (newest.lastModifiedSync().isAfter(currentModified)) return newest;
    return null;
  }

  static List<Directory> _candidateDirs(
    MusicProject project, {
    List<String>? customFolders,
    Map<String, List<String>>? customFoldersByDaw,
  }) {
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

    // User-defined additions scoped to this project's DAW, checked next —
    // ahead of that DAW's hardcoded defaults but after the fully-global list.
    final perDawFolders =
        customFoldersByDaw?[project.dawType ?? otherDawKey];
    if (perDawFolders != null) {
      for (final name in perDawFolders) {
        if (name.isEmpty) continue;
        dirs.add(p.join(projectDir, name));
      }
    }

    // Logic Pro: .logicx is a macOS bundle — Bounces lives inside it
    if (project.dawType == 'Logic Pro' &&
        project.filePath.toLowerCase().endsWith('.logicx')) {
      dirs.add(p.join(project.filePath, 'Bounces'));
    }

    // LUNA: .luna is a package — Exported Files (mixdowns) lives inside it.
    // (The "Rendered" folder holds frozen VSTi/track renders, not mixdowns,
    // so it's deliberately not treated as a preview source.)
    if (project.dawType == 'LUNA' &&
        project.filePath.toLowerCase().endsWith('.luna')) {
      dirs.add(p.join(project.filePath, 'Exported Files'));
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
