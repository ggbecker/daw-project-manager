import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/widgets/quit_confirm_dialog.dart';

/// Pumps a minimal localized app whose home exposes a button that opens the
/// quit-confirm dialog and records its result.
Future<bool?Function()> _pumpHost(WidgetTester tester, {Locale? locale}) async {
  bool? result;
  bool opened = false;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              opened = true;
              result = await showQuitConfirmDialog(context);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(opened, isTrue);
  return () => result;
}

void main() {
  group('showQuitConfirmDialog', () {
    testWidgets('shows localized title, message and buttons (English)',
        (tester) async {
      await _pumpHost(tester);

      expect(find.text('Quit DAW Project Manager?'), findsOneWidget);
      expect(find.text('Are you sure you want to quit?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Quit'), findsOneWidget);
    });

    testWidgets('shows translated strings in Portuguese', (tester) async {
      await _pumpHost(tester, locale: const Locale('pt'));

      expect(find.text('Sair do DAW Project Manager?'), findsOneWidget);
      expect(find.text('Tem certeza de que deseja sair?'), findsOneWidget);
    });

    testWidgets('returns false when Cancel is tapped', (tester) async {
      final result = await _pumpHost(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result(), isFalse);
    });

    testWidgets('returns true when Quit is tapped', (tester) async {
      final result = await _pumpHost(tester);

      await tester.tap(find.text('Quit'));
      await tester.pumpAndSettle();

      expect(result(), isTrue);
    });
  });
}
