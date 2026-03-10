import 'package:hive_ce/hive.dart';

/// Represents a recorded change event on a [MusicProject].
/// Events are logged going forward from the point this feature was implemented.
@HiveType(typeId: 11)
class ProjectEvent extends HiveObject {
  // --- Event type constants ---
  static const String statusChange = 'status_change';
  static const String metadataEdit = 'metadata_edit';
  static const String todoCompleted = 'todo_completed';
  static const String fileChanged = 'file_changed';

  @HiveField(0)
  late String id;

  @HiveField(1)
  late String projectId;

  /// One of the four static string constants defined above.
  @HiveField(2)
  late String eventType;

  @HiveField(3)
  late DateTime occurredAt;

  /// JSON-encoded payload with context for the event (nullable).
  /// Payload contracts:
  ///   status_change  → {"from": "Idea", "to": "Arranging"}
  ///   metadata_edit  → {"fields": ["bpm", "musicalKey"]}
  ///   todo_completed → {"todoId": "...", "todoText": "..."}
  ///   file_changed   → {"sizeChanged": true, "lastModifiedChanged": true, "newSizeBytes": 12345678}
  @HiveField(4)
  String? payload;

  ProjectEvent({
    required this.id,
    required this.projectId,
    required this.eventType,
    required this.occurredAt,
    this.payload,
  });
}

class ProjectEventAdapter extends TypeAdapter<ProjectEvent> {
  @override
  final int typeId = 11;

  @override
  ProjectEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectEvent(
      id: fields[0] as String,
      projectId: fields[1] as String,
      eventType: fields[2] as String,
      occurredAt: fields[3] as DateTime,
      payload: fields.containsKey(4) ? fields[4] as String? : null,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectEvent obj) {
    writer.writeByte(5);
    writer
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.eventType)
      ..writeByte(3)
      ..write(obj.occurredAt)
      ..writeByte(4)
      ..write(obj.payload);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
