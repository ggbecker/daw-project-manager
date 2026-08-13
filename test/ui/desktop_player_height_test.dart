import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/dashboard_page.dart';

void main() {
  group('desktopPlayerMaxHeight', () {
    test('scales with the window instead of a fixed 300 px ceiling', () {
      // Two stereo lanes plus the transport chrome need real height before
      // each lane is worth reading; 300 px left roughly 100 px per lane.
      expect(desktopPlayerMaxHeight(1440), greaterThan(300));
      expect(desktopPlayerMaxHeight(2160), greaterThan(600));
    });

    test('never lets the player swallow the window', () {
      for (final windowHeight in [200.0, 400.0, 600.0, 900.0, 1080.0, 1440.0]) {
        expect(desktopPlayerMaxHeight(windowHeight),
            lessThanOrEqualTo(windowHeight * 0.6 + 0.001),
            reason: 'at ${windowHeight}px the player took over the window');
      }
    });

    test('caps out so a very tall monitor does not run away', () {
      expect(desktopPlayerMaxHeight(4000), 720);
      expect(desktopPlayerMaxHeight(10000), 720);
    });

    test('a short window keeps a valid, non-inverted drag range', () {
      // The floor only exists so clamp(min, max) never inverts; it must not
      // grow large enough to hand the player the whole window.
      final short = desktopPlayerMaxHeight(200);
      expect(short, greaterThan(kDesktopPlayerMinHeight));
      expect(short, lessThan(200));
    });

    test('is monotonic — a taller window never allows less', () {
      double previous = 0;
      for (final windowHeight in [200.0, 600.0, 900.0, 1440.0, 2160.0, 4000.0]) {
        final current = desktopPlayerMaxHeight(windowHeight);
        expect(current, greaterThanOrEqualTo(previous),
            reason: 'a ${windowHeight}px window allowed less than a smaller one');
        previous = current;
      }
    });

    test('always exceeds the minimum, so the range is never inverted', () {
      for (final windowHeight in [0.0, 1.0, 200.0, 1080.0, 9999.0]) {
        expect(desktopPlayerMaxHeight(windowHeight),
            greaterThan(kDesktopPlayerMinHeight),
            reason: 'clamp(min, max) would throw at ${windowHeight}px');
      }
    });
  });
}
