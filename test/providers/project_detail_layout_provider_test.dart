import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:daw_project_manager/models/project_detail_layout.dart';
import 'package:daw_project_manager/models/waveform_style.dart';
import 'package:daw_project_manager/providers/providers.dart';

/// #104 — which layout the project detail page uses is a preference about
/// this machine's screen, not project data, so it lives in the same
/// device-local `settings` box as the theme and must never reach Drive sync
/// or a backup file.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('detail_layout_test_');
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await hiveDir.exists()) await hiveDir.delete(recursive: true);
  });

  test('defaults to the classic single scroll', () {
    // The layout everyone already has. Opting in is the user's call.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(projectDetailLayoutProvider),
        ProjectDetailLayout.classic);
  });

  test('persists the choice to the device-local settings box', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(projectDetailLayoutProvider.notifier)
        .set(ProjectDetailLayout.sectioned);

    expect(container.read(projectDetailLayoutProvider),
        ProjectDetailLayout.sectioned);
    final box = await Hive.openBox<String>('settings');
    expect(box.name, 'settings');
    expect(box.get('projectDetailLayout'), 'sectioned');
  });

  test('switching back to classic is written, not just left unset', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(projectDetailLayoutProvider.notifier);
    await notifier.set(ProjectDetailLayout.sectioned);
    await notifier.set(ProjectDetailLayout.classic);

    final box = await Hive.openBox<String>('settings');
    expect(box.get('projectDetailLayout'), 'classic');
  });

  test('a value written by a newer build falls back to the default', () async {
    final box = await Hive.openBox<String>('settings');
    await box.put('projectDetailLayout', 'somethingFromTheFuture');

    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(projectDetailLayoutProvider),
        ProjectDetailLayout.classic);
  });

  test('uses its own key, so it does not clobber the waveform style',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(waveformStyleProvider.notifier)
        .set(WaveformStyle.classic);
    await container
        .read(projectDetailLayoutProvider.notifier)
        .set(ProjectDetailLayout.sectioned);

    final box = await Hive.openBox<String>('settings');
    expect(box.get('waveformStyle'), 'classic');
    expect(box.get('projectDetailLayout'), 'sectioned');
  });

  test('every layout has a distinct name to persist', () {
    final names = ProjectDetailLayout.values.map((e) => e.name).toSet();
    expect(names, hasLength(ProjectDetailLayout.values.length));
  });
}
