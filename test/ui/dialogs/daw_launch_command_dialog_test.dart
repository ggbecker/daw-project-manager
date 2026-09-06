import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/dialogs/daw_launch_command_dialog.dart';

/// The "configure a DAW executable" dialog now opens in three modes. These
/// pin which explanatory banner each mode shows — the rest of its logic
/// (path validation, `.app` routing, launch strategy) is covered by pure
/// tests in file_launcher_test.dart and session_actions_test.dart.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    bool pathMissing = false,
    bool launchFailed = false,
    String? currentPath,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDawLaunchCommandDialog(
                  context,
                  dawType: 'Logic Pro',
                  currentPath: currentPath,
                  pathMissing: pathMissing,
                  launchFailed: launchFailed,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('launchFailed mode shows the "couldn\'t open" banner', (tester) async {
    await pump(tester, launchFailed: true);

    expect(
      find.textContaining("couldn't open this project through the system"),
      findsOneWidget,
    );
    // Not the generic first-run body.
    expect(find.textContaining('Point this at the Logic Pro program'), findsNothing);
  });

  testWidgets('default (first-run) mode shows the generic body', (tester) async {
    await pump(tester);

    expect(find.textContaining('Point this at the Logic Pro program'), findsOneWidget);
    expect(
      find.textContaining("couldn't open this project through the system"),
      findsNothing,
    );
  });

  testWidgets('pathMissing mode shows the missing-path warning', (tester) async {
    await pump(tester, pathMissing: true, currentPath: '/gone/Logic Pro.app');

    expect(find.textContaining('no longer exist'), findsOneWidget);
    expect(
      find.textContaining("couldn't open this project through the system"),
      findsNothing,
    );
  });
}
