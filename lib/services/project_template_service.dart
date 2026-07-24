import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:path/path.dart' as p;

import '../models/project_template.dart';
import 'scanner_service.dart';

/// A single recognized DAW project file found by
/// [ProjectTemplateService.discoverTemplateCandidates], ready to be turned
/// into a [ProjectTemplate] once given an id and timestamps. A folder with
/// several project files yields one candidate per file, all sharing the same
/// [sourceFolderPath].
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
  /// this level) for recognized DAW project files (searched recursively
  /// within that subfolder). Used for bulk-importing a folder that contains
  /// several template folders at once.
  ///
  /// A subfolder with exactly one project file produces one "self-contained"
  /// candidate for the whole folder. A subfolder with *multiple* project
  /// files — several independent songs sharing one sample pool/resource
  /// folder, for example — produces one candidate *per file* instead of
  /// being skipped as ambiguous; [instantiate] knows to leave sibling
  /// project files behind when copying that kind of candidate (see its doc
  /// comment). Subfolders with zero matches are omitted entirely.
  static List<TemplateFolderCandidate> discoverTemplateCandidates(String parentFolderPath) {
    final candidates = <TemplateFolderCandidate>[];
    List<FileSystemEntity> topLevel;
    try {
      topLevel = Directory(parentFolderPath).listSync(recursive: false);
    } catch (e) {
      // Root folder missing/inaccessible — return no candidates rather than
      // throwing, so one bad root doesn't abort scanning of the others.
      if (kDebugMode) {
        print('[ProjectTemplateService] Could not list "$parentFolderPath": $e');
      }
      return candidates;
    }

    if (kDebugMode) {
      print('[ProjectTemplateService] Scanning "$parentFolderPath": '
          '${topLevel.length} top-level entries');
    }

    for (final entity in topLevel) {
      if (entity is! Directory) {
        if (kDebugMode) {
          print('[ProjectTemplateService]   skip "${p.basename(entity.path)}": not a folder');
        }
        continue;
      }

      final matches = <File>[];
      try {
        for (final e in entity.listSync(recursive: true)) {
          if (e is File && ScannerService.supportedExtensions.contains(p.extension(e.path).toLowerCase())) {
            matches.add(e);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('[ProjectTemplateService]   skip "${entity.path}": could not list contents ($e)');
        }
        continue;
      }

      if (matches.isEmpty) {
        if (kDebugMode) {
          print('[ProjectTemplateService]   skip "${entity.path}": no recognized DAW project file found');
        }
        continue;
      }

      final folderName = p.basename(entity.path);
      if (matches.length == 1) {
        if (kDebugMode) {
          print('[ProjectTemplateService]   found candidate "${entity.path}" -> ${matches.single.path}');
        }
        candidates.add(TemplateFolderCandidate(
          name: folderName,
          sourceFolderPath: entity.path,
          mainFileRelativePath: p.relative(matches.single.path, from: entity.path),
        ));
        continue;
      }

      // Several project files share this folder (and its resources) —
      // register each as its own template rather than skipping the whole
      // folder. `instantiate` leaves the *other* project files behind when
      // copying one of these, so they don't bleed into an unrelated project.
      if (kDebugMode) {
        print('[ProjectTemplateService]   "${entity.path}": ${matches.length} DAW project files found '
            '(${matches.map((f) => p.basename(f.path)).join(', ')}) — registering each as its own template');
      }
      for (final match in matches) {
        candidates.add(TemplateFolderCandidate(
          name: '$folderName — ${p.basenameWithoutExtension(match.path)}',
          sourceFolderPath: entity.path,
          mainFileRelativePath: p.relative(match.path, from: entity.path),
        ));
      }
    }

    if (kDebugMode) {
      print('[ProjectTemplateService] "$parentFolderPath": ${candidates.length} candidate(s) found');
    }

    return candidates;
  }

  /// Filters [candidates] down to the ones not already registered — compared
  /// by full main-file path (`sourceFolderPath` + `mainFileRelativePath`)
  /// against [existingMainFilePaths] — so refreshing a set of template roots
  /// only adds newly-appeared template files instead of re-adding everything
  /// found on every refresh. Keying on the full file path (rather than just
  /// the folder) matters now that one folder can yield multiple candidates —
  /// registering one project file in a shared folder must not shadow its
  /// siblings on the next refresh.
  static List<TemplateFolderCandidate> filterNewCandidates(
    List<TemplateFolderCandidate> candidates,
    Set<String> existingMainFilePaths,
  ) {
    return candidates
        .where((c) => !existingMainFilePaths.contains(p.join(c.sourceFolderPath, c.mainFileRelativePath)))
        .toList();
  }

  /// Copies [template]'s source folder into [destinationFolderPath] (which
  /// must not already exist — callers should validate that first, the same
  /// way the empty-folder project creation flow does) and renames the copied
  /// main file to `<newProjectName><original extension>`, preserving
  /// whatever subfolder it originally lived in relative to the template
  /// root. Returns the new absolute path of the renamed main file.
  ///
  /// Other recognized DAW project files that sit in the *same* directory as
  /// the main file are left out of the copy — a template can be a single
  /// project file living alongside unrelated sibling projects that happen to
  /// share the same sample/resource folder, and instantiating one shouldn't
  /// drag the others along. Everything else (subfolders, non-project files,
  /// project files in *other* subfolders) is copied as-is.
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

    final excludedPaths = <String>{};
    try {
      for (final e in Directory(p.dirname(sourceMainFile.path)).listSync(recursive: false)) {
        if (e is File &&
            e.path != sourceMainFile.path &&
            ScannerService.supportedExtensions.contains(p.extension(e.path).toLowerCase())) {
          excludedPaths.add(e.path);
        }
      }
    } catch (_) {
      // Best-effort — if the sibling scan fails, fall back to copying
      // everything rather than blocking instantiation entirely.
    }

    await _copyDirectory(sourceDir, Directory(destinationFolderPath), excludedPaths: excludedPaths);

    final copiedMainFile = File(
      p.join(destinationFolderPath, template.mainFileRelativePath),
    );
    final newFileName =
        '$newProjectName${p.extension(template.mainFileRelativePath)}';
    final newMainFilePath = p.join(p.dirname(copiedMainFile.path), newFileName);
    await copiedMainFile.rename(newMainFilePath);

    return newMainFilePath;
  }

  static Future<void> _copyDirectory(
    Directory source,
    Directory destination, {
    Set<String> excludedPaths = const {},
  }) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      if (excludedPaths.contains(entity.path)) continue;
      final newPath = p.join(destination.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath), excludedPaths: excludedPaths);
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }
}
