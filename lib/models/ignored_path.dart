import 'package:hive_ce/hive.dart';

@HiveType(typeId: 7)
class IgnoredPath {
  @HiveField(0)
  final String id; // UUID

  @HiveField(1)
  final String path; // absolute directory path

  @HiveField(2)
  final DateTime addedAt;

  const IgnoredPath({
    required this.id,
    required this.path,
    required this.addedAt,
  });
}

class IgnoredPathAdapter extends TypeAdapter<IgnoredPath> {
  @override
  final int typeId = 7;

  @override
  IgnoredPath read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return IgnoredPath(
      id: fields[0] as String,
      path: fields[1] as String,
      addedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, IgnoredPath obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.path)
      ..writeByte(2)
      ..write(obj.addedAt);
  }
}

