import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/launch_diagnostics.dart';

// Covers the diagnostics added for "Failed to launch <project>" reports on
// Windows 11, where the only instrumentation on the launch path used to be
// `kDebugMode print` — compiled out of the release builds testers run, so a
// failure report arrived with nothing attached.
//
// The parts that reach the shell (ShellExecuteW, url_launcher) can't run in
// a unit test, so what's pinned here is everything pure: how an entry is
// formatted, what the buffer does under its cap, which properties of a path
// get reported, and how a ShellExecuteW return value is decoded.
void main() {
  setUp(() {
    LaunchDiagnostics.clear();
    LaunchDiagnostics.sink = null;
  });

  tearDown(() {
    LaunchDiagnostics.clear();
    LaunchDiagnostics.sink = null;
  });

  group('formatEntry', () {
    final timestamp = DateTime.utc(2026, 8, 19, 14, 30, 5);

    test('includes the timestamp and step', () {
      final entry = LaunchDiagnostics.formatEntry(timestamp, 'launch requested');
      expect(entry, '2026-08-19T14:30:05.000Z [launch] launch requested');
    });

    test('renders fields as key=value pairs', () {
      final entry = LaunchDiagnostics.formatEntry(
        timestamp,
        'launch result',
        {'launched': false, 'code': 31},
      );
      expect(entry, endsWith('launch result launched=false code=31'));
    });

    test('keeps null-valued fields rather than dropping them', () {
      // "we looked and found nothing registered" is the finding that matters
      // most in a no-association report — it must not vanish from the log.
      final entry = LaunchDiagnostics.formatEntry(
        timestamp,
        'windows file association',
        {'openCommand': null},
      );
      expect(entry, contains('openCommand=null'));
    });
  });

  group('record', () {
    test('appends entries to the buffer in order', () {
      LaunchDiagnostics.record('first');
      LaunchDiagnostics.record('second');
      expect(LaunchDiagnostics.entries, hasLength(2));
      expect(LaunchDiagnostics.entries.first, contains('first'));
      expect(LaunchDiagnostics.entries.last, contains('second'));
      expect(LaunchDiagnostics.report, contains('\n'));
    });

    test('forwards each entry to the sink', () {
      final forwarded = <String>[];
      LaunchDiagnostics.sink = forwarded.add;
      LaunchDiagnostics.record('step', {'a': 1});
      expect(forwarded, hasLength(1));
      expect(forwarded.single, contains('step a=1'));
    });

    test('still records when the sink throws', () {
      // The sink writes to disk; a failure there must not break a launch.
      LaunchDiagnostics.sink = (_) => throw StateError('disk full');
      expect(() => LaunchDiagnostics.record('step'), returnsNormally);
      expect(LaunchDiagnostics.entries, hasLength(1));
    });

    test('drops the oldest entries past maxEntries', () {
      for (var i = 0; i < LaunchDiagnostics.maxEntries + 10; i++) {
        LaunchDiagnostics.record('step $i');
      }
      expect(LaunchDiagnostics.entries, hasLength(LaunchDiagnostics.maxEntries));
      expect(LaunchDiagnostics.entries.first, contains('step 10'));
      expect(LaunchDiagnostics.entries.last,
          contains('step ${LaunchDiagnostics.maxEntries + 9}'));
    });

    test('clear empties the buffer and the report', () {
      LaunchDiagnostics.record('step');
      LaunchDiagnostics.clear();
      expect(LaunchDiagnostics.entries, isEmpty);
      expect(LaunchDiagnostics.report, isEmpty);
    });
  });

  group('describePath', () {
    test('reports the lowercased extension of a Windows path', () {
      final facts = LaunchDiagnostics.describePath(r'C:\Music\Song.CPR');
      expect(facts['ext'], '.cpr');
    });

    test('reports the extension of a POSIX path', () {
      expect(LaunchDiagnostics.describePath('/Music/Song.als')['ext'], '.als');
    });

    test('reports an empty extension when the file name has no dot', () {
      expect(LaunchDiagnostics.describePath(r'C:\Music\Song')['ext'], '');
    });

    test('does not mistake a dot in a directory name for an extension', () {
      // 'C:\My.Music\Song' has a dot, but not in the file name.
      expect(LaunchDiagnostics.describePath(r'C:\My.Music\Song')['ext'], '');
    });

    test('does not treat a dotfile as an extension', () {
      expect(LaunchDiagnostics.describePath(r'C:\Music\.hidden')['ext'], '');
    });

    test('flags a path containing "#"', () {
      // The '#' case has its own launch route; the report should say so.
      final facts = LaunchDiagnostics.describePath(r'C:\Music\Project #1\a.flp');
      expect(facts['hasHash'], isTrue);
      expect(LaunchDiagnostics.describePath(r'C:\Music\a.flp')['hasHash'],
          isFalse);
    });

    test('flags non-ASCII characters', () {
      expect(LaunchDiagnostics.describePath(r'C:\Música\a.cpr')['nonAscii'],
          isTrue);
      expect(LaunchDiagnostics.describePath(r'C:\Music\a.cpr')['nonAscii'],
          isFalse);
    });

    test('flags a UNC path', () {
      expect(LaunchDiagnostics.describePath(r'\\nas\share\a.cpr')['unc'],
          isTrue);
      expect(LaunchDiagnostics.describePath(r'C:\Music\a.cpr')['unc'], isFalse);
    });

    test('flags a path at or over MAX_PATH', () {
      final long = 'C:\\Music\\${'a' * 300}.cpr';
      expect(LaunchDiagnostics.describePath(long)['overMaxPath'], isTrue);
      expect(LaunchDiagnostics.describePath(r'C:\Music\a.cpr')['overMaxPath'],
          isFalse);
    });

    test('flags a trailing space or dot, which Windows silently strips', () {
      expect(
        LaunchDiagnostics.describePath(r'C:\Music\a.cpr ')['trailingSpaceOrDot'],
        isTrue,
      );
      expect(
        LaunchDiagnostics.describePath(r'C:\Music\a.cpr.')['trailingSpaceOrDot'],
        isTrue,
      );
      expect(
        LaunchDiagnostics.describePath(r'C:\Music\a.cpr')['trailingSpaceOrDot'],
        isFalse,
      );
    });

    test('reports the path length', () {
      expect(LaunchDiagnostics.describePath('abc')['length'], 3);
    });
  });

  group('describeShellExecuteResult', () {
    test('treats anything over 32 as success', () {
      expect(LaunchDiagnostics.describeShellExecuteResult(33), 'success');
      expect(LaunchDiagnostics.describeShellExecuteResult(42), 'success');
    });

    test('names SE_ERR_NOASSOC, the prime suspect for a silent failure', () {
      final described = LaunchDiagnostics.describeShellExecuteResult(
        LaunchDiagnostics.kShellExecuteNoAssociation,
      );
      expect(described, contains('SE_ERR_NOASSOC'));
      expect(described, contains('no application is associated'));
    });

    test('names the file- and path-not-found codes', () {
      expect(LaunchDiagnostics.describeShellExecuteResult(2),
          contains('file not found'));
      expect(LaunchDiagnostics.describeShellExecuteResult(3),
          contains('path not found'));
    });

    test('names the access-denied code', () {
      expect(LaunchDiagnostics.describeShellExecuteResult(5),
          contains('access denied'));
    });

    test('does not report 32 as success', () {
      // 32 is SE_ERR_DLLNOTFOUND — the boundary is "greater than 32".
      expect(LaunchDiagnostics.describeShellExecuteResult(32),
          contains('SE_ERR_DLLNOTFOUND'));
    });

    test('falls back to a readable string for an unrecognised code', () {
      expect(LaunchDiagnostics.describeShellExecuteResult(19),
          'unknown failure code');
    });
  });
}
