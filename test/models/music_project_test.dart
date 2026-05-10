import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:daw_project_manager/models/music_project.dart';
import '../helpers/test_factories.dart';
import '../helpers/hive_test_helper.dart';
import 'dart:io';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await HiveTestHelper.setUp();
  });

  tearDownAll(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  group('MusicProject.displayName', () {
    test('returns customDisplayName when set', () {
      final p = TestFactories.makeProject(customDisplayName: 'My Custom Name');
      expect(p.displayName, 'My Custom Name');
    });

    test('returns fileName without extension when customDisplayName is null', () {
      final p = TestFactories.makeProject(customDisplayName: null);
      expect(p.displayName, 'MyProject');
    });

    test('returns fileName without extension when customDisplayName is whitespace only', () {
      final p = TestFactories.makeProject(customDisplayName: '   ');
      expect(p.displayName, 'MyProject');
    });
  });

  group('MusicProject.projectAge', () {
    test('uses fileCreatedAt when set', () {
      final created = DateTime.now().subtract(const Duration(days: 30));
      final modified = DateTime.now().subtract(const Duration(days: 5));
      final p = TestFactories.makeProject(
        fileCreatedAt: created,
        lastModifiedAt: modified,
      );
      expect(p.projectAge.inDays, closeTo(30, 1));
    });

    test('falls back to lastModifiedAt when fileCreatedAt is null', () {
      final modified = DateTime.now().subtract(const Duration(days: 10));
      final p = TestFactories.makeProject(
        fileCreatedAt: null,
        lastModifiedAt: modified,
      );
      expect(p.projectAge.inDays, closeTo(10, 1));
    });
  });

  group('MusicProject.daysUntilDeadline', () {
    test('returns null when no deadline set', () {
      final p = TestFactories.makeProject(deadline: null);
      expect(p.daysUntilDeadline, isNull);
    });

    test('returns positive value for future deadline', () {
      final now = DateTime.now();
      final p = TestFactories.makeProject(
        deadline: DateTime(now.year, now.month, now.day + 7),
      );
      // Allow ±1 day for DST boundary crossings.
      expect(p.daysUntilDeadline, inInclusiveRange(6, 7));
    });

    test('returns negative value for past deadline', () {
      final now = DateTime.now();
      final p = TestFactories.makeProject(
        deadline: DateTime(now.year, now.month, now.day - 3),
      );
      expect(p.daysUntilDeadline, inInclusiveRange(-3, -2));
    });

    test('returns 0 for deadline today', () {
      final now = DateTime.now();
      final p = TestFactories.makeProject(
        deadline: DateTime(now.year, now.month, now.day),
      );
      expect(p.daysUntilDeadline, 0);
    });
  });

  group('MusicProject.deadlineStatus', () {
    test('returns null when no deadline', () {
      expect(TestFactories.makeProject().deadlineStatus, isNull);
    });

    test('returns "Due today" for today', () {
      final now = DateTime.now();
      final p = TestFactories.makeProject(
        deadline: DateTime(now.year, now.month, now.day),
        status: 'Mixing',
      );
      expect(p.deadlineStatus, 'Due today');
    });

    test('returns "X days left" format for near-future deadline', () {
      final now = DateTime.now();
      final p = TestFactories.makeProject(
        deadline: DateTime(now.year, now.month, now.day + 5),
        status: 'Mixing',
      );
      // Exact count may vary by ±1 around DST boundaries; verify the format.
      expect(p.deadlineStatus, matches(RegExp(r'^\d+ days? left$')));
    });

    test('returns "X weeks left" format for multi-week deadline', () {
      final now = DateTime.now();
      final p = TestFactories.makeProject(
        deadline: DateTime(now.year, now.month, now.day + 21),
        status: 'Mixing',
      );
      expect(p.deadlineStatus, matches(RegExp(r'^\d+ weeks? left$')));
    });

    test('returns overdue format for past deadline', () {
      final now = DateTime.now();
      final p = TestFactories.makeProject(
        deadline: DateTime(now.year, now.month, now.day - 2),
        status: 'Mixing',
      );
      expect(p.deadlineStatus, matches(RegExp(r'^\d+ days? overdue$')));
    });
  });

  group('MusicProject.camelotCode', () {
    test('returns correct code for C minor', () {
      final p = TestFactories.makeProject(musicalKey: 'c minor');
      expect(p.camelotCode, '5A');
    });

    test('returns correct code for A major', () {
      final p = TestFactories.makeProject(musicalKey: 'a major');
      expect(p.camelotCode, '11B');
    });

    test('returns correct code for G# minor (enharmonic)', () {
      final p = TestFactories.makeProject(musicalKey: 'g# minor');
      expect(p.camelotCode, '1A');
    });

    test('returns null for unrecognised key', () {
      final p = TestFactories.makeProject(musicalKey: 'X# ultra');
      expect(p.camelotCode, isNull);
    });

    test('returns null when musicalKey is null', () {
      final p = TestFactories.makeProject(musicalKey: null);
      expect(p.camelotCode, isNull);
    });
  });

  group('MusicProject.copyWith', () {
    test('preserves unchanged fields', () {
      final original = TestFactories.makeProject(bpm: 128.0, notes: 'cool track');
      final copy = original.copyWith(status: 'Finished');
      expect(copy.bpm, 128.0);
      expect(copy.notes, 'cool track');
      expect(copy.status, 'Finished');
    });

    test('clearNotes sets notes to null', () {
      final p = TestFactories.makeProject(notes: 'some notes');
      expect(p.copyWith(clearNotes: true).notes, isNull);
    });

    test('clearDeadline sets deadline to null', () {
      final p = TestFactories.makeProject(
        deadline: DateTime(2026, 6, 1),
      );
      expect(p.copyWith(clearDeadline: true).deadline, isNull);
    });

    test('does not change lastModifiedAt unless explicitly provided', () {
      final original = TestFactories.makeProject();
      final copy = original.copyWith(status: 'Finished');
      expect(copy.lastModifiedAt, original.lastModifiedAt);
    });
  });

  group('MusicProjectAdapter (Hive round-trip)', () {
    test('preserves all fields after write and read', () async {
      final todo = TestFactories.makeTodo();
      final original = TestFactories.makeProject(
        id: 'hive-round-trip',
        bpm: 140.0,
        musicalKey: 'F# minor',
        notes: 'test notes',
        fileCreatedAt: DateTime(2023, 5, 20),
        deadline: DateTime(2026, 12, 31),
        todos: [todo],
        dawType: 'FL Studio',
        dawVersion: '21',
      );

      final box = await Hive.openBox<MusicProject>('round_trip_test');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;

      expect(restored.id, original.id);
      expect(restored.filePath, original.filePath);
      expect(restored.lastModifiedAt, original.lastModifiedAt);
      expect(restored.fileCreatedAt, original.fileCreatedAt);
      expect(restored.createdAt, original.createdAt);
      expect(restored.bpm, original.bpm);
      expect(restored.musicalKey, original.musicalKey);
      expect(restored.notes, original.notes);
      expect(restored.deadline, original.deadline);
      expect(restored.dawType, original.dawType);
      expect(restored.todos.length, 1);
      expect(restored.todos.first.text, todo.text);
    });

    test('reads back null optional fields correctly', () async {
      final original = TestFactories.makeMinimalProject(id: 'minimal-hive');
      final box = await Hive.openBox<MusicProject>('minimal_round_trip_test');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;

      expect(restored.fileCreatedAt, isNull);
      expect(restored.deadline, isNull);
      expect(restored.bpm, isNull);
      expect(restored.notes, isNull);
      expect(restored.todos, isEmpty);
    });
  });
}
