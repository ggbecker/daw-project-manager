import 'dart:io';

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
