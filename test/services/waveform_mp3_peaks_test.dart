import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:daw_project_manager/services/audio_analysis_service.dart';

import 'waveform_peaks_test.dart' show writeWav, buzz;

// MPEG-1 Layer III, 44100 Hz, 128 kbps, stereo — 417-byte frames with a
// 32-byte side-information block. Only the header and the four global_gain
// fields matter to the peak parser; the rest of the frame stays zeroed.
const _frameBytes = 417;
const _sideInfoOffset = 4;

/// Bit offsets of `global_gain` inside an MPEG-1 stereo side-info block,
/// per ISO/IEC 11172-3 §2.4.3.3 — granule 0/1 × channel 0/1.
const _gainBitOffsets = [41, 100, 159, 218];

void _writeBits(
  Uint8List bytes,
  int byteOffset,
  int bitOffset,
  int numBits,
  int value,
) {
  for (int b = 0; b < numBits; b++) {
    final bit = (value >> (numBits - 1 - b)) & 1;
    final total = bitOffset + b;
    final idx = byteOffset + (total >> 3);
    final mask = 1 << (7 - (total & 7));
    if (bit == 1) {
      bytes[idx] |= mask;
    } else {
      bytes[idx] &= ~mask & 0xFF;
    }
  }
}

/// Builds an MP3 whose granules carry exactly the given `global_gain` values.
///
/// [gainsPerFrame] supplies `[g0c0, g0c1, g1c0, g1c1]` for each frame — two
/// granules, two channels each.
Future<File> writeMp3(String path, List<List<int>> gainsPerFrame) async {
  final bytes = Uint8List(gainsPerFrame.length * _frameBytes);
  for (int f = 0; f < gainsPerFrame.length; f++) {
    final base = f * _frameBytes;
    bytes[base] = 0xFF; // sync
    bytes[base + 1] = 0xFB; // sync + MPEG1 + Layer III + no CRC
    bytes[base + 2] = 0x90; // bitrate idx 9 (128k), sr idx 0 (44100), no pad
    bytes[base + 3] = 0x00; // stereo, no emphasis
    for (int g = 0; g < 4; g++) {
      _writeBits(bytes, base + _sideInfoOffset, _gainBitOffsets[g], 8,
          gainsPerFrame[f][g]);
    }
  }
  final file = File(path);
  await file.writeAsBytes(bytes);
  return file;
}

