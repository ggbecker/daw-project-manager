import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/services/auto_start_service.dart';

/// Covers [AutoStartNotifier]. The OS registration itself (registry value /
/// login item / .desktop file) is behind [AutoStartService.backend], swapped
/// here for a fake so these run on any platform without mutating the real
/// machine's startup items.
///
/// The behaviour that matters and is easy to get wrong: the Hive value is
/// only a *cache* of state the OS owns, so (a) it must never be written when
/// the OS call failed, or the switch would claim a setting that isn't
/// actually in effect, and (b) it must be corrected at startup when the user
/// revoked auto-start outside the app.
class _FakeBackend implements AutoStartBackend {
  bool enabled = false;
  bool failEnable = false;
  bool throwOnAll = false;

  int enableCalls = 0;
  int disableCalls = 0;
  int setupCalls = 0;

  /// The `minimized` value the most recent setup() was given — i.e. what
  /// would actually get baked into the registration.
  bool? lastSetupMinimized;

  /// What setup() had been told at the time enable() was last called.
  bool? minimizedAtEnable;

  @override
  Future<void> setup({required bool minimized}) async {
    setupCalls++;
    if (throwOnAll) throw Exception('setup boom');
    lastSetupMinimized = minimized;
  }

  @override
  Future<bool> isEnabled() async {
    if (throwOnAll) throw Exception('isEnabled boom');
    return enabled;
  }

  @override
  Future<bool> enable() async {
    enableCalls++;
    minimizedAtEnable = lastSetupMinimized;
    if (throwOnAll) throw Exception('enable boom');
    if (failEnable) return false;
    enabled = true;
    return true;
  }

  @override
  Future<bool> disable() async {
    disableCalls++;
    if (throwOnAll) throw Exception('disable boom');
    enabled = false;
    return true;
  }
}

