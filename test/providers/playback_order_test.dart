import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/providers/providers.dart';

import '../helpers/test_factories.dart';

List<MusicProject> _queue(int n) => List.generate(
      n,
      (i) => TestFactories.makeProject(
          id: 'p$i', previewSongPath: '/music/track$i.wav'),
    );

void main() {
  group('orderedQueueFor', () {
    final q = _queue(5);

    test('returns the natural order unchanged for non-shuffle modes', () {
      for (final mode in [
        PlaybackMode.normal,
        PlaybackMode.repeatOne,
        PlaybackMode.repeatAll,
      ]) {
        expect(orderedQueueFor(q, q[2], mode).map((p) => p.id),
            q.map((p) => p.id),
            reason: '$mode should not reorder');
      }
    });

    test('shuffle keeps the current track first and includes every track once',
        () {
      final ordered =
          orderedQueueFor(q, q[3], PlaybackMode.shuffle, random: Random(7));

      expect(ordered.first.id, 'p3', reason: 'current track stays first');
      expect(ordered.map((p) => p.id).toSet(), q.map((p) => p.id).toSet(),
          reason: 'no track dropped');
      expect(ordered.length, q.length, reason: 'no duplicates');
    });

    test('shuffle with a single track returns a copy unchanged', () {
      final one = _queue(1);
      final ordered = orderedQueueFor(one, one.first, PlaybackMode.shuffle);
      expect(ordered.map((p) => p.id), one.map((p) => p.id));
    });

    test('shuffle with no current track still returns all tracks', () {
      final ordered =
          orderedQueueFor(q, null, PlaybackMode.shuffle, random: Random(1));
      expect(ordered.map((p) => p.id).toSet(), q.map((p) => p.id).toSet());
    });
  });

  group('nextIndexIn / prevIndexIn', () {
    test('normal mode advances but does not wrap', () {
      expect(nextIndexIn(3, 0, PlaybackMode.normal), 1);
      expect(nextIndexIn(3, 2, PlaybackMode.normal), isNull);
      expect(prevIndexIn(3, 2, PlaybackMode.normal), 1);
      expect(prevIndexIn(3, 0, PlaybackMode.normal), isNull);
    });

    test('repeatAll and shuffle wrap around the ends', () {
      for (final mode in [PlaybackMode.repeatAll, PlaybackMode.shuffle]) {
        expect(nextIndexIn(3, 2, mode), 0, reason: '$mode wraps forward');
        expect(prevIndexIn(3, 0, mode), 2, reason: '$mode wraps backward');
      }
    });

    test('repeatOne advances like the other wrapping modes for manual skips',
        () {
      // repeat-one only pins the track on auto-advance; manual next still moves.
      expect(nextIndexIn(3, 1, PlaybackMode.repeatOne), 2);
      expect(nextIndexIn(3, 2, PlaybackMode.repeatOne), 0);
    });

    test('empty queue yields null', () {
      expect(nextIndexIn(0, 0, PlaybackMode.repeatAll), isNull);
      expect(prevIndexIn(0, 0, PlaybackMode.repeatAll), isNull);
    });
  });
}
