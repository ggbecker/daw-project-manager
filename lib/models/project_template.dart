import 'package:hive_ce/hive.dart';

part 'project_template.g.dart';

/// A registered "starter kit" folder a new project can be created from —
/// the whole folder containing [mainFileRelativePath] gets copied to a new
/// location and the main file (plus the destination folder itself) renamed
/// to the new project's name; every other file is copied unchanged.
@HiveType(typeId: 12)
class ProjectTemplate extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  /// The folder that gets copied wholesale when instantiating this template
  /// — the parent folder of the file the user pointed to when registering it.
  @HiveField(2)
  final String sourceFolderPath;

  /// Path of the main DAW project file, relative to [sourceFolderPath] (e.g.
  /// `'Song Template.als'` or `'Renders/Song Template.als'` for a nested main
  /// file). Used to locate the same file post-copy so it can be renamed and
  /// opened.
  @HiveField(3)
  final String mainFileRelativePath;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  ProjectTemplate({
    required this.id,
    required this.name,
    required this.sourceFolderPath,
    required this.mainFileRelativePath,
    required this.createdAt,
    required this.updatedAt,
  });

  ProjectTemplate copyWith({
    String? id,
    String? name,
    String? sourceFolderPath,
    String? mainFileRelativePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceFolderPath: sourceFolderPath ?? this.sourceFolderPath,
      mainFileRelativePath: mainFileRelativePath ?? this.mainFileRelativePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