void main() {
  late Directory tempDir;
  late _FakeBackend fake;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('auto_start_test_');
    Hive.init(tempDir.path);
    fake = _FakeBackend();
    AutoStartService.backend = fake;
    AutoStartService.resetSetupFlagForTest();
  });

  tearDown(() async {
    AutoStartService.resetBackend();
    AutoStartService.resetSetupFlagForTest();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  // These assertions are only meaningful where launch-at-login exists; on an
  // unsupported platform the provider is hardwired to false by design.
  final onDesktop = AutoStartService.isSupported;

  group('autoStartProvider initial read', () {
    test('defaults to false when nothing has been saved yet', () async {
      await Hive.openBox<String>('settings');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(autoStartProvider), isFalse);
    });

    test('reads a persisted "true" synchronously on the very first read', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('autoStart', 'true');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // No await, no pump — the settings switch paints from this first read.
      expect(container.read(autoStartProvider), onDesktop ? isTrue : isFalse);
    });

    test('falls back to false instead of throwing if the settings box was never opened', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(autoStartProvider), isFalse);
    });
  });

  group('set()', () {
    test('registers with the OS and caches the value when it succeeds', () async {
      await Hive.openBox<String>('settings');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ok = await container.read(autoStartProvider.notifier).set(true);

      if (!onDesktop) {
        expect(ok, isFalse);
        return;
      }
      expect(ok, isTrue);
      expect(fake.enableCalls, 1);
      expect(fake.enabled, isTrue);
      expect(container.read(autoStartProvider), isTrue);
      expect(Hive.box<String>('settings').get('autoStart'), 'true');
    });

    test('unregisters and caches false when turned off', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('autoStart', 'true');
      fake.enabled = true;

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ok = await container.read(autoStartProvider.notifier).set(false);

      if (!onDesktop) {
        expect(ok, isFalse);
        return;
      }
      expect(ok, isTrue);
      expect(fake.disableCalls, 1);
      expect(container.read(autoStartProvider), isFalse);
      expect(box.get('autoStart'), 'false');
    });

    test('does not cache the value when the OS refuses', () async {
      await Hive.openBox<String>('settings');
      fake.failEnable = true;

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ok = await container.read(autoStartProvider.notifier).set(true);

      expect(ok, isFalse);
      // Regression guard: persisting here would leave the switch showing "on"
      // forever while the app was never actually registered to launch.
      expect(container.read(autoStartProvider), isFalse);
      expect(Hive.box<String>('settings').get('autoStart'), isNull);
    });

    test('reports failure instead of throwing when the backend throws', () async {
      await Hive.openBox<String>('settings');
      fake.throwOnAll = true;

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ok = await container.read(autoStartProvider.notifier).set(true);

      expect(ok, isFalse);
      expect(container.read(autoStartProvider), isFalse);
      expect(Hive.box<String>('settings').get('autoStart'), isNull);
    });
  });

  group('syncWithOs()', () {
    test('clears a stale cached "true" when the OS no longer has the app registered', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('autoStart', 'true');
      fake.enabled = false; // user removed it via Task Manager / Login Items

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(autoStartProvider.notifier).syncWithOs();

      expect(container.read(autoStartProvider), isFalse);
      if (onDesktop) {
        expect(box.get('autoStart'), 'false');
      }
    });

    test('adopts a "true" the OS reports even if nothing was cached', () async {
      final box = await Hive.openBox<String>('settings');
      fake.enabled = true;

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(autoStartProvider.notifier).syncWithOs();

      expect(container.read(autoStartProvider), onDesktop ? isTrue : isFalse);
      if (onDesktop) {
        expect(box.get('autoStart'), 'true');
      }
    });

    test('leaves an already-matching value alone', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('autoStart', 'true');
      fake.enabled = true;

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(autoStartProvider.notifier).syncWithOs();

      expect(container.read(autoStartProvider), onDesktop ? isTrue : isFalse);
      expect(fake.enableCalls, 0);
      expect(fake.disableCalls, 0);
    });

    test('survives a backend that throws', () async {
      await Hive.openBox<String>('settings');
      fake.throwOnAll = true;

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await expectLater(
        container.read(autoStartProvider.notifier).syncWithOs(),
        completes,
      );
      expect(container.read(autoStartProvider), isFalse);
    });
  });

  group('startMinimizedProvider', () {
    test('defaults to false', () async {
      await Hive.openBox<String>('settings');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(startMinimizedProvider), isFalse);
    });

    test('reads a persisted "true" synchronously', () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('startMinimized', 'true');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(startMinimizedProvider), onDesktop ? isTrue : isFalse);
    });

    test('bakes the flag into the registration when auto-start is turned on',
        () async {
      final box = await Hive.openBox<String>('settings');
      await box.put('startMinimized', 'true');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(autoStartProvider.notifier).set(true);

      if (!onDesktop) return;
      // The flag lives inside the registration, so setup() must have been
      // told about it *before* enable() wrote it.
      expect(fake.minimizedAtEnable, isTrue);
    });

    test('rewrites an existing registration when toggled while auto-start is on',
        () async {
      await Hive.openBox<String>('settings');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(autoStartProvider.notifier).set(true);
      if (!onDesktop) return;
      expect(fake.minimizedAtEnable, isFalse);

      final ok =
          await container.read(startMinimizedProvider.notifier).set(true);

      expect(ok, isTrue);
      expect(container.read(startMinimizedProvider), isTrue);
      // Regression guard: without the re-registration the app would still be
      // registered with the old (no-flag) command and would keep opening its
      // window at login despite the setting reading "on".
      expect(fake.disableCalls, greaterThanOrEqualTo(1));
      expect(fake.enableCalls, 2);
      expect(fake.minimizedAtEnable, isTrue);
      expect(fake.enabled, isTrue);
      expect(Hive.box<String>('settings').get('startMinimized'), 'true');
    });

    test('does not touch the OS when auto-start is off', () async {
      await Hive.openBox<String>('settings');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final ok =
          await container.read(startMinimizedProvider.notifier).set(true);

      if (!onDesktop) {
        expect(ok, isFalse);
        return;
      }
      expect(ok, isTrue);
      expect(container.read(startMinimizedProvider), isTrue);
      expect(fake.enableCalls, 0);
      expect(fake.disableCalls, 0);
      expect(Hive.box<String>('settings').get('startMinimized'), 'true');
    });

    test('reverts and does not persist when the re-registration fails',
        () async {
      await Hive.openBox<String>('settings');
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(autoStartProvider.notifier).set(true);
      if (!onDesktop) return;
      fake.failEnable = true;

      final ok =
          await container.read(startMinimizedProvider.notifier).set(true);

      expect(ok, isFalse);
      expect(container.read(startMinimizedProvider), isFalse);
      expect(Hive.box<String>('settings').get('startMinimized'), isNull);
      // The rewrite unregisters before re-registering, so a failed re-enable
      // really does leave the app unregistered — auto-start must stop
      // claiming it is on, or the settings page would show a state the OS
      // does not have.
      expect(fake.enabled, isFalse);
      expect(container.read(autoStartProvider), isFalse);
      expect(Hive.box<String>('settings').get('autoStart'), 'false');
    });
  });

  group('launchedMinimized', () {
    test('is true only when the OS passed the flag', () {
      expect(
        AutoStartService.launchedMinimized([kStartMinimizedFlag]),
        onDesktop ? isTrue : isFalse,
      );
    });

    test('is false for a manual launch with no arguments', () {
      // The whole point of the flag: double-clicking the app must always
      // open the window, whatever the setting says.
      expect(AutoStartService.launchedMinimized(const []), isFalse);
      expect(AutoStartService.launchedMinimized(const ['--other']), isFalse);
    });
  });
}
