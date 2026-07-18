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
}
