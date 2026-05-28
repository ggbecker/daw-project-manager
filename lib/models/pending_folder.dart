import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class PendingFolder {
  final String id;
  final String path;
  final DateTime createdAt;
  final String? intendedDawName;

  const PendingFolder({
    required this.id,
    required this.path,
    required this.createdAt,
    this.intendedDawName,
  });

  String get folderName => p.basename(path);

  bool get folderExists => Directory(path).existsSync();

  // True if the folder contains a recognised DAW project file anywhere inside it.
  bool hasProjectFile() {
    if (!folderExists) return false;
    const dawExtensions = {
      '.als', '.alp', '.bwproject', '.cpr', '.flp', '.logicx',
      '.maschine', '.maschine2', '.npr', '.ptx', '.pts', '.rpp',
      '.song', '.tracktionedit', '.tracktion',
    };
    try {
      for (final entry in Directory(path).listSync(recursive: true)) {
        if (entry is File && dawExtensions.contains(p.extension(entry.path).toLowerCase())) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  // True when the only files are the .dawpm marker (or the folder is completely empty).
  bool get isEmptyOrOnlyMarker {
    if (!folderExists) return true;
    try {
      final nonMarker = Directory(path)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => p.basename(f.path) != '.dawpm')
          .toList();
      return nonMarker.isEmpty;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'createdAt': createdAt.toIso8601String(),
        if (intendedDawName != null) 'intendedDawName': intendedDawName,
      };

  factory PendingFolder.fromJson(Map<String, dynamic> json) => PendingFolder(
        id: json['id'] as String,
        path: json['path'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        intendedDawName: json['intendedDawName'] as String?,
      );

  static PendingFolder create({required String path, String? intendedDawName}) =>
      PendingFolder(
        id: const Uuid().v4(),
        path: path,
        createdAt: DateTime.now(),
        intendedDawName: intendedDawName,
      );
}
