import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:daw_project_manager/services/scanner_service.dart';

void main() {
  group('bundle directory detection', () {
    // Regression coverage: LUNA (.luna) and GarageBand (.band) save projects
    // as a directory bundle, same as Logic Pro's .logicx — but scanDirectory
    // used to only special-case .logicx, so a .luna/.band bundle would get
    // pushed onto the traversal stack and recursed into instead of yielded
    // as a single project, silently finding nothing (no supported extension
    // lives inside the bundle's own contents).
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('scanner_bundle_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('.luna bundle directory is yielded as a single project', () async {
      final lunaDir = Directory(p.join(tempDir.path, 'My Song.luna'));
      await lunaDir.create(recursive: true);
      await File(p.join(lunaDir.path, 'session.dat')).writeAsString('fake');

      final results = await ScannerService().scanDirectory(tempDir.path).toList();

      expect(results, hasLength(1));
      expect(results.first.path, lunaDir.path);
      expect(results.first, isA<Directory>());
    });

    test('.band bundle directory (GarageBand) is yielded as a single project', () async {
      final bandDir = Directory(p.join(tempDir.path, 'My Song.band'));
      await bandDir.create(recursive: true);
      await File(p.join(bandDir.path, 'projectData')).writeAsString('fake');

      final results = await ScannerService().scanDirectory(tempDir.path).toList();

      expect(results, hasLength(1));
      expect(results.first.path, bandDir.path);
    });
  });

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
