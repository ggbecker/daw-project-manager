import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/ui/widgets/project_detail_header.dart';

import '../helpers/test_factories.dart';

Future<void> _pumpHeader(
  WidgetTester tester,
  MusicProject project, {
  bool isSessionActive = false,
  int liveSessionSeconds = 0,
  Set<String> finishedPhase = const {'Finished'},
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ProjectDetailHeader(
          project: project,
          dateFormat: DateFormat('yyyy-MM-dd'),
          isSessionActive: isSessionActive,
          liveSessionSeconds: liveSessionSeconds,
          finishedPhase: finishedPhase,
        ),
      ),
    ),
  );
}

/// Finds the Tooltip whose message satisfies [predicate].
Finder _tooltipWhere(bool Function(String) predicate) =>
    find.byWidgetPredicate((w) => w is Tooltip && predicate(w.message ?? ''));

void main() {
  final now = DateTime.now();

  group('ProjectDetailHeader', () {
    testWidgets('shows title, phase chip and a compact meta line',
        (tester) async {
      final project = TestFactories.makeProject(
        customDisplayName: 'My Track',
        status: 'Mixing',
        fileCreatedAt: now.subtract(const Duration(days: 5)),
        lastModifiedAt: now.subtract(const Duration(days: 2)),
        totalWorkSeconds: 3 * 3600 + 25 * 60,
      );
      await _pumpHeader(tester, project);

      expect(find.text('My Track'), findsOneWidget);
      expect(find.text('Mixing'), findsOneWidget);
      expect(
        find.text('5 days old · edited 2 days ago · 3h 25m worked'),
        findsOneWidget,
      );
    });

    testWidgets('omits the worked segment when no work time is recorded',
        (tester) async {
      final project = TestFactories.makeProject(
        fileCreatedAt: now.subtract(const Duration(days: 5)),
        lastModifiedAt: now.subtract(const Duration(days: 2)),
      );
      await _pumpHeader(tester, project);

      expect(find.text('5 days old · edited 2 days ago'), findsOneWidget);
    });

    testWidgets(
        'no longer renders file path, BPM, key or DAW as header text '
        '(they live in the tooltip / form fields instead)', (tester) async {
      final project = TestFactories.makeProject(
        filePath: '/Users/test/Projects/MyProject.als',
        bpm: 128,
        musicalKey: 'A minor',
        dawType: 'Ableton Live',
        dawVersion: '11',
        fileCreatedAt: now.subtract(const Duration(days: 5)),
        lastModifiedAt: now.subtract(const Duration(days: 2)),
      );
      await _pumpHeader(tester, project);

      expect(find.text('/Users/test/Projects/MyProject.als'), findsNothing);
      expect(find.textContaining('BPM'), findsNothing);
      expect(find.textContaining('A minor'), findsNothing);
      expect(find.textContaining('Ableton'), findsNothing);
    });

    testWidgets('title tooltip carries the source file path', (tester) async {
      final project = TestFactories.makeProject(
        filePath: '/Users/test/Projects/MyProject.als',
        lastModifiedAt: now.subtract(const Duration(days: 2)),
      );
      await _pumpHeader(tester, project);

      expect(find.byTooltip('/Users/test/Projects/MyProject.als'),
          findsOneWidget);
    });

    testWidgets('meta line tooltip carries exact modified and created dates',
        (tester) async {
      final project = TestFactories.makeProject(
        fileCreatedAt: DateTime(2025, 6, 1),
        lastModifiedAt: DateTime(2026, 7, 10),
      );
      await _pumpHeader(tester, project);

      expect(
        _tooltipWhere((m) =>
            m.contains('Last modified: 2026-07-10') &&
            m.contains('created 2025-06-01')),
        findsOneWidget,
      );
    });

    testWidgets('meta line tooltip includes completion time for a finished '
        'project', (tester) async {
      final project = TestFactories.makeProject(
        status: 'Finished',
        fileCreatedAt: now.subtract(const Duration(days: 100)),
        lastModifiedAt: now.subtract(const Duration(days: 10)),
        statusChangedAt: now.subtract(const Duration(days: 10)),
      );
      await _pumpHeader(tester, project);

      expect(
        _tooltipWhere((m) => m.contains('Completed in: 3 months')),
        findsOneWidget,
      );
    });

    testWidgets('shows the live session timer only when a session is active',
        (tester) async {
      final project = TestFactories.makeProject(
        lastModifiedAt: now.subtract(const Duration(days: 2)),
      );

      await _pumpHeader(tester, project);
      expect(find.textContaining('Session:', findRichText: true), findsNothing);

      await _pumpHeader(tester, project,
          isSessionActive: true, liveSessionSeconds: 754);
      expect(find.textContaining('Session: 12:34', findRichText: true),
          findsOneWidget);
    });
  });
}
