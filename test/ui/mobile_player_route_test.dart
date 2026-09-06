import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/mobile_player_page.dart';

void main() {
  test('non-Android keeps the platform default MaterialPageRoute', () {
    expect(
      buildMobilePlayerRoute(android: false),
      isA<MaterialPageRoute<void>>(),
    );
  });

  test('Android uses a custom timed PageRouteBuilder', () {
    final route = buildMobilePlayerRoute(android: true);
    expect(route, isA<PageRouteBuilder<void>>());
    expect(route, isNot(isA<MaterialPageRoute<void>>()));

    final prb = route as PageRouteBuilder<void>;
    expect(prb.transitionDuration, const Duration(milliseconds: 300));
    expect(prb.reverseTransitionDuration, const Duration(milliseconds: 250));
  });

  testWidgets('Android route slides the page up from the bottom edge',
      (tester) async {
    final route = buildMobilePlayerRoute(android: true) as PageRouteBuilder<void>;
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 1),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) => route.buildTransitions(
            context,
            controller,
            controller,
            const SizedBox(key: Key('child')),
          ),
        ),
      ),
    );

    SlideTransition slide() =>
        tester.widget<SlideTransition>(find.byType(SlideTransition));

    // Fully dismissed: the page sits one whole height below its final spot.
    controller.value = 0;
    await tester.pump();
    expect(slide().position.value, const Offset(0, 1));

    // Half open: on its way up, still below the final spot.
    controller.value = 0.5;
    await tester.pump();
    expect(slide().position.value.dx, 0);
    expect(slide().position.value.dy, greaterThan(0));
    expect(slide().position.value.dy, lessThan(1));

    // Fully open: settled in place.
    controller.value = 1;
    await tester.pump();
    expect(slide().position.value, Offset.zero);
  });
}
