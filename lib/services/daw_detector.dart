import 'dart:io';

import 'package:flutter/foundation.dart';

class DetectedDaw {
  final String name;
  final String executablePath;
  final String? iconName;

  const DetectedDaw({
    required this.name,
    required this.executablePath,
    this.iconName,
  });
}

class DawDetector {
  static Future<List<DetectedDaw>> detectInstalledDaws() async {
    if (Platform.isWindows) return _detectWindows();
    if (Platform.isMacOS) return _detectMacOS();
    if (Platform.isLinux) return _detectLinux();
    return [];
  }

  static Future<List<DetectedDaw>> _detectWindows() async {
    final candidates = <_WindowsCandidate>[
      _WindowsCandidate(
        name: 'Ableton Live',
        // Ableton installs to: C:\ProgramData\Ableton\Live X Suite\Program\Ableton Live X Suite.exe
        baseDirs: [r'C:\ProgramData\Ableton', r'C:\Program Files\Ableton'],
        exePattern: RegExp(r'(?:Ableton )?Live.*\.exe$', caseSensitive: false),
        subdirPattern: RegExp(r'Live \d', caseSensitive: false),
      ),
      _WindowsCandidate(
        name: 'FL Studio',
        baseDirs: [r'C:\Program Files\Image-Line'],
        exePattern: RegExp(r'FL64\.exe$|FL\.exe$', caseSensitive: false),
        subdirPattern: RegExp(r'FL Studio', caseSensitive: false),
      ),
      _WindowsCandidate(
        name: 'Cubase',
        baseDirs: [r'C:\Program Files\Steinberg'],
        exePattern: RegExp(r'Cubase\d*\.exe$|Cubase\.exe$', caseSensitive: false),
        subdirPattern: RegExp(r'Cubase', caseSensitive: false),
      ),
      _WindowsCandidate(
        name: 'Nuendo',
        baseDirs: [r'C:\Program Files\Steinberg'],
        exePattern: RegExp(r'Nuendo\d*\.exe$|Nuendo\.exe$', caseSensitive: false),
        subdirPattern: RegExp(r'Nuendo', caseSensitive: false),
      ),
      _WindowsCandidate(
        name: 'Studio One',
        baseDirs: [r'C:\Program Files\PreSonus'],
        exePattern: RegExp(r'Studio One\.exe$', caseSensitive: false),
        subdirPattern: RegExp(r'Studio One', caseSensitive: false),
      ),
      _WindowsCandidate(
        name: 'Reaper',
        baseDirs: [
          r'C:\Program Files\REAPER (x64)',
          r'C:\Program Files\REAPER',
          r'C:\Program Files (x86)\REAPER',
        ],
        exePattern: RegExp(r'reaper\.exe$', caseSensitive: false),
        subdirPattern: null,
      ),
      _WindowsCandidate(
        name: 'Bitwig Studio',
        baseDirs: [r'C:\Program Files\Bitwig Studio'],
        exePattern: RegExp(r'Bitwig Studio\.exe$', caseSensitive: false),
        subdirPattern: null,
      ),
      _WindowsCandidate(
        name: 'Pro Tools',
        baseDirs: [r'C:\Program Files\Avid\Pro Tools'],
        exePattern: RegExp(r'Pro Tools\.exe$', caseSensitive: false),
        subdirPattern: null,
      ),
      _WindowsCandidate(
        name: 'Reason',
        baseDirs: [r'C:\Program Files\Reason Studios\Reason'],
        exePattern: RegExp(r'Reason\.exe$', caseSensitive: false),
        subdirPattern: null,
      ),
      _WindowsCandidate(
        name: 'Cakewalk',
        baseDirs: [r'C:\Program Files\Cakewalk', r'C:\Program Files\BandLab\Cakewalk'],
        exePattern: RegExp(r'Cakewalk\.exe$', caseSensitive: false),
        subdirPattern: RegExp(r'Cakewalk', caseSensitive: false),
      ),
      _WindowsCandidate(
        name: 'Waveform',
        baseDirs: [r'C:\Program Files\Tracktion\Waveform'],
        exePattern: RegExp(r'Waveform\.exe$', caseSensitive: false),
        subdirPattern: null,
      ),
    ];

    final results = <DetectedDaw>[];
    for (final c in candidates) {
      final exe = await c.find();
      if (exe != null) results.add(DetectedDaw(name: c.name, executablePath: exe));
    }
    return results;
  }

