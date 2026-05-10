import 'package:hive_ce/hive.dart';

@HiveType(typeId: 2)
class ScanRoot {
  @HiveField(0)
  final String id; // UUID

  @HiveField(1)
  final String path; // absolute directory path

  @HiveField(2)
  final DateTime addedAt;

  @HiveField(3)
  final DateTime? lastScanAt;

  /// 0 = unlimited (default), 1 = top-level subfolders only, 2 = two levels deep
  @HiveField(4)
  final int scanDepth;

  const ScanRoot({
    required this.id,
    required this.path,
    required this.addedAt,
    this.lastScanAt,
    this.scanDepth = 0,
  });

  ScanRoot copyWith({
    String? id,
    String? path,
    DateTime? addedAt,
    DateTime? lastScanAt,
    int? scanDepth,
  }) {
    return ScanRoot(
      id: id ?? this.id,
      path: path ?? this.path,
      addedAt: addedAt ?? this.addedAt,
      lastScanAt: lastScanAt ?? this.lastScanAt,
      scanDepth: scanDepth ?? this.scanDepth,
    );
  }
}

class ScanRootAdapter extends TypeAdapter<ScanRoot> {
  @override
  final int typeId = 2;

  @override
  ScanRoot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return ScanRoot(
      id: fields[0] as String,
      path: fields[1] as String,
      addedAt: fields[2] as DateTime,
      lastScanAt: fields[3] as DateTime?,
      scanDepth: fields.containsKey(4) ? (fields[4] as int? ?? 0) : 0,
    );
  }

  @override
  void write(BinaryWriter writer, ScanRoot obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.path)
      ..writeByte(2)
      ..write(obj.addedAt)
      ..writeByte(3)
      ..write(obj.lastScanAt)
      ..writeByte(4)
      ..write(obj.scanDepth);
  }
}


