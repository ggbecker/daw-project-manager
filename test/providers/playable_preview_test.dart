import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/providers.dart';

import '../helpers/test_factories.dart';

void main() {
  group('isPlayablePreview', () {
    test('true for a normal local preview path', () {
      final p = TestFactories.makeProject(previewSongPath: '/music/track.wav');
      expect(isPlayablePreview(p), isTrue);
    });

    test('false when there is no preview path at all', () {
      final p = TestFactories.makeProject(previewSongPath: null);
      expect(isPlayablePreview(p), isFalse);
    });

    test('false for an empty preview path', () {
      final p = TestFactories.makeProject(previewSongPath: '');
      expect(isPlayablePreview(p), isFalse);
    });

    test('false for a drive:// placeholder that is not downloaded yet', () {
      final p = TestFactories.makeProject(previewSongPath: 'drive://abc123');
      expect(isPlayablePreview(p), isFalse);
    });

    test('falls back to the auto preview path when the manual one is empty', () {
      final p = TestFactories.makeProject(previewSongPath: '')
          .copyWith(previewSongAutoPath: '/music/auto.wav');
      expect(isPlayablePreview(p), isTrue);
      expect(resolvedPreviewPath(p), '/music/auto.wav');
    });
  });
}