  static Future<List<DetectedDaw>> _detectMacOS() async {
    final patterns = [
      RegExp(r'^Ableton Live', caseSensitive: false),
      RegExp(r'^FL Studio', caseSensitive: false),
      RegExp(r'^Logic Pro', caseSensitive: false),
      RegExp(r'^GarageBand$', caseSensitive: false),
      RegExp(r'^Cubase', caseSensitive: false),
      RegExp(r'^Studio One', caseSensitive: false),
      RegExp(r'^Bitwig Studio', caseSensitive: false),
      RegExp(r'^REAPER', caseSensitive: false),
      RegExp(r'^Pro Tools', caseSensitive: false),
      RegExp(r'^Nuendo', caseSensitive: false),
      RegExp(r'^Reason$', caseSensitive: false),
    ];

    final results = <DetectedDaw>[];
    final appsDir = Directory('/Applications');
    if (!appsDir.existsSync()) return results;

    try {
      final entries = appsDir
          .listSync()
          .whereType<Directory>()
          .where((d) => d.path.endsWith('.app'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      for (final entry in entries) {
        final basename = entry.path.split('/').last;
        final appName = basename.substring(0, basename.length - 4);
        for (final pattern in patterns) {
          if (pattern.hasMatch(appName)) {
            results.add(DetectedDaw(name: appName, executablePath: entry.path));
            break;
          }
        }
      }
    } catch (_) {}

    return results;
  }

  // Linux has no install-location convention to guess paths from the way
  // Windows/macOS do above, so detection instead reads .desktop files —
  // the one signal that reliably points at a real, launchable binary for
  // both package-manager-installed and AppImageLauncher-integrated DAWs.
  // Curated to DAWs that plausibly ship a Linux build/AppImage at all
  // (unlike the full 28-DAW extension list in metadata_extractor.dart,
  // most of which — Logic Pro, Pro Tools, Cubase, FL Studio, etc. — never
  // have a Linux .desktop entry to find).
  @visibleForTesting
  static final List<LinuxDawPattern> linuxDawPatterns = [
    LinuxDawPattern('Bitwig Studio', RegExp(r'^Bitwig Studio', caseSensitive: false)),
    LinuxDawPattern('Reaper', RegExp(r'^REAPER', caseSensitive: false)),
    LinuxDawPattern('Ardour', RegExp(r'^Ardour', caseSensitive: false)),
    LinuxDawPattern('LMMS', RegExp(r'^LMMS', caseSensitive: false)),
    LinuxDawPattern('Audacity', RegExp(r'^Audacity', caseSensitive: false)),
    LinuxDawPattern('Qtractor', RegExp(r'^Qtractor', caseSensitive: false)),
    LinuxDawPattern('Rosegarden', RegExp(r'^Rosegarden', caseSensitive: false)),
    LinuxDawPattern('Renoise', RegExp(r'^Renoise', caseSensitive: false)),
    LinuxDawPattern('Zrythm', RegExp(r'^Zrythm', caseSensitive: false)),
    LinuxDawPattern('Reason', RegExp(r'^Reason$', caseSensitive: false)),
    LinuxDawPattern('Studio One', RegExp(r'^Studio One', caseSensitive: false)),
    LinuxDawPattern('Waveform', RegExp(r'^Waveform', caseSensitive: false)),
    LinuxDawPattern('MAGDA', RegExp(r'^MAGDA', caseSensitive: false)),
  ];

  static List<String> _linuxDesktopFileDirs() {
    final home = Platform.environment['HOME'];
    final dirs = <String>[
      '/usr/share/applications',
      '/var/lib/flatpak/exports/share/applications',
    ];
    if (home != null && home.isNotEmpty) {
      dirs.add('$home/.local/share/applications');
      // Per-user Flatpak installs export desktop files here, not under
      // ~/.var/app (that's each sandboxed app's own private data dir).
      dirs.add('$home/.local/share/flatpak/exports/share/applications');
    }
    return dirs;
  }

  static Future<List<DetectedDaw>> _detectLinux() async {
    final results = <DetectedDaw>[];
    final seenNames = <String>{};

    for (final dirPath in _linuxDesktopFileDirs()) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) continue;

      List<FileSystemEntity> entries;
      try {
        entries = dir.listSync(recursive: false, followLinks: false);
      } catch (_) {
        continue;
      }

      for (final entry in entries) {
        if (entry is! File || !entry.path.endsWith('.desktop')) continue;
        String content;
        try {
          content = entry.readAsStringSync();
        } catch (_) {
          continue;
        }
        final detected = parseLinuxDesktopEntry(content, linuxDawPatterns);
        if (detected == null || !seenNames.add(detected.name)) continue;
        results.add(detected);
      }
    }

    return results;
  }
}

