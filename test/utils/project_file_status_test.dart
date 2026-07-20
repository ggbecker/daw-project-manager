import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/utils/project_file_status.dart';

import '../helpers/test_factories.dart';

void main() {
  group('projectFileExists', () {
    test('is false for a path that does not exist', () {
      final project = TestFactories.makeProject(
        filePath: '/nonexistent/path/project.als',
      );

      expect(projectFileExists(project), isFalse);
    });

    test('is true for a project whose file exists', () async {
      final dir = await Directory.systemTemp.createTemp('project_file_status_');
      try {
        final file = File('${dir.path}/project.als');
        await file.create();
        final project = TestFactories.makeProject(filePath: file.path);

        expect(projectFileExists(project), isTrue);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('is true for a bundle-style (directory) project, e.g. Logic Pro .logicx', () async {
      final parent = await Directory.systemTemp.createTemp('project_file_status_');
      try {
        final bundle = Directory('${parent.path}/Song.logicx');
        await bundle.create();
        final project = TestFactories.makeProject(filePath: bundle.path);

        expect(projectFileExists(project), isTrue);
      } finally {
        await parent.delete(recursive: true);
      }
    });
  });
}
