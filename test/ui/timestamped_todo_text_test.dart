import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/mobile_player_page.dart';

void main() {
  group('buildTimestampedTodoText', () {
    test('prefixes the playback position as [m:ss]', () {
      expect(
        buildTimestampedTodoText(
            const Duration(minutes: 1, seconds: 23), 'fix vocal reverb'),
        '[01:23] fix vocal reverb',
      );
    });

    test('handles zero position', () {
      expect(
        buildTimestampedTodoText(Duration.zero, 'intro too long'),
        '[00:00] intro too long',
      );
    });

    test('trims surrounding whitespace from the entered text', () {
      expect(
        buildTimestampedTodoText(const Duration(seconds: 5), '  tighten kick  '),
        '[00:05] tighten kick',
      );
    });

    test('minutes past 60 wrap within the mm:ss field', () {
      // 61 minutes => minutes.remainder(60) == 1
      expect(
        buildTimestampedTodoText(
            const Duration(minutes: 61, seconds: 9), 'note'),
        '[01:09] note',
      );
    });
  });
}