class LinuxDawPattern {
  final String canonicalName;
  final RegExp namePattern;
  const LinuxDawPattern(this.canonicalName, this.namePattern);
}

/// Parses a single .desktop file's contents (INI-like `key=value` format)
/// and returns a [DetectedDaw] if its `[Desktop Entry]` `Name=` matches one
/// of [patterns] and it has a non-empty `Exec=`. Returns null for
/// non-matching, hidden (`NoDisplay=true`/`Hidden=true`), or malformed
/// entries. Pure and filesystem-free so it's directly unit-testable.
@visibleForTesting
DetectedDaw? parseLinuxDesktopEntry(String content, List<LinuxDawPattern> patterns) {
  String? name;
  String? exec;
  var hidden = false;
  var inDesktopEntrySection = false;

  for (final rawLine in content.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    if (line.startsWith('[')) {
      inDesktopEntrySection = line == '[Desktop Entry]';
      continue;
    }
    if (!inDesktopEntrySection) continue;

    final eq = line.indexOf('=');
    if (eq <= 0) continue;
    final key = line.substring(0, eq).trim();
    final value = line.substring(eq + 1).trim();

    switch (key) {
      case 'Name':
        name ??= value;
      case 'Exec':
        exec ??= value;
      case 'NoDisplay':
      case 'Hidden':
        if (value.toLowerCase() == 'true') hidden = true;
    }
  }

  if (hidden || name == null || exec == null || exec.isEmpty) return null;

  String? matchedName;
  for (final pattern in patterns) {
    if (pattern.namePattern.hasMatch(name)) {
      matchedName = pattern.canonicalName;
      break;
    }
  }
  if (matchedName == null) return null;

  final binary = extractLinuxExecPath(exec);
  if (binary.isEmpty) return null;

  return DetectedDaw(name: matchedName, executablePath: binary);
}

/// Extracts the executable path from a .desktop `Exec=` value — the first
/// (optionally quoted) token, with any trailing field-code placeholders
/// (`%f`, `%F`, `%u`, `%U`, etc.) and arguments dropped. Doesn't handle an
/// `env VAR=val`-prefixed `Exec=` (rare for the DAWs this targets).
@visibleForTesting
String extractLinuxExecPath(String execValue) {
  final trimmed = execValue.trim();
  if (trimmed.isEmpty) return '';

  if (trimmed.startsWith('"')) {
    final end = trimmed.indexOf('"', 1);
    return end == -1 ? trimmed.substring(1).trim() : trimmed.substring(1, end).trim();
  }

  final spaceIdx = trimmed.indexOf(' ');
  return (spaceIdx == -1 ? trimmed : trimmed.substring(0, spaceIdx)).trim();
}

class _WindowsCandidate {
  final String name;
  final List<String> baseDirs;
  final RegExp exePattern;
  final RegExp? subdirPattern;

  _WindowsCandidate({
    required this.name,
    required this.baseDirs,
    required this.exePattern,
    this.subdirPattern,
  });

  Future<String?> find() async {
    for (final baseDir in baseDirs) {
      final base = Directory(baseDir);
      if (!base.existsSync()) continue;

      if (subdirPattern != null) {
        // Look inside matching subdirectories
        try {
          final entries = base.listSync();
          for (final entry in entries) {
            if (entry is Directory && subdirPattern!.hasMatch(entry.path.split(r'\').last)) {
              final found = _findExeIn(entry);
              if (found != null) return found;
            }
          }
        } catch (_) {}
      } else {
        // Look directly in the base dir
        final found = _findExeIn(base);
        if (found != null) return found;
      }
    }
    return null;
  }

  String? _findExeIn(Directory dir) {
    try {
      final entries = dir.listSync(recursive: false);
      // Check files at this level first
      for (final entry in entries) {
        if (entry is File && exePattern.hasMatch(entry.path.split(r'\').last)) {
          return entry.path;
        }
      }
      // Then check one level of subdirectories (e.g. Ableton's Program\ subfolder)
      for (final entry in entries) {
        if (entry is Directory) {
          try {
            final subEntries = entry.listSync(recursive: false);
            for (final sub in subEntries) {
              if (sub is File && exePattern.hasMatch(sub.path.split(r'\').last)) {
                return sub.path;
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    return null;
  }
}
