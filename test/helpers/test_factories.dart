import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/todo_item.dart';

/// Factory helpers for creating consistent test fixtures.
class TestFactories {
  /// A recent, fully-populated [MusicProject] with all fields set.
  static MusicProject makeProject({
    String id = 'test-id-1',
    String filePath = '/Users/test/Projects/MyProject.als',
    String fileName = 'MyProject.als',
    int fileSizeBytes = 1024000,
    DateTime? lastModifiedAt,
    DateTime? fileCreatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String status = 'Mixing',
    String? customDisplayName,
    String? dawType = 'Ableton Live',
    String? dawVersion = '11',
    double? bpm,
    String? musicalKey,
    String? notes,
    List<TodoItem>? todos,
    DateTime? deadline,
    bool hidden = false,
    String? previewSongPath,
    String? previewSongFileName,
    DateTime? statusChangedAt,
    int totalWorkSeconds = 0,
  }) {
    return MusicProject(
      id: id,
      filePath: filePath,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      lastModifiedAt: lastModifiedAt ?? DateTime(2025, 1, 15, 10, 30),
      fileExtension: '.als',
      createdAt: createdAt ?? DateTime(2024, 6, 1, 12, 0),
      updatedAt: updatedAt ?? DateTime(2025, 1, 14, 9, 0),
      status: status,
      customDisplayName: customDisplayName,
      dawType: dawType,
      dawVersion: dawVersion,
      fileCreatedAt: fileCreatedAt,
      bpm: bpm,
      musicalKey: musicalKey,
      notes: notes,
      todos: todos ?? const [],
      deadline: deadline,
      hidden: hidden,
      previewSongPath: previewSongPath,
      previewSongFileName: previewSongFileName,
      statusChangedAt: statusChangedAt,
      totalWorkSeconds: totalWorkSeconds,
    );
  }

  static TodoItem makeTodo({
    String id = 'todo-1',
    String text = 'Mix the kick drum',
    bool completed = false,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id,
      text: text,
      completed: completed,
      createdAt: createdAt ?? DateTime(2025, 1, 10),
    );
  }

  /// Minimal project with only required fields.
  static MusicProject makeMinimalProject({String id = 'min-id'}) {
    return MusicProject(
      id: id,
      filePath: '/test/$id.als',
      fileName: '$id.als',
      fileSizeBytes: 512,
      lastModifiedAt: DateTime(2025, 3, 1),
      fileExtension: '.als',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );
  }
}
