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
}
