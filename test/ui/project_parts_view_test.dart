import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/part_template.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/ui/project_parts_page.dart';

import '../helpers/test_factories.dart';

void main() {
  /// Pumps the parts workspace and feeds whatever it saves straight back in,
  /// which is the same round trip [ProjectPartsPage] makes through the
  /// repository — minus Hive, which cannot be written to from inside a
  /// `testWidgets` body (its write path waits on a timer that only advances
  /// when the test pumps, so the await deadlocks).
  ///
  /// Returns a getter for the most recently saved parts list.
  Future<List<ProjectPart> Function()> pumpView(
    WidgetTester tester,
    MusicProject project, {
    List<PartTemplate> templates = const [],
  }) async {
    var current = project;

    // The workspace is a desktop-width table; the 800x600 test default is
    // narrower than any real window it ships in.
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ProjectPartsView(
              project: current,
              templates: templates,
              onPartsChanged: (parts) async {
                setState(() => current = current.copyWith(parts: parts));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return () => current.parts;
  }

  MusicProject projectWithParts(List<ProjectPart> parts) =>
      TestFactories.makeProject(
        id: 'p',
        customDisplayName: 'Banger',
        parts: parts,
      );

  group('ProjectPartsView — rendering', () {
    testWidgets('shows the empty state for a project with no parts',
        (tester) async {
      await pumpView(tester, projectWithParts(const []));

      expect(find.text('No parts tracked yet'), findsOneWidget);
    });

    testWidgets('lists every part with performer and status', (tester) async {
      await pumpView(
        tester,
        projectWithParts([
          TestFactories.makePart(
            id: 'p1',
            name: 'Drums',
            performer: 'Alex',
            status: PartTakeStatus.finalTake,
          ),
          TestFactories.makePart(id: 'p2', name: 'Bass', performer: null),
        ]),
      );

      expect(find.text('Drums'), findsOneWidget);
      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('Bass'), findsOneWidget);
      expect(find.text('Unassigned'), findsOneWidget);
      expect(find.text('1 of 2 final takes'), findsOneWidget);
    });
  });

  group('ProjectPartsView — editing', () {
    testWidgets('adding a part appends it to the list', (tester) async {
      final parts = await pumpView(tester, projectWithParts(const []));

      await tester.enterText(find.byType(TextField).first, 'Lead Vocals');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(parts().single.name, 'Lead Vocals');
      expect(find.text('Lead Vocals'), findsOneWidget);
    });

    testWidgets('a blank name is not added', (tester) async {
      final parts = await pumpView(tester, projectWithParts(const []));

      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(parts(), isEmpty);
    });

    testWidgets('changing a row status saves it', (tester) async {
      final parts = await pumpView(
        tester,
        projectWithParts([TestFactories.makePart(id: 'p1', name: 'Drums')]),
      );

      await tester.tap(find.byTooltip('Take status'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Final take').last);
      await tester.pumpAndSettle();

      expect(parts().single.status, PartTakeStatus.finalTake);
      expect(find.text('1 of 1 final takes'), findsOneWidget);
    });

    testWidgets('the edit dialog saves name and performer', (tester) async {
      final parts = await pumpView(
        tester,
        projectWithParts([
          TestFactories.makePart(id: 'p1', name: 'Drums', performer: 'Alex'),
        ]),
      );

      await tester.tap(find.byTooltip('Edit part'));
      await tester.pumpAndSettle();

      final fields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), 'Percussion');
      await tester.enterText(fields.at(1), 'Jules');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(parts().single.name, 'Percussion');
      expect(parts().single.performer, 'Jules');
    });
  });

  group('ProjectPartsView — search, filter and sort', () {
    Future<List<ProjectPart> Function()> pumpThree(WidgetTester tester) =>
        pumpView(
          tester,
          projectWithParts([
            TestFactories.makePart(
              id: 'p1',
              name: 'Drums',
              performer: 'Alex',
              status: PartTakeStatus.finalTake,
            ),
            TestFactories.makePart(id: 'p2', name: 'Bass', performer: 'Sam'),
            TestFactories.makePart(id: 'p3', name: 'Cello', performer: 'Alex'),
          ]),
        );

    Finder searchField() => find.widgetWithText(TextField, 'Search parts');

    List<String> visibleOrder(WidgetTester tester) => tester
        .widgetList<Text>(find.descendant(
          of: find.byType(ReorderableListView),
          matching: find.byType(Text),
        ))
        .map((t) => t.data ?? '')
        .where((t) => ['Drums', 'Bass', 'Cello'].contains(t))
        .toList();

    testWidgets('search narrows the table by performer', (tester) async {
      await pumpThree(tester);

      await tester.enterText(searchField(), 'Sam');
      await tester.pumpAndSettle();

      expect(find.text('Bass'), findsOneWidget);
      expect(find.text('Drums'), findsNothing);
    });

    testWidgets('a search matching nothing shows the no-match state',
        (tester) async {
      await pumpThree(tester);

      await tester.enterText(searchField(), 'zzzz');
      await tester.pumpAndSettle();

      expect(find.text('No parts match these filters'), findsOneWidget);
    });

    testWidgets('the status filter keeps only that status', (tester) async {
      await pumpThree(tester);

      await tester.tap(find.text('All statuses').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Final take').last);
      await tester.pumpAndSettle();

      expect(find.text('Drums'), findsOneWidget);
      expect(find.text('Bass'), findsNothing);
    });

    testWidgets('the performer filter keeps only that performer',
        (tester) async {
      await pumpThree(tester);

      await tester.tap(find.text('All performers').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sam').last);
      await tester.pumpAndSettle();

      expect(find.text('Bass'), findsOneWidget);
      expect(find.text('Cello'), findsNothing);
    });

    testWidgets('sorting by name cycles ascending, descending, then back',
        (tester) async {
      await pumpThree(tester);

      expect(visibleOrder(tester), ['Drums', 'Bass', 'Cello']);

      await tester.tap(find.text('Part'));
      await tester.pumpAndSettle();
      expect(visibleOrder(tester), ['Bass', 'Cello', 'Drums']);

      await tester.tap(find.text('Part'));
      await tester.pumpAndSettle();
      expect(visibleOrder(tester), ['Drums', 'Cello', 'Bass']);

      // A third tap returns to the stored order, which is also the only mode
      // where rows can be dragged.
      await tester.tap(find.text('Part'));
      await tester.pumpAndSettle();
      expect(visibleOrder(tester), ['Drums', 'Bass', 'Cello']);
    });

    testWidgets('drag handles disappear while the list is filtered',
        (tester) async {
      await pumpThree(tester);

      expect(find.byIcon(Icons.drag_indicator), findsNWidgets(3));

      await tester.enterText(searchField(), 'Alex');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.drag_indicator), findsNothing);
      expect(
        find.text(
            'Clear the search, filters and sorting to drag parts into order'),
        findsOneWidget,
      );
    });
  });

  group('ProjectPartsView — bulk actions', () {
    Future<List<ProjectPart> Function()> pumpTwo(WidgetTester tester) =>
        pumpView(
          tester,
          projectWithParts([
            TestFactories.makePart(id: 'p1', name: 'Drums', performer: 'Alex'),
            TestFactories.makePart(id: 'p2', name: 'Bass', performer: 'Sam'),
          ]),
        );

    testWidgets('the bulk bar only appears once something is selected',
        (tester) async {
      await pumpTwo(tester);

      expect(find.text('Set status'), findsNothing);

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Set status'), findsOneWidget);
    });

    testWidgets('the header checkbox selects and clears every visible row',
        (tester) async {
      await pumpTwo(tester);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('selected'), findsNothing);
    });

    testWidgets('bulk status applies to every selected part', (tester) async {
      final parts = await pumpTwo(tester);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set status'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Final take').last);
      await tester.pumpAndSettle();

      expect(
        parts().map((p) => p.status),
        everyElement(PartTakeStatus.finalTake),
      );
    });

    testWidgets('bulk performer assignment applies to every selected part',
        (tester) async {
      final parts = await pumpTwo(tester);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assign performer'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Nina',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(parts().map((p) => p.performer), everyElement('Nina'));
    });

    testWidgets('bulk delete asks first and then removes the parts',
        (tester) async {
      final parts = await pumpTwo(tester);

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete selected'));
      await tester.pumpAndSettle();

      expect(find.text('Delete 1 parts from this song?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(parts().map((p) => p.name), ['Bass']);
    });

    testWidgets('cancelling the delete confirmation keeps the parts',
        (tester) async {
      final parts = await pumpTwo(tester);

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete selected'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(parts().length, 2);
    });
  });

  group('ProjectPartsView — templates', () {
    testWidgets('importing a template appends its parts', (tester) async {
      final template = PartTemplate(
        id: 'pt-1',
        name: 'Band Lineup',
        items: PartTemplate.parseItems('Drums — Alex\nBass — Sam'),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final parts = await pumpView(
        tester,
        projectWithParts([
          TestFactories.makePart(id: 'p1', name: 'Synth Pads'),
        ]),
        templates: [template],
      );

      await tester.tap(find.byTooltip('More part actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import parts from template'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Band Lineup'));
      await tester.pumpAndSettle();

      expect(parts().map((p) => p.name), ['Synth Pads', 'Drums', 'Bass']);
    });

    Future<void> openTemplatePicker(WidgetTester tester) async {
      await tester.tap(find.byTooltip('More part actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import parts from template'));
      await tester.pumpAndSettle();
    }

    testWidgets('with no templates the picker offers to create one',
        (tester) async {
      await pumpView(tester, projectWithParts(const []));

      await openTemplatePicker(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('No part templates yet'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Create part template'),
          findsOneWidget);
    });

    // Regression: this used to be a SnackBar carrying a SnackBarAction. Such a
    // bar never auto-dismisses, so it sat on screen indefinitely, and its
    // action held this State's context — tapping Create after navigating away
    // threw "This widget has been unmounted".
    testWidgets('nothing is left pinned on screen after the picker closes',
        (tester) async {
      await pumpView(tester, projectWithParts(const []));

      await openTemplatePicker(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);

      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a still-loading template list is not reported as empty',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: ProjectPartsView(
              project: projectWithParts(const []),
              templatesLoading: true,
              onPartsChanged: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fixed pumps, not pumpAndSettle: the dialog this opens holds a spinner,
      // and an indefinite animation never settles.
      await tester.tap(find.byTooltip('More part actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import parts from template'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 30));
      }

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No part templates yet'), findsNothing);
    });
  });
}
