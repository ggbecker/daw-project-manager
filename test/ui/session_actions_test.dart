import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/ui/session_actions.dart';

import '../helpers/test_factories.dart';

// Avoids WorkTimerNotifier's real build(), which listens to
// activeProjectProvider and reaches into repositoryProvider/Hive and starts a
// periodic Timer — none of which are needed to exercise the dialog logic in
// session_actions.dart, and all of which would require a full Hive test
// harness to run safely.
class _FakeWorkTimerNotifier extends WorkTimerNotifier {
  @override
  int build() => 0;
}

Future<void> _pumpHost(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        allProjectsStreamProvider.overrideWith((ref) => Stream.value(const <MusicProject>[])),
        workTimerProvider.overrideWith(_FakeWorkTimerNotifier.new),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              final active = ref.watch(activeProjectProvider);
              return Column(
                children: [
                  Text('active: ${active?.id ?? 'none'}'),
                  TextButton(
                    onPressed: () => confirmStartSession(
                        context, ref, TestFactories.makeProject(id: 'p1')),
                    child: const Text('start p1'),
                  ),
                  TextButton(
                    onPressed: () => confirmStartSession(
                        context, ref, TestFactories.makeProject(id: 'p2')),
                    child: const Text('start p2'),
                  ),
                  TextButton(
                    onPressed: () => confirmEndSession(context, ref),
                    child: const Text('end'),
                  ),
                  TextButton(
                    onPressed: () => launchProjectInDaw(
                      context,
                      ref,
                      TestFactories.makeProject(id: 'missing'),
                    ),
                    child: const Text('launch missing'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('confirmStartSession', () {
    testWidgets('no active project — confirming sets the active project',
        (tester) async {
      await _pumpHost(tester);
      expect(find.text('active: none'), findsOneWidget);

      await tester.tap(find.text('start p1'));
      await tester.pumpAndSettle();

      // Simple start dialog, not the switch dialog.
      expect(find.text('Switch session'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Start Session'));
      await tester.pumpAndSettle();

      expect(find.text('active: p1'), findsOneWidget);
    });

    testWidgets('no active project — cancelling leaves no active project',
        (tester) async {
      await _pumpHost(tester);

      await tester.tap(find.text('start p1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('active: none'), findsOneWidget);
    });

    testWidgets(
        'another session already active — shows switch dialog and confirming switches',
        (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.text('start p1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start Session'));
      await tester.pumpAndSettle();
      expect(find.text('active: p1'), findsOneWidget);

      await tester.tap(find.text('start p2'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Switch session'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Switch session'));
      await tester.pumpAndSettle();

      expect(find.text('active: p2'), findsOneWidget);
    });

    testWidgets(
        'another session already active — cancelling the switch keeps the original project',
        (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.text('start p1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start Session'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('start p2'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('active: p1'), findsOneWidget);
    });
  });

  group('launchProjectInDaw', () {
    testWidgets(
      'project file does not exist — shows "File missing" and never touches the DAW-launch path',
      (tester) async {
        await _pumpHost(tester);

        await tester.tap(find.text('launch missing'));
        await tester.pumpAndSettle();

        expect(find.text('File missing.'), findsOneWidget);
      },
    );
  });

  group('confirmEndSession', () {
    testWidgets('no active project — does nothing (no dialog)',
        (tester) async {
      await _pumpHost(tester);

      await tester.tap(find.text('end'));
      await tester.pumpAndSettle();

      expect(find.text('End session'), findsNothing);
      expect(find.text('active: none'), findsOneWidget);
    });

    testWidgets('active project — confirming clears the active project',
        (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.text('start p1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start Session'));
      await tester.pumpAndSettle();
      expect(find.text('active: p1'), findsOneWidget);

      await tester.tap(find.text('end'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'End session'));
      await tester.pumpAndSettle();

      expect(find.text('active: none'), findsOneWidget);
    });

    testWidgets('active project — cancelling leaves the session active',
        (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.text('start p1'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start Session'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('end'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('active: p1'), findsOneWidget);
    });
  });
}
