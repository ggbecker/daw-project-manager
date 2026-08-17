import 'package:hive_ce/hive.dart';

/// How far along one instrument/part is in the recording process.
///
/// Persisted by [key], never by index: a reordered or extended enum must not
/// silently reinterpret data already written to Hive, Drive, or a backup file.
enum PartTakeStatus {
  /// The song calls for this part, but nothing has been recorded yet.
  needed('needed'),

  /// Currently being tracked.
  recording('recording'),

  /// Something is recorded, but it is a scratch/reference take.
  earlyTake('earlyTake'),

  /// The keeper take — this part is done.
  finalTake('finalTake');

  const PartTakeStatus(this.key);

  final String key;

  /// Unknown/missing keys degrade to [needed] rather than throwing, so a part
  /// written by a newer version of the app still loads on an older one.
  static PartTakeStatus fromKey(String? key) {
    for (final status in values) {
      if (status.key == key) return status;
    }
    return needed;
  }

  /// Whether this part counts as finished for progress purposes.
  bool get isDone => this == PartTakeStatus.finalTake;
}

/// One instrument, voice, or role within a song — what it is, who plays it,
/// and how far along the recording of it is.
///
/// Deliberately separate from [TodoItem]: a todo is a one-off task that gets
/// checked off and forgotten, whereas a part is a standing property of the
/// arrangement whose state moves through [PartTakeStatus] and can be reported
/// on (progress counts, CSV export, "who played bass on this?").
///
/// Order within a project's list is meaningful (drums, bass, guitars, vocals…)
/// and is preserved as-is — there is no created/updated timestamp to sort by.
@HiveType(typeId: 14)
class ProjectPart {
  @HiveField(0)
  final String id;

  /// Instrument or role, e.g. "Drums", "Lead Vocals", "Rhodes".
  @HiveField(1)
  final String name;

  /// Who plays/played it. Null or empty when unassigned.
  @HiveField(2)
  final String? performer;

  @HiveField(3)
  final PartTakeStatus status;

  /// Free text for this part alone, e.g. "needs a re-amp".
  @HiveField(4)
  final String? notes;

  const ProjectPart({
    required this.id,
    required this.name,
    this.performer,
    this.status = PartTakeStatus.needed,
    this.notes,
  });

  ProjectPart copyWith({
    String? id,
    String? name,
    String? performer,
    bool clearPerformer = false,
    PartTakeStatus? status,
    String? notes,
    bool clearNotes = false,
  }) {
    return ProjectPart(
      id: id ?? this.id,
      name: name ?? this.name,
      performer: clearPerformer ? null : (performer ?? this.performer),
      status: status ?? this.status,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'performer': performer,
        'status': status.key,
        'notes': notes,
      };

  factory ProjectPart.fromJson(Map<dynamic, dynamic> json) => ProjectPart(
        id: json['id'] as String,
        name: json['name'] as String,
        performer: json['performer'] as String?,
        status: PartTakeStatus.fromKey(json['status'] as String?),
        notes: json['notes'] as String?,
      );

  /// How many of [parts] are finished (i.e. on their final take).
  static int doneCount(List<ProjectPart> parts) =>
      parts.where((p) => p.status.isDone).length;

  /// Whether every part in [parts] is finished. False for an empty list —
  /// a song with no parts listed has not "finished" anything.
  static bool allDone(List<ProjectPart> parts) =>
      parts.isNotEmpty && doneCount(parts) == parts.length;

  /// Every distinct performer across [parts], in first-seen order, ignoring
  /// blanks. Used for the credits line and for making parts searchable.
  static List<String> performers(List<ProjectPart> parts) {
    final seen = <String>{};
    final result = <String>[];
    for (final part in parts) {
      final name = part.performer?.trim();
      if (name == null || name.isEmpty) continue;
      if (seen.add(name.toLowerCase())) result.add(name);
    }
    return result;
  }

  /// A single string with every part's name, performer and notes, for
  /// substring/fuzzy search over a project's instrumentation.
  static String searchableText(List<ProjectPart> parts) {
    final buffer = StringBuffer();
    for (final part in parts) {
      buffer.write(part.name);
      final performer = part.performer;
      if (performer != null && performer.isNotEmpty) buffer.write(' $performer');
      final notes = part.notes;
      if (notes != null && notes.isNotEmpty) buffer.write(' $notes');
      buffer.write(' ');
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectPart &&
          other.id == id &&
          other.name == name &&
          other.performer == performer &&
          other.status == status &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(id, name, performer, status, notes);
}

class ProjectPartAdapter extends TypeAdapter<ProjectPart> {
  @override
  final int typeId = 14;

  @override
  ProjectPart read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return ProjectPart(
      id: fields[0] as String,
      name: fields[1] as String,
      performer: fields[2] as String?,
      status: PartTakeStatus.fromKey(fields[3] as String?),
      notes: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectPart obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.performer)
      ..writeByte(3)
      ..write(obj.status.key)
      ..writeByte(4)
      ..write(obj.notes);
  }
}
