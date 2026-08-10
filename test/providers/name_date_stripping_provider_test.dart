import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/providers/providers.dart';

/// Covers [NameDateStrippingNotifier].
///
/// The load-bearing behaviour is the mirroring: `MusicProject.displayName` is
/// a plain getter with no access to Riverpod, so it reads
/// [MusicProject.stripDatesFromNames] instead. If the notifier and that
/// static ever drift, the setting silently stops working — which is exactly
/// the kind of bug no widget test would catch.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('name_date_stripping_test_');
    Hive.init(tempDir.path);
    MusicProject.stripDatesFromNames = false;
  });

  tearDown(() async {
    MusicProject.stripDatesFromNames = false;
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('initial read', () {
    test('defaults to false when nothing has been saved yet', () async {
      await Hive.openBox<String>('settings');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(nameDateStrippingProvider), isFalse);
      expect(MusicProject.stripDatesFromNames, isFalse);
    });

    test('reads a persisted "true" synchronously on the very first read', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('stripDatesFromNames', 'true');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // No await, no pump — the settings switch paints from this first read.
      expect(container.read(nameDateStrippingProvider), isTrue);
    });

    test('mirrors the persisted value into the model static on first read', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('stripDatesFromNames', 'true');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(MusicProject.stripDatesFromNames, isFalse, reason: 'not read yet');
      container.read(nameDateStrippingProvider);
      expect(MusicProject.stripDatesFromNames, isTrue);
    });

    test('falls back to false instead of throwing if the box was never opened', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(nameDateStrippingProvider), isFalse);
      expect(MusicProject.stripDatesFromNames, isFalse);
    });
  });

  group('set()', () {
    test('updates state, the model static and Hive together', () async {
      final box = await Hive.openBox<String>('settings');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(nameDateStrippingProvider.notifier).set(true);

      expect(container.read(nameDateStrippingProvider), isTrue);
      expect(MusicProject.stripDatesFromNames, isTrue);
      expect(box.get('stripDatesFromNames'), 'true');
    });

    test('turning it back off restores all three', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('stripDatesFromNames', 'true');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(nameDateStrippingProvider);

      await container.read(nameDateStrippingProvider.notifier).set(false);

      expect(container.read(nameDateStrippingProvider), isFalse);
      expect(MusicProject.stripDatesFromNames, isFalse);
      expect(box.get('stripDatesFromNames'), 'false');
    });

    test('setting the value it already has is a no-op', () async {
      final box = await Hive.openBox<String>('settings');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(nameDateStrippingProvider.notifier).set(false);

      // Nothing written — the default is absence, not a stored "false".
      expect(box.get('stripDatesFromNames'), isNull);
    });

    test('does not throw when the settings box cannot be written', () async {
      // No Hive.openBox at all: set() must still update the in-memory state
      // so the switch responds, even though persistence fails.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(nameDateStrippingProvider.notifier).set(true);

      expect(container.read(nameDateStrippingProvider), isTrue);
      expect(MusicProject.stripDatesFromNames, isTrue);
    });
  });
}
