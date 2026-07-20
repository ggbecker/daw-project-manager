import '../models/music_project.dart';

/// Formats [MusicProject] data as human-readable plain text, so a record of a
/// project survives even after its DAW file and library entry are gone.
class ProjectTextExportService {
  const ProjectTextExportService._();

  /// A single project's info as plain text.
  static String formatProject(MusicProject project) {
    final buffer = StringBuffer();
    _writeProject(buffer, project);
    return buffer.toString();
  }

  /// Every project's info as one plain text document, in the given order.
  static String formatProjects(List<MusicProject> projects) {
    final buffer = StringBuffer()
      ..writeln('DAW PROJECT MANAGER — PROJECT EXPORT')
      ..writeln('Exported: ${_formatDateTime(DateTime.now())}')
      ..writeln('Total projects: ${projects.length}')
      ..writeln();
    for (final project in projects) {
      buffer.writeln('=' * 80);
      _writeProject(buffer, project);
      buffer.writeln();
    }
    return buffer.toString();
  }

  static void _writeProject(StringBuffer buffer, MusicProject project) {
    buffer
      ..writeln('Project: ${project.displayName}')
      ..writeln('-' * 80);

    if (project.dawType != null && project.dawType!.isNotEmpty) {
      final version = project.dawVersion;
      buffer.writeln('DAW: ${project.dawType}${version != null && version.isNotEmpty ? ' $version' : ''}');
    }
    buffer.writeln('Status: ${project.status}');
    if (project.bpm != null) {
      buffer.writeln('BPM: ${_formatBpm(project.bpm!)}');
    }
    if (project.musicalKey != null && project.musicalKey!.isNotEmpty) {
      final camelot = project.camelotCode;
      buffer.writeln('Key: ${project.musicalKey}${camelot != null ? ' (Camelot $camelot)' : ''}');
    }
    buffer
      ..writeln('File path: ${project.filePath}')
      ..writeln('File size: ${_formatFileSize(project.fileSizeBytes)}');
    if (project.fileCreatedAt != null) {
      buffer.writeln('File created: ${_formatDate(project.fileCreatedAt!)}');
    }
    buffer
      ..writeln('Added to library: ${_formatDate(project.createdAt)}')
      ..writeln('Last modified: ${_formatDate(project.lastModifiedAt)}');
    if (project.deadline != null) {
      final status = project.deadlineStatus;
      buffer.writeln('Deadline: ${_formatDate(project.deadline!)}${status != null ? ' ($status)' : ''}');
    }
    if (project.totalWorkSeconds > 0) {
      buffer.writeln('Total time worked: ${_formatDuration(project.totalWorkSeconds)}');
    }

    final notes = project.notes?.trim();
    if (notes != null && notes.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Notes:');
      for (final line in notes.split('\n')) {
        buffer.writeln('  $line');
      }
    }

    if (project.todos.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('To-dos:');
      for (final todo in project.todos) {
        buffer.writeln('  [${todo.completed ? 'x' : ' '}] ${todo.text}');
      }
    }

    if (project.sessions.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Work sessions (${project.sessions.length}):');
      for (final session in project.sessions) {
        final phase = session.phase != null && session.phase!.isNotEmpty ? ' [${session.phase}]' : '';
        buffer.writeln(
          '  ${_formatDateTime(session.startedAt)} - ${_formatDateTime(session.endedAt)} '
          '(${_formatDuration(session.durationSeconds)})$phase',
        );
      }
    }
  }

  static String _formatBpm(double bpm) =>
      bpm == bpm.roundToDouble() ? bpm.toStringAsFixed(0) : bpm.toStringAsFixed(2);

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _formatDateTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)} $h:$min';
  }

  static String _formatFileSize(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;
    if (bytes < kb) return '$bytes B';
    if (bytes < mb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    if (bytes < gb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / gb).toStringAsFixed(2)} GB';
  }

  static String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m';
    return '${totalSeconds}s';
  }

  static String _sanitizeForFileName(String name) =>
      name.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_').trim();

  /// Suggested file name for a single-project export.
  static String suggestedFileNameFor(MusicProject project) {
    final safeName = _sanitizeForFileName(project.displayName);
    return '${safeName.isEmpty ? 'project' : safeName}_info.txt';
  }

  /// Suggested file name for a bulk, all-projects export.
  static String suggestedBulkFileName() =>
      'daw_project_manager_projects_${_formatDate(DateTime.now())}.txt';
}
