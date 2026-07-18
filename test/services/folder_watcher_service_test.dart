import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/scan_root.dart';
import 'package:daw_project_manager/services/folder_watcher_service.dart';

void main() {
  late Directory watchedDir;
  late FolderWatcherService watcher;

  ScanRoot rootFor(String path) =>
      ScanRoot(id: 'r1', path: path, addedAt: DateTime.now());

  setUp(() async {
    watchedDir = await Directory.systemTemp.createTemp('folder_watcher_test_');
    watcher = FolderWatcherService(debounce: const Duration(milliseconds: 150));
  });

  tearDown(() async {
    await watcher.dispose();
    if (await watchedDir.exists()) {
      await watchedDir.delete(recursive: true);
    }
  });

  test('emits the root path once activity under it settles', () async {
    watcher.syncRoots([rootFor(watchedDir.path)]);
    // Let the native watch handle attach before writing.
    await Future.delayed(const Duration(milliseconds: 100));

    final events = <String>[];
    final sub = watcher.changes.listen(events.add);

    File('${watchedDir.path}/project.als').writeAsStringSync('data');

    await Future.delayed(const Duration(milliseconds: 500));
    await sub.cancel();

    expect(events, [watchedDir.path]);
  });

  test('collapses a burst of writes into a single emission (debounce)', () async {
    watcher.syncRoots([rootFor(watchedDir.path)]);
    await Future.delayed(const Duration(milliseconds: 100));

    final events = <String>[];
    final sub = watcher.changes.listen(events.add);

    for (var i = 0; i < 5; i++) {
      File('${watchedDir.path}/project_$i.als').writeAsStringSync('data');
      await Future.delayed(const Duration(milliseconds: 20));
    }

    await Future.delayed(const Duration(milliseconds: 500));
    await sub.cancel();

    expect(events, [watchedDir.path]);
  });

  test('stops emitting once a root is dropped from syncRoots, resumes when re-added', () async {
    watcher.syncRoots([rootFor(watchedDir.path)]);
    await Future.delayed(const Duration(milliseconds: 100));

    watcher.syncRoots([]);

    final events = <String>[];
    final sub = watcher.changes.listen(events.add);

    File('${watchedDir.path}/ignored.als').writeAsStringSync('data');
    await Future.delayed(const Duration(milliseconds: 500));
    expect(events, isEmpty, reason: 'watcher was told to stop watching this root');

    watcher.syncRoots([rootFor(watchedDir.path)]);
    await Future.delayed(const Duration(milliseconds: 100));

    File('${watchedDir.path}/seen.als').writeAsStringSync('data');
    await Future.delayed(const Duration(milliseconds: 500));
    await sub.cancel();

    expect(events, [watchedDir.path]);
  });

  test('watching a path that does not exist on disk does not throw', () async {
    final missingPath = '${watchedDir.path}${Platform.pathSeparator}does_not_exist';

    expect(() => watcher.syncRoots([rootFor(missingPath)]), returnsNormally);
  });
}
