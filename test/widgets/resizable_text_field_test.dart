import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/widgets/resizable_text_field.dart';

Future<void> _pump(
  WidgetTester tester, {
  required TextEditingController controller,
  double initialHeight = 130,
  double expandedHeight = 400,
  double minHeight = 100,
  double maxHeight = 800,
  ValueChanged<String>? onChanged,
  bool? enableDragResize,
  bool readOnly = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ResizableTextField(
          controller: controller,
          labelText: 'Notes',
          expandTooltip: 'Expand',
          collapseTooltip: 'Collapse',
          initialHeight: initialHeight,
          expandedHeight: expandedHeight,
          minHeight: minHeight,
          maxHeight: maxHeight,
          onChanged: onChanged,
          enableDragResize: enableDragResize,
          readOnly: readOnly,
        ),
      ),
    ),
  );
}

double _heightOf(WidgetTester tester) => tester
    .widget<SizedBox>(find.byKey(const Key('resizableTextFieldHeightBox')))
    .height!;

void main() {
  group('ResizableTextField', () {
    testWidgets('renders the label and starts collapsed at initialHeight',
        (tester) async {
      final controller = TextEditingController();
      await _pump(tester, controller: controller);

      expect(find.text('Notes'), findsOneWidget);
      expect(_heightOf(tester), 130);
      expect(find.byIcon(Icons.open_in_full), findsOneWidget);
      expect(find.byTooltip('Expand'), findsOneWidget);
    });

    testWidgets('tapping the expand icon grows to expandedHeight and flips the icon',
        (tester) async {
      final controller = TextEditingController();
      await _pump(tester, controller: controller);

      await tester.tap(find.byIcon(Icons.open_in_full));
      await tester.pumpAndSettle();

      expect(_heightOf(tester), 400);
      expect(find.byIcon(Icons.close_fullscreen), findsOneWidget);
      expect(find.byTooltip('Collapse'), findsOneWidget);
    });

    testWidgets('tapping again collapses back to initialHeight',
        (tester) async {
      final controller = TextEditingController();
      await _pump(tester, controller: controller);

      await tester.tap(find.byIcon(Icons.open_in_full));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close_fullscreen));
      await tester.pumpAndSettle();

      expect(_heightOf(tester), 130);
      expect(find.byIcon(Icons.open_in_full), findsOneWidget);
    });

    testWidgets('dragging the resize grip down grows the field and clamps at maxHeight',
        (tester) async {
      final controller = TextEditingController();
      await _pump(tester, controller: controller, maxHeight: 200);

      await tester.drag(
        find.byKey(const Key('resizableTextFieldGrip')),
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();

      expect(_heightOf(tester), 200);
    });

    testWidgets('dragging the resize grip up shrinks the field and clamps at minHeight',
        (tester) async {
      final controller = TextEditingController();
      await _pump(tester, controller: controller, minHeight: 60);

      await tester.drag(
        find.byKey(const Key('resizableTextFieldGrip')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      expect(_heightOf(tester), 60);
    });

    testWidgets('dragging past initialHeight flips to the collapse icon without tapping the button',
        (tester) async {
      final controller = TextEditingController();
      await _pump(tester, controller: controller);

      await tester.drag(
        find.byKey(const Key('resizableTextFieldGrip')),
        const Offset(0, 50),
      );
      await tester.pumpAndSettle();

      expect(_heightOf(tester), greaterThan(130));
      expect(find.byIcon(Icons.close_fullscreen), findsOneWidget);
    });

    testWidgets('shows the resize grip when enableDragResize is true',
        (tester) async {
      final controller = TextEditingController();
      await _pump(tester, controller: controller, enableDragResize: true);

      expect(find.byKey(const Key('resizableTextFieldGrip')), findsOneWidget);
    });

    testWidgets('hides the resize grip when enableDragResize is false (mobile)',
        (tester) async {
      final controller = TextEditingController();
      await _pump(tester, controller: controller, enableDragResize: false);

      expect(find.byKey(const Key('resizableTextFieldGrip')), findsNothing);
      // The tap-based expand toggle is still available on mobile.
      expect(find.byIcon(Icons.open_in_full), findsOneWidget);
    });

    testWidgets('typing calls onChanged with the new text', (tester) async {
      final controller = TextEditingController();
      final changes = <String>[];
      await _pump(tester, controller: controller, onChanged: changes.add);

      await tester.enterText(find.byType(TextFormField), 'hello world');
      await tester.pump();

      expect(changes, contains('hello world'));
      expect(controller.text, 'hello world');
    });

    testWidgets('readOnly rejects typed input but still allows expand/collapse',
        (tester) async {
      final controller = TextEditingController(text: 'extracted notes');
      await _pump(tester, controller: controller, readOnly: true);

      await tester.enterText(find.byType(TextFormField), 'should not stick');
      await tester.pump();
      expect(controller.text, 'extracted notes');

      await tester.tap(find.byIcon(Icons.open_in_full));
      await tester.pumpAndSettle();
      expect(_heightOf(tester), 400);
    });
  });
}
