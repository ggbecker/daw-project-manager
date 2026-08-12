import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/part_template.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/ui/widgets/parts_list_widget.dart';

import '../helpers/test_factories.dart';

void main() {
  /// Pumps the widget with [project]'s parts, feeding whatever it hands back
  /// straight into a rebuild — the same round trip the project detail page
  /// makes through the repository, minus Hive.
  Future<void> pumpParts(
    WidgetTester tester,
    MusicProject project, {
    List<PartTemplate> templates = const [],
  }) async {
    var current = project;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          partTemplatesProvider.overrideWith((ref) => Stream.value(templates)),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => PartsListWidget(
                  project: current,
                  onPartsChanged: (parts) async {
                    setState(() => current = current.copyWith(parts: parts));
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty state when a project has no parts', (tester) async {
    await pumpParts(tester, TestFactories.makeProject());

    expect(find.text('No parts tracked yet'), findsOneWidget);
    expect(find.text('Instruments & Parts'), findsOneWidget);
  });

  testWidgets('lists each part with its performer and status', (tester) async {
    final project = TestFactories.makeProject(parts: [
      TestFactories.makePart(
        id: 'p1',
        name: 'Drums',
        performer: 'Alex',
        status: PartTakeStatus.finalTake,
      ),
      TestFactories.makePart(id: 'p2', name: 'Bass', performer: null),
    ]);
    await pumpParts(tester, project);

    expect(find.text('Drums'), findsOneWidget);
    expect(find.text('Alex · Final take'), findsOneWidget);
    expect(find.text('Bass'), findsOneWidget);
    expect(find.text('Unassigned · Needed'), findsOneWidget);
  });

  testWidgets('shows how many parts are on their final take', (tester) async {
    final project = TestFactories.makeProject(parts: [
      TestFactories.makePart(id: 'p1', status: PartTakeStatus.finalTake),
      TestFactories.makePart(id: 'p2', name: 'Bass'),
      TestFactories.makePart(id: 'p3', name: 'Guitar'),
    ]);
    await pumpParts(tester, project);

    expect(find.text('1 of 3 final takes'), findsOneWidget);
  });

  testWidgets('typing a name and submitting appends a part', (tester) async {
    await pumpParts(tester, TestFactories.makeProject());

    await tester.enterText(find.byType(TextField).first, 'Lead Vocals');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Lead Vocals'), findsOneWidget);
    expect(find.text('No parts tracked yet'), findsNothing);
  });

  testWidgets('a blank name is not added as a part', (tester) async {
    await pumpParts(tester, TestFactories.makeProject());

    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('No parts tracked yet'), findsOneWidget);
  });

  testWidgets('deleting a part removes it from the list', (tester) async {
    final project = TestFactories.makeProject(parts: [
      TestFactories.makePart(id: 'p1', name: 'Drums'),
      TestFactories.makePart(id: 'p2', name: 'Bass'),
    ]);
    await pumpParts(tester, project);

    await tester.tap(find.byTooltip('Delete part').first);
    await tester.pumpAndSettle();

    expect(find.text('Drums'), findsNothing);
    expect(find.text('Bass'), findsOneWidget);
  });

  testWidgets('picking a status from the row menu updates that part', (tester) async {
    final project = TestFactories.makeProject(parts: [
      TestFactories.makePart(id: 'p1', name: 'Drums', performer: 'Alex'),
    ]);
    await pumpParts(tester, project);

    await tester.tap(find.byTooltip('Take status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Final take').last);
    await tester.pumpAndSettle();

    expect(find.text('Alex · Final take'), findsOneWidget);
    expect(find.text('1 of 1 final takes'), findsOneWidget);
  });

  testWidgets('the edit dialog saves name, performer, status and notes', (tester) async {
    final project = TestFactories.makeProject(parts: [
      TestFactories.makePart(id: 'p1', name: 'Drums', performer: 'Alex'),
    ]);
    await pumpParts(tester, project);

    await tester.tap(find.byTooltip('Edit part'));
    await tester.pumpAndSettle();

    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), 'Percussion');
    await tester.enterText(fields.at(1), 'Jules');
    await tester.enterText(fields.at(2), 'shaker + tambourine');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Percussion'), findsOneWidget);
    expect(find.text('Jules · Needed'), findsOneWidget);
    expect(find.text('shaker + tambourine'), findsOneWidget);
  });

  testWidgets('the edit dialog refuses to save an empty name', (tester) async {
    final project = TestFactories.makeProject(parts: [
      TestFactories.makePart(id: 'p1', name: 'Drums', performer: 'Alex'),
    ]);
    await pumpParts(tester, project);

    await tester.tap(find.byTooltip('Edit part'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ).first,
      '  ',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('A part name is required'), findsOneWidget);
    // Still open — the edit was not committed.
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('importing a template appends its parts with fresh ids', (tester) async {
    final template = PartTemplate(
      id: 'pt-1',
      name: 'Band Lineup',
      items: PartTemplate.parseItems('Drums — Alex\nBass — Sam'),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    final project = TestFactories.makeProject(parts: [
      TestFactories.makePart(id: 'existing', name: 'Synth Pads'),
    ]);
    await pumpParts(tester, project, templates: [template]);

    await tester.tap(find.byTooltip('Import parts from template'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Band Lineup'));
    await tester.pumpAndSettle();

    expect(find.text('Synth Pads'), findsOneWidget);
    expect(find.text('Drums'), findsOneWidget);
    expect(find.text('Bass'), findsOneWidget);
  });

  testWidgets('importing with no templates saved explains why nothing happened',
      (tester) async {
    await pumpParts(tester, TestFactories.makeProject());

    await tester.tap(find.byTooltip('Import parts from template'));
    await tester.pump();

    expect(find.text('No part templates available'), findsOneWidget);
  });
}
