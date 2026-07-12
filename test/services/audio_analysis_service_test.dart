import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/audio_analysis_service.dart';

void main() {
  group('AudioAnalysisService.needsMp3ConversionForSharing', () {
    test('returns true for .wav', () {
      expect(AudioAnalysisService.needsMp3ConversionForSharing('/x/song.wav'), isTrue);
    });

    test('returns true for .aiff and .aif', () {
      expect(AudioAnalysisService.needsMp3ConversionForSharing('/x/song.aiff'), isTrue);
      expect(AudioAnalysisService.needsMp3ConversionForSharing('/x/song.aif'), isTrue);
    });

    test('returns true for .flac', () {
      expect(AudioAnalysisService.needsMp3ConversionForSharing('/x/song.flac'), isTrue);
    });

    test('returns false for .mp3 (already compatible)', () {
      expect(AudioAnalysisService.needsMp3ConversionForSharing('/x/song.mp3'), isFalse);
    });

    test('returns false for .m4a and .aac', () {
      expect(AudioAnalysisService.needsMp3ConversionForSharing('/x/song.m4a'), isFalse);
      expect(AudioAnalysisService.needsMp3ConversionForSharing('/x/song.aac'), isFalse);
    });

    test('is case-insensitive', () {
      expect(AudioAnalysisService.needsMp3ConversionForSharing('/x/SONG.WAV'), isTrue);
    });
  });
}
