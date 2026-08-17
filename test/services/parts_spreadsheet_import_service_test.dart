import 'dart:convert';
import 'dart:typed_data';

import 'package:daw_project_manager/generated/l10n/app_localizations_en.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/services/parts_spreadsheet_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_factories.dart';

void main() {
  final l10n = AppLocalizationsEn();

  Uint8List csv(String text) => Uint8List.fromList(utf8.encode(text));

  List<List<String>> rowsOf(String text) =>
      PartsSpreadsheetImportService.parseRows(csv(text), 'parts.csv');

  PartsImportResult importCsv(
    String text, {
    List<ProjectPart> existing = const [],
    String projectName = 'Banger',
  }) =>
      PartsSpreadsheetImportService.importInto(
        existing: existing,
        rows: rowsOf(text),
        projectName: projectName,
        l10n: l10n,
      );

  group('parseRows — CSV', () {
    test('splits plain comma-separated rows', () {
      expect(rowsOf('a,b,c\n1,2,3'), [
        ['a', 'b', 'c'],
        ['1', '2', '3'],
      ]);
    });

    test('keeps commas and newlines inside quoted fields', () {
      final rows = rowsOf('Part,Notes\nDrums,"kick, snare\nand hats"');
      expect(rows[1], ['Drums', 'kick, snare\nand hats']);
    });

    test('unescapes doubled quotes', () {
      expect(rowsOf('Part,Notes\nDrums,"the ""big"" fill"')[1].last,
          'the "big" fill');
    });

    test('handles CRLF line endings', () {
      expect(rowsOf('a,b\r\n1,2'), [
        ['a', 'b'],
        ['1', '2'],
      ]);
    });

    test('strips a UTF-8 BOM so the first header is still recognized', () {
      final rows = PartsSpreadsheetImportService.parseRows(
        csv('﻿Project,Part\nBanger,Drums'),
        'parts.csv',
      );
      expect(rows.first.first, 'Project');
    });

    test('reads semicolon-delimited files, as Excel writes in much of Europe',
        () {
      expect(rowsOf('Part;Performer\nDrums;Alex')[1], ['Drums', 'Alex']);
    });
  });

  group('importInto — column detection', () {
    test('maps columns from a header row in any order', () {
      final result = importCsv(
        'Notes,Status,Part,Performer\nkeeper,Final take,Drums,Alex',
      );

      final part = result.parts.single;
      expect(part.name, 'Drums');
      expect(part.performer, 'Alex');
      expect(part.status, PartTakeStatus.finalTake);
      expect(part.notes, 'keeper');
    });

    test('accepts common alternative header names', () {
      final result = importCsv('Instrument,Musician\nRhodes,Nina');

      expect(result.parts.single.name, 'Rhodes');
      expect(result.parts.single.performer, 'Nina');
    });

    test('falls back to part/performer/status/notes order with no header', () {
      final result = importCsv('Drums,Alex,Final take,keeper');

      final part = result.parts.single;
      expect(part.name, 'Drums');
      expect(part.performer, 'Alex');
      expect(part.status, PartTakeStatus.finalTake);
      expect(part.notes, 'keeper');
    });

    test('skips blank rows and rows with no part name', () {
      final result = importCsv('Part,Performer\n\nDrums,Alex\n,Sam\n');

      expect(result.parts.map((p) => p.name), ['Drums']);
      expect(result.added, 1);
    });
  });

  group('importInto — project scoping', () {
    const sheet = 'Project,Part\n'
        'Banger,Drums\n'
        'Other Song,Strings\n';

    test('keeps only rows naming this project when the sheet lists several', () {
      final result = importCsv(sheet, projectName: 'Banger');

      expect(result.parts.map((p) => p.name), ['Drums']);
    });

    test('matches the project name case-insensitively', () {
      final result = importCsv(sheet, projectName: 'banger');

      expect(result.parts.map((p) => p.name), ['Drums']);
    });

    test('imports everything when no row names this project', () {
      // The user picked this file for this song on purpose — a deliberate
      // copy from another song should not silently import nothing.
      final result = importCsv(sheet, projectName: 'Third Song');

      expect(result.parts.map((p) => p.name), ['Drums', 'Strings']);
    });
  });

  group('importInto — merging with existing parts', () {
    test('updates a part that already exists instead of duplicating it', () {
      final existing = [
        TestFactories.makePart(id: 'p1', name: 'Drums', performer: 'Alex'),
      ];

      final result = importCsv(
        'Part,Performer,Status\nDrums,Alex,Final take',
        existing: existing,
      );

      expect(result.parts.length, 1);
      expect(result.parts.single.id, 'p1', reason: 'the part keeps its id');
      expect(result.parts.single.status, PartTakeStatus.finalTake);
      expect(result.updated, 1);
      expect(result.added, 0);
    });

    test('matches existing parts ignoring case and surrounding space', () {
      final existing = [TestFactories.makePart(id: 'p1', name: 'Drums')];

      final result = importCsv(
        'Part,Status\n  drums  ,Recording',
        existing: existing,
      );

      expect(result.parts.length, 1);
      expect(result.parts.single.status, PartTakeStatus.recording);
    });

    test('appends parts the project did not have', () {
      final existing = [TestFactories.makePart(id: 'p1', name: 'Drums')];

      final result = importCsv(
        'Part,Performer\nDrums,Jules\nBass,Sam',
        existing: existing,
      );

      expect(result.parts.map((p) => p.name), ['Drums', 'Bass']);
      expect(result.added, 1);
      expect(result.updated, 1);
    });

    test('leaves fields alone when the sheet has no column for them', () {
      final existing = [
        TestFactories.makePart(
          id: 'p1',
          name: 'Drums',
          performer: 'Alex',
          status: PartTakeStatus.finalTake,
          notes: 'keeper',
        ),
      ];

      final result = importCsv('Part\nDrums', existing: existing);

      expect(result.parts.single.performer, 'Alex');
      expect(result.parts.single.status, PartTakeStatus.finalTake);
      expect(result.parts.single.notes, 'keeper');
      expect(result.updated, 0);
    });

    test('clears a field when the column is present but the cell is blank', () {
      final existing = [
        TestFactories.makePart(
            id: 'p1', name: 'Drums', performer: 'Alex', notes: 'keeper'),
      ];

      final result =
          importCsv('Part,Performer,Notes\nDrums,,', existing: existing);

      expect(result.parts.single.performer, isNull);
      expect(result.parts.single.notes, isNull);
      expect(result.updated, 1);
    });

    test('reports nothing when the sheet changes nothing', () {
      final existing = [
        TestFactories.makePart(id: 'p1', name: 'Drums', performer: 'Alex'),
      ];

      final result =
          importCsv('Part,Performer\nDrums,Alex', existing: existing);

      expect(result.isEmpty, isTrue);
      expect(result.parts, existing);
    });

    test('an empty file leaves the list untouched', () {
      final existing = [TestFactories.makePart(id: 'p1')];

      final result = importCsv('', existing: existing);

      expect(result.isEmpty, isTrue);
      expect(result.parts, existing);
    });
  });

  group('importInto — status parsing', () {
    test('reads the English labels an exported sheet contains', () {
      for (final entry in {
        'Needed': PartTakeStatus.needed,
        'Recording': PartTakeStatus.recording,
        'Early take': PartTakeStatus.earlyTake,
        'Final take': PartTakeStatus.finalTake,
      }.entries) {
        final result = importCsv('Part,Status\nDrums,${entry.key}');
        expect(result.parts.single.status, entry.value);
      }
    });

    test('is case-insensitive and also accepts the raw storage keys', () {
      expect(
        importCsv('Part,Status\nDrums,FINAL TAKE').parts.single.status,
        PartTakeStatus.finalTake,
      );
      expect(
        importCsv('Part,Status\nDrums,earlyTake').parts.single.status,
        PartTakeStatus.earlyTake,
      );
    });

    test('an unrecognized status falls back to needed rather than failing', () {
      expect(
        importCsv('Part,Status\nDrums,overdubbing').parts.single.status,
        PartTakeStatus.needed,
      );
    });
  });

  // A producer running the app in one language exports a sheet and hands it to
  // a collaborator running it in another; the file has to survive that trip.
  group('importInto — sheets from other UI languages', () {
    test('recognizes headers written in another language', () {
      // Portuguese headers: Projeto, Parte, Músico, Status, Notas.
      final result = importCsv(
        'Projeto,Parte,Músico,Status,Notas\nBanger,Bateria,Alex,Take final,ok',
      );

      final part = result.parts.single;
      expect(part.name, 'Bateria');
      expect(part.performer, 'Alex');
      expect(part.status, PartTakeStatus.finalTake);
      expect(part.notes, 'ok');
    });

    test('reads take statuses written in another language', () {
      // German labels for recording and needed.
      expect(
        importCsv('Part,Status\nDrums,Wird aufgenommen').parts.single.status,
        PartTakeStatus.recording,
      );
      expect(
        importCsv('Part,Status\nDrums,Benötigt').parts.single.status,
        PartTakeStatus.needed,
      );
    });
  });
}
