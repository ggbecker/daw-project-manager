import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/release.dart';

Release _release(String id, List<String> trackIds) =>
    Release(id: id, title: id, trackIds: trackIds);

void main() {
  group('releaseProtectedProjectIds', () {
    // Regression coverage for the "Delete Missing" bulk action: every other
    // deletion path in the app (removeRoot, _deleteProjectsUnderPathPrefix,
    // clearAllData) protects projects referenced by a release from being
    // destroyed. This helper is what lets that same rule be applied there.

    test('collects track ids across every release', () {
      final releases = [
        _release('r1', ['a', 'b']),
        _release('r2', ['c']),
      ];

      expect(releaseProtectedProjectIds(releases), {'a', 'b', 'c'});
    });

    test('de-duplicates a project referenced by more than one release', () {
      final releases = [
        _release('r1', ['a']),
        _release('r2', ['a', 'b']),
      ];

      expect(releaseProtectedProjectIds(releases), {'a', 'b'});
    });

    test('is empty when there are no releases', () {
      expect(releaseProtectedProjectIds([]), isEmpty);
    });

    test('is empty when releases have no tracks', () {
      expect(releaseProtectedProjectIds([_release('r1', [])]), isEmpty);
    });
  });

  group('trackIdsAfterRemoving', () {
    // Regression coverage for the "Delete Missing" dialog's opt-in checkbox:
    // choosing to also delete release-tracked missing projects must scrub
    // those ids out of trackIds, or the release keeps pointing at a project
    // that no longer exists.

    test('removes every deleted id from trackIds', () {
      final release = _release('r1', ['a', 'b', 'c']);

      expect(trackIdsAfterRemoving(release, {'a', 'c'}), ['b']);
    });

    test('preserves order of the ids that remain', () {
      final release = _release('r1', ['c', 'a', 'b']);

      expect(trackIdsAfterRemoving(release, {'a'}), ['c', 'b']);
    });

    test('is a no-op when none of the deleted ids are tracked', () {
      final release = _release('r1', ['a', 'b']);

      expect(trackIdsAfterRemoving(release, {'z'}), ['a', 'b']);
    });

    test('results in an empty list when every track is deleted', () {
      final release = _release('r1', ['a', 'b']);

      expect(trackIdsAfterRemoving(release, {'a', 'b'}), isEmpty);
    });
  });
}
