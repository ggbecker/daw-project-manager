import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/project_part.dart';
import '../utils/part_status_display.dart';

/// Outcome of folding a spreadsheet into a project's parts list.
class PartsImportResult {
  /// The full parts list to save — existing parts (updated in place) followed
  /// by any parts the sheet introduced.
  final List<ProjectPart> parts;

  /// Parts the sheet introduced that the project did not have.
  final int added;

  /// Existing parts whose performer, status or notes the sheet changed.
  final int updated;

  const PartsImportResult({
    required this.parts,
    required this.added,
    required this.updated,
  });

  bool get isEmpty => added == 0 && updated == 0;
}

/// Reads a parts list back out of a `.csv` or `.xlsx` file — the other half of
/// [ProjectPartsCsvExportService] / [ProjectPartsXlsxExportService], so a list
/// can be exported, filled in by a bandmate in a spreadsheet, and folded back
/// into the project.
class PartsSpreadsheetImportService {
  const PartsSpreadsheetImportService._();

  static const _uuid = Uuid();

  /// File extensions [parseRows] understands, for the file picker.
  static const supportedExtensions = ['csv', 'xlsx'];

  /// Splits a spreadsheet into rows of trimmed cell strings.
  ///
  /// [fileName] only decides which parser to use; anything that isn't `.xlsx`
  /// is treated as delimited text.
  static List<List<String>> parseRows(Uint8List bytes, String fileName) {
    return fileName.toLowerCase().endsWith('.xlsx')
        ? _parseXlsx(bytes)
        : _parseDelimitedText(_decodeText(bytes));
  }

  /// Folds [rows] into [existing].
  ///
  /// A row is matched to an existing part by name, case- and
  /// whitespace-insensitively; matches are updated in place and everything
  /// else is appended, so re-importing an edited export updates rather than
  /// duplicates. Only columns actually present in the file are touched — a
  /// sheet with no Notes column leaves existing notes alone, while a sheet
  /// that has the column and leaves a cell blank clears them.
  ///
  /// When the file carries a Project column and at least one row names
  /// [projectName], only those rows are used; when nothing matches, the whole
  /// file is treated as a plain parts list (the user picked it deliberately).
  static PartsImportResult importInto({
    required List<ProjectPart> existing,
    required List<List<String>> rows,
    required String projectName,
    required AppLocalizations l10n,
  }) {
    final nonEmpty = rows.where((r) => r.any((c) => c.isNotEmpty)).toList();
    if (nonEmpty.isEmpty) {
      return PartsImportResult(parts: existing, added: 0, updated: 0);
    }

    final columns = _ColumnMap.detect(nonEmpty.first, l10n);
    final dataRows = columns.hasHeaderRow ? nonEmpty.skip(1).toList() : nonEmpty;

    final scoped = columns.project == null
        ? dataRows
        : () {
            final matching = dataRows
                .where((r) =>
                    _at(r, columns.project).toLowerCase() ==
                    projectName.trim().toLowerCase())
                .toList();
            return matching.isEmpty ? dataRows : matching;
          }();

    final statuses = _statusLookup(l10n);
    final result = [...existing];
    var added = 0;
    var updated = 0;

    for (final row in scoped) {
      final name = _at(row, columns.name);
      if (name.isEmpty) continue;

      final index = result.indexWhere(
        (p) => p.name.trim().toLowerCase() == name.toLowerCase(),
      );

      final performer = columns.performer == null
          ? null
          : _at(row, columns.performer);
      final notes = columns.notes == null ? null : _at(row, columns.notes);
      final status = columns.status == null
          ? null
          : statuses[_at(row, columns.status).toLowerCase()];

      if (index == -1) {
        result.add(ProjectPart(
          id: _uuid.v4(),
          name: name,
          performer: (performer == null || performer.isEmpty) ? null : performer,
          status: status ?? PartTakeStatus.needed,
          notes: (notes == null || notes.isEmpty) ? null : notes,
        ));
        added++;
        continue;
      }

      final before = result[index];
      final after = before.copyWith(
        name: name,
        performer: performer == null || performer.isEmpty ? null : performer,
        clearPerformer: performer != null && performer.isEmpty,
        status: status,
        notes: notes == null || notes.isEmpty ? null : notes,
        clearNotes: notes != null && notes.isEmpty,
      );
      if (after != before) {
        result[index] = after;
        updated++;
      }
    }

    return PartsImportResult(parts: result, added: added, updated: updated);
  }

  static String _at(List<String> row, int? index) =>
      (index == null || index >= row.length) ? '' : row[index].trim();

