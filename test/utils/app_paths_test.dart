import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/utils/app_paths.dart';

/// Regression coverage for a real incident during this project's own test
/// suite: ensureHiveInitialized() only tracked its own private
/// `_hiveInitialized` flag, not Hive's actual state. The first call to it
/// anywhere in a `flutter test` process — reached via many providers'
/// fire-and-forget _load() methods — would silently call
/// `Hive.init(realAppDataPath)`, overwriting the developer's actual
/// settings.hive, even when an earlier test file in the same process had
/// already called `Hive.init(tempDir)` itself. It must never fall back to
/// the real app-data directory while running under `flutter test`.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_paths_test_');
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('runs under FLUTTER_TEST=true (precondition for the next test)', () {
    expect(Platform.environment['FLUTTER_TEST'], 'true');
  });

  test(
    'never falls back to the real app-data directory while running under '
    'flutter test, even with no prior Hive.init() in this process',
    () async {
      // Deliberately does NOT call Hive.init() first — this is the exact
      // shape of the bug: some provider reaches ensureHiveInitialized() as
      // the very first Hive-related call in the process.
      await ensureHiveInitialized();

      // If it had fallen back to the real path, this would silently create
      // a box file under the developer's actual LOCALAPPDATA directory.
      // Instead, Hive still has no initialized directory, so opening a box
      // must fail loudly rather than writing anywhere real.
      await expectLater(
        () => Hive.openBox<String>('regression_probe'),
        throwsA(anything),
      );
    },
  );

  // A build that writes a Hive type the installed release does not know about
  // leaves that release unable to read its own boxes ("Cannot read, unknown
  // typeId"). Pull-request builds are shipped to testers as real installers,
  // so build mode alone cannot keep them off the stable app's library — CI
  // passes an explicit directory name instead.
  group('resolveAppDataDirName', () {
    test('a release build with no override uses the real library', () {
      expect(
        resolveAppDataDirName(override: '', isRelease: true),
        defaultAppDataDirName,
      );
    });

    test('a non-release build with no override is isolated', () {
      expect(
        resolveAppDataDirName(override: '', isRelease: false),
        '${defaultAppDataDirName}_dev',
      );
    });

    test('an override wins even in a release build', () {
      // This is the pull-request case: --release, but must not touch the
      // tester's real library.
      expect(
        resolveAppDataDirName(
          override: 'daw_project_manager_pr123',
          isRelease: true,
        ),
        'daw_project_manager_pr123',
      );
    });

    test('a blank or whitespace override falls through to build mode', () {
      expect(resolveAppDataDirName(override: '   ', isRelease: true),
          defaultAppDataDirName);
      expect(resolveAppDataDirName(override: '', isRelease: false),
          '${defaultAppDataDirName}_dev');
    });

    test('path separators and traversal are stripped out', () {
      // The value becomes a path segment under the app-data root, so it must
      // not be able to escape it.
      expect(
        resolveAppDataDirName(override: '../../Windows', isRelease: true),
        'Windows',
      );
      expect(
        resolveAppDataDirName(override: 'a/b\\c', isRelease: true),
        'abc',
      );
    });

    test('an override of only separators falls back rather than resolving to '
        'the app-data root itself', () {
      expect(
        resolveAppDataDirName(override: '../..', isRelease: true),
        defaultAppDataDirName,
      );
      expect(
        resolveAppDataDirName(override: '/', isRelease: true),
        defaultAppDataDirName,
      );
    });
  });
}
