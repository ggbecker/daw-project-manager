import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/widgets/license_dialog.dart';

void main() {
  group('showLicenseDialog', () {
    testWidgets('shows the bundled LICENSE contents and closes on Close',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showLicenseDialog(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(LicenseTextDialog), findsOneWidget);
      expect(find.textContaining('MIT License'), findsOneWidget);
      expect(find.textContaining('Permission is hereby granted'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(LicenseTextDialog), findsNothing);
    });
  });
}