  /// Every spelling of a take status this importer accepts: the stable storage
  /// keys plus the status labels of *every* UI language.
  ///
  /// All languages, not just the running one, because the whole point of the
  /// export is handing the sheet to someone else — and a producer running the
  /// app in Portuguese routinely sends a sheet to a collaborator whose app is
  /// in English. The current locale is applied last so it wins any collision.
  static Map<String, PartTakeStatus> _statusLookup(AppLocalizations l10n) {
    final lookup = <String, PartTakeStatus>{
      for (final status in PartTakeStatus.values)
        status.key.toLowerCase(): status,
    };
    for (final other in allLocalizations()) {
      for (final status in PartTakeStatus.values) {
        lookup[status.label(other).toLowerCase()] = status;
      }
    }
    for (final status in PartTakeStatus.values) {
      lookup[status.label(l10n).toLowerCase()] = status;
    }
    return lookup;
  }

  /// Every locale the app ships, so headers and statuses written by a
  /// collaborator running a different language are still understood.
  /// Any locale that fails to load is skipped rather than failing the import.
  static List<AppLocalizations> allLocalizations() {
    final all = <AppLocalizations>[];
    for (final locale in AppLocalizations.supportedLocales) {
      try {
        all.add(lookupAppLocalizations(locale));
      } catch (_) {
        continue;
      }
    }
    return all;
  }

  // ── CSV ────────────────────────────────────────────────────────────────────

  static String _decodeText(Uint8List bytes) {
    // Strip a UTF-8 BOM — every spreadsheet app writes one, and left in place
    // it becomes part of the first header cell and defeats header detection.
    final text = utf8.decode(bytes, allowMalformed: true);
    return text.startsWith('﻿') ? text.substring(1) : text;
  }

  /// RFC 4180 parsing: quoted fields may contain the delimiter, newlines, and
  /// doubled quotes. The delimiter is sniffed per file so semicolon CSVs (what
  /// Excel writes in most of Europe) work too.
  static List<List<String>> _parseDelimitedText(String text) {
    final delimiter = _sniffDelimiter(text);
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;

    void endField() {
      row.add(field.toString());
      field.clear();
    }

    void endRow() {
      endField();
      rows.add(row);
      row = <String>[];
    }

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(char);
        }
        continue;
      }
      if (char == '"') {
        inQuotes = true;
      } else if (char == delimiter) {
        endField();
      } else if (char == '\n') {
        endRow();
      } else if (char == '\r') {
        // Swallow CR; the following LF ends the row.
      } else {
        field.write(char);
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) endRow();

    return rows;
  }

  /// Picks whichever of `,` or `;` appears more often outside quotes.
  static String _sniffDelimiter(String text) {
    var commas = 0;
    var semicolons = 0;
    var inQuotes = false;
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (!inQuotes) {
        if (char == ',') commas++;
        if (char == ';') semicolons++;
      }
    }
    return semicolons > commas ? ';' : ',';
  }

  // ── XLSX ───────────────────────────────────────────────────────────────────

  /// Reads the first worksheet of an xlsx as rows of strings.
  ///
  /// Deliberately partial: cell values only, no formulas, formats or dates.
  /// A parts sheet is text, and anything richer degrades to the displayed
  /// string rather than failing the import.
  static List<List<String>> _parseXlsx(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    ArchiveFile? fileNamed(String name) {
      for (final file in archive.files) {
        if (file.name == name) return file;
      }
      return null;
    }

    String? contentOf(String name) {
      final file = fileNamed(name);
      if (file == null) return null;
      return utf8.decode(file.content as List<int>, allowMalformed: true);
    }

    final sharedStrings = <String>[];
    final sharedXml = contentOf('xl/sharedStrings.xml');
    if (sharedXml != null) {
      for (final si in XmlDocument.parse(sharedXml).findAllElements('si')) {
        // Runs (<r><t>…</t></r>) split a single string across elements.
        sharedStrings.add(
          si.findAllElements('t').map((t) => t.innerText).join(),
        );
      }
    }

    final sheetPath = _firstSheetPath(archive, contentOf);
    final sheetXml = sheetPath == null ? null : contentOf(sheetPath);
    if (sheetXml == null) return const [];

    final rows = <List<String>>[];
    for (final rowNode in XmlDocument.parse(sheetXml).findAllElements('row')) {
      final cells = <int, String>{};
      var widest = -1;
      for (final cell in rowNode.findElements('c')) {
        final ref = cell.getAttribute('r');
        final column = ref == null ? cells.length : _columnIndexOf(ref);
        final type = cell.getAttribute('t');
        String value;
        if (type == 'inlineStr') {
          value = cell.findAllElements('t').map((t) => t.innerText).join();
        } else {
          final raw = cell.findElements('v').firstOrNull?.innerText ?? '';
          if (type == 's') {
            final index = int.tryParse(raw);
            value = (index != null && index < sharedStrings.length)
                ? sharedStrings[index]
                : '';
          } else {
            value = raw;
          }
        }
        cells[column] = value;
        if (column > widest) widest = column;
      }
      rows.add([
        for (var i = 0; i <= widest; i++) cells[i] ?? '',
      ]);
    }
    return rows;
  }

  /// Resolves the first sheet's part path via the workbook relationships,
  /// falling back to the conventional location when the rels are unusable.
  static String? _firstSheetPath(
    Archive archive,
    String? Function(String) contentOf,
  ) {
    try {
      final workbook = contentOf('xl/workbook.xml');
      final rels = contentOf('xl/_rels/workbook.xml.rels');
      if (workbook != null && rels != null) {
        final sheet =
            XmlDocument.parse(workbook).findAllElements('sheet').firstOrNull;
        final relId = sheet?.getAttribute('r:id') ?? sheet?.getAttribute('id');
        if (relId != null) {
          for (final rel
              in XmlDocument.parse(rels).findAllElements('Relationship')) {
            if (rel.getAttribute('Id') != relId) continue;
            final target = rel.getAttribute('Target');
            if (target == null) break;
            final normalized =
                target.startsWith('/') ? target.substring(1) : 'xl/$target';
            if (archive.files.any((f) => f.name == normalized)) {
              return normalized;
            }
          }
        }
      }
    } catch (_) {
      // Fall through to the conventional path below.
    }
    return archive.files.any((f) => f.name == 'xl/worksheets/sheet1.xml')
        ? 'xl/worksheets/sheet1.xml'
        : archive.files
            .where((f) => f.name.startsWith('xl/worksheets/'))
            .map((f) => f.name)
            .firstOrNull;
  }

  /// `'BC12'` → 54. Returns 0 for a reference with no column letters.
  static int _columnIndexOf(String cellRef) {
    var index = 0;
    var sawLetter = false;
    for (final unit in cellRef.codeUnits) {
      if (unit < 65 || unit > 90) break;
      index = index * 26 + (unit - 64);
      sawLetter = true;
    }
    return sawLetter ? index - 1 : 0;
  }
}

