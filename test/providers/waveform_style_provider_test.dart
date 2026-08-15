import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:daw_project_manager/models/waveform_style.dart';
import 'package:daw_project_manager/providers/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('waveform_style_test_');
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await hiveDir.exists()) await hiveDir.delete(recursive: true);
  });

  test('defaults to the detailed rendering', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(waveformStyleProvider), WaveformStyle.detailed);
  });

  test('persists the choice to the device-local settings box', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(waveformStyleProvider.notifier).set(WaveformStyle.classic);

    expect(container.read(waveformStyleProvider), WaveformStyle.classic);
    final box = await Hive.openBox<String>('settings');
    expect(box.get('waveformStyle'), 'classic');
  });

  test('shares the settings box with the theme rather than a synced store',
      () async {
    // This is a display preference for this machine — it must not land
    // anywhere that Drive sync or a backup would carry to another device.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(waveformStyleProvider.notifier).set(WaveformStyle.classic);

    final box = await Hive.openBox<String>('settings');
    expect(box.name, 'settings');
    expect(box.get('waveformStyle'), isNotNull);
  });

  test('a value written by a newer build falls back to the default', () async {
    final box = await Hive.openBox<String>('settings');
    await box.put('waveformStyle', 'somethingFromTheFuture');

    final container = ProviderContainer();
    addTearDown(container.dispose);
    // The load is post-frame; reading straight away gives the default, and an
    // unrecognised stored name must never throw when it does run.
    expect(container.read(waveformStyleProvider), WaveformStyle.detailed);
  });

  test('every style has a distinct name to persist', () {
    final names = WaveformStyle.values.map((e) => e.name).toSet();
    expect(names, hasLength(WaveformStyle.values.length));
  });

  group('waveformStereoProvider', () {
    test('defaults to a single lane', () {
      // On a finished master L and R correlate above 0.93, so two lanes redraw
      // the same shape at half the vertical resolution. Opt-in, not default.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(waveformStereoProvider), isFalse);
    });

    test('persists to the same device-local box as the style', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(waveformStereoProvider.notifier).set(true);

      expect(container.read(waveformStereoProvider), isTrue);
      final box = await Hive.openBox<String>('settings');
      expect(box.get('waveformStereo'), 'true');
    });

    test('turning it back off is persisted too, not just left unset', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(waveformStereoProvider.notifier).set(true);
      await container.read(waveformStereoProvider.notifier).set(false);

      final box = await Hive.openBox<String>('settings');
      expect(box.get('waveformStereo'), 'false');
    });

    test('uses a different key from the style, so neither clobbers the other',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(waveformStyleProvider.notifier).set(WaveformStyle.classic);
      await container.read(waveformStereoProvider.notifier).set(true);

      final box = await Hive.openBox<String>('settings');
      expect(box.get('waveformStyle'), 'classic');
      expect(box.get('waveformStereo'), 'true');
    });
  });
}
