import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/project_template.dart';
import 'scanner_service.dart';

/// A subfolder found by [ProjectTemplateService.discoverTemplateCandidates]
/// that unambiguously looks like a template — one recognized DAW project
/// file inside it — ready to be turned into a [ProjectTemplate] once given
/// an id and timestamps.
class TemplateFolderCandidate {
  final String name;
  final String sourceFolderPath;
  final String mainFileRelativePath;

  const TemplateFolderCandidate({
    required this.name,
    required this.sourceFolderPath,
    required this.mainFileRelativePath,
  });
}

/// Instantiates a [ProjectTemplate] into a new project folder: copies the
/// template's whole source folder to a new location and renames only the
/// main project file to match the new project's name — every other copied
/// file or subfolder keeps its original name.
class ProjectTemplateService {
  /// Scans the immediate subfolders of [parentFolderPath] (non-recursive at
  /// this level) for exactly one recognized DAW project file each (searched
  /// recursively within that subfolder). Used for bulk-importing a folder
  /// that contains several template folders at once. Subfolders with zero or
  /// multiple candidate files are omitted — ambiguous cases are left for
  /// manual registration rather than guessed at; compare the returned list's
  /// length against the subfolder count to report how many were skipped.
  static List<TemplateFolderCandidate> discoverTemplateCandidates(String parentFolderPath) {
    final candidates = <TemplateFolderCandidate>[];
    for (final entity in Directory(parentFolderPath).listSync(recursive: false)) {
      if (entity is! Directory) continue;

      final matches = <File>[];
      try {
        for (final e in entity.listSync(recursive: true)) {
          if (e is File && ScannerService.supportedExtensions.contains(p.extension(e.path).toLowerCase())) {
            matches.add(e);
          }
        }
      } catch (_) {}

      if (matches.length != 1) continue;
      candidates.add(TemplateFolderCandidate(
        name: p.basename(entity.path),
        sourceFolderPath: entity.path,
        mainFileRelativePath: p.relative(matches.single.path, from: entity.path),
      ));
    }
    return candidates;
  }

  /// Filters [candidates] down to the ones not already registered — compared
  /// by [TemplateFolderCandidate.sourceFolderPath] against
  /// [existingSourceFolderPaths] — so refreshing a set of template roots only
  /// adds newly-appeared template folders instead of re-adding everything
  /// found on every refresh.
  static List<TemplateFolderCandidate> filterNewCandidates(
    List<TemplateFolderCandidate> candidates,
    Set<String> existingSourceFolderPaths,
  ) {
    return candidates
        .where((c) => !existingSourceFolderPaths.contains(c.sourceFolderPath))
        .toList();
  }

  /// Copies [template]'s source folder into [destinationFolderPath] (which
  /// must not already exist — callers should validate that first, the same
  /// way the empty-folder project creation flow does) and renames the copied
  /// main file to `<newProjectName><original extension>`, preserving
  /// whatever subfolder it originally lived in relative to the template
  /// root. Returns the new absolute path of the renamed main file.
  static Future<String> instantiate({
    required ProjectTemplate template,
    required String destinationFolderPath,
    required String newProjectName,
  }) async {
    final sourceDir = Directory(template.sourceFolderPath);
    if (!await sourceDir.exists()) {
      throw StateError(
        'Template source folder no longer exists: ${template.sourceFolderPath}',
      );
    }
    final sourceMainFile = File(
      p.join(template.sourceFolderPath, template.mainFileRelativePath),
    );
    if (!await sourceMainFile.exists()) {
      throw StateError(
        'Template main file no longer exists: ${sourceMainFile.path}',
      );
    }

    await _copyDirectory(sourceDir, Directory(destinationFolderPath));

    final copiedMainFile = File(
      p.join(destinationFolderPath, template.mainFileRelativePath),
    );
    final newFileName =
        '$newProjectName${p.extension(template.mainFileRelativePath)}';
    final newMainFilePath = p.join(p.dirname(copiedMainFile.path), newFileName);
    await copiedMainFile.rename(newMainFilePath);

    return newMainFilePath;
  }

  static Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      final newPath = p.join(destination.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }
}
