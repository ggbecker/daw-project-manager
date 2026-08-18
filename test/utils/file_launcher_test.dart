import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/file_launcher_platform_io.dart';

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
// '%' fails the same way for a different reason on that second pass:
// ShellExecuteW's URL-to-path conversion percent-decodes again, so a literal
// '%' followed by two hex digits (e.g. a file saved from a download link as
// "My%20Track.cpr") decodes into a different name — "My Track.cpr" — and the
// launch either fails or opens the wrong project. Confirmed against
// ShellExecuteW/PathCreateFromUrlW directly: "100%25off.cpr" resolves to
// "100%off.cpr", "pct-a%41b.cpr" to "pct-aAb.cpr".
//
// The fix calls ShellExecuteW directly with the raw path (no file:// URI at
// all) for the specific paths that trigger this — those containing '#' or '%'
// — and leaves every other path on the existing url_launcher flow. The actual
// ShellExecuteW call can't be exercised in a unit test (it launches a real
// Windows process/association), so this pins the one thing that is pure and
// matters: which paths get routed to the workaround.
void main() {
  group('windowsNeedsDirectShellExecute', () {
    test('is true for a Windows path containing "#"', () {
      expect(windowsNeedsDirectShellExecute(r'C:\Music\Project #1\song.flp'),
          isTrue);
    }, testOn: 'windows');

    test('is true for a Windows path containing "%" plus hex digits', () {
      expect(windowsNeedsDirectShellExecute(r'C:\Music\My%20Track.cpr'), isTrue);
    }, testOn: 'windows');

    test('is true for a "%" in a folder name, not just the file name', () {
      expect(windowsNeedsDirectShellExecute(r'C:\Music\100%25 Off\song.flp'),
          isTrue);
    }, testOn: 'windows');

    test('is true for a bare "%" with no hex digits after it', () {
      // Harmless to ShellExecuteW on its own, but the workaround is the more
      // correct route for any path, so we do not try to be precise here.
      expect(windowsNeedsDirectShellExecute(r'C:\Music\Wet 50% Dry.cpr'),
          isTrue);
    }, testOn: 'windows');

    test('is false for a Windows path with no "#" or "%"', () {
      expect(windowsNeedsDirectShellExecute(r'C:\Music\Song.flp'), isFalse);
    }, testOn: 'windows');

    test('is false for Windows paths with other punctuation and Unicode', () {
      // Everything here round-trips through Uri.file + url_launcher's unescape
      // unchanged, so it must stay on the url_launcher flow.
      expect(
          windowsNeedsDirectShellExecute(r"C:\Music\Mix (v2) & 日本語 ~ 'x'.flp"),
          isFalse);
    }, testOn: 'windows');

    test('is false on non-Windows platforms even with "#" in the path', () {
      expect(windowsNeedsDirectShellExecute('/Music/Project #1/song.flp'),
          isFalse);
    }, testOn: 'mac-os || linux');

    test('is false on non-Windows platforms even with "%" in the path', () {
      // macOS hands the percent-encoded string straight to NSWorkspace with no
      // unescape step, so there is no double-decode to work around.
      expect(windowsNeedsDirectShellExecute('/Music/My%20Track.cpr'), isFalse);
    }, testOn: 'mac-os || linux');
  });
}
