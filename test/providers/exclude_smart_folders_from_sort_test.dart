import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/providers/providers.dart';

/// Reads synchronously from the already-open `settings` box (see
/// close_to_tray_provider_test.dart for the same pattern and why it matters
/// here too): this value feeds the Projects grid's remount key, so an
/// async load that flips the value a frame after cold start would make the
/// grid visibly remount again almost immediately.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('exclude_smart_folders_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('excludeSmartFoldersFromSortProvider', () {
    test('reads a persisted "true" synchronously on the very first read', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('excludeSmartFoldersFromSort', 'true');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(excludeSmartFoldersFromSortProvider), isTrue);
    });

    test('reads a persisted "false" synchronously on the very first read', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('excludeSmartFoldersFromSort', 'false');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(excludeSmartFoldersFromSortProvider), isFalse);
    });

    test('defaults to false (opt-in feature) when nothing has been saved yet', () async {
      await Hive.openBox<String>('settings');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(excludeSmartFoldersFromSortProvider), isFalse);
    });

    test('falls back to the default instead of throwing if the settings box was never opened', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(excludeSmartFoldersFromSortProvider), isFalse);
    });

    test('set() persists the value so a fresh container picks it back up', () async {
      final first = ProviderContainer();
      await first.read(excludeSmartFoldersFromSortProvider.notifier).set(true);
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);

      expect(second.read(excludeSmartFoldersFromSortProvider), isTrue);
    });
  });
}
