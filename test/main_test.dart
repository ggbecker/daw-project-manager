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
}
