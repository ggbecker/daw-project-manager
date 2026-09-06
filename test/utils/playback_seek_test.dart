import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/playback_seek.dart';

void main() {
  group('seekTarget', () {
    const total = Duration(minutes: 3); // 180s

    test('jumps forward and backward by the given seconds', () {
      expect(seekTarget(const Duration(seconds: 40), 5, total),
          const Duration(seconds: 45));
      expect(seekTarget(const Duration(seconds: 40), -5, total),
          const Duration(seconds: 35));
    });

    test('clamps to zero at the start', () {
      expect(seekTarget(const Duration(seconds: 3), -5, total), Duration.zero);
      expect(seekTarget(Duration.zero, -30, total), Duration.zero);
    });

    test('clamps to the track length at the end', () {
      expect(seekTarget(const Duration(seconds: 178), 5, total), total);
    });

    test('only enforces the lower bound when the length is unknown', () {
      // duration 0 = not loaded yet; a +5s tap must still advance, not clamp.
      expect(seekTarget(const Duration(seconds: 10), 5, Duration.zero),
          const Duration(seconds: 15));
      expect(seekTarget(const Duration(seconds: 2), -5, Duration.zero),
          Duration.zero);
    });
  });
}
