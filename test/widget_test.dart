import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/widgets/shortcuts_help_dialog.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pumps [widget] inside a minimal MaterialApp with the given [brightness].
Future<void> pumpWithTheme(
  WidgetTester tester,
  Widget widget, {
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(body: Center(child: widget)),
    ),
  );
}

// ---------------------------------------------------------------------------
// KeyCap
// ---------------------------------------------------------------------------

void main() {
  group('KeyCap — rendering', () {
    testWidgets('displays the label text', (tester) async {
      await pumpWithTheme(tester, const KeyCap(label: 'Ctrl'));
      expect(find.text('Ctrl'), findsOneWidget);
    });

    testWidgets('renders in light theme without throwing', (tester) async {
      await pumpWithTheme(tester, const KeyCap(label: 'F'),
          brightness: Brightness.light);
      expect(find.byType(KeyCap), findsOneWidget);
    });

    testWidgets('renders in dark theme without throwing', (tester) async {
      await pumpWithTheme(tester, const KeyCap(label: 'F'),
          brightness: Brightness.dark);
      expect(find.byType(KeyCap), findsOneWidget);
    });

    testWidgets('uses light background in light theme', (tester) async {
      await pumpWithTheme(tester, const KeyCap(label: 'X'),
          brightness: Brightness.light);

      final container = tester.widget<Container>(
        find.descendant(
            of: find.byType(KeyCap), matching: find.byType(Container)),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFF0F0F0));
    });

    testWidgets('uses dark background in dark theme', (tester) async {
      await pumpWithTheme(tester, const KeyCap(label: 'X'),
          brightness: Brightness.dark);

      final container = tester.widget<Container>(
        find.descendant(
            of: find.byType(KeyCap), matching: find.byType(Container)),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF3A3A3C));
    });
  });

  // -------------------------------------------------------------------------
  // ShortcutEntry
  // -------------------------------------------------------------------------

  group('ShortcutEntry — rendering', () {
    testWidgets('displays the description text', (tester) async {
      await pumpWithTheme(
        tester,
        const ShortcutEntry(keys: ['Ctrl'], description: 'Open search'),
      );
      expect(find.text('Open search'), findsOneWidget);
    });

    testWidgets('renders a KeyCap for every key', (tester) async {
      await pumpWithTheme(
        tester,
        const ShortcutEntry(keys: ['Ctrl', 'F'], description: 'Focus search'),
      );
      expect(find.text('Ctrl'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('inserts + between multiple keys', (tester) async {
      await pumpWithTheme(
        tester,
        const ShortcutEntry(
            keys: ['Ctrl', 'Shift', 'F'], description: 'Something'),
      );
      // Three keys → two '+' separators
      expect(find.text('+'), findsNWidgets(2));
    });

    testWidgets('shows no + separator for a single key', (tester) async {
      await pumpWithTheme(
        tester,
        const ShortcutEntry(keys: ['Space'], description: 'Play/Pause'),
      );
      expect(find.text('+'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // ShortcutGroup
  // -------------------------------------------------------------------------

  group('ShortcutGroup — rendering', () {
    testWidgets('displays the group label', (tester) async {
      await pumpWithTheme(
        tester,
        const ShortcutGroup(label: 'Navigation', entries: []),
      );
      expect(find.text('Navigation'), findsOneWidget);
    });

    testWidgets('renders all provided entries', (tester) async {
      await pumpWithTheme(
        tester,
        const ShortcutGroup(
          label: 'Global',
          entries: [
            ShortcutEntry(keys: ['Ctrl', 'F'], description: 'Search'),
            ShortcutEntry(keys: ['Ctrl', 'R'], description: 'Rescan'),
          ],
        ),
      );
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Rescan'), findsOneWidget);
    });

    testWidgets('renders with an empty entries list without throwing',
        (tester) async {
      await pumpWithTheme(
        tester,
        const ShortcutGroup(label: 'Empty', entries: []),
      );
      expect(find.byType(ShortcutGroup), findsOneWidget);
    });
  });
}
