import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/repository/project_repository.dart';
import 'package:daw_project_manager/services/scan_import_service.dart';

import '../helpers/hive_test_helper.dart';

// Regression coverage for: adding a projects folder via the startup dialog or
// the onboarding wizard registered the scan root but never scanned it, so a
// folder that already contained projects stayed empty in the UI until the
// user hit "Rescan" (or relaunched the app, which re-runs the initial scan).
// The background folder watcher doesn't help — it only reacts to filesystem
// activity that happens *after* it starts watching.
//
// importProjectsFromRoot is the shared "scan the one folder I just added"
// step those entry points now call right after ProjectRepository.addRoot.
void main() {
  late Directory hiveDir;
  late Directory musicDir;
  late ProjectRepository repo;

  setUp(() async {
    hiveDir = await HiveTestHelper.setUp();
    repo = await HiveTestHelper.createRepository();
    musicDir = await Directory.systemTemp.createTemp('scan_import_music_');
  });

  tearDown(() async {
    await HiveTestHelper.tearDown(hiveDir);
    if (await musicDir.exists()) await musicDir.delete(recursive: true);
  });

  test('imports a plain-file project and a package-bundle project from a '
      'freshly added root, and stamps the root scan time', () async {
    // A single-file DAW project…
    await File(p.join(musicDir.path, 'Track.flp')).writeAsString('x');
    // …and a Logic Pro / LUNA style package bundle (a *directory* on disk).
    final logicx = Directory(p.join(musicDir.path, 'Song.logicx'));
    await logicx.create();
    await File(p.join(logicx.path, 'ProjectData')).writeAsString('x');

    final root = await repo.addRoot(musicDir.path);
    expect(repo.getAllProjects(), isEmpty, reason: 'addRoot must not scan');

    final found = await importProjectsFromRoot(repo, root.id, root.path);

    expect(found, 2);
    final paths = repo.getAllProjects().map((e) => e.filePath).toSet();
    expect(paths, {
      p.join(musicDir.path, 'Track.flp'),
      logicx.path,
    });
    expect(repo.getRoots().single.lastScanAt, isNotNull);
  });

  test('returns 0 and still stamps the scan time for an empty folder', () async {
    final root = await repo.addRoot(musicDir.path);

    final found = await importProjectsFromRoot(repo, root.id, root.path);

    expect(found, 0);
    expect(repo.getAllProjects(), isEmpty);
    expect(repo.getRoots().single.lastScanAt, isNotNull);
  });
}
