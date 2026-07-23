import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/pending_folder.dart';

PendingFolder _folder(String path) =>
    PendingFolder(id: 'test', path: path, createdAt: DateTime(2025, 1, 1));

void main() {
  group('PendingFolder.folderExists', () {
    test('returns false for a path that does not exist', () {
      expect(_folder('/definitely/no/such/path/exists').folderExists, isFalse);
    });

    test('returns true for an existing directory', () async {
      final dir = await Directory.systemTemp.createTemp('pf_exists_');
      addTearDown(() => dir.delete(recursive: true));

      expect(_folder(dir.path).folderExists, isTrue);
    });

    test('returns false after the directory is deleted', () async {
      final dir = await Directory.systemTemp.createTemp('pf_deleted_');
      await dir.delete(recursive: true);

      expect(_folder(dir.path).folderExists, isFalse);
    });
  });

  group('PendingFolder.hasProjectFile', () {
    test('returns false for a non-existent path', () {
      expect(_folder('/no/such/path').hasProjectFile(), isFalse);
    });

    test('returns false for an empty directory', () async {
      final dir = await Directory.systemTemp.createTemp('pf_empty_');
      addTearDown(() => dir.delete(recursive: true));

      expect(_folder(dir.path).hasProjectFile(), isFalse);
    });

    test('returns false when folder contains only non-DAW files', () async {
      final dir = await Directory.systemTemp.createTemp('pf_nondaw_');
      addTearDown(() => dir.delete(recursive: true));

      await File(p.join(dir.path, 'notes.txt')).create();
      await File(p.join(dir.path, 'audio.wav')).create();

      expect(_folder(dir.path).hasProjectFile(), isFalse);
    });

    test('returns true when folder contains an .als file', () async {
      final dir = await Directory.systemTemp.createTemp('pf_als_');
      addTearDown(() => dir.delete(recursive: true));

      await File(p.join(dir.path, 'project.als')).create();

      expect(_folder(dir.path).hasProjectFile(), isTrue);
    });

    test('returns true when folder contains an .flp file', () async {
      final dir = await Directory.systemTemp.createTemp('pf_flp_');
      addTearDown(() => dir.delete(recursive: true));

      await File(p.join(dir.path, 'beat.flp')).create();

      expect(_folder(dir.path).hasProjectFile(), isTrue);
    });

    test('returns true when folder contains a supported DAW bundle like .luna or .mgd', () async {
      final dir = await Directory.systemTemp.createTemp('pf_bundle_');
      addTearDown(() => dir.delete(recursive: true));

      await File(p.join(dir.path, 'mix.luna')).create();
      expect(_folder(dir.path).hasProjectFile(), isTrue);

      await File(p.join(dir.path, 'project.mgd')).create();
      expect(_folder(dir.path).hasProjectFile(), isTrue);
    });

    test('returns true when DAW file is inside a subdirectory', () async {
      final dir = await Directory.systemTemp.createTemp('pf_sub_');
      addTearDown(() => dir.delete(recursive: true));

      final sub = await Directory(p.join(dir.path, 'session')).create();
      await File(p.join(sub.path, 'track.als')).create();

      expect(_folder(dir.path).hasProjectFile(), isTrue);
    });

    test('extension matching is case-insensitive', () async {
      final dir = await Directory.systemTemp.createTemp('pf_upper_');
      addTearDown(() => dir.delete(recursive: true));

      // .ALS (uppercase) should still be detected
      await File(p.join(dir.path, 'PROJECT.ALS')).create();

      expect(_folder(dir.path).hasProjectFile(), isTrue);
    });
  });

  group('PendingFolder.isEmptyOrOnlyMarker', () {
    test('returns true for a non-existent path', () {
      expect(_folder('/no/such/path').isEmptyOrOnlyMarker, isTrue);
    });

    test('returns true for an empty directory', () async {
      final dir = await Directory.systemTemp.createTemp('pf_marker_empty_');
      addTearDown(() => dir.delete(recursive: true));

      expect(_folder(dir.path).isEmptyOrOnlyMarker, isTrue);
    });

    test('returns true when folder contains only the .dawpm marker', () async {
      final dir = await Directory.systemTemp.createTemp('pf_marker_only_');
      addTearDown(() => dir.delete(recursive: true));

      await File(p.join(dir.path, '.dawpm')).create();

      expect(_folder(dir.path).isEmptyOrOnlyMarker, isTrue);
    });

    test('returns false when folder contains a non-marker file', () async {
      final dir = await Directory.systemTemp.createTemp('pf_marker_file_');
      addTearDown(() => dir.delete(recursive: true));

      await File(p.join(dir.path, '.dawpm')).create();
      await File(p.join(dir.path, 'project.als')).create();

      expect(_folder(dir.path).isEmptyOrOnlyMarker, isFalse);
    });

    test('marker check ignores .dawpm in a subdirectory too', () async {
      // .dawpm anywhere in the tree (not just root) should still count as "marker only"
      final dir = await Directory.systemTemp.createTemp('pf_marker_sub_');
      addTearDown(() => dir.delete(recursive: true));

      final sub = await Directory(p.join(dir.path, 'sub')).create();
      await File(p.join(sub.path, '.dawpm')).create();

      expect(_folder(dir.path).isEmptyOrOnlyMarker, isTrue);
    });
  });

  group('PendingFolder.createEmptyFolder', () {
    test('creates the directory', () async {
      final base = await Directory.systemTemp.createTemp('pf_create_');
      addTearDown(() => base.delete(recursive: true));
      final target = p.join(base.path, 'New Project');

      await PendingFolder.createEmptyFolder(target);

      expect(Directory(target).existsSync(), isTrue);
    });

    test('leaves no marker file behind, so DAWs see a truly empty folder', () async {
      // Regression: a DPM-written .dawpm marker made Cubase's "Back Up
      // Project" refuse the folder as non-empty. The folder must contain
      // zero entries after creation.
      final base = await Directory.systemTemp.createTemp('pf_create_nomarker_');
      addTearDown(() => base.delete(recursive: true));
      final target = p.join(base.path, 'New Project');

      await PendingFolder.createEmptyFolder(target);

      expect(Directory(target).listSync(), isEmpty);
    });
  });
}
