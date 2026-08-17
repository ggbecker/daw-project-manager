import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/utils/project_freshness.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_factories.dart';

void main() {
  MusicProject project(
    String id, {
    String? notes,
    String? projectNotes,
    String? customDisplayName,
    String status = 'Mixing',
    DateTime? updatedAt,
  }) =>
      TestFactories.makeProject(
        id: id,
        fileName: '$id.als',
        filePath: '/Projects/$id.als',
        notes: notes,
        projectNotes: projectNotes,
        customDisplayName: customDisplayName,
        status: status,
        updatedAt: updatedAt ?? DateTime(2025, 1, 14, 9, 0),
      );

  group('freshestProject', () {
    test('returns the repository copy for the same id', () {
      final stale = project('a', notes: 'old notes');
      final fresh = project('a', notes: 'new notes');

      expect(freshestProject(stale, [project('b'), fresh])!.notes,
          'new notes');
    });

    test('keeps the snapshot when the project is no longer in the list', () {
      final stale = project('a', notes: 'old notes');

      expect(freshestProject(stale, [project('b')]), same(stale));
    });

    test('keeps the snapshot while the project list has not loaded', () {
      final stale = project('a');

      expect(freshestProject(stale, null), same(stale));
    });

    test('passes null through', () {
      expect(freshestProject(null, [project('a')]), isNull);
    });
  });

  group('freshestProjects', () {
    test('refreshes every entry it can match', () {
      final queue = [project('a', notes: 'old a'), project('b', notes: 'old b')];
      final latest = [
        project('a', notes: 'new a'),
        project('b', notes: 'new b'),
      ];

      expect(
        freshestProjects(queue, latest).map((p) => p.notes),
        ['new a', 'new b'],
      );
    });

    test('preserves queue order rather than repository order', () {
      // Shuffle order must survive: the queue is the play sequence.
      final queue = [project('c'), project('a'), project('b')];
      final latest = [project('a'), project('b'), project('c')];

      expect(
        freshestProjects(queue, latest).map((p) => p.id),
        ['c', 'a', 'b'],
      );
    });

    test('keeps snapshots of projects deleted while queued', () {
      final deleted = project('gone', notes: 'still queued');
      final queue = [deleted, project('a', notes: 'old')];

      final result = freshestProjects(queue, [project('a', notes: 'new')]);

      expect(result[0], same(deleted));
      expect(result[1].notes, 'new');
    });

    test('returns the queue untouched when the list has not loaded', () {
      final queue = [project('a')];

      expect(freshestProjects(queue, null), same(queue));
    });
  });

  group('trackListChanged', () {
    test('is false when nothing changed', () {
      expect(
        trackListChanged([project('a'), project('b')],
            [project('a'), project('b')]),
        isFalse,
      );
    });

    test('is true when only the user notes changed', () {
      // Regression for #105 follow-up: editing a project's notes elsewhere left
      // the player rendering its stale snapshot, because the old skip check
      // compared only name/phase/todo counts.
      expect(
        trackListChanged(
          [project('a', notes: 'old', updatedAt: DateTime(2025, 1, 14))],
          [project('a', notes: 'new', updatedAt: DateTime(2025, 2, 20))],
        ),
        isTrue,
      );
    });

    test('is true when only the DAW-extracted notes changed', () {
      expect(
        trackListChanged(
          [project('a', projectNotes: 'old session log')],
          [project('a', projectNotes: 'new session log')],
        ),
        isTrue,
      );
    });

    test('is true when any other edit bumped updatedAt', () {
      // BPM/key/deadline are not compared field by field; updatedAt covers them.
      expect(
        trackListChanged(
          [project('a', updatedAt: DateTime(2025, 1, 14))],
          [project('a', updatedAt: DateTime(2025, 3, 1))],
        ),
        isTrue,
      );
    });

    test('is true when the length, order, name or phase changed', () {
      expect(trackListChanged([project('a')], []), isTrue);
      expect(
        trackListChanged([project('a'), project('b')],
            [project('b'), project('a')]),
        isTrue,
      );
      expect(
        trackListChanged(
            [project('a')], [project('a', customDisplayName: 'Renamed')]),
        isTrue,
      );
      expect(
        trackListChanged([project('a')], [project('a', status: 'Finished')]),
        isTrue,
      );
    });

    test('is true when a todo was added or completed', () {
      final withTodo = TestFactories.makeProject(
        id: 'a',
        todos: [TestFactories.makeTodo(id: 't1')],
      );
      final completed = TestFactories.makeProject(
        id: 'a',
        todos: [TestFactories.makeTodo(id: 't1', completed: true)],
      );

      expect(
        trackListChanged([TestFactories.makeProject(id: 'a')], [withTodo]),
        isTrue,
      );
      expect(trackListChanged([withTodo], [completed]), isTrue);
    });
  });
}
