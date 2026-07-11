import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class PendingFolder {
  final String id;
  final String path;
  final DateTime createdAt;
  final String? intendedDawName;
  /// Set when the user opts in to session tracking at folder-creation time.
  /// Stores the moment the DAW was launched so elapsed time can be credited
  /// to the project once it is saved and the pending entry resolves.
  final DateTime? sessionStartedAt;

  const PendingFolder({
    required this.id,
    required this.path,
    required this.createdAt,
    this.intendedDawName,
    this.sessionStartedAt,
  });

  PendingFolder copyWith({DateTime? sessionStartedAt}) => PendingFolder(
        id: id,
        path: path,
        createdAt: createdAt,
        intendedDawName: intendedDawName,
        sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
      );

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
        if (sessionStartedAt != null) 'sessionStartedAt': sessionStartedAt!.toIso8601String(),
      };

  factory PendingFolder.fromJson(Map<String, dynamic> json) => PendingFolder(
        id: json['id'] as String,
        path: json['path'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        intendedDawName: json['intendedDawName'] as String?,
        sessionStartedAt: json['sessionStartedAt'] != null
            ? DateTime.parse(json['sessionStartedAt'] as String)
            : null,
      );

  static PendingFolder create({required String path, String? intendedDawName}) =>
      PendingFolder(
        id: const Uuid().v4(),
        path: path,
        createdAt: DateTime.now(),
        intendedDawName: intendedDawName,
      );

  /// Creates an empty project folder on disk with no on-disk marker files.
  ///
  /// DAWs such as Cubase refuse to "Back Up Project" into a destination
  /// folder that isn't completely empty, so this must not leave anything
  /// behind — pending-folder tracking lives entirely in the Hive registry.
  static Future<void> createEmptyFolder(String path) async {
    await Directory(path).create(recursive: true);
  }
}
