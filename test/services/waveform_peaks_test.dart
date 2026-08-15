import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:daw_project_manager/services/audio_analysis_service.dart';
import 'package:daw_project_manager/services/waveform_disk_cache.dart';

/// Points the disk cache at a real temp folder instead of a device path.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.supportPath);
  final String supportPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;
}

/// Writes a 16-bit PCM WAV whose channels are [channels] (each the same
/// length, samples in −1…+1).
Future<File> writeWav(
  String path,
  List<List<double>> channels, {
  int sampleRate = 8000,
}) async {
  final numChannels = channels.length;
  final numFrames = channels.first.length;
  final dataSize = numFrames * numChannels * 2;

  final bytes = Uint8List(44 + dataSize);
  final bd = ByteData.sublistView(bytes);
  bytes.setAll(0, 'RIFF'.codeUnits);
  bd.setUint32(4, 36 + dataSize, Endian.little);
  bytes.setAll(8, 'WAVE'.codeUnits);
  bytes.setAll(12, 'fmt '.codeUnits);
  bd.setUint32(16, 16, Endian.little);
  bd.setUint16(20, 1, Endian.little); // PCM
  bd.setUint16(22, numChannels, Endian.little);
  bd.setUint32(24, sampleRate, Endian.little);
  bd.setUint32(28, sampleRate * numChannels * 2, Endian.little);
  bd.setUint16(32, numChannels * 2, Endian.little);
  bd.setUint16(34, 16, Endian.little);
  bytes.setAll(36, 'data'.codeUnits);
  bd.setUint32(40, dataSize, Endian.little);

  for (int f = 0; f < numFrames; f++) {
    for (int c = 0; c < numChannels; c++) {
      final off = 44 + (f * numChannels + c) * 2;
      bd.setInt16(off, (channels[c][f] * 32767).round(), Endian.little);
    }
  }

  final file = File(path);
  await file.writeAsBytes(bytes);
  return file;
}

