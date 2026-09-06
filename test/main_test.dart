import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/main.dart';

import 'helpers/test_factories.dart';

void main() {
  group('findProjectForPendingFolder', () {
    // Backs reconciling a session-tracked PendingFolder once its DAW
    // project file appears on disk (see _onFolderWatcherActivity): the
    // folder-watcher needs to find which scanned project actually lives
    // inside the pending folder so it can hand session tracking over to it
    // instead of leaving the "waiting for project" chip stuck until the
    // user manually clicks Refresh/Scan.

    test('finds the project whose path is inside the pending folder', () {
      final other = TestFactories.makeProject(
        id: 'other',
        filePath: '/Music/Other Song/Other Song.cpr',
      );
      final match = TestFactories.makeProject(
        id: 'match',
        filePath: '/Music/New Song/New Song.cpr',
      );

      final found = findProjectForPendingFolder([
        other,
        match,
      ], '/Music/New Song');

      expect(found?.id, 'match');
    });

    test('returns null when no project lives inside the pending folder', () {
      final unrelated = TestFactories.makeProject(
        id: 'unrelated',
        filePath: '/Music/Other Song/Other Song.cpr',
      );

      final found = findProjectForPendingFolder([unrelated], '/Music/New Song');

      expect(found, isNull);
    });

    test('returns null for an empty project list', () {
      expect(findProjectForPendingFolder([], '/Music/New Song'), isNull);
    });
  });

  group('shouldResumeSessionOnResolve', () {
    // Regression: when a session-tracked pending folder resolved, the folder
    // watcher activated the project and started its work timer regardless of
    // the session mode setting — so a user who created the folder with
    // session mode on, then turned it off, got a session started for them
    // when the project file finally appeared.
    final start = DateTime(2026, 1, 1, 10);

    test('true only when session mode is on and the folder was stamped', () {
      expect(
        shouldResumeSessionOnResolve(
          sessionModeOn: true,
          sessionStartedAt: start,
        ),
        isTrue,
      );
    });

    test('false when session mode is off, even with a stamp', () {
      expect(
        shouldResumeSessionOnResolve(
          sessionModeOn: false,
          sessionStartedAt: start,
        ),
        isFalse,
      );
    });

    test('false when the folder was never stamped for session tracking', () {
      expect(
        shouldResumeSessionOnResolve(
          sessionModeOn: true,
          sessionStartedAt: null,
        ),
        isFalse,
      );
    });
  });
}
