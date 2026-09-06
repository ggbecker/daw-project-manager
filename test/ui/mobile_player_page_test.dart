import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/mobile_player_page.dart';

void main() {
  group('isAnalyzablePreviewPath', () {
    // Gates whether the mobile player tries to extract a waveform for the
    // current track — a real local file yes, a not-yet-downloaded Drive
    // reference (or nothing) no.
    test('true for a real local file path', () {
      expect(isAnalyzablePreviewPath('/data/user/0/app/files/mix.wav'), isTrue);
    });

    test('false for null or empty', () {
      expect(isAnalyzablePreviewPath(null), isFalse);
      expect(isAnalyzablePreviewPath(''), isFalse);
    });

    test('false for an undownloaded drive:// reference', () {
      expect(isAnalyzablePreviewPath('drive://1a2b3c'), isFalse);
    });
  });
}
