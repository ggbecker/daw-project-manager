import '../models/music_project.dart';

/// Helpers for keeping player UIs showing the *current* copy of a project.
///
/// Both music players hold `MusicProject` snapshots taken when the track list
/// or the playback queue was built. Editing a project elsewhere (detail page,
/// deep scan, Drive restore) writes a new copy to Hive, but the snapshot the
/// player is still rendering never changes — so notes, phase, BPM etc. go
/// stale until the page is rebuilt from scratch. Re-resolving snapshots
/// against `allProjectsStreamProvider` by id fixes that without disturbing
/// queue order or playback state.

/// The current copy of [project] from [latest], matched by id.
///
/// Returns [project] unchanged when it is null, when [latest] is not loaded
/// yet, or when the project is no longer in the list (deleted while queued) —
/// the stale snapshot is still better than showing nothing.
MusicProject? freshestProject(
  MusicProject? project,
  List<MusicProject>? latest,
) {
  if (project == null || latest == null) return project;
  for (final candidate in latest) {
    if (candidate.id == project.id) return candidate;
  }
  return project;
}

/// [projects] with each entry replaced by its current copy from [latest],
/// preserving the original order (which is the playback order, possibly
/// shuffled — it must not be re-derived from [latest]).
List<MusicProject> freshestProjects(
  List<MusicProject> projects,
  List<MusicProject>? latest,
) {
  if (latest == null || projects.isEmpty) return projects;
  final byId = {for (final p in latest) p.id: p};
  return [
    for (final project in projects) byId[project.id] ?? project,
  ];
}

/// Whether [incoming] differs from [current] in any way a player renders.
///
/// The desktop player uses this to skip rebuilding its track list on stream
/// emissions that change nothing it shows. [MusicProject.updatedAt] is bumped
/// by `ProjectRepository.updateProject` on every user edit, so it catches
/// changes to any displayed field — notes, DAW notes, BPM, key, deadline —
/// without this having to enumerate them. The remaining comparisons cover
/// writes that bypass that bump, such as a Drive restore replaying the
/// remote's own `updatedAt`.
bool trackListChanged(
  List<MusicProject> current,
  List<MusicProject> incoming,
) {
  if (current.length != incoming.length) return true;
  for (var i = 0; i < current.length; i++) {
    if (_rendersDifferently(current[i], incoming[i])) return true;
  }
  return false;
}

bool _rendersDifferently(MusicProject a, MusicProject b) =>
    a.id != b.id ||
    a.updatedAt != b.updatedAt ||
    a.displayName != b.displayName ||
    a.notes != b.notes ||
    a.projectNotes != b.projectNotes ||
    a.status != b.status ||
    a.todos.length != b.todos.length ||
    a.todos.where((t) => t.completed).length !=
        b.todos.where((t) => t.completed).length;
