import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/daw_detector.dart';

void main() {
  group('extractLinuxExecPath', () {
    test('extracts a plain unquoted binary path with a %U placeholder', () {
      expect(extractLinuxExecPath('zrythm %U'), 'zrythm');
    });

    test('extracts a quoted path containing spaces', () {
      expect(
        extractLinuxExecPath('"/home/user/Apps/Ardour 7.AppImage" %f'),
        '/home/user/Apps/Ardour 7.AppImage',
      );
    });

    test('returns the whole value when there is no placeholder/arguments', () {
      expect(extractLinuxExecPath('/opt/reaper/reaper'), '/opt/reaper/reaper');
    });

    test('returns empty string for an empty Exec value', () {
      expect(extractLinuxExecPath(''), '');
      expect(extractLinuxExecPath('   '), '');
    });

    test('handles an unterminated quote by taking the rest of the string', () {
      expect(extractLinuxExecPath('"/opt/broken/path'), '/opt/broken/path');
    });
  });

  group('parseLinuxDesktopEntry', () {
    final patterns = DawDetector.linuxDawPatterns;

    test('matches a known DAW and extracts its executable path', () {
      const content = '''
[Desktop Entry]
Type=Application
Name=Zrythm
Exec=/opt/zrythm/bin/zrythm %U
Icon=zrythm
''';
      final result = parseLinuxDesktopEntry(content, patterns);
      expect(result, isNotNull);
      expect(result!.name, 'Zrythm');
      expect(result.executablePath, '/opt/zrythm/bin/zrythm');
    });

    test('matches case-insensitively', () {
      const content = '''
[Desktop Entry]
Name=REAPER
Exec=/opt/reaper/reaper
''';
      final result = parseLinuxDesktopEntry(content, patterns);
      expect(result?.name, 'Reaper');
    });

    test('returns null for a DAW not in the known-name patterns', () {
      const content = '''
[Desktop Entry]
Name=GIMP
Exec=/usr/bin/gimp %U
''';
      expect(parseLinuxDesktopEntry(content, patterns), isNull);
    });

    test('returns null when NoDisplay=true even for a matching name', () {
      const content = '''
[Desktop Entry]
Name=Ardour
Exec=/opt/ardour/ardour
NoDisplay=true
''';
      expect(parseLinuxDesktopEntry(content, patterns), isNull);
    });

    test('returns null when Hidden=true even for a matching name', () {
      const content = '''
[Desktop Entry]
Name=Ardour
Exec=/opt/ardour/ardour
Hidden=true
''';
      expect(parseLinuxDesktopEntry(content, patterns), isNull);
    });

    test('returns null when Exec is missing', () {
      const content = '''
[Desktop Entry]
Name=Ardour
''';
      expect(parseLinuxDesktopEntry(content, patterns), isNull);
    });

    test('ignores keys outside the [Desktop Entry] section', () {
      const content = '''
[Desktop Entry]
Name=Ardour
Exec=/opt/ardour/ardour

[Desktop Action NewWindow]
Name=Reaper
Exec=/opt/reaper/reaper
''';
      final result = parseLinuxDesktopEntry(content, patterns);
      // The first Name/Exec pair inside [Desktop Entry] wins; the
      // [Desktop Action ...] section's values must not override it.
      expect(result?.name, 'Ardour');
      expect(result?.executablePath, '/opt/ardour/ardour');
    });

    test('ignores comment and blank lines', () {
      const content = '''
[Desktop Entry]
# a comment
Name=Ardour

Exec=/opt/ardour/ardour
''';
      final result = parseLinuxDesktopEntry(content, patterns);
      expect(result?.name, 'Ardour');
    });
  });
}
