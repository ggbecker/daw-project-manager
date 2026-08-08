import 'dart:io';

import 'package:path/path.dart' as p;

/// Recursively copies every entity under [source] into [destination]
/// (created if missing), skipping any top-level-relative entity whose full
/// source path is in [excludedPaths]. Shared by `ProjectTemplateService` and
/// `TemplateDuplicationService` so both "copy a template into a new
/// project" and "duplicate a template into a new, independent template" go
/// through one implementation.
Future<void> copyDirectoryRecursive(
  Directory source,
  Directory destination, {
  Set<String> excludedPaths = const {},
}) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(recursive: false)) {
    if (excludedPaths.contains(entity.path)) continue;
    final newPath = p.join(destination.path, p.basename(entity.path));
    if (entity is Directory) {
      await copyDirectoryRecursive(
        entity,
        Directory(newPath),
        excludedPaths: excludedPaths,
      );
    } else if (entity is File) {
      await entity.copy(newPath);
    }
  }
}
