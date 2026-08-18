import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/ui/session_actions.dart';
import 'package:daw_project_manager/utils/launch_diagnostics.dart';

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

  // The failure snackbar is where a tester meets the launch diagnostics: it
  // carries the recorded log and a Copy button, because "Failed to launch
  // <project>" alone is the report we keep receiving and asking them to go
  // find a log file loses most of them.
  group('showLaunchResultSnackBar', () {
    setUp(() {
      LaunchDiagnostics.clear();
      LaunchDiagnostics.sink = null;
    });

    tearDown(() {
      LaunchDiagnostics.clear();
      LaunchDiagnostics.sink = null;
    });

    testWidgets('a success stays a plain one-line message', (tester) async {
      LaunchDiagnostics.record('some step');
      await _pumpSnackBarHost(tester, launched: true);
      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.textContaining('Launching'), findsOneWidget);
      expect(find.text('Copy'), findsNothing);
      expect(find.textContaining('some step'), findsNothing);
    });

    testWidgets('a failure shows the recorded log inline', (tester) async {
      LaunchDiagnostics.record('windows file association', {'openCommand': null});
      await _pumpSnackBarHost(tester, launched: false);
      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.textContaining('Failed to launch'), findsOneWidget);
      expect(find.textContaining('openCommand=null'), findsOneWidget);
    });

    testWidgets('a failure offers Copy, which puts the log on the clipboard',
        (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      LaunchDiagnostics.record('launch result', {'launched': false});
      await _pumpSnackBarHost(tester, launched: false);
      await tester.tap(find.text('show'));
      // Settle the snackbar's entrance animation before tapping into it —
      // mid-slide its buttons are still below the viewport.
      await tester.pumpAndSettle();

      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();

      expect(copied, isNotNull);
      expect(copied, contains('launched=false'));
      expect(find.textContaining('copied'), findsOneWidget);
    });

    testWidgets('an identified cause is stated in plain language',
        (tester) async {
      // The '.rpp with nothing registered to open it' case — the tester must
      // not have to read 'openCommand=null' out of the log to learn this.
      LaunchDiagnostics.recordCause(
          LaunchFailureCause.noFileAssociation, '.rpp');
      await _pumpSnackBarHost(tester, launched: false);
      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.textContaining('no app set to open .rpp'), findsOneWidget);
    });

    testWidgets('no cause line when none was identified', (tester) async {
      LaunchDiagnostics.record('launch result', {'launched': false});
      await _pumpSnackBarHost(tester, launched: false);
      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.textContaining('no app set to open'), findsNothing);
    });

    testWidgets('Details opens the full diagnostics dialog', (tester) async {
      LaunchDiagnostics.record('resolved path', {'exists': true});
      await _pumpSnackBarHost(tester, launched: false);
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      expect(find.text('Launch diagnostics'), findsOneWidget);
    });
  });
}

/// A bare host for [showLaunchResultSnackBar] — no Riverpod and no Hive,
/// since the snackbar depends on neither.
Future<void> _pumpSnackBarHost(
  WidgetTester tester, {
  required bool launched,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showLaunchResultSnackBar(
              context,
              TestFactories.makeProject(id: 'p1', customDisplayName: 'Teardrop'),
              launched,
            ),
            child: const Text('show'),
          ),
        ),
      ),
    ),
  );
}
