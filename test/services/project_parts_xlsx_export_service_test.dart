import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:daw_project_manager/generated/l10n/app_localizations_en.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/services/parts_spreadsheet_import_service.dart';
import 'package:daw_project_manager/services/project_parts_xlsx_export_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

import '../helpers/test_factories.dart';

void main() {
  final l10n = AppLocalizationsEn();

  Archive open(List<int> bytes) => ZipDecoder().decodeBytes(bytes);

  String partOf(Archive archive, String name) {
    final file = archive.files.firstWhere((f) => f.name == name);
    return utf8.decode(file.content as List<int>);
  }

  group('ProjectPartsXlsxExportService.buildWorkbook', () {
    test('returns null when there is nothing to export', () {
      expect(
        ProjectPartsXlsxExportService.buildWorkbook(
          [TestFactories.makeProject()],
          l10n,
        ),
        isNull,
      );
      expect(
        ProjectPartsXlsxExportService.buildWorkbook(const [], l10n),
        isNull,
      );
    });

    test('produces a zip with every part an xlsx package requires', () {
      final project = TestFactories.makeProject(
        parts: [TestFactories.makePart(id: 'p1', name: 'Drums')],
      );

      final archive =
          open(ProjectPartsXlsxExportService.buildWorkbook([project], l10n)!);

      expect(
        archive.files.map((f) => f.name).toSet(),
        containsAll([
          '[Content_Types].xml',
          '_rels/.rels',
          'xl/workbook.xml',
          'xl/_rels/workbook.xml.rels',
          'xl/styles.xml',
          'xl/worksheets/sheet1.xml',
        ]),
      );
    });

    test('every part of the package is well-formed XML', () {
      final project = TestFactories.makeProject(
        parts: [TestFactories.makePart(id: 'p1', name: 'Drums')],
      );

      final archive =
          open(ProjectPartsXlsxExportService.buildWorkbook([project], l10n)!);

      for (final file in archive.files) {
        expect(
          () => XmlDocument.parse(utf8.decode(file.content as List<int>)),
          returnsNormally,
          reason: '${file.name} is not parseable XML',
        );
      }
    });

    test('writes a header row plus one row per part', () {
      final project = TestFactories.makeProject(
        customDisplayName: 'Banger',
        parts: [
          TestFactories.makePart(id: 'p1', name: 'Drums', performer: 'Alex'),
          TestFactories.makePart(id: 'p2', name: 'Bass', performer: 'Sam'),
        ],
      );

      final sheet = XmlDocument.parse(partOf(
        open(ProjectPartsXlsxExportService.buildWorkbook([project], l10n)!),
        'xl/worksheets/sheet1.xml',
      ));

      expect(sheet.findAllElements('row').length, 3);
      expect(sheet.toXmlString(), contains('Project'));
      expect(sheet.toXmlString(), contains('Banger'));
      expect(sheet.toXmlString(), contains('Drums'));
      expect(sheet.toXmlString(), contains('Alex'));
    });

    test('freezes the header row and puts a filter over the used range', () {
      final project = TestFactories.makeProject(parts: [
        TestFactories.makePart(id: 'p1'),
        TestFactories.makePart(id: 'p2', name: 'Bass'),
      ]);

      final xml = partOf(
        open(ProjectPartsXlsxExportService.buildWorkbook([project], l10n)!),
        'xl/worksheets/sheet1.xml',
      );

      expect(xml, contains('state="frozen"'));
      expect(xml, contains('ySplit="1"'));
      // Header row + two parts.
      expect(xml, contains('<autoFilter ref="A1:E3"/>'));
    });

    test('puts a status dropdown on the column so it comes back importable',
        () {
      final project = TestFactories.makeProject(parts: [
        TestFactories.makePart(id: 'p1'),
        TestFactories.makePart(id: 'p2', name: 'Bass'),
      ]);

      final xml = partOf(
        open(ProjectPartsXlsxExportService.buildWorkbook([project], l10n)!),
        'xl/worksheets/sheet1.xml',
      );

      expect(xml, contains('<dataValidation'));
      expect(xml, contains('sqref="D2:D3"'));
      expect(
        xml,
        contains('<formula1>"Needed,Recording,Early take,Final take"</formula1>'),
      );
    });

    test('gives each take status its own style so the column reads at a glance',
        () {
      final project = TestFactories.makeProject(parts: [
        TestFactories.makePart(id: 'p1', status: PartTakeStatus.needed),
        TestFactories.makePart(
            id: 'p2', name: 'Bass', status: PartTakeStatus.finalTake),
      ]);

      final sheet = XmlDocument.parse(partOf(
        open(ProjectPartsXlsxExportService.buildWorkbook([project], l10n)!),
        'xl/worksheets/sheet1.xml',
      ));

      String styleOf(String ref) => sheet
          .findAllElements('c')
          .firstWhere((c) => c.getAttribute('r') == ref)
          .getAttribute('s')!;

      expect(styleOf('D2'), isNot(styleOf('D3')));
    });

    test('escapes characters that would otherwise break the XML', () {
      final project = TestFactories.makeProject(
        customDisplayName: 'Rock & <Roll>',
        parts: [
          TestFactories.makePart(id: 'p1', notes: 'use the "big" mic & go'),
        ],
      );

      final xml = partOf(
        open(ProjectPartsXlsxExportService.buildWorkbook([project], l10n)!),
        'xl/worksheets/sheet1.xml',
      );

      expect(() => XmlDocument.parse(xml), returnsNormally);
      expect(xml, contains('Rock &amp; &lt;Roll>'));
    });

    test('round-trips back through the spreadsheet importer', () {
      final project = TestFactories.makeProject(
        customDisplayName: 'Banger',
        parts: [
          TestFactories.makePart(
            id: 'p1',
            name: 'Drums',
            performer: 'Alex',
            status: PartTakeStatus.finalTake,
            notes: 'keeper',
          ),
          TestFactories.makePart(
              id: 'p2', name: 'Bass', performer: null, notes: null),
        ],
      );

      final bytes =
          ProjectPartsXlsxExportService.buildWorkbook([project], l10n)!;
      final rows = PartsSpreadsheetImportService.parseRows(bytes, 'parts.xlsx');
      final result = PartsSpreadsheetImportService.importInto(
        existing: const [],
        rows: rows,
        projectName: 'Banger',
        l10n: l10n,
      );

      expect(result.added, 2);
      expect(result.parts.map((p) => p.name), ['Drums', 'Bass']);
      expect(result.parts.first.performer, 'Alex');
      expect(result.parts.first.status, PartTakeStatus.finalTake);
      expect(result.parts.first.notes, 'keeper');
      expect(result.parts.last.performer, isNull);
    });
  });

  group('column letters and file names', () {
    test('columnLetter counts past Z the way a spreadsheet does', () {
      expect(ProjectPartsXlsxExportService.columnLetter(0), 'A');
      expect(ProjectPartsXlsxExportService.columnLetter(4), 'E');
      expect(ProjectPartsXlsxExportService.columnLetter(25), 'Z');
      expect(ProjectPartsXlsxExportService.columnLetter(26), 'AA');
      expect(ProjectPartsXlsxExportService.columnLetter(27), 'AB');
      expect(ProjectPartsXlsxExportService.columnLetter(51), 'AZ');
      expect(ProjectPartsXlsxExportService.columnLetter(52), 'BA');
    });

    test('suggested names end in .xlsx', () {
      expect(
        ProjectPartsXlsxExportService.suggestedFileNameFor(
          TestFactories.makeProject(customDisplayName: 'My Song'),
        ),
        'My Song_parts.xlsx',
      );
      expect(
        ProjectPartsXlsxExportService.suggestedBulkFileName(),
        endsWith('.xlsx'),
      );
    });
  });
}
