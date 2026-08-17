import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/widgets/project_notes_section.dart';

/// #105 — the music players show two kinds of notes: what the user typed, and
/// what was read out of the DAW project file. They come from different places
/// and only one is editable, so which is which must never be ambiguous.
///
/// `ProjectNotesSection` takes strings rather than a `MusicProject` precisely
/// so these can run without opening Hive.
void main() {
  const userLabel = 'NOTES';
  // The players label this block with the very string the project detail page
  // uses for the same field (l10n.projectNotesFromDaw).
  const dawLabel = 'Project Notes (from DAW file)';

  Widget wrap({String? userNotes, String? dawNotes, int lineLimit = 8}) =>
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProjectNotesSection(
              userNotes: userNotes,
              dawNotes: dawNotes,
              userNotesLabel: userLabel,
              dawNotesLabel: dawLabel,
              expandLabel: 'Expand',
              collapseLabel: 'Collapse',
              collapsedLineLimit: lineLimit,
            ),
          ),
        ),
      );

  group('hasContent', () {
    test('false when both are null, empty or whitespace', () {
      expect(ProjectNotesSection.hasContent(), isFalse);
      expect(
        ProjectNotesSection.hasContent(userNotes: '', dawNotes: ''),
        isFalse,
      );
      expect(
        ProjectNotesSection.hasContent(userNotes: '   ', dawNotes: '\n'),
        isFalse,
      );
    });

    test('true when either has real content', () {
      expect(ProjectNotesSection.hasContent(userNotes: 'x'), isTrue);
      expect(ProjectNotesSection.hasContent(dawNotes: 'x'), isTrue);
    });
  });

  group('the four states', () {
    testWidgets('neither set renders nothing', (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.text(userLabel), findsNothing);
      expect(find.text(dawLabel), findsNothing);
    });

    testWidgets('only user notes shows one labelled block', (tester) async {
      await tester.pumpWidget(wrap(userNotes: 'needs more reverb'));

      expect(find.text(userLabel), findsOneWidget);
      expect(find.text('needs more reverb'), findsOneWidget);
      expect(find.text(dawLabel), findsNothing);
    });

    testWidgets('only DAW notes shows one labelled block', (tester) async {
      await tester.pumpWidget(wrap(dawNotes: 'mixed on the shared monitors'));

      expect(find.text(dawLabel), findsOneWidget);
      expect(find.text('mixed on the shared monitors'), findsOneWidget);
      expect(find.text(userLabel), findsNothing);
    });

    testWidgets('both show, labelled, user notes first', (tester) async {
      await tester.pumpWidget(
        wrap(userNotes: 'user text', dawNotes: 'daw text'),
      );

      expect(find.text(userLabel), findsOneWidget);
      expect(find.text(dawLabel), findsOneWidget);

      final userY = tester.getTopLeft(find.text('user text')).dy;
      final dawY = tester.getTopLeft(find.text('daw text')).dy;
      expect(
        userY,
        lessThan(dawY),
        reason: 'order must be fixed so the source of each block is obvious',
      );
    });

    testWidgets('whitespace-only values are treated as absent', (tester) async {
      await tester.pumpWidget(wrap(userNotes: '   ', dawNotes: 'real'));

      expect(find.text(userLabel), findsNothing);
      expect(find.text(dawLabel), findsOneWidget);
    });
  });

  group('long DAW notes', () {
    String manyLines(int n) =>
        List.generate(n, (i) => 'line $i').join('\n');

    testWidgets('short notes get no expand toggle', (tester) async {
      await tester.pumpWidget(wrap(dawNotes: manyLines(3), lineLimit: 8));

      expect(find.text('Expand'), findsNothing);
      expect(find.text('Collapse'), findsNothing);
    });

    testWidgets('a long session log collapses behind a toggle', (tester) async {
      // The case this exists for: a whole session's production notes pasted
      // into REAPER's Notes tab would otherwise push the tasks list off pane.
      await tester.pumpWidget(wrap(dawNotes: manyLines(40), lineLimit: 8));

      expect(find.text('Expand'), findsOneWidget);
    });

    testWidgets('toggling expands and collapses again', (tester) async {
      await tester.pumpWidget(wrap(dawNotes: manyLines(40), lineLimit: 8));

      await tester.tap(find.text('Expand'));
      await tester.pump();
      expect(find.text('Collapse'), findsOneWidget);
      expect(find.text('Expand'), findsNothing);

      // Expanded, the 40 lines push the toggle past the bottom of the 600px
      // test viewport; tapping it there silently misses.
      await tester.ensureVisible(find.text('Collapse'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Collapse'));
      await tester.pump();
      expect(find.text('Expand'), findsOneWidget);
    });

    testWidgets('user notes are never collapsed', (tester) async {
      // They are the user's own text and editable elsewhere; hiding them
      // behind a toggle would be surprising.
      await tester.pumpWidget(wrap(userNotes: manyLines(40), lineLimit: 8));

      expect(find.text('Expand'), findsNothing);
    });
  });
}
