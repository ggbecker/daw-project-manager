import 'dart:io';

import '../models/music_project.dart';

/// Whether [project]'s source file (or, for bundle-style DAWs like Logic
/// Pro's .logicx, directory) still exists on this machine.
///
/// A live filesystem check, not a stored field — "missing" is inherently
/// per-device (e.g. a project on an external drive that isn't currently
/// mounted, or one only backed up from another machine), so it can't be
/// synced and re-derives correctly on every device independently.
bool projectFileExists(MusicProject project) {
  return File(project.filePath).existsSync() ||
      Directory(project.filePath).existsSync();
}
