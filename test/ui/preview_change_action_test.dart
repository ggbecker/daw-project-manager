import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/project_detail_page.dart';

// Regression coverage for the preview player's didUpdateWidget decision.
//
// The bug: removing a manually-picked preview song immediately re-ran mixdown
// auto-detection, so the thing the user just deleted popped straight back
// (unless a mixdown folder happened to be empty). Removing an *auto-detected*
// preview already didn't re-detect; manual removal now behaves the same.
// A fresh scan is only automatic on a project switch — otherwise it's an
// explicit action ("Find automatically" button).
void main() {
  group('previewChangeAction', () {
    test('project switch always rescans', () {
      expect(
        previewChangeAction(
          idChanged: true,
          oldManualPath: '/a/song.wav',
          newManualPath: null,
          oldAutoPath: null,
          newAutoPath: null,
        ),
        PreviewChangeAction.rescanMixdown,
      );
    });

    test('removing a manual pick with no auto path on record → doNothing', () {
      expect(
        previewChangeAction(
          idChanged: false,
          oldManualPath: '/a/song.wav',
          newManualPath: null,
          oldAutoPath: null,
          newAutoPath: null,
        ),
        PreviewChangeAction.doNothing,
      );
    });

    test('removing a manual pick that has a known auto path → adopt it', () {
      expect(
        previewChangeAction(
          idChanged: false,
          oldManualPath: '/a/song.wav',
          newManualPath: '',
          oldAutoPath: '/a/Bounces/mix.wav',
          newAutoPath: '/a/Bounces/mix.wav',
        ),
        PreviewChangeAction.adoptKnownAutoPath,
      );
    });

    test('removing the auto-detected preview → doNothing', () {
      expect(
        previewChangeAction(
          idChanged: false,
          oldManualPath: null,
          newManualPath: null,
          oldAutoPath: '/a/Bounces/mix.wav',
          newAutoPath: null,
        ),
        PreviewChangeAction.doNothing,
      );
    });

    test('switching to a new manual pick → rescan (not a removal)', () {
      expect(
        previewChangeAction(
          idChanged: false,
          oldManualPath: '/a/song.wav',
          newManualPath: '/a/other.wav',
          oldAutoPath: null,
          newAutoPath: null,
        ),
        PreviewChangeAction.rescanMixdown,
      );
    });

    test('an auto path getting populated (detection landed) → rescan path, harmless', () {
      // Not a removal; the widget re-runs _detectMixdown which is a no-op once
      // previewSongAutoPath is set. The important cases above are the removals.
      expect(
        previewChangeAction(
          idChanged: false,
          oldManualPath: null,
          newManualPath: null,
          oldAutoPath: null,
          newAutoPath: '/a/Bounces/mix.wav',
        ),
        PreviewChangeAction.rescanMixdown,
      );
    });
  });
}
