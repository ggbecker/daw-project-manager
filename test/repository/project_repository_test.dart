import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
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
