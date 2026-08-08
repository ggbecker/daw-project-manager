import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/project_template.dart';
import 'package:daw_project_manager/services/template_duplication_service.dart';

void main() {
  late Directory tempDir;
  late Directory sourceDir;

  ProjectTemplate makeTemplate({
    String mainFileRelativePath = 'Song Template.als',
    double? bpm,
    String? musicalKey,
    String? dawVersion,
    String? notes,
    String? projectNotes,
  }) {
    return ProjectTemplate(
      id: 'template-1',
      name: 'Song Template',
      sourceFolderPath: sourceDir.path,
      mainFileRelativePath: mainFileRelativePath,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      bpm: bpm,
      musicalKey: musicalKey,
      dawVersion: dawVersion,
      notes: notes,
      projectNotes: projectNotes,
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('template_duplication_service_test_');
    sourceDir = Directory(p.join(tempDir.path, 'Song Template'));
    await sourceDir.create(recursive: true);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TemplateDuplicationService.duplicate', () {
    test('copies the folder to a sibling "<name> v2" path by default', () async {
      File(p.join(sourceDir.path, 'Song Template.als')).writeAsStringSync('als data');

      final duplicated = await TemplateDuplicationService.duplicate(
        template: makeTemplate(),
        newName: 'Song Template Copy',
      );

      expect(duplicated.sourceFolderPath, p.join(tempDir.path, 'Song Template v2'));
      expect(duplicated.mainFileRelativePath, 'Song Template.als');
      expect(
        File(p.join(duplicated.sourceFolderPath, 'Song Template.als')).readAsStringSync(),
        'als data',
      );
      // The original folder is left untouched.
      expect(File(p.join(sourceDir.path, 'Song Template.als')).existsSync(), isTrue);
    });

    test('is a brand new, independent template with its own id', () async {
      File(p.join(sourceDir.path, 'Song Template.als')).writeAsStringSync('als data');
      final original = makeTemplate(bpm: 128, musicalKey: 'C#m', dawVersion: '11.3');

      final duplicated = await TemplateDuplicationService.duplicate(
        template: original,
        newName: 'Song Template Copy',
      );

      expect(duplicated.id, isNot(original.id));
      expect(duplicated.name, 'Song Template Copy');
      expect(duplicated.bpm, 128);
      expect(duplicated.musicalKey, 'C#m');
      expect(duplicated.dawVersion, '11.3');
    });

    test('carries over notes and projectNotes', () async {
      File(p.join(sourceDir.path, 'Song Template.als')).writeAsStringSync('als data');
      final original = makeTemplate(
        notes: 'Great for peak-time sets',
        projectNotes: 'Author: DJ Example',
      );

      final duplicated = await TemplateDuplicationService.duplicate(
        template: original,
        newName: 'Song Template Copy',
      );

      expect(duplicated.notes, 'Great for peak-time sets');
      expect(duplicated.projectNotes, 'Author: DJ Example');
    });

    test('copies sibling files unchanged', () async {
      File(p.join(sourceDir.path, 'Song Template.als')).writeAsStringSync('als data');
      File(p.join(sourceDir.path, 'Kick.wav')).writeAsStringSync('kick data');

      final duplicated = await TemplateDuplicationService.duplicate(
        template: makeTemplate(),
        newName: 'Song Template Copy',
      );

      expect(
        File(p.join(duplicated.sourceFolderPath, 'Kick.wav')).readAsStringSync(),
        'kick data',
      );
    });

    test('picks v3, v4... when earlier sibling copies already exist', () async {
      File(p.join(sourceDir.path, 'Song Template.als')).writeAsStringSync('als data');
      await Directory(p.join(tempDir.path, 'Song Template v2')).create(recursive: true);

      final duplicated = await TemplateDuplicationService.duplicate(
        template: makeTemplate(),
        newName: 'Song Template Copy',
      );

      expect(duplicated.sourceFolderPath, p.join(tempDir.path, 'Song Template v3'));
    });

    test('throws when the template source folder no longer exists', () async {
      await sourceDir.delete(recursive: true);

      expect(
        () => TemplateDuplicationService.duplicate(
          template: makeTemplate(),
          newName: 'Song Template Copy',
        ),
        throwsStateError,
      );
    });
  });
}
