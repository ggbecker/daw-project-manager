import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/music_project.dart';

/// Writes the plain-text `bpm.txt` / `key.txt` sidecar files some users keep
/// next to a project folder.
///
/// These are not just an export: [MetadataExtractor] reads them back on scan
/// (see its `bpm`/`key`/`tempo` filename patterns), so they are how a BPM set
/// in this app survives a database reset or reaches another tool.
///
/// Lives in a service rather than on a page because the only writer used to
/// be the dashboard grid's inline cell editor. That editor is gone — BPM and
/// key are edited on the project detail page now — and the behaviour had to
/// move with it rather than quietly disappear.
class MetadataSidecarService {
  const MetadataSidecarService._();

  static const String bpmFileName = 'bpm.txt';
  static const String keyFileName = 'key.txt';

  /// Writes `bpm.txt` next to [project], or deletes it when [bpm] is null.
  ///
  /// Throws on I/O failure — callers decide whether a failed sidecar write is
  /// worth interrupting the user for (it never blocks the Hive save itself).
  static Future<void> writeBpm(MusicProject project, double? bpm) =>
      _write(project, bpmFileName, bpm?.toStringAsFixed(2));

  /// Writes `key.txt` next to [project], or deletes it when [key] is null or
  /// empty.
  static Future<void> writeKey(MusicProject project, String? key) =>
      _write(project, keyFileName, (key?.isEmpty ?? true) ? null : key);

  static Future<void> _write(
    MusicProject project,
    String fileName,
    String? contents,
  ) async {
    if (project.filePath.isEmpty) return;
    final file = File(
      p.join(File(project.filePath).parent.path, fileName),
    );

    if (contents != null) {
      await file.writeAsString(contents);
    } else if (await file.exists()) {
      await file.delete();
    }
  }
}
