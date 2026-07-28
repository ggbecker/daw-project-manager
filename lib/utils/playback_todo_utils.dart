/// Formats a playback [duration] as `mm:ss`, or `hh:mm:ss` once it reaches an hour.
String formatPlaybackTimestamp(Duration duration) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = duration.inHours;
  final m = two(duration.inMinutes.remainder(60));
  final s = two(duration.inSeconds.remainder(60));
  return h > 0 ? '${two(h)}:$m:$s' : '$m:$s';
}

/// Builds the todo text for a note captured at a given playback [position],
/// prefixing the trimmed [note] with its formatted timestamp, e.g. `[1:23] Fix the kick drum`.
String buildTimestampedTodoText(Duration position, String note) {
  return '[${formatPlaybackTimestamp(position)}] ${note.trim()}';
}

/// Builds the text for a new task on a project's task list. Only stamps a
/// timestamp when [isCurrentlyPlaying] is true — i.e. the task's project is
/// the one actually loaded in the player right now — since [position]
/// otherwise refers to a different (or no) track.
String buildTaskTextForProject({
  required bool isCurrentlyPlaying,
  required Duration position,
  required String text,
}) {
  final trimmed = text.trim();
  return isCurrentlyPlaying
      ? buildTimestampedTodoText(position, trimmed)
      : trimmed;
}
