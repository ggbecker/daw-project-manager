import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/services/scanner_service.dart';

void main() {
  group('newlyFoundPaths', () {
    // Regression coverage for the "New" badge (recentlyDiscoveredProjectsProvider)
    // now that both the initial scan and a manual rescan run without blocking
    // the UI: a project that appears mid-scan needs to be distinguishable
    // from one that was already known, purely by comparing scan output
    // against a pre-scan snapshot of known paths.

    test('returns paths not present in knownPaths', () {
      final found = {'/a/one.als', '/a/two.als', '/a/three.als'};
      final known = {'/a/one.als'};

      expect(newlyFoundPaths(found, known), {'/a/two.als', '/a/three.als'});
    });

    test('returns empty when every found path was already known', () {
      final found = {'/a/one.als', '/a/two.als'};
      final known = {'/a/one.als', '/a/two.als', '/a/other.als'};

      expect(newlyFoundPaths(found, known), isEmpty);
    });

    test('returns everything found when nothing was previously known', () {
      final found = {'/a/one.als', '/a/two.als'};

      expect(newlyFoundPaths(found, {}), found);
    });

    test('is empty when the scan found nothing', () {
      expect(newlyFoundPaths({}, {'/a/one.als'}), isEmpty);
    });
  });
}
