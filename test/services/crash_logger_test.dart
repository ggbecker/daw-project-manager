import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import 'package:daw_project_manager/services/crash_logger.dart';

void main() {
  group('CrashLogger.formatEntry', () {
    test('includes source, error text and timestamp', () {
      final entry = CrashLogger.formatEntry(
        'flutter',
        'boom',
        null,
        DateTime.utc(2026, 1, 2, 3, 4, 5),
      );
      expect(entry, contains('[flutter]'));
      expect(entry, contains('boom'));
      expect(entry, contains('2026-01-02T03:04:05'));
    });

    test('includes the stack trace when provided', () {
      final trace = StackTrace.fromString('#0 foo\n#1 bar');
      final entry = CrashLogger.formatEntry('platform', 'err', trace, DateTime.now());
      expect(entry, contains('#0 foo'));
      expect(entry, contains('#1 bar'));
    });

    test('omits stack trace section entirely when null', () {
      final entry = CrashLogger.formatEntry('lifecycle', 'App resumed', null, DateTime.now());
      // Two lines: the header and the message — no trailing stack dump.
      final lines = entry.trimRight().split('\n');
      expect(lines.length, 2);
    });
  });

  group('CrashLogger.appendToFile', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('crash_logger_test_');
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('creates the file and writes the entry when it does not exist', () async {
      final file = File(p.join(dir.path, 'log.txt'));

      await CrashLogger.appendToFile(file, 'first entry\n');

      expect(await file.readAsString(), 'first entry\n');
    });

    test('appends subsequent entries instead of overwriting', () async {
      final file = File(p.join(dir.path, 'log.txt'));

      await CrashLogger.appendToFile(file, 'first\n');
      await CrashLogger.appendToFile(file, 'second\n');

      final contents = await file.readAsString();
      expect(contents, contains('first'));
      expect(contents, contains('second'));
    });

    test('truncates before writing once the file exceeds maxBytes', () async {
      final file = File(p.join(dir.path, 'log.txt'));
      await file.writeAsString('x' * 100);

      await CrashLogger.appendToFile(file, 'new entry\n', maxBytes: 50);

      final contents = await file.readAsString();
      expect(contents, 'new entry\n');
      expect(contents.contains('x'), isFalse);
    });

    test('does not truncate while under maxBytes', () async {
      final file = File(p.join(dir.path, 'log.txt'));
      await file.writeAsString('short');

      await CrashLogger.appendToFile(file, ' more\n', maxBytes: 1000);

      expect(await file.readAsString(), 'short more\n');
    });
  });

  group('CrashLogger.shareSheetUnavailable', () {
    // shareOrRevealLogFiles itself isn't unit-tested end to end: it calls a
    // real platform channel (Share.shareXFiles) and, on the fallback path, a
    // real FileLauncher.openFolder that spawns an OS process — neither
    // belongs in `flutter test`. What's covered here is the pure decision
    // extracted from it: which ShareResultStatus values should trigger the
    // folder-reveal fallback for Linux (share_plus has no file-sharing
    // implementation there and throws every time — modeled as `null`
    // status) and unpackaged Windows (returns `.unavailable`).
    test('treats a null status (the share call threw) as unavailable', () {
      expect(CrashLogger.shareSheetUnavailable(null), isTrue);
    });

    test('treats ShareResultStatus.unavailable as unavailable', () {
      expect(CrashLogger.shareSheetUnavailable(ShareResultStatus.unavailable), isTrue);
    });

    test('treats ShareResultStatus.success as available', () {
      expect(CrashLogger.shareSheetUnavailable(ShareResultStatus.success), isFalse);
    });

    test('treats ShareResultStatus.dismissed as available (share sheet did show)', () {
      expect(CrashLogger.shareSheetUnavailable(ShareResultStatus.dismissed), isFalse);
    });
  });

  group('CrashLogger.nativeFileShareSheetSupported', () {
    // Native sharing turned out unusable on every desktop platform: Linux
    // (share_plus throws unconditionally there), Windows (the
    // DataTransferManager flyout opens but fails inside its own UI for an
    // unpackaged build, with no ShareResultStatus to detect that from Dart),
    // and macOS wasn't worth keeping a separate code path alive for. Desktop
    // now always just opens the log folder; only mobile still attempts the
    // native share sheet, since there's no folder-reveal equivalent there.
    test('is false on desktop', () {
      expect(CrashLogger.nativeFileShareSheetSupported(isMobile: false), isFalse);
    });

    test('is true on mobile', () {
      expect(CrashLogger.nativeFileShareSheetSupported(isMobile: true), isTrue);
    });
  });

  // isEnabled/setEnabled are a pure in-memory flag, safe to exercise
  // directly. log() and clearLogs() are NOT covered here — both ultimately
  // call _resolveFile(), which calls getLocalAppDataPath() → the real
  // %LOCALAPPDATA%/application support directory, with no test-safe
  // override (unlike Hive, which tests redirect via
  // HiveTestHelper.setUp()'s explicit Hive.init(tempDir)). Calling them
  // directly here would write to or delete a real user's actual crash log
  // during `flutter test` — the same restraint the appendToFile tests above
  // already take by operating on an explicit temp-dir File instead.
  group('CrashLogger.isEnabled / setEnabled', () {
    tearDown(() => CrashLogger.setEnabled(false)); // restore the default for other tests

    test('defaults to disabled (opt-in, not opt-out)', () {
      expect(CrashLogger.isEnabled, isFalse);
    });

    test('setEnabled(true) is reflected by isEnabled', () {
      CrashLogger.setEnabled(true);
      expect(CrashLogger.isEnabled, isTrue);
    });

    test('setEnabled(false) after true disables it again', () {
      CrashLogger.setEnabled(true);
      CrashLogger.setEnabled(false);
      expect(CrashLogger.isEnabled, isFalse);
    });
  });
}