/// Same `global_gain` on both granules and both channels, for [count] frames.
List<List<int>> flat(int count, int gain) =>
    List.generate(count, (_) => [gain, gain, gain, gain]);

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.tempPath);
  final String tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('waveform_mp3_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    // These cover the decoder-free path: MP3 normally prefers a real decode
    // now, and a machine with ffmpeg installed would take it and never reach
    // the granule parser these tests are about.
    AudioAnalysisService.decoderOverride = (_, _) async => false;
  });

  tearDown(() async {
    AudioAnalysisService.decoderOverride = null;
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('mp3GainToAmplitude', () {
    // Layer III requantisation scales a granule by 2^((global_gain − 210)/4),
    // so the field is logarithmic. Reading it as a linear 0–255 amplitude —
    // which this parser originally did — squeezed a track's whole dynamic
    // range into a few percent and rendered every MP3 as one flat slab.
    test('treats global_gain as logarithmic, 4 steps to a doubling', () {
      expect(mp3GainToAmplitude(210), closeTo(1.0, 1e-9));
      expect(mp3GainToAmplitude(214), closeTo(2.0, 1e-9));
      expect(mp3GainToAmplitude(206), closeTo(0.5, 1e-9));
      expect(mp3GainToAmplitude(186), closeTo(1 / 64, 1e-9));
    });

    test('one step is about 1.5 dB', () {
      final db = 20 * log(mp3GainToAmplitude(200) / mp3GainToAmplitude(199)) /
          ln10;
      expect(db, closeTo(1.505, 0.01));
    });

    test('is strictly increasing across the whole field range', () {
      for (int g = 1; g <= 255; g++) {
        expect(mp3GainToAmplitude(g), greaterThan(mp3GainToAmplitude(g - 1)));
      }
    });
  });

  group('extractWaveformPeaks — MP3 decoder preference', () {
    test('decodes to PCM when a decoder is available', () async {
      // global_gain moves in fixed ~1.5 dB steps, one value per 576 samples,
      // so the envelope it yields is visibly stair-stepped and carries no
      // sample-level peaks. Real PCM is worth the temp file, so the decoder
      // has to be tried first and the header parser kept as the fallback.
      final mp3 = await writeMp3(p.join(tempDir.path, 'pref.mp3'), flat(50, 200));

      String? decodedInput;
      AudioAnalysisService.decoderOverride = (input, output) async {
        decodedInput = input;
        // Stand in for ffmpeg: a real, loud stereo WAV at the output path.
        await writeWav(output, [buzz(4000, 0.8), buzz(4000, 0.8)]);
        return true;
      };

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        mp3.path,
        targetFrames: 100,
      );

      expect(decodedInput, mp3.path);
      expect(peaks, isNotNull);
      // Square wave at 0.8 — this is the decoded PCM, not the granule gains,
      // which were all 200 and would have normalised to full scale.
      expect(peaks!.maxValues.reduce(max), closeTo(0.8, 0.01));
    });

    test('falls back to frame headers when the decoder reports nothing',
        () async {
      AudioAnalysisService.decoderOverride = (_, _) async => false;
      final mp3 = await writeMp3(p.join(tempDir.path, 'fb.mp3'), flat(50, 200));

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        mp3.path,
        targetFrames: 100,
      );

      expect(peaks, isNotNull);
      expect(peaks!.maxValues.reduce(max), closeTo(1.0, 0.01));
    });

    test('falls back when the decoder throws instead of returning', () async {
      // A missing temp directory or an exploding subprocess must cost quality,
      // not the whole waveform.
      AudioAnalysisService.decoderOverride =
          (_, _) async => throw StateError('no decoder here');
      final mp3 = await writeMp3(p.join(tempDir.path, 'boom.mp3'), flat(50, 200));

      expect(
        await AudioAnalysisService.extractWaveformPeaks(mp3.path,
            targetFrames: 100),
        isNotNull,
      );
    });
  });

  group('extractWaveformPeaks — MP3 without a decoder', () {
    test('a quiet passage stays visibly quieter than a loud one', () async {
      // 40 dB apart. Read linearly these two would come out within 15% of
      // each other; the quiet half has to land near the floor instead.
      final mp3 = await writeMp3(
        p.join(tempDir.path, 'dynamics.mp3'),
        [...flat(100, 170), ...flat(100, 210)],
      );

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        mp3.path,
        targetFrames: 200,
      );

      expect(peaks, isNotNull);
      final half = peaks!.frameCount ~/ 2;
      final quiet = peaks.maxValues.sublist(0, half).reduce(max);
      final loud = peaks.maxValues.sublist(half).reduce(max);

      expect(loud, closeTo(1.0, 0.01));
      expect(quiet, lessThan(0.01), reason: 'quiet half was not quiet');
    });

    test('a handful of nonsense granules cannot flatten the whole track',
        () async {
      // Regression: normalising by the outright maximum let a few granules
      // that decode to a spurious global_gain — 0.7% of one real file read as
      // exactly 210, some 40 dB above the music — crush everything else to a
      // hairline. Normalising against the 99th percentile clamps them instead.
      final mp3 = await writeMp3(
        p.join(tempDir.path, 'outliers.mp3'),
        [...flat(199, 180), ...flat(1, 255)],
      );

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        mp3.path,
        targetFrames: 100,
      );

      expect(peaks, isNotNull);
      // The 99.5% of frames carrying the real level must still be full-scale.
      final typical = peaks!.maxValues.sublist(0, 90).reduce(max);
      expect(typical, closeTo(1.0, 0.01),
          reason: 'the outlier flattened the track');
    });

    test('keeps left and right as separate lanes', () async {
      // Left 12 dB above right, held for the whole file.
      final mp3 = await writeMp3(
        p.join(tempDir.path, 'stereo.mp3'),
        List.generate(100, (_) => [210, 202, 210, 202]),
      );

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        mp3.path,
        targetFrames: 100,
      );

      expect(peaks!.hasChannelData, isTrue);
      expect(peaks.channelMax[0].reduce(max), closeTo(1.0, 0.01));
      // 8 global_gain steps down = 2^-2.
      expect(peaks.channelMax[1].reduce(max), closeTo(0.25, 0.01));
    });

    test('carries an RMS body that stays inside the peak outline', () async {
      // Alternating loud/quiet granules: the peak of a bin is the loud one,
      // the body its average, so the two must not coincide.
      final mp3 = await writeMp3(
        p.join(tempDir.path, 'body.mp3'),
        List.generate(200, (i) {
          final g = i.isEven ? 210 : 194;
          return [g, g, g, g];
        }),
      );

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        mp3.path,
        targetFrames: 50,
      );

      expect(peaks!.hasRms, isTrue);
      for (int i = 0; i < peaks.frameCount; i++) {
        expect(peaks.rmsValues[i], lessThanOrEqualTo(peaks.maxValues[i] + 1e-6),
            reason: 'body escaped the outline at frame $i');
      }
      expect(peaks.rmsValues.reduce(max), lessThan(peaks.maxValues.reduce(max)));
    });

    test('reports a duration matching the frame count', () async {
      // 100 frames × 1152 samples at 44100 Hz ≈ 2.61 s.
      final mp3 = await writeMp3(
        p.join(tempDir.path, 'duration.mp3'),
        flat(100, 200),
      );

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        mp3.path,
        targetFrames: 50,
      );

      expect(peaks!.sampleRate, 44100);
      expect(peaks.durationSeconds, closeTo(100 * 1152 / 44100, 0.01));
    });
  });
}
