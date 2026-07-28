import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/services/auto_start_service.dart';
import 'package:daw_project_manager/ui/onboarding_wizard_page.dart';

import '../helpers/hive_test_helper.dart';

/// Stand-in for the real login-item registration so the wizard's Startup
/// step never touches the OS registry / launch agents while under test.
class _NoopAutoStartBackend implements AutoStartBackend {
  @override
  Future<void> setup({required bool minimized}) async {}
  @override
  Future<bool> isEnabled() async => false;
  @override
  Future<bool> enable() async => true;
  @override
  Future<bool> disable() async => true;
}

/// Regression coverage for the Folders / Updates / Suggestions / Session Mode
/// wizard steps. All four existed (with fully translated strings) but were
/// silently dropped from the page list in commit 6c86adc, which bundled
/// "reduce wizard pages from 10 to 6" into an unrelated mobile-player
/// rewrite. This walks the real wizard end-to-end so a future edit that
/// forgets one of these steps (or lets `_totalPages` drift from the actual
/// page list) fails here instead of shipping silently again.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
    AutoStartService.backend = _NoopAutoStartBackend();
  });

  tearDown(() async {
    AutoStartService.resetBackend();
    await HiveTestHelper.tearDown(tempDir);
  });

  Future<AppLocalizations> pumpWizard(WidgetTester tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const OnboardingWizardPage();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return l10n;
  }

  Future<void> next(WidgetTester tester, AppLocalizations l10n) async {
    await tester.tap(find.widgetWithText(FilledButton, l10n.onboardingNext));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'steps through Folders, Updates, Suggestions and Session Mode before Phases',
    (tester) async {
      final l10n = await pumpWizard(tester);

      expect(find.text(l10n.onboardingWelcomeTitle), findsOneWidget);
      await next(tester, l10n); // -> Language
      await next(tester, l10n); // -> Theme
      await next(tester, l10n); // -> Tabs
      await next(tester, l10n); // -> Folders

      expect(find.text(l10n.onboardingFoldersTitle), findsOneWidget);

      await next(tester, l10n); // -> Updates
      expect(find.text(l10n.onboardingUpdatesTitle), findsOneWidget);
      expect(find.text(l10n.checkForUpdates), findsOneWidget);

      await next(tester, l10n); // -> Suggestions
      expect(find.text(l10n.onboardingSuggestionsTitle), findsOneWidget);
      expect(find.text(l10n.suggestionsEnableToggle), findsOneWidget);

      await next(tester, l10n); // -> Session Mode
      expect(find.text(l10n.onboardingSessionModeTitle), findsOneWidget);

      final sessionSwitch =
          find.widgetWithText(SwitchListTile, l10n.sessionMode);
      expect(sessionSwitch, findsOneWidget);
      expect(tester.widget<SwitchListTile>(sessionSwitch).value, isFalse);

      // Toggling here is the whole point of the step existing — it must
      // actually persist, not just flip the on-screen switch.
      await tester.tap(sessionSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(sessionSwitch).value, isTrue);

      await next(tester, l10n); // -> Phases
      expect(find.text(l10n.phases), findsOneWidget);
    },
  );
}
