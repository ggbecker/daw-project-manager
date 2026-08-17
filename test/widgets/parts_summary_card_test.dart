import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/ui/widgets/parts_summary_card.dart';

import '../helpers/test_factories.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, MusicProject project) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(body: PartsSummaryCard(project: project)),
      ),
    );
    await tester.pumpAndSettle();
  }

  ProjectPart part(String id, String name, {PartTakeStatus? status}) =>
      TestFactories.makePart(
        id: id,
        name: name,
        status: status ?? PartTakeStatus.needed,
      );

  testWidgets('shows the empty state and still offers the workspace',
      (tester) async {
    await pumpCard(tester, TestFactories.makeProject());

    expect(find.text('No parts tracked yet'), findsOneWidget);
    expect(find.text('Manage parts'), findsOneWidget);
  });

  testWidgets('lists parts with their performer and status', (tester) async {
    await pumpCard(
      tester,
      TestFactories.makeProject(parts: [
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
    expect(find.text('Final take'), findsOneWidget);
    expect(find.text('Unassigned'), findsOneWidget);
  });

  testWidgets('shows recording progress', (tester) async {
    await pumpCard(
      tester,
      TestFactories.makeProject(parts: [
        part('p1', 'Drums', status: PartTakeStatus.finalTake),
        part('p2', 'Bass'),
      ]),
    );

    expect(find.text('1 of 2 final takes'), findsOneWidget);
  });

  testWidgets('collapses a long list into a "+N more" line', (tester) async {
    await pumpCard(
      tester,
      TestFactories.makeProject(parts: [
        for (var i = 0; i < PartsSummaryCard.previewCount + 3; i++)
          part('p$i', 'Part $i'),
      ]),
    );

    expect(find.text('Part 0'), findsOneWidget);
    expect(
      find.text('Part ${PartsSummaryCard.previewCount}'),
      findsNothing,
      reason: 'parts past the preview count are collapsed',
    );
    expect(find.text('+3 more'), findsOneWidget);
  });

  testWidgets('shows no "+N more" line when every part fits', (tester) async {
    await pumpCard(
      tester,
      TestFactories.makeProject(parts: [part('p1', 'Drums')]),
    );

    expect(find.textContaining('more'), findsNothing);
  });
}
