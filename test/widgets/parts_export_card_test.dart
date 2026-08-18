import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/widgets/parts_export_card.dart';

void main() {
  Future<List<bool>> pumpCard(
    WidgetTester tester, {
    bool busy = false,
    double width = 900,
  }) async {
    final exported = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          // A SingleChildScrollView the way the settings page hosts it: the
          // page is one scrollable column, which is where the card's own
          // constraints come from.
          body: SingleChildScrollView(
            child: SizedBox(
              width: width,
              child: PartsExportCard(
                busy: busy,
                onExport: ({required bool asXlsx}) => exported.add(asXlsx),
              ),
            ),
          ),
        ),
      ),
    );
    return exported;
  }

  group('PartsExportCard', () {
    testWidgets('lays out without forcing an infinite width', (tester) async {
      await pumpCard(tester);

      // The regression: the buttons sat in a Column with
      // CrossAxisAlignment.stretch as a non-flex child of a Row, so they were
      // measured against an unbounded width and layout threw
      // "BoxConstraints forces an infinite width" before anything painted.
      expect(tester.takeException(), isNull);
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('Excel (.xlsx)'), findsOneWidget);
    });

    testWidgets('still lays out when the settings page is narrow',
        (tester) async {
      await pumpCard(tester, width: 360);

      expect(tester.takeException(), isNull);
    });

    testWidgets('the two buttons share one width so they line up',
        (tester) async {
      await pumpCard(tester);

      final csv = tester.getSize(find.widgetWithText(FilledButton, 'CSV'));
      final xlsx =
          tester.getSize(find.widgetWithText(FilledButton, 'Excel (.xlsx)'));
      expect(csv.width, xlsx.width,
          reason: 'stretch inside IntrinsicWidth should equalize them');
    });

    testWidgets('each button reports which format was asked for',
        (tester) async {
      final exported = await pumpCard(tester);

      await tester.tap(find.text('CSV'));
      await tester.pump();
      expect(exported, [false]);

      await tester.tap(find.text('Excel (.xlsx)'));
      await tester.pump();
      expect(exported, [false, true]);
    });

    testWidgets('both buttons are disabled while another task is running',
        (tester) async {
      final exported = await pumpCard(tester, busy: true);

      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'CSV'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('CSV'), warnIfMissed: false);
      await tester.pump();
      expect(exported, isEmpty);
    });
  });
}
