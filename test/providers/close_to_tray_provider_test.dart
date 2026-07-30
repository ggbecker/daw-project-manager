import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/providers/providers.dart';

/// Regression coverage for a startup race in CloseToTrayNotifier /
/// WarnBeforeQuitNotifier: build() used to return a hardcoded `true`
/// default and only load the real persisted value via a post-frame
/// callback. A window-close event firing before that callback ran (e.g.
/// closing the app moments after launch) would see the wrong value and
/// silently ignore the user's actual "close to tray" / "warn before quit"
/// preference. build() now reads the already-open settings box (opened by
/// main() before runApp(), specifically so this can be synchronous)
/// directly, so the very first read is always correct.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('close_to_tray_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('closeToTrayProvider', () {
    test('reads a persisted "false" synchronously on the very first read', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('closeToTray', 'false');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // No await, no pump — this is the exact call shape of onWindowClose's
      // `ref.read(closeToTrayProvider)`. Regression: this used to return
      // `true` here regardless of what was persisted.
      expect(container.read(closeToTrayProvider), isFalse);
    });

    test('reads a persisted "true" synchronously on the very first read', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('closeToTray', 'true');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(closeToTrayProvider), isTrue);
    });

    test('defaults to false when nothing has been saved yet', () async {
      await Hive.openBox<String>('settings');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(closeToTrayProvider), isFalse);
    });

    test('falls back to the default instead of throwing if the settings box was never opened', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(closeToTrayProvider), isFalse);
    });
  });

  group('warnBeforeQuitProvider', () {
    test('reads a persisted "false" synchronously on the very first read', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('warnBeforeQuit', 'false');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(warnBeforeQuitProvider), isFalse);
    });

    test('defaults to true when nothing has been saved yet', () async {
      await Hive.openBox<String>('settings');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(warnBeforeQuitProvider), isTrue);
    });
  });
}
