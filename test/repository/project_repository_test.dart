import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/pending_folder.dart';
import 'package:daw_project_manager/models/release.dart';
import 'package:daw_project_manager/services/backup_service.dart';
import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
  });

  tearDown(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  group('ProjectRepository.updateProject', () {
    test('bumps updatedAt to approximately now', () async {
      final repo = await HiveTestHelper.createRepository();
      final project = TestFactories.makeProject(
        updatedAt: DateTime(2020, 1, 1),
      );
      await repo.updateProject(project);

      final saved = repo.getById(project.id)!;
      final diff = DateTime.now().difference(saved.updatedAt).abs();
      expect(diff.inSeconds, lessThan(5));
    });

    test('does NOT change lastModifiedAt', () async {
      final repo = await HiveTestHelper.createRepository();
      final modifiedAt = DateTime(2024, 6, 15, 10, 0, 0);
      final project = TestFactories.makeProject(lastModifiedAt: modifiedAt);

      await repo.updateProject(project);

      final saved = repo.getById(project.id)!;
      expect(saved.lastModifiedAt, modifiedAt);
    });

    test('preserves all other fields', () async {
      final repo = await HiveTestHelper.createRepository();
      final original = TestFactories.makeProject(
        bpm: 140.0,
        notes: 'great track',
        status: 'Mastering',
        musicalKey: 'D minor',
      );

      await repo.updateProject(original);
      final saved = repo.getById(original.id)!;

      expect(saved.bpm, 140.0);
      expect(saved.notes, 'great track');
      expect(saved.status, 'Mastering');
      expect(saved.musicalKey, 'D minor');
    });

    test('creates project if it does not exist yet', () async {
      final repo = await HiveTestHelper.createRepository();
      expect(repo.getAllProjects(), isEmpty);

      final project = TestFactories.makeProject(id: 'new-id');
      await repo.updateProject(project);

      expect(repo.getAllProjects().length, 1);
      expect(repo.getById('new-id'), isNotNull);
    });
  });

  group('ProjectRepository.restoreProject', () {
    test('preserves lastModifiedAt exactly (does not bump)', () async {
      final repo = await HiveTestHelper.createRepository();
      final modifiedAt = DateTime(2019, 3, 22, 15, 30, 0);
      final project = TestFactories.makeProject(lastModifiedAt: modifiedAt);

      await repo.restoreProject(project);

      final saved = repo.getById(project.id)!;
      expect(saved.lastModifiedAt, modifiedAt);
    });

    test('preserves updatedAt exactly (does not bump)', () async {
      final repo = await HiveTestHelper.createRepository();
      final updatedAt = DateTime(2019, 3, 22, 16, 0, 0);
      final project = TestFactories.makeProject(updatedAt: updatedAt);

      await repo.restoreProject(project);

      final saved = repo.getById(project.id)!;
      expect(saved.updatedAt, updatedAt);
    });

    test('preserves fileCreatedAt', () async {
      final repo = await HiveTestHelper.createRepository();
      final fileCreatedAt = DateTime(2018, 1, 1);
      final project = TestFactories.makeProject(fileCreatedAt: fileCreatedAt);

      await repo.restoreProject(project);

      final saved = repo.getById(project.id)!;
      expect(saved.fileCreatedAt, fileCreatedAt);
    });

    test('overwrites existing project completely', () async {
      final repo = await HiveTestHelper.createRepository();
      final original = TestFactories.makeProject(status: 'Idea');
      await repo.updateProject(original);

      final fromBackup = TestFactories.makeProject(
        id: original.id,
        status: 'Finished',
        lastModifiedAt: DateTime(2021, 5, 5),
        updatedAt: DateTime(2021, 5, 5),
      );
      await repo.restoreProject(fromBackup);

      final saved = repo.getById(original.id)!;
      expect(saved.status, 'Finished');
      expect(saved.lastModifiedAt, DateTime(2021, 5, 5));
    });
  });

  group('ProjectRepository.getById', () {
    test('returns project for matching id', () async {
      final repo = await HiveTestHelper.createRepository();
      final project = TestFactories.makeProject(id: 'find-me');
      await repo.restoreProject(project);

      expect(repo.getById('find-me'), isNotNull);
      expect(repo.getById('find-me')!.id, 'find-me');
    });

    test('returns null for unknown id', () async {
      final repo = await HiveTestHelper.createRepository();
      expect(repo.getById('does-not-exist'), isNull);
    });
  });

  group('ProjectRepository.getByPath', () {
    test('returns project for matching path', () async {
      final repo = await HiveTestHelper.createRepository();
      final project = TestFactories.makeProject(
        filePath: '/music/project.als',
      );
      await repo.restoreProject(project);

      expect(repo.getByPath('/music/project.als'), isNotNull);
    });

    test('returns null for non-matching path', () async {
      final repo = await HiveTestHelper.createRepository();
      expect(repo.getByPath('/does/not/exist.als'), isNull);
    });
  });

  group('ProjectRepository.getAllProjects', () {
    test('returns empty list when no projects stored', () async {
      final repo = await HiveTestHelper.createRepository();
      expect(repo.getAllProjects(), isEmpty);
    });

    test('returns all stored projects', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.restoreProject(TestFactories.makeProject(id: 'p1'));
      await repo.restoreProject(TestFactories.makeProject(id: 'p2'));
      await repo.restoreProject(TestFactories.makeProject(id: 'p3'));

      expect(repo.getAllProjects().length, 3);
    });
  });

  group('ProjectRepository.custom phases', () {
    test('getCustomPhases returns the 5 default phases when not configured', () async {
      final repo = await HiveTestHelper.createRepository();
      expect(repo.getCustomPhases(),
          ['Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished']);
    });

    test('setCustomPhases / getCustomPhases round-trip', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.setCustomPhases(['Draft', 'WIP', 'Done']);
      expect(repo.getCustomPhases(), ['Draft', 'WIP', 'Done']);
    });

    test('getCustomPhases falls back to defaults on malformed JSON', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.appSettingsBox.put('test-profile_phases', 'not valid json{{');
      expect(repo.getCustomPhases(),
          ['Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished']);
    });

    test('getCustomPhases returns an unmodifiable list', () async {
      final repo = await HiveTestHelper.createRepository();
      final phases = repo.getCustomPhases();
      expect(() => (phases as dynamic).add('Extra'), throwsUnsupportedError);
    });
  });

  group('ProjectRepository.phase colors', () {
    test('getPhaseColors returns empty map when not configured', () async {
      final repo = await HiveTestHelper.createRepository();
      expect(repo.getPhaseColors(), isEmpty);
    });

    test('setPhaseColors / getPhaseColors round-trip', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.setPhaseColors({'Mixing': '#FF5733', 'Finished': '#2ECC71'});
      final colors = repo.getPhaseColors();
      expect(colors['Mixing'], '#FF5733');
      expect(colors['Finished'], '#2ECC71');
    });

    test('getPhaseColors returns empty map on malformed JSON', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.appSettingsBox.put('test-profile_phase_colors', '{bad}');
      expect(repo.getPhaseColors(), isEmpty);
    });
  });

  group('ProjectRepository.finished phases', () {
    test('getFinishedPhases defaults to {"Finished"} when not configured', () async {
      final repo = await HiveTestHelper.createRepository();
      expect(repo.getFinishedPhases(), {'Finished'});
    });

    test('setFinishedPhases / getFinishedPhases round-trip', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.setFinishedPhases({'Released', 'Archived'});
      expect(repo.getFinishedPhases(), {'Released', 'Archived'});
    });

    test('setFinishedPhase wraps a single phase into a set', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.setFinishedPhase('Mastering');
      expect(repo.getFinishedPhases(), {'Mastering'});
    });

    test('migrates legacy single-phase key when new key is absent', () async {
      final repo = await HiveTestHelper.createRepository();
      // Simulate a DB written before the multi-phase feature was added
      await repo.appSettingsBox.put('test-profile_finished_phase', 'Released');
      expect(repo.getFinishedPhases(), {'Released'});
    });
  });

  group('ProjectRepository.custom mixdown folder', () {
    test('getCustomMixdownFolder returns null when not configured', () async {
      final repo = await HiveTestHelper.createRepository();
      expect(repo.getCustomMixdownFolder(), isNull);
    });

    test('setCustomMixdownFolder saves the trimmed value', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.setCustomMixdownFolder('  Exports  ');
      expect(repo.getCustomMixdownFolder(), 'Exports');
    });

    test('setCustomMixdownFolder with null deletes the setting', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.setCustomMixdownFolder('/something');
      await repo.setCustomMixdownFolder(null);
      expect(repo.getCustomMixdownFolder(), isNull);
    });

    test('setCustomMixdownFolder with empty string deletes the setting', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.setCustomMixdownFolder('/something');
      await repo.setCustomMixdownFolder('');
      expect(repo.getCustomMixdownFolder(), isNull);
    });
  });

  group('ProjectRepository.pending folders', () {
    test('getPendingFolders returns empty list when not configured', () async {
      final repo = await HiveTestHelper.createRepository();
      expect(repo.getPendingFolders(), isEmpty);
    });

    test('addPendingFolder / getPendingFolders round-trip', () async {
      final repo = await HiveTestHelper.createRepository();
      final folder = PendingFolder(
        id: 'pf-1',
        path: '/music/project',
        createdAt: DateTime(2025, 1, 1),
      );
      await repo.addPendingFolder(folder);
      final saved = repo.getPendingFolders();
      expect(saved.length, 1);
      expect(saved.first.id, 'pf-1');
      expect(saved.first.path, '/music/project');
    });

    test('addPendingFolder deduplicates by path — new entry replaces old', () async {
      final repo = await HiveTestHelper.createRepository();
      final old = PendingFolder(id: 'pf-old', path: '/same', createdAt: DateTime(2025, 1, 1));
      final newer = PendingFolder(id: 'pf-new', path: '/same', createdAt: DateTime(2025, 6, 1));
      await repo.addPendingFolder(old);
      await repo.addPendingFolder(newer);
      final folders = repo.getPendingFolders();
      expect(folders.length, 1);
      expect(folders.first.id, 'pf-new');
    });

    test('removePendingFolder removes by id, keeps others', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addPendingFolder(PendingFolder(id: 'pf-1', path: '/a', createdAt: DateTime(2025, 1, 1)));
      await repo.addPendingFolder(PendingFolder(id: 'pf-2', path: '/b', createdAt: DateTime(2025, 1, 1)));
      await repo.removePendingFolder('pf-1');
      final folders = repo.getPendingFolders();
      expect(folders.length, 1);
      expect(folders.first.id, 'pf-2');
    });

    test('updatePendingFolder replaces the existing entry', () async {
      final repo = await HiveTestHelper.createRepository();
      final original = PendingFolder(id: 'pf-1', path: '/a', createdAt: DateTime(2025, 1, 1));
      await repo.addPendingFolder(original);
      final updated = original.copyWith(sessionStartedAt: DateTime(2025, 3, 1));
      await repo.updatePendingFolder(updated);
      final folders = repo.getPendingFolders();
      expect(folders.length, 1);
      expect(folders.first.sessionStartedAt, DateTime(2025, 3, 1));
    });

    test('resolveCompletedPendingFolders removes non-existent folders', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addPendingFolder(PendingFolder(
        id: 'pf-gone',
        path: '/definitely/does/not/exist/on/disk',
        createdAt: DateTime(2025, 1, 1),
      ));
      final removed = await repo.resolveCompletedPendingFolders();
      expect(removed, contains('pf-gone'));
      expect(repo.getPendingFolders(), isEmpty);
    });

    test('resolveCompletedPendingFolders removes folders that contain a DAW project file', () async {
      final dir = await Directory.systemTemp.createTemp('resolve_done_');
      try {
        await File('${dir.path}/project.als').create();
        final repo = await HiveTestHelper.createRepository();
        await repo.addPendingFolder(PendingFolder(
          id: 'pf-done',
          path: dir.path,
          createdAt: DateTime(2025, 1, 1),
        ));
        final removed = await repo.resolveCompletedPendingFolders();
        expect(removed, contains('pf-done'));
        expect(repo.getPendingFolders(), isEmpty);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('resolveCompletedPendingFolders keeps folders that exist and have no project file', () async {
      final dir = await Directory.systemTemp.createTemp('resolve_keep_');
      try {
        final repo = await HiveTestHelper.createRepository();
        await repo.addPendingFolder(PendingFolder(
          id: 'pf-empty',
          path: dir.path,
          createdAt: DateTime(2025, 1, 1),
        ));
        final removed = await repo.resolveCompletedPendingFolders();
        expect(removed, isEmpty);
        expect(repo.getPendingFolders().length, 1);
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });

  group('ProjectRepository.watchAllProjects', () {
    // Regression: _scanAll in dashboard_page.dart was missing
    // ref.invalidate(allProjectsStreamProvider) after completing a scan,
    // so the table would not refresh until the user navigated away and back.
    // The fix relies on watchAllProjects() emitting after every Box.put(),
    // which these tests verify at the repository level.

    test('emits initial snapshot immediately on subscribe', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.updateProject(TestFactories.makeProject(id: 'p1'));
      await repo.updateProject(TestFactories.makeProject(id: 'p2'));

      final first = await repo.watchAllProjects().first;
      expect(first.map((p) => p.id), containsAll(['p1', 'p2']));
    });

    test('emits updated list after a project is saved', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.updateProject(TestFactories.makeProject(id: 'existing'));

      // Collect all emissions via listen so no events are missed. The
      // Future.delayed(Duration.zero) drains the microtask queue after
      // each step, ensuring the async* generator has subscribed to
      // box.watch() before we write.
      final emissions = <List<MusicProject>>[];
      final sub = repo.watchAllProjects().listen(emissions.add);
      await Future.delayed(Duration.zero);

      await repo.updateProject(TestFactories.makeProject(id: 'newly-added'));
      await Future.delayed(Duration.zero);
      await sub.cancel();

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last.any((p) => p.id == 'newly-added'), isTrue);
    });

    test('emits updated lastModifiedAt after rescan upsert', () async {
      // Simulates the rescan path: upsertFromFileSystemEntity calls
      // projectsBox.put() unconditionally, which must trigger a Box.watch()
      // event so the dashboard table reflects the new date.
      final repo = await HiveTestHelper.createRepository();
      final original = TestFactories.makeProject(
        id: 'scanned',
        lastModifiedAt: DateTime(2024, 1, 1),
      );
      await repo.updateProject(original);

      final emissions = <List<MusicProject>>[];
      final sub = repo.watchAllProjects().listen(emissions.add);
      await Future.delayed(Duration.zero);

      final rescanned = original.copyWith(
        lastModifiedAt: DateTime(2025, 6, 10),
      );
      await repo.restoreProject(rescanned);
      await Future.delayed(Duration.zero);
      await sub.cancel();

      expect(emissions.length, greaterThanOrEqualTo(2));
      final saved = emissions.last.firstWhere((p) => p.id == 'scanned');
      expect(saved.lastModifiedAt, DateTime(2025, 6, 10));
    });
  });

  group('ProjectRepository.removeRoot', () {
    test('removes projects whose filePath is under the root', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.updateProject(
          TestFactories.makeProject(id: 'p1', filePath: '/rootA/track1.als'));
      await repo.updateProject(
          TestFactories.makeProject(id: 'p2', filePath: '/rootA/sub/track2.als'));

      await repo.removeRoot(rootId);

      expect(repo.getById('p1'), isNull);
      expect(repo.getById('p2'), isNull);
    });

    test('preserves projects under a different root', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.updateProject(
          TestFactories.makeProject(id: 'inA', filePath: '/rootA/track.als'));
      await repo.updateProject(
          TestFactories.makeProject(id: 'inB', filePath: '/rootB/other.als'));

      await repo.removeRoot(rootId);

      expect(repo.getById('inA'), isNull);
      expect(repo.getById('inB'), isNotNull);
    });

    test('preserves projects referenced in a release', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.updateProject(
          TestFactories.makeProject(id: 'normal', filePath: '/rootA/normal.als'));
      await repo.updateProject(
          TestFactories.makeProject(id: 'protected', filePath: '/rootA/protected.als'));
      await repo.addRelease(
          Release(id: 'r1', title: 'EP', trackIds: ['protected']));

      await repo.removeRoot(rootId);

      expect(repo.getById('normal'), isNull);
      expect(repo.getById('protected'), isNotNull);
    });

    test('removes the root entry from the roots box', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.removeRoot(rootId);

      expect(repo.getRoots(), isEmpty);
    });

    test('does nothing when root id is not found', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.updateProject(
          TestFactories.makeProject(id: 'p1', filePath: '/rootA/track.als'));

      await repo.removeRoot('no-such-root-id');

      expect(repo.getById('p1'), isNotNull);
    });
  });

  group('ProjectRepository.relocateRoot', () {
    test('updates the root path', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.relocateRoot(rootId, '/rootB');

      expect(p.normalize(repo.getRoots().first.path), p.normalize('/rootB'));
    });

    test('rewrites filePath for every project under the old root', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.updateProject(
          TestFactories.makeProject(id: 'p1', filePath: '/rootA/track1.als'));
      await repo.updateProject(
          TestFactories.makeProject(id: 'p2', filePath: '/rootA/sub/track2.als'));

      await repo.relocateRoot(rootId, '/rootB');

      expect(
        p.normalize(repo.getById('p1')!.filePath),
        p.normalize('/rootB/track1.als'),
      );
      expect(
        p.normalize(repo.getById('p2')!.filePath),
        p.normalize('/rootB/sub/track2.als'),
      );
    });

    test('returns the count of rewritten projects', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.updateProject(
          TestFactories.makeProject(id: 'p1', filePath: '/rootA/a.als'));
      await repo.updateProject(
          TestFactories.makeProject(id: 'p2', filePath: '/rootA/b.als'));

      final count = await repo.relocateRoot(rootId, '/rootB');

      expect(count, 2);
    });

    test('does not touch projects under a different root', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.updateProject(
          TestFactories.makeProject(id: 'inA', filePath: '/rootA/track.als'));
      await repo.updateProject(
          TestFactories.makeProject(id: 'inB', filePath: '/rootB/other.als'));

      await repo.relocateRoot(rootId, '/rootC');

      expect(
        p.normalize(repo.getById('inB')!.filePath),
        p.normalize('/rootB/other.als'),
        reason: 'Project outside the relocated root must be unchanged',
      );
    });

    test('also rewrites previewSongPath when it starts with the old root', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.addRoot('/rootA');
      final rootId = repo.getRoots().first.id;

      await repo.updateProject(TestFactories.makeProject(
        id: 'p1',
        filePath: '/rootA/track.als',
        previewSongPath: '/rootA/Exports/mix.mp3',
      ));

      await repo.relocateRoot(rootId, '/rootB');

      expect(
        p.normalize(repo.getById('p1')!.previewSongPath!),
        p.normalize('/rootB/Exports/mix.mp3'),
      );
    });

    test('returns 0 when root id is not found', () async {
      final repo = await HiveTestHelper.createRepository();
      final count = await repo.relocateRoot('no-such-id', '/rootB');
      expect(count, 0);
    });
  });

  group('ProjectRepository.removeOrphanedProjectsFromRoot', () {
    test('removes projects not in foundPaths', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.updateProject(
          TestFactories.makeProject(id: 'kept', filePath: '/root/kept.als'));
      await repo.updateProject(
          TestFactories.makeProject(id: 'orphan', filePath: '/root/orphan.als'));

      await repo.removeOrphanedProjectsFromRoot('/root', {'/root/kept.als'});

      expect(repo.getById('kept'), isNotNull);
      expect(repo.getById('orphan'), isNull);
    });

    test('preserves all projects when every path is in foundPaths', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.updateProject(
          TestFactories.makeProject(id: 'p1', filePath: '/root/a.als'));
      await repo.updateProject(
          TestFactories.makeProject(id: 'p2', filePath: '/root/b.als'));

      await repo.removeOrphanedProjectsFromRoot(
          '/root', {'/root/a.als', '/root/b.als'});

      expect(repo.getById('p1'), isNotNull);
      expect(repo.getById('p2'), isNotNull);
    });

    test('does not touch projects under a different root', () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.updateProject(
          TestFactories.makeProject(id: 'inRoot', filePath: '/root/track.als'));
      await repo.updateProject(
          TestFactories.makeProject(id: 'other', filePath: '/otherRoot/track.als'));

      // foundPaths is empty — every project under /root is "orphaned"
      await repo.removeOrphanedProjectsFromRoot('/root', {});

      expect(repo.getById('inRoot'), isNull);
      expect(repo.getById('other'), isNotNull);
    });

    test('preserves release-protected projects even when absent from foundPaths',
        () async {
      final repo = await HiveTestHelper.createRepository();
      await repo.updateProject(
          TestFactories.makeProject(id: 'normal', filePath: '/root/normal.als'));
      await repo.updateProject(
          TestFactories.makeProject(id: 'protected', filePath: '/root/protected.als'));
      await repo.addRelease(
          Release(id: 'r1', title: 'EP', trackIds: ['protected']));

      // Neither path is in foundPaths — normal should be deleted, protected should survive
      await repo.removeOrphanedProjectsFromRoot('/root', {});

      expect(repo.getById('normal'), isNull);
      expect(repo.getById('protected'), isNotNull);
    });
  });

  group('Backup restore contract', () {
    test('restoreProject after updateProject keeps backup dates', () async {
      // Simulates: user changes status on mobile (updateProject),
      // then re-imports backup (restoreProject). Backup dates must win.
      final repo = await HiveTestHelper.createRepository();
      final desktopDate = DateTime(2023, 8, 10, 12, 0, 0);

      // First: project exists on device with a recent updatedAt
      final onDevice = TestFactories.makeProject(
        id: 'sync-test',
        lastModifiedAt: DateTime.now(),
      );
      await repo.updateProject(onDevice);

      // Then: backup import restores the correct desktop date
      final fromBackup = TestFactories.makeProject(
        id: 'sync-test',
        lastModifiedAt: desktopDate,
        updatedAt: desktopDate,
      );
      await repo.restoreProject(fromBackup);

      final saved = repo.getById('sync-test')!;
      expect(saved.lastModifiedAt, desktopDate);
    });

    // -----------------------------------------------------------------------
    // Full end-to-end scenario
    // -----------------------------------------------------------------------
    // Scenario:
    //   1. Android already has the project but with an OLD lastModifiedAt
    //      (e.g. from when the file was first synced to the device months ago).
    //   2. On desktop the user has been working on the project — lastModifiedAt
    //      is now a NEWER date reflecting the latest DAW save.
    //   3. User generates a backup on desktop and imports it on Android.
    //   4. After the import, Android must show the NEW desktop date.
    test('desktop backup with newer date overwrites old Android date', () async {
      final repo = await HiveTestHelper.createRepository();

      // --- Step 1: Android already has the project with an OLD date ---
      // The file was first synced to Android back in January; that is what
      // stat.modified returned when the app scanned it.
      final androidOldDate = DateTime(2024, 1, 10, 8, 0, 0);

      final androidExistingProject = TestFactories.makeProject(
        id: 'daw-project-001',
        filePath: '/storage/emulated/0/Drive/MyBanger.als',
        fileName: 'MyBanger.als',
        lastModifiedAt: androidOldDate,
        fileCreatedAt: androidOldDate,
        status: 'Idea',
        bpm: 120.0,
      );
      await repo.restoreProject(androidExistingProject);

      // Confirm the old date is in the DB before the import.
      expect(repo.getById('daw-project-001')!.lastModifiedAt, androidOldDate);

      // --- Step 2: desktop has a newer backup ---
      // The project was worked on heavily; last DAW save was Nov 12 2024.
      final desktopNewDate = DateTime(2024, 11, 12, 9, 45, 0);

      final desktopBackupProject = TestFactories.makeProject(
        id: 'daw-project-001',
        filePath: '/Users/artist/Live/MyBanger.als',
        fileName: 'MyBanger.als',
        lastModifiedAt: desktopNewDate,
        fileCreatedAt: DateTime(2023, 3, 1),
        status: 'Mixing',
        bpm: 128.0,
        musicalKey: 'C minor',
        notes: 'Needs vocal chop on drop',
      );

      final backupJson = BackupService.projectToJson(desktopBackupProject);

      // --- Step 3: user imports the desktop backup on Android ---
      final projectFromBackup = BackupService.projectFromJson(backupJson);
      await repo.restoreProject(projectFromBackup);

      // --- Step 4: verify the NEW desktop date is now stored ---
      final saved = repo.getById('daw-project-001')!;

      expect(
        saved.lastModifiedAt,
        desktopNewDate,
        reason: 'lastModifiedAt must be updated to the newer desktop DAW date.',
      );
      expect(
        saved.lastModifiedAt,
        isNot(androidOldDate),
        reason: 'The old Android date must have been replaced by the backup.',
      );
      expect(
        saved.lastModifiedAt.isAfter(androidOldDate),
        isTrue,
        reason: 'Stored date must be newer than the previous Android date.',
      );

      // Other metadata from the backup must also be intact.
      expect(saved.bpm, 128.0);
      expect(saved.musicalKey, 'C minor');
      expect(saved.notes, 'Needs vocal chop on drop');
      expect(saved.status, 'Mixing');
    });
  });
}
