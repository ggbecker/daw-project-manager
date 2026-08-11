import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/services/metadata_sidecar_service.dart';

import '../helpers/test_factories.dart';

/// Covers [MetadataSidecarService].
///
/// These files are not decorative: `MetadataExtractor` reads `bpm.txt` and
/// `key.txt` back on every scan, so they're how a BPM set in the app survives
/// a database reset. The writer moved here when the dashboard's inline cell
/// editor was removed, and these tests are what stop it going missing again.
void main() {
  late Directory tempDir;
  late File projectFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sidecar_test_');
    projectFile = File(p.join(tempDir.path, 'MyProject.als'));
    await projectFile.writeAsString('not a real project');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  File bpmFile() => File(p.join(tempDir.path, 'bpm.txt'));
  File keyFile() => File(p.join(tempDir.path, 'key.txt'));

  group('writeBpm', () {
    test('writes bpm.txt next to the project file', () async {
      final project = TestFactories.makeProject(filePath: projectFile.path);

      await MetadataSidecarService.writeBpm(project, 128);

      expect(await bpmFile().readAsString(), '128.00');
    });

    test('writes two decimal places for fractional tempos', () async {
      final project = TestFactories.makeProject(filePath: projectFile.path);

      await MetadataSidecarService.writeBpm(project, 174.5);

      expect(await bpmFile().readAsString(), '174.50');
    });

    test('overwrites an existing bpm.txt rather than appending', () async {
      final project = TestFactories.makeProject(filePath: projectFile.path);

      await MetadataSidecarService.writeBpm(project, 128);
      await MetadataSidecarService.writeBpm(project, 140);

      expect(await bpmFile().readAsString(), '140.00');
    });

    test('deletes bpm.txt when the BPM is cleared', () async {
      final project = TestFactories.makeProject(filePath: projectFile.path);
      await MetadataSidecarService.writeBpm(project, 128);

      await MetadataSidecarService.writeBpm(project, null);

      expect(await bpmFile().exists(), isFalse);
    });

    test('clearing when no bpm.txt exists is a no-op, not an error', () async {
      final project = TestFactories.makeProject(filePath: projectFile.path);

      await MetadataSidecarService.writeBpm(project, null);

      expect(await bpmFile().exists(), isFalse);
    });
  });

  group('writeKey', () {
    test('writes key.txt next to the project file', () async {
      final project = TestFactories.makeProject(filePath: projectFile.path);

      await MetadataSidecarService.writeKey(project, 'C#m');

      expect(await keyFile().readAsString(), 'C#m');
    });

    test('deletes key.txt when the key is cleared', () async {
      final project = TestFactories.makeProject(filePath: projectFile.path);
      await MetadataSidecarService.writeKey(project, 'C#m');

      await MetadataSidecarService.writeKey(project, null);

      expect(await keyFile().exists(), isFalse);
    });

    test('treats an empty key as a clear', () async {
      final project = TestFactories.makeProject(filePath: projectFile.path);
      await MetadataSidecarService.writeKey(project, 'C#m');

      await MetadataSidecarService.writeKey(project, '');

      expect(await keyFile().exists(), isFalse);
    });
  });

  group('projects with no usable path', () {
    test('writeBpm does nothing when filePath is empty', () async {
      final project = TestFactories.makeProject(filePath: '');

      await MetadataSidecarService.writeBpm(project, 128);

      expect(await bpmFile().exists(), isFalse);
    });

    test('writeKey does nothing when filePath is empty', () async {
      final project = TestFactories.makeProject(filePath: '');

      await MetadataSidecarService.writeKey(project, 'Am');

      expect(await keyFile().exists(), isFalse);
    });
  });

  test('bpm and key sidecars coexist in the same folder', () async {
    final project = TestFactories.makeProject(filePath: projectFile.path);

    await MetadataSidecarService.writeBpm(project, 90);
    await MetadataSidecarService.writeKey(project, 'F major');

    expect(await bpmFile().readAsString(), '90.00');
    expect(await keyFile().readAsString(), 'F major');
  });
}
