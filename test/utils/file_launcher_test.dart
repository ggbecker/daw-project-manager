import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/file_launcher_platform_macos.dart';

// Regression test for https://github.com/bandpassrecords/daw-project-manager/issues/62:
// projects with a '#' in the path failed to launch on Windows.
//
// Root cause: launchResolvedPath used to always build a Uri.file(path) and
// hand it to url_launcher. url_launcher_windows unescapes %-encoded file://
// URLs before calling ShellExecuteW (to support UTF-8 paths), which turns the
// '%23' from Uri.file() back into a literal '#'. ShellExecuteW then reparses
// the still "file://"-prefixed string as a URL and treats '#' as a fragment
// delimiter, silently truncating the path there.
//
// The fix calls ShellExecuteW directly with the raw path (no file:// URI at
// all) for the specific paths that trigger this — those containing '#' — and
// leaves every other path on the existing url_launcher flow. The actual
// ShellExecuteW call can't be exercised in a unit test (it launches a real
// Windows process/association), so this pins the one thing that is pure and
// matters: which paths get routed to the workaround.
void main() {
  group('windowsNeedsDirectShellExecute', () {
    test('is true for a Windows path containing "#"', () {
      expect(windowsNeedsDirectShellExecute(r'C:\Music\Project #1\song.flp'),
          isTrue);
    }, testOn: 'windows');

    test('is false for a Windows path with no "#"', () {
      expect(windowsNeedsDirectShellExecute(r'C:\Music\Song.flp'), isFalse);
    }, testOn: 'windows');

    test('is false on non-Windows platforms even with "#" in the path', () {
      expect(windowsNeedsDirectShellExecute('/Music/Project #1/song.flp'),
          isFalse);
    }, testOn: 'mac-os || linux');
  });
}
