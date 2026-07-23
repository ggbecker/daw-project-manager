import 'package:hive_ce/hive.dart';

/// A registered parent folder scanned for template subfolders — the
/// template-side equivalent of [ScanRoot], but refreshed manually rather
/// than watched, since template folders change far less often than active
/// projects.
@HiveType(typeId: 13)
class TemplateRoot {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String path;

  @HiveField(2)
  final DateTime addedAt;

  @HiveField(3)
  final DateTime? lastRefreshedAt;

  const TemplateRoot({
    required this.id,
    required this.path,
    required this.addedAt,
    this.lastRefreshedAt,
  });

  TemplateRoot copyWith({
    String? id,
    String? path,
    DateTime? addedAt,
    DateTime? lastRefreshedAt,
  }) {
    return TemplateRoot(
      id: id ?? this.id,
      path: path ?? this.path,
      addedAt: addedAt ?? this.addedAt,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
    );
  }
}

class TemplateRootAdapter extends TypeAdapter<TemplateRoot> {
  @override
  final int typeId = 13;

  @override
  TemplateRoot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return TemplateRoot(
      id: fields[0] as String,
      path: fields[1] as String,
      addedAt: fields[2] as DateTime,
      lastRefreshedAt: fields.containsKey(3) ? fields[3] as DateTime? : null,
    );
  }

  @override
  void write(BinaryWriter writer, TemplateRoot obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.path)
      ..writeByte(2)
      ..write(obj.addedAt)
      ..writeByte(3)
      ..write(obj.lastRefreshedAt);
  }
}
