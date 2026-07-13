import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/audio_analysis_service.dart';

void main() {
  group('AudioAnalysisService.needsConversionForSharing', () {
    test('returns true for .wav', () {
      expect(AudioAnalysisService.needsConversionForSharing('/x/song.wav'), isTrue);
    });

    test('returns true for .aiff and .aif', () {
      expect(AudioAnalysisService.needsConversionForSharing('/x/song.aiff'), isTrue);
      expect(AudioAnalysisService.needsConversionForSharing('/x/song.aif'), isTrue);
    });

    test('returns true for .flac', () {
      expect(AudioAnalysisService.needsConversionForSharing('/x/song.flac'), isTrue);
    });

    test('returns false for .mp3 (already compatible)', () {
      expect(AudioAnalysisService.needsConversionForSharing('/x/song.mp3'), isFalse);
    });

    test('returns false for .m4a and .aac', () {
      expect(AudioAnalysisService.needsConversionForSharing('/x/song.m4a'), isFalse);
      expect(AudioAnalysisService.needsConversionForSharing('/x/song.aac'), isFalse);
    });

    test('is case-insensitive', () {
      expect(AudioAnalysisService.needsConversionForSharing('/x/SONG.WAV'), isTrue);
    });
  });
}
