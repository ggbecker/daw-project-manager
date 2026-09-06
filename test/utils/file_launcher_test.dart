import 'dart:io';

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

  // Regression test for the "Launch in DAW" failure on macOS for Logic Pro
  // (.logicx) and Universal Audio LUNA (.luna) projects.
  //
  // Root cause: these DAWs save a project as a *directory* "package bundle",
  // and the scanner stores that directory as project.filePath. launchProject()
  // calls FileLauncher.launch(path, isFolder: false), and launchResolvedPath
  // used to gate on `File(path).exists()` when isFolder was false — which is
  // always false for a directory bundle, so the launch returned false before
  // ever handing the path to the OS. Plain single-file projects (.als, .flp,
  // …) were unaffected, which is why it looked DAW-specific.
  //
  // The fix accepts either a file or a directory at that path. The real
  // launchUrl/NSWorkspace call can't run in a unit test, so this pins the
  // check that was actually rejecting the bundle.
  group('launchTargetExists', () {
    late Directory tmp;

    setUp(() => tmp = Directory.systemTemp.createTempSync('launch_target_test'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('is true for a package-bundle project directory (.logicx / .luna)', () {
      final logicx = Directory('${tmp.path}/Song.logicx')..createSync();
      final luna = Directory('${tmp.path}/Song.luna')..createSync();
      expect(launchTargetExists(logicx.path), isTrue);
      expect(launchTargetExists(luna.path), isTrue);
    });

    test('is true for a plain single-file project', () {
      final flp = File('${tmp.path}/Song.flp')..writeAsStringSync('x');
      expect(launchTargetExists(flp.path), isTrue);
    });

    test('is false when nothing exists at the path', () {
      expect(launchTargetExists('${tmp.path}/does-not-exist.logicx'), isFalse);
    });
  });

  // launchWithBinary on macOS has to route a `.app` bundle through
  // `open -a` (a bundle is a directory, not an executable) but run a plain
  // Windows/Linux binary directly. The Process call itself can't run in a
  // unit test, so this pins the pure classifier that picks the route.
  group('isMacOsAppBundlePath', () {
    test('true for an application bundle path', () {
      expect(isMacOsAppBundlePath('/Applications/Logic Pro.app'), isTrue);
      expect(isMacOsAppBundlePath('/Applications/Ableton Live 12 Suite.APP'),
          isTrue);
      expect(isMacOsAppBundlePath('/Applications/REAPER.app/'), isTrue);
    });

    test('false for a plain executable', () {
      expect(
        isMacOsAppBundlePath(r'C:\Program Files\Ableton\Live 12\Ableton Live 12 Suite.exe'),
        isFalse,
      );
      expect(isMacOsAppBundlePath('/opt/zrythm/zrythm'), isFalse);
      expect(isMacOsAppBundlePath('/Applications/Logic Pro.app/Contents/MacOS/Logic Pro'), isFalse);
    });
  });
}
