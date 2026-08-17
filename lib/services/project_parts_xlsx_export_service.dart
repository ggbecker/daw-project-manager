import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart';
import '../models/project_part.dart';
import '../utils/part_status_display.dart';

/// Writes a project's parts as a real `.xlsx` workbook — a frozen, filterable
/// header row, colour-coded take statuses and sized columns — for handing
/// recording progress to collaborators who live in a spreadsheet.
///
/// The file is assembled as OOXML by hand on top of `xml` + `archive`, both
/// already dependencies here. The obvious alternative (`package:excel`) pins
/// `archive ^3`, which this app cannot take: it is on `archive ^4` for the
/// release-ZIP feature.
///
/// Columns match [ProjectPartsCsvExportService] exactly, so a workbook exported
/// here can be edited and read straight back in by
/// [PartsSpreadsheetImportService].
class ProjectPartsXlsxExportService {
  const ProjectPartsXlsxExportService._();

  static const _mainNs =
      'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  static const _relNs =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  static const _pkgRelNs =
      'http://schemas.openxmlformats.org/package/2006/relationships';

  /// Style ids as laid out by [_stylesXml]. Kept as named constants because a
  /// worksheet refers to them only by index.
  static const _styleDefault = 0;
  static const _styleHeader = 1;
  static const _styleWrapped = 2;
  static const _styleFirstStatus = 3; // + PartTakeStatus.index

  /// Fill colours per take status, in [PartTakeStatus.values] order. Excel
  /// wants opaque ARGB. These are the light-background counterparts of the
  /// in-app badge colours in [PartTakeStatusDisplay].
  static const _statusFills = [
    'FFE4E6E8', // needed
    'FFFFE3BF', // recording
    'FFCFE4FA', // early take
    'FFCDECD2', // final take
  ];