/// Alternating ±[amplitude] for [length] samples, so every bin sees both a
/// minimum and a maximum whatever the bin boundaries land on.
List<double> buzz(int length, double amplitude) =>
    List<double>.generate(length, (i) => i.isEven ? amplitude : -amplitude);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('waveform_peaks_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('extractWaveformPeaks — stereo lanes', () {
    test('keeps left and right as separate envelopes', () async {
      final wav = await writeWav(
        p.join(tempDir.path, 'stereo.wav'),
        [buzz(4000, 1.0), buzz(4000, 0.25)],
      );

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );

      expect(peaks, isNotNull);
      expect(peaks!.hasChannelData, isTrue);
      expect(peaks.channelMin, hasLength(2));
      expect(peaks.channelMax, hasLength(2));
      expect(peaks.channelMax[0], hasLength(peaks.frameCount));

      // Loud left, quiet right — the whole point of drawing two lanes.
      expect(peaks.channelMax[0].reduce((a, b) => a > b ? a : b), closeTo(1.0, 0.01));
      expect(peaks.channelMax[1].reduce((a, b) => a > b ? a : b), closeTo(0.25, 0.01));
      expect(peaks.channelMin[0].reduce((a, b) => a < b ? a : b), closeTo(-1.0, 0.01));
      expect(peaks.channelMin[1].reduce((a, b) => a < b ? a : b), closeTo(-0.25, 0.01));

      // The mono mixdown is still the average, not either channel.
      expect(peaks.maxValues.reduce((a, b) => a > b ? a : b), closeTo(0.625, 0.01));
    });

    test('carries an RMS body sitting inside the peak outline', () async {
      // A square wave has RMS == peak; a sine sits at peak/√2. The gap between
      // the two is the whole point of the body layer, so it has to be real
      // per-frame data rather than a scaled copy of the peaks.
      final sine = List<double>.generate(
          8000, (i) => sin(2 * pi * i / 40) * 0.8);
      final wav = await writeWav(p.join(tempDir.path, 'sine.wav'), [sine]);

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );

      expect(peaks!.hasRms, isTrue);
      expect(peaks.rmsValues, hasLength(peaks.frameCount));
      for (int i = 0; i < peaks.frameCount; i++) {
        expect(peaks.rmsValues[i], lessThanOrEqualTo(peaks.maxValues[i] + 1e-6),
            reason: 'body escaped the outline at frame $i');
        expect(peaks.rmsValues[i], greaterThan(0));
      }
      // 0.8 peak → 0.8/√2 ≈ 0.566 RMS.
      final meanRms =
          peaks.rmsValues.reduce((a, b) => a + b) / peaks.frameCount;
      expect(meanRms, closeTo(0.566, 0.02));
    });

    test('gives each lane its own RMS body', () async {
      final wav = await writeWav(
        p.join(tempDir.path, 'stereo_rms.wav'),
        [buzz(4000, 1.0), buzz(4000, 0.25)],
      );

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );

      expect(peaks!.hasChannelRms(0), isTrue);
      expect(peaks.hasChannelRms(1), isTrue);
      // Alternating ±a is a square wave, so RMS equals the amplitude.
      expect(peaks.channelRms[0].first, closeTo(1.0, 0.01));
      expect(peaks.channelRms[1].first, closeTo(0.25, 0.01));
    });

    test('a mono source carries no lanes, only the mixdown', () async {
      final wav = await writeWav(
        p.join(tempDir.path, 'mono.wav'),
        [buzz(4000, 0.5)],
      );

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );

      expect(peaks, isNotNull);
      expect(peaks!.hasChannelData, isFalse);
      expect(peaks.channelMin, isEmpty);
      expect(peaks.maxValues.reduce((a, b) => a > b ? a : b), closeTo(0.5, 0.01));
    });

    test('drops channels beyond the two the renderer can show', () async {
      final wav = await writeWav(
        p.join(tempDir.path, 'surround.wav'),
        [buzz(4000, 1.0), buzz(4000, 0.8), buzz(4000, 0.6), buzz(4000, 0.4)],
      );

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );

      expect(peaks!.channelMin, hasLength(maxWaveformLanes));
      expect(peaks.channelMax, hasLength(maxWaveformLanes));
    });
  });

  group('extractWaveformPeaks — bin coverage', () {
    // Regression: bin width used to be `numSamples ~/ frames`, truncated, so
    // the last `numSamples % frames` samples were covered by no bin at all —
    // a final transient simply never appeared, and every drawn column sat
    // slightly earlier than the audio it represented.
    test('the very end of the file lands in the last frame', () async {
      // 256 × 100 + 90: the truncated bin width stops 90 samples short.
      const total = 25690;
      final samples = List<double>.filled(total, 0.0);
      for (int i = total - 50; i < total; i++) {
        samples[i] = i.isEven ? 0.9 : -0.9;
      }

      final wav = await writeWav(p.join(tempDir.path, 'tail.wav'), [samples]);
      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 256,
      );

      expect(peaks, isNotNull);
      expect(peaks!.frameCount, 256);
      expect(peaks.maxValues.last, greaterThan(0.5));
      expect(peaks.minValues.last, lessThan(-0.5));
    });

    test('every frame is populated for a file shorter than the frame count',
        () async {
      final wav = await writeWav(
        p.join(tempDir.path, 'short.wav'),
        [buzz(64, 1.0)],
      );

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 4096,
      );

      // Clamped to the sample count rather than emitting empty frames. Each
      // frame holds a single sample here, so it registers on one side of zero
      // only — what matters is that none of them is a dead, zero-width frame.
      expect(peaks!.frameCount, 64);
      for (int i = 0; i < peaks.frameCount; i++) {
        expect(peaks.maxValues[i] - peaks.minValues[i], greaterThan(0),
            reason: 'frame $i covered no samples');
      }
    });
  });

  group('WaveformDiskCache', () {
    late Directory supportDir;

    setUp(() async {
      supportDir = await Directory.systemTemp.createTemp('waveform_cache_test_');
      PathProviderPlatform.instance = _FakePathProvider(supportDir.path);
    });

    tearDown(() async {
      if (await supportDir.exists()) await supportDir.delete(recursive: true);
    });

    test('round-trips the stereo lanes, not just the mixdown', () async {
      final wav = await writeWav(
        p.join(tempDir.path, 'cached.wav'),
        [buzz(4000, 1.0), buzz(4000, 0.25)],
      );
      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );

      await WaveformDiskCache.save(wav.path, peaks!);
      final loaded = await WaveformDiskCache.load(wav.path);

      expect(loaded, isNotNull);
      expect(loaded!.frameCount, peaks.frameCount);
      expect(loaded.hasChannelData, isTrue);
      expect(loaded.hasRms, isTrue);
      expect(loaded.channelMin, hasLength(2));
      for (int i = 0; i < peaks.frameCount; i++) {
        expect(loaded.rmsValues[i], closeTo(peaks.rmsValues[i], 1e-6));
      }
      for (int c = 0; c < 2; c++) {
        expect(loaded.hasChannelRms(c), isTrue);
        for (int i = 0; i < peaks.frameCount; i++) {
          expect(loaded.channelMax[c][i], closeTo(peaks.channelMax[c][i], 1e-6));
          expect(loaded.channelMin[c][i], closeTo(peaks.channelMin[c][i], 1e-6));
          expect(loaded.channelRms[c][i], closeTo(peaks.channelRms[c][i], 1e-6));
        }
      }
    });

    test('round-trips a mono entry with no lanes', () async {
      final wav = await writeWav(
        p.join(tempDir.path, 'cached_mono.wav'),
        [buzz(4000, 0.5)],
      );
      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );

      await WaveformDiskCache.save(wav.path, peaks!);
      final loaded = await WaveformDiskCache.load(wav.path);

      expect(loaded, isNotNull);
      expect(loaded!.hasChannelData, isFalse);
      expect(loaded.channelMin, isEmpty);
      expect(loaded.maxValues, hasLength(peaks.frameCount));
    });

    test('rejects an entry written by the pre-lane cache format', () async {
      // v1 entries have neither the lanes nor the higher frame count, so they
      // must be discarded and re-extracted rather than read as v2 and
      // misparsed.
      final wav = await writeWav(
        p.join(tempDir.path, 'legacy.wav'),
        [buzz(4000, 0.5)],
      );
      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );
      await WaveformDiskCache.save(wav.path, peaks!);

      // Find the entry we just wrote and stamp it back to version 1.
      final entry = Directory(p.join(supportDir.path, 'waveform_cache'))
          .listSync()
          .whereType<File>()
          .single;
      final bytes = await entry.readAsBytes();
      ByteData.sublistView(bytes).setUint32(4, 1, Endian.little);
      await entry.writeAsBytes(bytes);

      expect(await WaveformDiskCache.load(wav.path), isNull);
    });

    test('invalidates when the source file changes', () async {
      final path = p.join(tempDir.path, 'changing.wav');
      final wav = await writeWav(path, [buzz(4000, 0.5)]);
      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );
      await WaveformDiskCache.save(wav.path, peaks!);
      expect(await WaveformDiskCache.load(wav.path), isNotNull);

      // Rewrite with different content, stamping the mtime explicitly rather
      // than sleeping past the filesystem's timestamp granularity.
      await writeWav(path, [buzz(4000, 0.9)]);
      File(path).setLastModifiedSync(
        DateTime.now().add(const Duration(seconds: 5)),
      );

      expect(await WaveformDiskCache.load(wav.path), isNull);
    });
  });
}
