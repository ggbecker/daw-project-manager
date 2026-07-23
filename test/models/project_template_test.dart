import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/models/project_template.dart';

import '../helpers/hive_test_helper.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await HiveTestHelper.setUp();
  });

  tearDownAll(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  ProjectTemplate makeTemplate({
    String id = 'template-1',
    String name = 'Song Template',
    String sourceFolderPath = '/Users/artist/Templates/Song Template',
    String mainFileRelativePath = 'Song Template.als',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectTemplate(
      id: id,
      name: name,
      sourceFolderPath: sourceFolderPath,
      mainFileRelativePath: mainFileRelativePath,
      createdAt: createdAt ?? DateTime(2025, 1, 1),
      updatedAt: updatedAt ?? DateTime(2025, 1, 2),
    );
  }

  group('ProjectTemplate.copyWith', () {
    test('preserves unchanged fields when no arguments are given', () {
      final t = makeTemplate();
      final copy = t.copyWith();

      expect(copy.id, t.id);
      expect(copy.name, t.name);
      expect(copy.sourceFolderPath, t.sourceFolderPath);
      expect(copy.mainFileRelativePath, t.mainFileRelativePath);
      expect(copy.createdAt, t.createdAt);
      expect(copy.updatedAt, t.updatedAt);
    });

    test('updates only the provided fields', () {
      final t = makeTemplate();
      final renamed = t.copyWith(name: 'New Name', updatedAt: DateTime(2025, 6, 1));

      expect(renamed.name, 'New Name');
      expect(renamed.updatedAt, DateTime(2025, 6, 1));
      expect(renamed.id, t.id);
      expect(renamed.sourceFolderPath, t.sourceFolderPath);
      expect(renamed.mainFileRelativePath, t.mainFileRelativePath);
    });
  });

  group('ProjectTemplateAdapter (Hive round-trip)', () {
    test('preserves all fields after write and read', () async {
      final original = makeTemplate(
        mainFileRelativePath: 'Renders/Song Template.als',
      );

      final box = await Hive.openBox<ProjectTemplate>('project_template_round_trip_test');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;
      await box.close();

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.sourceFolderPath, original.sourceFolderPath);
      expect(restored.mainFileRelativePath, original.mainFileRelativePath);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });
  });
}
