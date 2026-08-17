import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/widgets/section_nav_rail.dart';

/// #104 — the rail was lifted out of the settings page so the project detail
/// page could use the same one. These pin the behaviour both pages rely on,
/// including the search box being optional (the detail page has nothing to
/// search).
void main() {
  const items = [
    SectionNavItem(icon: Icons.tune_outlined, label: 'Details'),
    SectionNavItem(icon: Icons.notes_outlined, label: 'Notes'),
    SectionNavItem(
      icon: Icons.history_outlined,
      label: 'Work Sessions',
      newGroup: true,
    ),
  ];

  Widget wrap({
    int activeIndex = 0,
    ValueChanged<int>? onTap,
    TextEditingController? searchController,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 500,
            child: SectionNavRail(
              items: items,
              activeIndex: activeIndex,
              onTap: onTap ?? (_) {},
              searchController: searchController,
              searchHint: searchController == null ? null : 'Search',
            ),
          ),
        ),
      );

  testWidgets('lists every section', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Work Sessions'), findsOneWidget);
  });

  testWidgets('reports the index that was tapped', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(wrap(onTap: taps.add));

    await tester.tap(find.text('Notes'));
    await tester.pump();

    expect(taps, [1]);
  });

  testWidgets('marks the active section', (tester) async {
    await tester.pumpWidget(wrap(activeIndex: 1));

    final active = tester.widget<Text>(find.text('Notes'));
    final inactive = tester.widget<Text>(find.text('Details'));

    expect(active.style?.fontWeight, FontWeight.w600);
    expect(inactive.style?.fontWeight, FontWeight.normal);
  });

  testWidgets('draws a divider above an item that starts a group',
      (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.byType(Divider), findsOneWidget);
  });

  group('search box', () {
    testWidgets('is absent when no controller is given', (tester) async {
      // The project detail page has nothing to search across.
      await tester.pumpWidget(wrap());

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('appears when a controller is given', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(wrap(searchController: controller));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('a running search deselects every section', (tester) async {
      // While results from all sections are showing, none of them is "the
      // current one".
      final controller = TextEditingController(text: 'theme');
      addTearDown(controller.dispose);

      await tester.pumpWidget(wrap(activeIndex: 0, searchController: controller));

      final first = tester.widget<Text>(find.text('Details'));
      expect(first.style?.fontWeight, FontWeight.normal);
    });

    testWidgets('the clear button empties the field', (tester) async {
      final controller = TextEditingController(text: 'theme');
      addTearDown(controller.dispose);

      await tester.pumpWidget(wrap(searchController: controller));
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(controller.text, isEmpty);
    });
  });
}