/// Which spreadsheet column holds which field.
class _ColumnMap {
  final int? project;
  final int? name;
  final int? performer;
  final int? status;
  final int? notes;
  final bool hasHeaderRow;

  const _ColumnMap({
    this.project,
    this.name,
    this.performer,
    this.status,
    this.notes,
    required this.hasHeaderRow,
  });

  /// Reads [firstRow] as a header when any cell is a recognizable column name;
  /// otherwise assumes the app's own column order minus the project column,
  /// which is the shape someone typing a list from scratch would produce.
  ///
  /// Header names are recognized in every UI language, not just the running
  /// one — the sheet is meant to be filled in by someone else, who may well
  /// have exported or be reading it in a different language.
  static _ColumnMap detect(List<String> firstRow, AppLocalizations l10n) {
    int? find(List<String> aliases) {
      for (var i = 0; i < firstRow.length; i++) {
        if (aliases.contains(firstRow[i].trim().toLowerCase())) return i;
      }
      return null;
    }

    String low(String s) => s.trim().toLowerCase();

    final translations = [
      l10n,
      ...PartsSpreadsheetImportService.allLocalizations(),
    ];
    List<String> headers(
      String Function(AppLocalizations) pick,
      List<String> extras,
    ) =>
        [...translations.map((t) => low(pick(t))), ...extras];

    final project = find(headers(
        (t) => t.csvHeaderProject, ['project', 'song', 'track']));
    final name = find([
      ...headers((t) => t.csvHeaderPart, ['part', 'instrument']),
      ...translations.map((t) => low(t.partNameLabel)),
    ]);
    final performer = find(headers((t) => t.csvHeaderPerformer,
        ['performer', 'musician', 'player']));
    final status = find([
      ...headers((t) => t.csvHeaderStatus, ['status', 'take']),
      ...translations.map((t) => low(t.partStatusLabel)),
    ]);
    final notes =
        find(headers((t) => t.csvHeaderNotes, ['notes', 'comments']));

    final recognized = [project, name, performer, status, notes]
        .where((i) => i != null)
        .isNotEmpty;

    if (!recognized) {
      return const _ColumnMap(
        name: 0,
        performer: 1,
        status: 2,
        notes: 3,
        hasHeaderRow: false,
      );
    }

    return _ColumnMap(
      project: project,
      // A header row that names a project column but no part column still has
      // to put the part somewhere; the column after the project is the only
      // sensible guess, and column 0 otherwise.
      name: name ?? (project == 0 ? 1 : 0),
      performer: performer,
      status: status,
      notes: notes,
      hasHeaderRow: true,
    );
  }
}
