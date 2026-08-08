import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/project_template.dart';
import '../utils/folder_copy_utils.dart';

/// Duplicates a [ProjectTemplate] into a brand new, fully independent
/// template — a plain copy with no link back to the original (no shared
/// history or changelog). The new folder is created as a sibling of the
/// original inside the same parent directory, named `<original folder
/// name> vN` for the smallest N >= 2 not already taken on disk — visible
/// and browsable by the user like any other folder, rather than tucked away
/// in app-managed storage.
class TemplateDuplicationService {
  static const _uuid = Uuid();

  static Future<ProjectTemplate> duplicate({
    required ProjectTemplate template,
    required String newName,
  }) async {
    final sourceDir = Directory(template.sourceFolderPath);
    if (!await sourceDir.exists()) {
      throw StateError(
        'Template source folder does not exist: ${template.sourceFolderPath}',
      );
    }

    final parent = p.dirname(template.sourceFolderPath);
    final baseName = p.basename(template.sourceFolderPath);
    var n = 2;
    var destinationPath = p.join(parent, '$baseName v$n');
    while (await Directory(destinationPath).exists()) {
      n++;
      destinationPath = p.join(parent, '$baseName v$n');
    }

    await copyDirectoryRecursive(sourceDir, Directory(destinationPath));

    final now = DateTime.now();
    return ProjectTemplate(
      id: _uuid.v4(),
      name: newName,
      sourceFolderPath: destinationPath,
      mainFileRelativePath: template.mainFileRelativePath,
      createdAt: now,
      updatedAt: now,
      bpm: template.bpm,
      musicalKey: template.musicalKey,
      dawVersion: template.dawVersion,
      notes: template.notes,
      projectNotes: template.projectNotes,
    );
  }
}
