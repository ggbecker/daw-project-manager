import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/providers/theme_provider.dart';

/// Exercises the exact calls the Settings page's new Language row (General
/// section) and Theme selector (Appearance section) make —
/// `localeProvider.notifier.setLocale` and `themeTypeProvider.notifier.setThemeType`.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('locale_theme_provider_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('localeProvider', () {
    test('defaults to English before any preference is saved', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(localeProvider), const Locale('en'));
    });

    test('setLocale updates state immediately', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale(const Locale('ja'));

      expect(container.read(localeProvider), const Locale('ja'));
    });

    test('setLocale persists languageCode_countryCode to the settings box', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale(const Locale('pt', 'BR'));

      final box = await Hive.openBox<String>('settings');
      expect(box.get('locale'), 'pt_BR');
    });

    test('setLocale persists an empty country code when the locale has none', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale(const Locale('de'));

      final box = await Hive.openBox<String>('settings');
      expect(box.get('locale'), 'de_');
    });
  });

  group('themeTypeProvider', () {
    test('defaults to classicDark before any preference is saved', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeTypeProvider), AppThemeType.classicDark);
    });

    test('setThemeType updates state immediately', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeTypeProvider.notifier).setThemeType(AppThemeType.neonDark);

      expect(container.read(themeTypeProvider), AppThemeType.neonDark);
    });

    test('setThemeType persists the enum name to the settings box', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeTypeProvider.notifier).setThemeType(AppThemeType.neonDark);

      final box = await Hive.openBox<String>('settings');
      expect(box.get('theme'), 'neonDark');
    });
  });
}
