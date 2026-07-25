import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/widgets/filter_dropdown.dart';

Future<void> _pump(
  WidgetTester tester, {
  required String? value,
  required ValueChanged<String?> onChanged,
  Color hoverColor = const Color(0xFF123456),
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(hoverColor: hoverColor),
      home: Scaffold(
        body: FilterDropdown<String>(
          icon: Icons.piano,
          value: value,
          hintText: 'Filter by DAW',
          items: const [
            DropdownMenuItem<String>(value: null, child: Text('All DAWs')),
            DropdownMenuItem<String>(
              value: 'Ableton Live',
              child: Text('Ableton Live'),
            ),
            DropdownMenuItem<String>(
              value: 'FL Studio',
              child: Text('FL Studio'),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    ),
  );
}

BoxDecoration _containerDecoration(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration
        as BoxDecoration;

void main() {
  group('FilterDropdown', () {
    testWidgets('renders the leading icon', (tester) async {
      await _pump(tester, value: null, onChanged: (_) {});

      expect(find.byIcon(Icons.piano), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('selecting a menu item calls onChanged with that value', (
      tester,
    ) async {
      String? selected;
      await _pump(tester, value: null, onChanged: (value) => selected = value);

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      // The item text is also present (invisible) in the closed button's own
      // IndexedStack for sizing, so once the menu is open there are two
      // matches — the closed button's copy and the open overlay's entry.
      // Tap the last one, the interactive overlay item.
      await tester.tap(find.text('Ableton Live').last);
      await tester.pumpAndSettle();

      expect(selected, 'Ableton Live');
    });

    testWidgets(
      'background highlights with the theme hover color while the mouse is over it, and clears on exit',
      (tester) async {
        const hoverColor = Color(0xFF123456);
        await _pump(
          tester,
          value: null,
          onChanged: (_) {},
          hoverColor: hoverColor,
        );

        expect(_containerDecoration(tester).color, Colors.transparent);

        // Start far outside the (small, top-left) widget's bounds so the
        // first moveTo below is a genuine hover-enter, not already inside.
        final outside = const Offset(750, 550);
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await gesture.addPointer(location: outside);
        await tester.pump();

        await gesture.moveTo(
          tester.getCenter(find.byType(FilterDropdown<String>)),
        );
        await tester.pump();
        expect(_containerDecoration(tester).color, hoverColor);

        await gesture.moveTo(outside);
        await tester.pump();
        expect(_containerDecoration(tester).color, Colors.transparent);
      },
    );
  });
}
