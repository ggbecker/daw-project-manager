import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/utils/playback_todo_utils.dart';

void main() {
  group('formatPlaybackTimestamp', () {
    test('formats zero duration as 00:00', () {
      expect(formatPlaybackTimestamp(Duration.zero), '00:00');
    });

    test('formats sub-minute duration', () {
      expect(formatPlaybackTimestamp(const Duration(seconds: 7)), '00:07');
    });

    test('formats minutes and seconds without hours', () {
      expect(formatPlaybackTimestamp(const Duration(minutes: 1, seconds: 23)), '01:23');
    });

    test('omits hour component under one hour', () {
      expect(formatPlaybackTimestamp(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('includes hour component once duration reaches an hour', () {
      expect(
        formatPlaybackTimestamp(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '01:02:03',
      );
    });
  });

  group('buildTimestampedTodoText', () {
    test('prefixes note with formatted timestamp', () {
      expect(
        buildTimestampedTodoText(const Duration(minutes: 1, seconds: 23), 'Fix the kick drum'),
        '[01:23] Fix the kick drum',
      );
    });

    test('trims surrounding whitespace from the note', () {
      expect(
        buildTimestampedTodoText(Duration.zero, '  needs reverb  '),
        '[00:00] needs reverb',
      );
    });

    test('handles timestamps past one hour', () {
      expect(
        buildTimestampedTodoText(const Duration(hours: 1, minutes: 5), 'long jam section'),
        '[01:05:00] long jam section',
      );
    });
  });
}
