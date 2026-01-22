import 'package:hive/hive.dart';

@HiveType(typeId: 8)
class Playlist {
  @HiveField(0)
  final String id; // UUID primary key

  @HiveField(1)
  final String name; // Playlist name

  @HiveField(2)
  final List<String> projectIds; // List of MusicProject IDs in order

  @HiveField(3)
  final List<String> audioFilePaths; // List of direct audio file paths (for files not in projects)

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  const Playlist({
    required this.id,
    required this.name,
    required this.projectIds,
    this.audioFilePaths = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Playlist copyWith({
    String? id,
    String? name,
    List<String>? projectIds,
    List<String>? audioFilePaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      projectIds: projectIds ?? this.projectIds,
      audioFilePaths: audioFilePaths ?? this.audioFilePaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PlaylistAdapter extends TypeAdapter<Playlist> {
  @override
  final int typeId = 8;

  @override
  Playlist read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    
    // Handle migration from old format (without audioFilePaths)
    // Old format: id(0), name(1), projectIds(2), createdAt(3), updatedAt(4) - 5 fields
    // New format: id(0), name(1), projectIds(2), audioFilePaths(3), createdAt(4), updatedAt(5) - 6 fields
    
    final isOldFormat = numOfFields == 5;
    
    return Playlist(
      id: fields[0] as String,
      name: fields[1] as String,
      projectIds: (fields[2] as List).cast<String>(),
      audioFilePaths: isOldFormat 
          ? const [] // Old format doesn't have audioFilePaths
          : (fields[3] as List).cast<String>(),
      createdAt: isOldFormat 
          ? (fields[3] as DateTime) // Old format: createdAt is at index 3
          : (fields[4] as DateTime), // New format: createdAt is at index 4
      updatedAt: isOldFormat 
          ? (fields[4] as DateTime) // Old format: updatedAt is at index 4
          : (fields[5] as DateTime), // New format: updatedAt is at index 5
    );
  }

  @override
  void write(BinaryWriter writer, Playlist obj) {
    writer
      ..writeByte(6) // 6 fields (0-5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.projectIds)
      ..writeByte(3)
      ..write(obj.audioFilePaths)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }
}
