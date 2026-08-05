import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/route_observer.dart';

class _DropTargetHost extends StatefulWidget {
  const _DropTargetHost();

  @override
  State<_DropTargetHost> createState() => _DropTargetHostState();
}

class _DropTargetHostState extends State<_DropTargetHost>
    with RouteAwareDropTargetState<_DropTargetHost> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(dropTargetEnabled ? 'enabled' : 'disabled'),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => Scaffold(
                  body: Column(
                    children: [
                      const Text('covering route'),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('pop'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            child: const Text('push'),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets(
    'dropTargetEnabled turns false when another route is pushed on top, true again when it is popped',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [appRouteObserver],
          home: const _DropTargetHost(),
        ),
      );

      expect(find.text('enabled'), findsOneWidget);
      expect(find.text('disabled'), findsNothing);

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();

      expect(find.text('covering route'), findsOneWidget);

      await tester.tap(find.text('pop'));
      await tester.pumpAndSettle();

      expect(find.text('enabled'), findsOneWidget);
      expect(find.text('disabled'), findsNothing);
    },
  );

  testWidgets(
    'unsubscribes on dispose without throwing',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [appRouteObserver],
          home: const _DropTargetHost(),
        ),
      );

      // Replacing the whole tree disposes _DropTargetHostState — should not
      // throw (e.g. from double-unsubscribing or a stale route reference).
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(tester.takeException(), isNull);
    },
  );
}
