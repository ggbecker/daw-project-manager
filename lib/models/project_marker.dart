/// A named position on a DAW project's own timeline — REAPER's markers and
/// regions, read straight out of the `.rpp` file.
///
/// Sessions that hold several songs at once are otherwise a single opaque
/// entry in the app; markers are how those sections are already labelled
/// inside the DAW, so indexing them turns one project row into a table of
/// contents.
///
/// Stored inside `MusicProject` as a plain `Map` (see [toMap]/[fromMap])
/// rather than as its own `@HiveType` — same approach as `SessionRecord`,
/// which avoids claiming a type id and registering another adapter for what
/// is really a value object.
class ProjectMarker {
  const ProjectMarker({
    required this.index,
    required this.name,
    required this.positionSeconds,
    this.endSeconds,
  });

  /// The number the DAW shows in the ruler. Markers and regions are numbered
  /// in separate sequences, so this is only unique within one of the two —
  /// never use it as a key across the whole list.
  final int index;

  /// The label the user typed in the DAW. May be empty: an unnamed marker is
  /// still a position worth keeping, and callers localize their own fallback
  /// text rather than having an English one baked into stored data.
  final String name;

  /// Offset from the start of the project timeline, in seconds.
  final double positionSeconds;

  /// End of the span, for regions. Null for point markers — which is exactly
  /// what [isRegion] tests.
  final double? endSeconds;

  bool get isRegion => endSeconds != null;

  Duration get position => _toDuration(positionSeconds);

  Duration? get end => endSeconds == null ? null : _toDuration(endSeconds!);

  /// Length of a region, or null for a point marker.
  Duration? get length {
    final e = endSeconds;
    if (e == null) return null;
    final seconds = e - positionSeconds;
    return seconds <= 0 ? null : _toDuration(seconds);
  }

  static Duration _toDuration(double seconds) =>
      Duration(milliseconds: (seconds * 1000).round());

  ProjectMarker copyWith({
    int? index,
    String? name,
    double? positionSeconds,
    double? endSeconds,
  }) {
    return ProjectMarker(
      index: index ?? this.index,
      name: name ?? this.name,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      endSeconds: endSeconds ?? this.endSeconds,
    );
  }

  Map<String, dynamic> toMap() => {
        'index': index,
        'name': name,
        'position': positionSeconds,
        if (endSeconds != null) 'end': endSeconds,
      };

  factory ProjectMarker.fromMap(Map map) {
    return ProjectMarker(
      index: (map['index'] as num?)?.toInt() ?? 0,
      name: map['name'] as String? ?? '',
      positionSeconds: (map['position'] as num?)?.toDouble() ?? 0,
      endSeconds: (map['end'] as num?)?.toDouble(),
    );
  }

  /// Value equality so a rescan that finds the same markers can be recognised
  /// as a no-op instead of rewriting the record.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectMarker &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          name == other.name &&
          positionSeconds == other.positionSeconds &&
          endSeconds == other.endSeconds;

  @override
  int get hashCode =>
      Object.hash(index, name, positionSeconds, endSeconds);

  @override
  String toString() =>
      'ProjectMarker($index, "$name", $positionSeconds'
      '${endSeconds == null ? '' : '..$endSeconds'})';
}
