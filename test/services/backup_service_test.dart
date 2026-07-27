import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/services/backup_service.dart';
import '../helpers/test_factories.dart';

void main() {
  group('BackupService JSON round-trip', () {
    test('preserves all basic fields', () {
      final original = TestFactories.makeProject(
        id: 'rt-1',
        filePath: '/Users/artist/Live Sets/Banger.als',
        fileName: 'Banger.als',
        fileSizeBytes: 2048000,
        status: 'Mixing',
        dawType: 'Ableton Live',
        dawVersion: '11',
      );

      final json = BackupService.projectToJson(original);
      final restored = BackupService.projectFromJson(json);

      expect(restored.id, original.id);
      expect(restored.filePath, original.filePath);
      expect(restored.fileName, original.fileName);
      expect(restored.fileSizeBytes, original.fileSizeBytes);
      expect(restored.status, original.status);
      expect(restored.dawType, original.dawType);
      expect(restored.dawVersion, original.dawVersion);
      expect(restored.fileExtension, original.fileExtension);
    });

    test('preserves lastModifiedAt exactly', () {
      final modifiedAt = DateTime(2024, 11, 5, 14, 23, 45);
      final original = TestFactories.makeProject(lastModifiedAt: modifiedAt);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.lastModifiedAt, modifiedAt);
    });

    test('preserves fileCreatedAt when set', () {
      final createdAt = DateTime(2023, 3, 10, 9, 0, 0);
      final original =
          TestFactories.makeProject(fileCreatedAt: createdAt);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.fileCreatedAt, createdAt);
    });

    test('preserves null fileCreatedAt', () {
      final original = TestFactories.makeProject(fileCreatedAt: null);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.fileCreatedAt, isNull);
    });

    test('preserves createdAt and updatedAt', () {
      final createdAt = DateTime(2022, 1, 1);
      final updatedAt = DateTime(2025, 6, 15);
      final original = TestFactories.makeProject(
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.createdAt, createdAt);
      expect(restored.updatedAt, updatedAt);
    });

    test('preserves optional metadata (bpm, key, notes)', () {
      final original = TestFactories.makeProject(
        bpm: 128.5,
        musicalKey: 'F# minor',
        notes: 'Needs more reverb on the snare',
      );

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.bpm, 128.5);
      expect(restored.musicalKey, 'F# minor');
      expect(restored.notes, 'Needs more reverb on the snare');
    });

    test('preserves null optional metadata', () {
      final original =
          TestFactories.makeProject(bpm: null, musicalKey: null, notes: null);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.bpm, isNull);
      expect(restored.musicalKey, isNull);
      expect(restored.notes, isNull);
    });

    test('preserves deadline', () {
      final deadline = DateTime(2026, 9, 1);
      final original = TestFactories.makeProject(deadline: deadline);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.deadline, deadline);
    });

    test('preserves null deadline', () {
      final original = TestFactories.makeProject(deadline: null);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.deadline, isNull);
    });

    test('preserves todos list', () {
      final todos = [
        TestFactories.makeTodo(id: 't1', text: 'EQ the bass'),
        TestFactories.makeTodo(id: 't2', text: 'Add reverb', completed: true),
      ];
      final original = TestFactories.makeProject(todos: todos);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.todos.length, 2);
      expect(restored.todos[0].text, 'EQ the bass');
      expect(restored.todos[0].completed, false);
      expect(restored.todos[1].text, 'Add reverb');
      expect(restored.todos[1].completed, true);
    });

    test('preserves empty todos list', () {
      final original = TestFactories.makeProject(todos: []);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.todos, isEmpty);
    });

    test('preserves hidden flag', () {
      final original = TestFactories.makeProject(hidden: true);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.hidden, true);
    });

    test('preserves customDisplayName', () {
      final original =
          TestFactories.makeProject(customDisplayName: 'My Banger');

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.customDisplayName, 'My Banger');
    });

    test('backward compat: missing optional fields default to null/false', () {
      // Simulate an old backup that lacks newer fields
      final minimalJson = {
        'id': 'old-id',
        'filePath': '/old/project.als',
        'fileName': 'project.als',
        'fileSizeBytes': 512,
        'lastModifiedAt': DateTime(2022, 1, 1).toIso8601String(),
        'fileExtension': '.als',
        'status': 'Idea',
        'createdAt': DateTime(2021, 6, 1).toIso8601String(),
        'updatedAt': DateTime(2022, 1, 1).toIso8601String(),
      };

      final restored = BackupService.projectFromJson(minimalJson);

      expect(restored.id, 'old-id');
      expect(restored.fileCreatedAt, isNull);
      expect(restored.deadline, isNull);
      expect(restored.bpm, isNull);
      expect(restored.notes, isNull);
      expect(restored.hidden, false);
      expect(restored.todos, isEmpty);
    });

    test('preserves previewSongAutoPath, parentProjectId, and ignoredNewerSongPath', () {
      final original = TestFactories.makeProject(
        previewSongAutoPath: '/Users/artist/Live Sets/Bounces/mixdown.wav',
        parentProjectId: 'parent-project-id',
        ignoredNewerSongPath: '/Users/artist/Live Sets/Bounces/rejected.wav',
      );

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.previewSongAutoPath, '/Users/artist/Live Sets/Bounces/mixdown.wav');
      expect(restored.parentProjectId, 'parent-project-id');
      expect(restored.ignoredNewerSongPath, '/Users/artist/Live Sets/Bounces/rejected.wav');
    });

    test('preserves null previewSongAutoPath, parentProjectId, and ignoredNewerSongPath', () {
      final original = TestFactories.makeProject(
        previewSongAutoPath: null,
        parentProjectId: null,
        ignoredNewerSongPath: null,
      );

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.previewSongAutoPath, isNull);
      expect(restored.parentProjectId, isNull);
      expect(restored.ignoredNewerSongPath, isNull);
    });

    test('preserves projectNotes', () {
      final original = TestFactories.makeProject(
        projectNotes: 'Notes 1\nby Audio Crawler\n\nSome project notes',
      );

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.projectNotes, 'Notes 1\nby Audio Crawler\n\nSome project notes');
    });

    test('preserves null projectNotes', () {
      final original = TestFactories.makeProject(projectNotes: null);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.projectNotes, isNull);
    });

    test('lastModifiedAt is unchanged after round-trip (not bumped to now)',
        () {
      final past = DateTime(2020, 6, 15, 8, 0, 0);
      final original = TestFactories.makeProject(lastModifiedAt: past);

      final restored =
          BackupService.projectFromJson(BackupService.projectToJson(original));

      expect(restored.lastModifiedAt, past);
      expect(
        restored.lastModifiedAt.isAfter(DateTime.now()),
        isFalse,
        reason: 'lastModifiedAt must not be bumped to now during round-trip',
      );
    });
  });
}
