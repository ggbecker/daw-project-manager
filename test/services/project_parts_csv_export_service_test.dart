import 'package:daw_project_manager/generated/l10n/app_localizations_en.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/services/project_parts_csv_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_factories.dart';

void main() {
  final l10n = AppLocalizationsEn();

  List<String> linesOf(String csv) => csv
      .replaceFirst(ProjectPartsCsvExportService.utf8Bom, '')
      .trim()
      .split('\n')
      .map((l) => l.trimRight())
      .toList();

  group('ProjectPartsCsvExportService.formatProject', () {
    test('writes a header row and one row per part', () {
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
            id: 'p2',
            name: 'Bass',
            performer: null,
            status: PartTakeStatus.needed,
          ),
        ],
      );

      final lines = linesOf(
        ProjectPartsCsvExportService.formatProject(project, l10n),
      );

      expect(lines, [
        'Project,Part,Performer,Status,Notes',
        'Banger,Drums,Alex,Final take,keeper',
        'Banger,Bass,,Needed,',
      ]);
    });

    test('starts with a UTF-8 BOM so spreadsheets read accents correctly', () {
      final project = TestFactories.makeProject(
        parts: [TestFactories.makePart(performer: 'Renée')],
      );

      final csv = ProjectPartsCsvExportService.formatProject(project, l10n);

      expect(csv.startsWith(ProjectPartsCsvExportService.utf8Bom), isTrue);
      expect(csv, contains('Renée'));
    });

    test('returns an empty string when the project has no parts', () {
      final project = TestFactories.makeProject();
      expect(ProjectPartsCsvExportService.formatProject(project, l10n), '');
    });

    test('quotes fields containing a comma', () {
      final project = TestFactories.makeProject(
        customDisplayName: 'Song',
        parts: [
          TestFactories.makePart(
            name: 'Drums',
            performer: 'Alex, Jr.',
            notes: 'kick, snare, hats',
          ),
        ],
      );

      final lines = linesOf(
        ProjectPartsCsvExportService.formatProject(project, l10n),
      );

      expect(lines.last, 'Song,Drums,"Alex, Jr.",Needed,"kick, snare, hats"');
    });

    test('doubles embedded quotes', () {
      final project = TestFactories.makeProject(
        customDisplayName: 'Song',
        parts: [
          TestFactories.makePart(
            name: 'Drums',
            performer: 'Alex',
            notes: 'the "big" fill',
          ),
        ],
      );

      final csv = ProjectPartsCsvExportService.formatProject(project, l10n);

      expect(csv, contains('"the ""big"" fill"'));
    });

    test('quotes multi-line notes so the row stays one CSV record', () {
      final project = TestFactories.makeProject(
        customDisplayName: 'Song',
        parts: [
          TestFactories.makePart(
            name: 'Drums',
            performer: 'Alex',
            notes: 'first line\nsecond line',
          ),
        ],
      );

      final csv = ProjectPartsCsvExportService.formatProject(project, l10n);

      expect(csv, contains('"first line\nsecond line"'));
    });
  });

  group('ProjectPartsCsvExportService.formatProjects', () {
    test('flattens every project into one sheet with a single header', () {
      final projects = [
        TestFactories.makeProject(
          id: 'a',
          customDisplayName: 'First',
          parts: [TestFactories.makePart(id: 'p1', name: 'Drums')],
        ),
        TestFactories.makeProject(
          id: 'b',
          customDisplayName: 'Second',
          parts: [TestFactories.makePart(id: 'p2', name: 'Bass')],
        ),
      ];

      final lines =
          linesOf(ProjectPartsCsvExportService.formatProjects(projects, l10n));

      expect(lines.length, 3);
      expect(lines.first, 'Project,Part,Performer,Status,Notes');
      expect(lines[1], startsWith('First,Drums,'));
      expect(lines[2], startsWith('Second,Bass,'));
    });

    test('skips projects that have no parts', () {
      final projects = [
        TestFactories.makeProject(id: 'a', customDisplayName: 'Empty'),
        TestFactories.makeProject(
          id: 'b',
          customDisplayName: 'Has parts',
          parts: [TestFactories.makePart(id: 'p1', name: 'Drums')],
        ),
      ];

      final csv = ProjectPartsCsvExportService.formatProjects(projects, l10n);

      expect(csv, isNot(contains('Empty')));
      expect(linesOf(csv).length, 2);
    });

    test('returns an empty string when no project has parts', () {
      final projects = [TestFactories.makeProject(id: 'a')];
      expect(ProjectPartsCsvExportService.formatProjects(projects, l10n), '');
    });
  });

  group('ProjectPartsCsvExportService.partCount', () {
    test('sums parts across projects', () {
      final projects = [
        TestFactories.makeProject(id: 'a', parts: [
          TestFactories.makePart(id: 'p1'),
          TestFactories.makePart(id: 'p2'),
        ]),
        TestFactories.makeProject(id: 'b', parts: [TestFactories.makePart(id: 'p3')]),
        TestFactories.makeProject(id: 'c'),
      ];

      expect(ProjectPartsCsvExportService.partCount(projects), 3);
    });

    test('is zero for an empty library', () {
      expect(ProjectPartsCsvExportService.partCount(const []), 0);
    });
  });

  group('suggested file names', () {
    test('uses the project name, sanitized, for a single export', () {
      final project =
          TestFactories.makeProject(customDisplayName: 'Track: One/Two');
      expect(
        ProjectPartsCsvExportService.suggestedFileNameFor(project),
        'Track_ One_Two_parts.csv',
      );
    });

    test('falls back to a generic name when the display name sanitizes away', () {
      final project = TestFactories.makeProject(customDisplayName: '///');
      expect(
        ProjectPartsCsvExportService.suggestedFileNameFor(project),
        '____parts.csv',
      );
    });

    test('bulk export name is dated and ends in .csv', () {
      final name = ProjectPartsCsvExportService.suggestedBulkFileName();
      expect(name, startsWith('daw_project_manager_parts_'));
      expect(name, endsWith('.csv'));
    });
  });
}