  /// One row per part across [projects], or null when there is nothing to
  /// write — callers treat null as "no parts to export".
  static Uint8List? buildWorkbook(
    List<MusicProject> projects,
    AppLocalizations l10n,
  ) {
    final rows = <_PartRow>[];
    for (final project in projects) {
      for (final part in project.parts) {
        rows.add(_PartRow(project.displayName, part));
      }
    }
    if (rows.isEmpty) return null;

    final headers = [
      l10n.csvHeaderProject,
      l10n.csvHeaderPart,
      l10n.csvHeaderPerformer,
      l10n.csvHeaderStatus,
      l10n.csvHeaderNotes,
    ];

    final archive = Archive();
    void add(String path, String xml) {
      final bytes = utf8.encode(xml);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    add('[Content_Types].xml', _contentTypesXml());
    add('_rels/.rels', _rootRelsXml());
    add('xl/workbook.xml', _workbookXml(_sheetName(l10n)));
    add('xl/_rels/workbook.xml.rels', _workbookRelsXml());
    add('xl/styles.xml', _stylesXml());
    add('xl/worksheets/sheet1.xml', _sheetXml(headers, rows, l10n));

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// Excel rejects `[ ] : * ? / \` in a sheet name and truncates past 31
  /// characters, so a translated title is sanitized rather than trusted.
  static String _sheetName(AppLocalizations l10n) {
    final cleaned = l10n.songParts.replaceAll(RegExp(r'[\[\]:*?/\\]'), ' ').trim();
    if (cleaned.isEmpty) return 'Parts';
    return cleaned.length <= 31 ? cleaned : cleaned.substring(0, 31);
  }

  static String _contentTypesXml() {
    final b = XmlBuilder();
    b.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    b.element('Types', nest: () {
      b.attribute('xmlns',
          'http://schemas.openxmlformats.org/package/2006/content-types');
      b.element('Default', nest: () {
        b.attribute('Extension', 'rels');
        b.attribute('ContentType',
            'application/vnd.openxmlformats-package.relationships+xml');
      });
      b.element('Default', nest: () {
        b.attribute('Extension', 'xml');
        b.attribute('ContentType', 'application/xml');
      });
      void override(String part, String type) {
        b.element('Override', nest: () {
          b.attribute('PartName', part);
          b.attribute('ContentType', type);
        });
      }

      override('/xl/workbook.xml',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml');
      override('/xl/worksheets/sheet1.xml',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml');
      override('/xl/styles.xml',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml');
    });
    return b.buildDocument().toXmlString();
  }

  static String _rootRelsXml() {
    final b = XmlBuilder();
    b.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    b.element('Relationships', nest: () {
      b.attribute('xmlns', _pkgRelNs);
      b.element('Relationship', nest: () {
        b.attribute('Id', 'rId1');
        b.attribute('Type', '$_relNs/officeDocument');
        b.attribute('Target', 'xl/workbook.xml');
      });
    });
    return b.buildDocument().toXmlString();
  }

  static String _workbookXml(String sheetName) {
    final b = XmlBuilder();
    b.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    b.element('workbook', nest: () {
      b.attribute('xmlns', _mainNs);
      b.attribute('xmlns:r', _relNs);
      b.element('sheets', nest: () {
        b.element('sheet', nest: () {
          b.attribute('name', sheetName);
          b.attribute('sheetId', '1');
          b.attribute('r:id', 'rId1');
        });
      });
    });
    return b.buildDocument().toXmlString();
  }

  static String _workbookRelsXml() {
    final b = XmlBuilder();
    b.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    b.element('Relationships', nest: () {
      b.attribute('xmlns', _pkgRelNs);
      b.element('Relationship', nest: () {
        b.attribute('Id', 'rId1');
        b.attribute('Type', '$_relNs/worksheet');
        b.attribute('Target', 'worksheets/sheet1.xml');
      });
      b.element('Relationship', nest: () {
        b.attribute('Id', 'rId2');
        b.attribute('Type', '$_relNs/styles');
        b.attribute('Target', 'styles.xml');
      });
    });
    return b.buildDocument().toXmlString();
  }

  static String _stylesXml() {
    final b = XmlBuilder();
    b.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    b.element('styleSheet', nest: () {
      b.attribute('xmlns', _mainNs);

      b.element('fonts', nest: () {
        b.attribute('count', '2');
        // 0: body
        b.element('font', nest: () {
          b.element('sz', nest: () => b.attribute('val', '11'));
          b.element('name', nest: () => b.attribute('val', 'Calibri'));
        });
        // 1: header — bold, white on the dark header fill
        b.element('font', nest: () {
          b.element('b');
          b.element('sz', nest: () => b.attribute('val', '11'));
          b.element('color', nest: () => b.attribute('rgb', 'FFFFFFFF'));
          b.element('name', nest: () => b.attribute('val', 'Calibri'));
        });
      });

      b.element('fills', nest: () {
        b.attribute('count', '${2 + 1 + _statusFills.length}');
        // Excel requires these first two fills to exist, in this order.
        b.element('fill',
            nest: () => b.element('patternFill',
                nest: () => b.attribute('patternType', 'none')));
        b.element('fill',
            nest: () => b.element('patternFill',
                nest: () => b.attribute('patternType', 'gray125')));
        for (final rgb in ['FF2F3B52', ..._statusFills]) {
          b.element('fill', nest: () {
            b.element('patternFill', nest: () {
              b.attribute('patternType', 'solid');
              b.element('fgColor', nest: () => b.attribute('rgb', rgb));
              b.element('bgColor', nest: () => b.attribute('indexed', '64'));
            });
          });
        }
      });

      b.element('borders', nest: () {
        b.attribute('count', '1');
        b.element('border', nest: () {
          b.element('left');
          b.element('right');
          b.element('top');
          b.element('bottom');
          b.element('diagonal');
        });
      });

      b.element('cellStyleXfs', nest: () {
        b.attribute('count', '1');
        b.element('xf', nest: () {
          b.attribute('numFmtId', '0');
          b.attribute('fontId', '0');
          b.attribute('fillId', '0');
          b.attribute('borderId', '0');
        });
      });

      b.element('cellXfs', nest: () {
        b.attribute('count', '${3 + _statusFills.length}');
        // 0: default
        b.element('xf', nest: () {
          b.attribute('numFmtId', '0');
          b.attribute('fontId', '0');
          b.attribute('fillId', '0');
          b.attribute('borderId', '0');
          b.attribute('xfId', '0');
        });
        // 1: header
        b.element('xf', nest: () {
          b.attribute('numFmtId', '0');
          b.attribute('fontId', '1');
          b.attribute('fillId', '2');
          b.attribute('borderId', '0');
          b.attribute('xfId', '0');
          b.attribute('applyFont', '1');
          b.attribute('applyFill', '1');
          b.attribute('applyAlignment', '1');
          b.element('alignment', nest: () {
            b.attribute('vertical', 'center');
          });
        });
        // 2: wrapped body text (notes)
        b.element('xf', nest: () {
          b.attribute('numFmtId', '0');
          b.attribute('fontId', '0');
          b.attribute('fillId', '0');
          b.attribute('borderId', '0');
          b.attribute('xfId', '0');
          b.attribute('applyAlignment', '1');
          b.element('alignment', nest: () {
            b.attribute('vertical', 'top');
            b.attribute('wrapText', '1');
          });
        });
        // 3..: one per take status, filled with that status' colour
        for (var i = 0; i < _statusFills.length; i++) {
          b.element('xf', nest: () {
            b.attribute('numFmtId', '0');
            b.attribute('fontId', '0');
            b.attribute('fillId', '${3 + i}');
            b.attribute('borderId', '0');
            b.attribute('xfId', '0');
            b.attribute('applyFill', '1');
          });
        }
      });

      b.element('cellStyles', nest: () {
        b.attribute('count', '1');
        b.element('cellStyle', nest: () {
          b.attribute('name', 'Normal');
          b.attribute('xfId', '0');
          b.attribute('builtinId', '0');
        });
      });
    });
    return b.buildDocument().toXmlString();
  }

  static String _sheetXml(
    List<String> headers,
    List<_PartRow> rows,
    AppLocalizations l10n,
  ) {
    final lastRow = rows.length + 1;
    final b = XmlBuilder();
    b.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    b.element('worksheet', nest: () {
      b.attribute('xmlns', _mainNs);

      b.element('dimension', nest: () => b.attribute('ref', 'A1:E$lastRow'));

      // Freeze the header so it stays put while scrolling a long parts list.
      b.element('sheetViews', nest: () {
        b.element('sheetView', nest: () {
          b.attribute('workbookViewId', '0');
          b.element('pane', nest: () {
            b.attribute('ySplit', '1');
            b.attribute('topLeftCell', 'A2');
            b.attribute('activePane', 'bottomLeft');
            b.attribute('state', 'frozen');
          });
        });
      });

      b.element('sheetFormatPr',
          nest: () => b.attribute('defaultRowHeight', '15'));

      b.element('cols', nest: () {
        const widths = [30.0, 24.0, 22.0, 16.0, 48.0];
        for (var i = 0; i < widths.length; i++) {
          b.element('col', nest: () {
            b.attribute('min', '${i + 1}');
            b.attribute('max', '${i + 1}');
            b.attribute('width', '${widths[i]}');
            b.attribute('customWidth', '1');
          });
        }
      });

      b.element('sheetData', nest: () {
        b.element('row', nest: () {
          b.attribute('r', '1');
          for (var col = 0; col < headers.length; col++) {
            _cell(b, col, 1, headers[col], _styleHeader);
          }
        });
        for (var i = 0; i < rows.length; i++) {
          final row = rows[i];
          final rowNumber = i + 2;
          b.element('row', nest: () {
            b.attribute('r', '$rowNumber');
            _cell(b, 0, rowNumber, row.projectName, _styleDefault);
            _cell(b, 1, rowNumber, row.part.name, _styleDefault);
            _cell(b, 2, rowNumber, row.part.performer ?? '', _styleDefault);
            _cell(b, 3, rowNumber, row.part.status.label(l10n),
                _styleFirstStatus + row.part.status.index);
            _cell(b, 4, rowNumber, row.part.notes ?? '', _styleWrapped);
          });
        }
      });

      // Must follow sheetData per the OOXML worksheet element order.
      b.element('autoFilter',
          nest: () => b.attribute('ref', 'A1:E$lastRow'));

      // A real dropdown on the Status column. Whoever fills this sheet in has
      // to pick one of the four statuses, so the file comes back in a shape
      // the importer can actually read instead of holding free text.
      b.element('dataValidations', nest: () {
        b.attribute('count', '1');
        b.element('dataValidation', nest: () {
          b.attribute('type', 'list');
          b.attribute('allowBlank', '1');
          b.attribute('showInputMessage', '1');
          b.attribute('showErrorMessage', '1');
          b.attribute('sqref', 'D2:D$lastRow');
          b.element('formula1', nest: () {
            // An inline list literal: "a,b,c" — quoted, and with any comma in
            // a translated label swapped out, since the commas separate items.
            final options = PartTakeStatus.values
                .map((s) => s.label(l10n).replaceAll(',', ' '))
                .join(',');
            b.text('"$options"');
          });
        });
      });
    });
    return b.buildDocument().toXmlString();
  }

  /// Emits one inline-string cell. Inline strings avoid a sharedStrings part
  /// entirely, at the cost of a slightly larger file — a fine trade for a
  /// parts list, and one fewer part to keep consistent.
  static void _cell(
    XmlBuilder b,
    int columnIndex,
    int rowNumber,
    String value,
    int styleIndex,
  ) {
    b.element('c', nest: () {
      b.attribute('r', '${columnLetter(columnIndex)}$rowNumber');
      if (styleIndex != 0) b.attribute('s', '$styleIndex');
      if (value.isEmpty) return; // an empty cell carries style but no value
      b.attribute('t', 'inlineStr');
      b.element('is', nest: () {
        b.element('t', nest: () {
          // Leading/trailing spaces are stripped by Excel without this.
          b.attribute('xml:space', 'preserve');
          b.text(value);
        });
      });
    });
  }

  /// 0 → A, 25 → Z, 26 → AA. Only ever called with small indices here, but
  /// written generally so it stays correct if columns are added.
  static String columnLetter(int index) {
    var i = index;
    final buffer = StringBuffer();
    do {
      buffer.write(String.fromCharCode(65 + (i % 26)));
      i = i ~/ 26 - 1;
    } while (i >= 0);
    return String.fromCharCodes(buffer.toString().codeUnits.reversed);
  }

  static String _sanitizeForFileName(String name) =>
      name.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_').trim();

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String suggestedFileNameFor(MusicProject project) {
    final safeName = _sanitizeForFileName(project.displayName);
    return '${safeName.isEmpty ? 'project' : safeName}_parts.xlsx';
  }

  static String suggestedBulkFileName() =>
      'daw_project_manager_parts_${_formatDate(DateTime.now())}.xlsx';
}

class _PartRow {
  final String projectName;
  final ProjectPart part;

  const _PartRow(this.projectName, this.part);
}
