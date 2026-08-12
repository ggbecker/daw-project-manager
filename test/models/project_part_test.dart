import 'dart:io';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

void main() {
  group('PartTakeStatus', () {
    test('every status has a stable, unique key', () {
      final keys = PartTakeStatus.values.map((s) => s.key).toList();
      expect(keys, ['needed', 'recording', 'earlyTake', 'finalTake']);
      expect(keys.toSet().length, keys.length);
    });

    test('fromKey round-trips every status', () {
      for (final status in PartTakeStatus.values) {
        expect(PartTakeStatus.fromKey(status.key), status);
      }
    });

    test('fromKey falls back to needed for unknown or missing keys', () {
      // A part written by a future version that added a status must still
      // load rather than throwing and taking the whole project down with it.
      expect(PartTakeStatus.fromKey('overdubbing'), PartTakeStatus.needed);
      expect(PartTakeStatus.fromKey(null), PartTakeStatus.needed);
      expect(PartTakeStatus.fromKey(''), PartTakeStatus.needed);
    });

    test('only finalTake counts as done', () {
      expect(PartTakeStatus.finalTake.isDone, isTrue);
      expect(PartTakeStatus.needed.isDone, isFalse);
      expect(PartTakeStatus.recording.isDone, isFalse);
      expect(PartTakeStatus.earlyTake.isDone, isFalse);
    });
  });

  group('ProjectPart.copyWith', () {
    test('replaces only the named fields', () {
      final part = TestFactories.makePart(
        name: 'Bass',
        performer: 'Sam',
        notes: 'DI only',
      );
      final updated = part.copyWith(status: PartTakeStatus.finalTake);

      expect(updated.name, 'Bass');
      expect(updated.performer, 'Sam');
      expect(updated.notes, 'DI only');
      expect(updated.status, PartTakeStatus.finalTake);
    });

    test('clearPerformer and clearNotes null the fields out', () {
      final part = TestFactories.makePart(performer: 'Sam', notes: 'DI only');
      final cleared = part.copyWith(clearPerformer: true, clearNotes: true);

      expect(cleared.performer, isNull);
      expect(cleared.notes, isNull);
    });
  });

  group('ProjectPart aggregate helpers', () {
    final parts = [
      TestFactories.makePart(id: 'a', name: 'Drums', performer: 'Alex',
          status: PartTakeStatus.finalTake),
      TestFactories.makePart(id: 'b', name: 'Bass', performer: 'sam',
          status: PartTakeStatus.earlyTake),
      TestFactories.makePart(id: 'c', name: 'Vocals', performer: 'Sam',
          status: PartTakeStatus.finalTake),
      TestFactories.makePart(id: 'd', name: 'Synth', performer: null,
          status: PartTakeStatus.needed),
    ];

    test('doneCount counts only final takes', () {
      expect(ProjectPart.doneCount(parts), 2);
      expect(ProjectPart.doneCount(const []), 0);
    });

    test('allDone is true only when every part is a final take', () {
      expect(ProjectPart.allDone(parts), isFalse);
      expect(
        ProjectPart.allDone(
          parts.map((p) => p.copyWith(status: PartTakeStatus.finalTake)).toList(),
        ),
        isTrue,
      );
    });

    test('allDone is false for an empty list', () {
      // Nothing listed means nothing finished — not "everything finished".
      expect(ProjectPart.allDone(const []), isFalse);
    });

    test('performers de-duplicates case-insensitively and skips blanks', () {
      expect(ProjectPart.performers(parts), ['Alex', 'sam']);
      expect(
        ProjectPart.performers([
          TestFactories.makePart(id: 'x', performer: '   '),
          TestFactories.makePart(id: 'y', performer: null),
        ]),
        isEmpty,
      );
    });

    test('searchableText includes names, performers and notes', () {
      final text = ProjectPart.searchableText([
        TestFactories.makePart(
            name: 'Rhodes', performer: 'Nina', notes: 're-amp needed'),
      ]);
      expect(text, contains('Rhodes'));
      expect(text, contains('Nina'));
      expect(text, contains('re-amp needed'));
    });
  });

  group('ProjectPart JSON', () {
    test('round-trips every field', () {
      final part = TestFactories.makePart(
        id: 'p1',
        name: 'Lead Vocals',
        performer: 'Nina',
        status: PartTakeStatus.earlyTake,
        notes: 'double-track the chorus',
      );

      final restored = ProjectPart.fromJson(part.toJson());

      expect(restored, part);
    });

    test('serializes the status as its stable key, not its index', () {
      final json = TestFactories.makePart(status: PartTakeStatus.earlyTake).toJson();
      expect(json['status'], 'earlyTake');
    });

    test('tolerates a missing status and missing optional fields', () {
      final restored = ProjectPart.fromJson({'id': 'p1', 'name': 'Drums'});

      expect(restored.status, PartTakeStatus.needed);
      expect(restored.performer, isNull);
      expect(restored.notes, isNull);
    });
  });

  group('ProjectPartAdapter (Hive round-trip)', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await HiveTestHelper.setUp();
    });

    tearDown(() async {
      await HiveTestHelper.tearDown(tempDir);
    });

    test('preserves parts nested inside a MusicProject', () async {
      final original = TestFactories.makeProject(
        id: 'parts-round-trip',
        parts: [
          TestFactories.makePart(
            id: 'p1',
            name: 'Drums',
            performer: 'Alex',
            status: PartTakeStatus.finalTake,
            notes: 'keeper',
          ),
          TestFactories.makePart(id: 'p2', name: 'Bass', performer: null),
        ],
      );

      final box = await Hive.openBox<MusicProject>('parts_round_trip');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;

      expect(restored.parts.length, 2);
      expect(restored.parts.first.name, 'Drums');
      expect(restored.parts.first.performer, 'Alex');
      expect(restored.parts.first.status, PartTakeStatus.finalTake);
      expect(restored.parts.first.notes, 'keeper');
      expect(restored.parts.last.performer, isNull);
      expect(restored.parts.last.status, PartTakeStatus.needed);
    });

    test('preserves part order, which is the arrangement order', () async {
      final original = TestFactories.makeProject(
        id: 'parts-order',
        parts: [
          TestFactories.makePart(id: 'p1', name: 'Drums'),
          TestFactories.makePart(id: 'p2', name: 'Bass'),
          TestFactories.makePart(id: 'p3', name: 'Guitar'),
        ],
      );

      final box = await Hive.openBox<MusicProject>('parts_order');
      await box.put(original.id, original);

      expect(
        box.get(original.id)!.parts.map((p) => p.name),
        ['Drums', 'Bass', 'Guitar'],
      );
    });

    test('a project saved without parts reads back with an empty list', () async {
      final original = TestFactories.makeMinimalProject(id: 'no-parts');
      final box = await Hive.openBox<MusicProject>('parts_absent');
      await box.put(original.id, original);

      expect(box.get(original.id)!.parts, isEmpty);
    });
  });

  group('MusicProject parts accessors', () {
    test('copyWith replaces the parts list', () {
      final project = TestFactories.makeProject();
      final updated = project.copyWith(parts: [TestFactories.makePart()]);

      expect(project.parts, isEmpty);
      expect(updated.parts.single.name, 'Drums');
    });

    test('partsDoneCount and performers read through to the parts list', () {
      final project = TestFactories.makeProject(parts: [
        TestFactories.makePart(id: 'a', performer: 'Alex',
            status: PartTakeStatus.finalTake),
        TestFactories.makePart(id: 'b', performer: 'Sam'),
      ]);

      expect(project.partsDoneCount, 1);
      expect(project.performers, ['Alex', 'Sam']);
    });
  });
}
