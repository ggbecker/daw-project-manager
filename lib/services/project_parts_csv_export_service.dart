import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart';
import '../models/project_part.dart';
import '../utils/part_status_display.dart';

/// Formats a project's [ProjectPart]s as CSV, so recording progress can be
/// opened in a spreadsheet and handed to people who don't run this app.
class ProjectPartsCsvExportService {
  const ProjectPartsCsvExportService._();

  /// Excel and Numbers only recognise a UTF-8 CSV when it starts with a BOM;
  /// without it, accented performer names arrive mangled.
  static const String utf8Bom = '﻿';

  /// One row per part of [project]. Returns an empty string when the project
  /// has no parts, so callers can treat "" as "nothing to write".
  static String formatProject(MusicProject project, AppLocalizations l10n) =>
      formatProjects([project], l10n);

  /// One row per part across [projects], each row carrying its project name so
  /// the whole library reads as a single flat sheet. Projects without parts
  /// contribute no rows.
  static String formatProjects(
    List<MusicProject> projects,
    AppLocalizations l10n,
  ) {
    final rows = <List<String>>[];
    for (final project in projects) {
      for (final part in project.parts) {
        rows.add([
          project.displayName,
          part.name,
          part.performer ?? '',
          part.status.label(l10n),
          part.notes ?? '',
        ]);
      }
    }
    if (rows.isEmpty) return '';

    final buffer = StringBuffer(utf8Bom)
      ..writeln(_row([
        l10n.csvHeaderProject,
        l10n.csvHeaderPart,
        l10n.csvHeaderPerformer,
        l10n.csvHeaderStatus,
        l10n.csvHeaderNotes,
      ]));
    for (final row in rows) {
      buffer.writeln(_row(row));
    }
    return buffer.toString();
  }

  /// How many part rows [formatProjects] would write for [projects].
  static int partCount(List<MusicProject> projects) =>
      projects.fold(0, (sum, p) => sum + p.parts.length);

  static String _row(List<String> fields) => fields.map(_escape).join(',');

  /// RFC 4180 quoting: a field is quoted when it contains a comma, a quote or
  /// a line break, and embedded quotes are doubled. Newlines inside a quoted
  /// field are legal CSV and are kept as-is so multi-line part notes survive.
  static String _escape(String field) {
    if (!field.contains(',') &&
        !field.contains('"') &&
        !field.contains('\n') &&
        !field.contains('\r')) {
      return field;
    }
    return '"${field.replaceAll('"', '""')}"';
  }

  static String _sanitizeForFileName(String name) =>
      name.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_').trim();

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Suggested file name for a single-project parts export.
  static String suggestedFileNameFor(MusicProject project) {
    final safeName = _sanitizeForFileName(project.displayName);
    return '${safeName.isEmpty ? 'project' : safeName}_parts.csv';
  }

  /// Suggested file name for an all-projects parts export.
  static String suggestedBulkFileName() =>
      'daw_project_manager_parts_${_formatDate(DateTime.now())}.csv';
}
