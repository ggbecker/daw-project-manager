import 'package:daw_project_manager/models/scan_mode.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;

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

  /// 0 = Flat (deep recursive, no grouping), 1+ = Smart Folder (group by top-level subfolder).
  /// Old value 2 auto-migrates to Smart Folder via [scanMode].
  @HiveField(4)
  final int scanDepth;

  /// User-facing label shown instead of [path]. On Linux under Flatpak,
  /// [path] is a sandboxed document-portal path (e.g.
  /// `/run/user/1000/doc/98127/projects`) rather than the real filesystem
  /// location — the portal never exposes the real path to a sandboxed app
  /// without broader filesystem permissions this app deliberately doesn't
  /// request (see flatpak/com.bandpassrecords.dpm.yml). Auto-filled with the
  /// picked folder's own name (the one part of the real path the portal
  /// does preserve) when a root is added; user-editable afterward.
  @HiveField(5)
  final String? displayName;

  ScanMode get scanMode => scanDepth >= 1 ? ScanMode.smartFolder : ScanMode.flat;

  /// [displayName] if set, otherwise the folder's own name derived from
  /// [path] — never the full [path] itself. Unified across every platform
  /// (not just Linux/Flatpak, where [displayName] is most necessary) so the
  /// UI behaves the same way everywhere: roots added before [displayName]
  /// existed, and any other case where it's unset, still show just the
  /// folder name here instead of the full path.
  String get effectiveDisplayName => displayName ?? p.basename(path);

  const ScanRoot({
    required this.id,
    required this.path,
    required this.addedAt,
    this.lastScanAt,
    this.scanDepth = 0,
    this.displayName,
  });

  ScanRoot copyWith({
    String? id,
    String? path,
    DateTime? addedAt,
    DateTime? lastScanAt,
    int? scanDepth,
    String? displayName,
  }) {
    return ScanRoot(
      id: id ?? this.id,
      path: path ?? this.path,
      addedAt: addedAt ?? this.addedAt,
      lastScanAt: lastScanAt ?? this.lastScanAt,
      scanDepth: scanDepth ?? this.scanDepth,
      displayName: displayName ?? this.displayName,
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
      displayName: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScanRoot obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.path)
      ..writeByte(2)
      ..write(obj.addedAt)
      ..writeByte(3)
      ..write(obj.lastScanAt)
      ..writeByte(4)
      ..write(obj.scanDepth)
      ..writeByte(5)
      ..write(obj.displayName);
  }
}


