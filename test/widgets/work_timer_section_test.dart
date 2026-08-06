import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/ui/notification_settings_page.dart';

// Avoids the real Notifiers' build(), which reach into Hive — none of which
// is needed to exercise the session-mode gating logic in WorkTimerSection.
class _FakeSessionModeNotifier extends SessionModeNotifier {
  final bool initial;
  _FakeSessionModeNotifier(this.initial);
  @override
  bool build() => initial;
}

class _FakeWorkTimerNotifEnabledNotifier extends WorkTimerNotifEnabledNotifier {
  @override
  bool build() => true;
}

class _FakeWorkTimerNotifIntervalNotifier extends WorkTimerNotifIntervalNotifier {
  @override
  int build() => 3600;
}

Future<void> _pumpHost(WidgetTester tester, {required bool sessionMode}) async {
  final l10n = await AppLocalizations.delegate.load(const Locale('en'));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionModeProvider.overrideWith(() => _FakeSessionModeNotifier(sessionMode)),
        workTimerNotifEnabledProvider.overrideWith(_FakeWorkTimerNotifEnabledNotifier.new),
        workTimerNotifIntervalProvider.overrideWith(_FakeWorkTimerNotifIntervalNotifier.new),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: WorkTimerSection(l10n: l10n),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('WorkTimerSection', () {
    testWidgets('Session Mode off — reminder controls are disabled and the hint explains why',
        (tester) async {
      await _pumpHost(tester, sessionMode: false);

      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNull,
      );
      expect(
        tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>)).onChanged,
        isNull,
      );
      expect(find.text('Enable Session Mode above to use work session reminders'),
          findsOneWidget);
    });

    testWidgets('Session Mode on — reminder controls are interactive',
        (tester) async {
      await _pumpHost(tester, sessionMode: true);

      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNotNull,
      );
      expect(
        tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>)).onChanged,
        isNotNull,
      );
      expect(find.text('Get notified periodically while you have an active work session'),
          findsOneWidget);
    });

    // Not tapped: it calls DeadlineNotificationService, which reaches real
    // platform notification channels with no test-harness mock available.
    testWidgets('Send Test Notification stays enabled regardless of Session Mode',
        (tester) async {
      await _pumpHost(tester, sessionMode: false);

      final button = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Send Test Notification'),
          matching: find.byType(TextButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
