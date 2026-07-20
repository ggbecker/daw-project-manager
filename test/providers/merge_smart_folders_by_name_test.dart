import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/providers/providers.dart';

/// Reads synchronously from the already-open `settings` box (see
/// exclude_smart_folders_from_sort_test.dart for the same pattern and why it
/// matters here too): this value feeds the Projects grid's remount key, so an
/// async load that flips the value a frame after cold start would make the
/// grid visibly remount again almost immediately.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('merge_smart_folders_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('mergeSmartFoldersByNameProvider', () {
    test('reads a persisted "true" synchronously on the very first read', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('mergeSmartFoldersByName', 'true');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(mergeSmartFoldersByNameProvider), isTrue);
    });

    test('reads a persisted "false" synchronously on the very first read', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('mergeSmartFoldersByName', 'false');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(mergeSmartFoldersByNameProvider), isFalse);
    });

    test('defaults to false (opt-in feature) when nothing has been saved yet', () async {
      await Hive.openBox<String>('settings');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(mergeSmartFoldersByNameProvider), isFalse);
    });

    test('falls back to the default instead of throwing if the settings box was never opened', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(mergeSmartFoldersByNameProvider), isFalse);
    });

    test('set() persists the value so a fresh container picks it back up', () async {
      final first = ProviderContainer();
      await first.read(mergeSmartFoldersByNameProvider.notifier).set(true);
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);

      expect(second.read(mergeSmartFoldersByNameProvider), isTrue);
    });
  });
}
