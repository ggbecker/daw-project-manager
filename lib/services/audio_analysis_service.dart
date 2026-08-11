import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Results of audio loudness & mastering analysis.
class AudioAnalysisResult {
  /// Integrated loudness per ITU-R BS.1770-4 (LUFS / LKFS).
  final double integratedLufs;

  /// True peak in dBTP (sample peak, not 4× oversampled, but accurate enough for preview).
  final double truePeakDbTp;

  /// Peak level in dBFS.
  final double peakDbFs;

  /// RMS level in dBFS (all channels combined).
  final double rmsDbFs;

  /// Crest factor / dynamic range: peak − RMS in dB.
  final double dynamicRange;

  final int sampleRate;
  final int bitDepth;
  final int channels;
  final double durationSeconds;

  const AudioAnalysisResult({
    required this.integratedLufs,
    required this.truePeakDbTp,
    required this.peakDbFs,
    required this.rmsDbFs,
    required this.dynamicRange,
    required this.sampleRate,
    required this.bitDepth,
    required this.channels,
    required this.durationSeconds,
  });
}

/// Lightweight audio file metadata (format-agnostic).
class AudioFileInfo {
  final int sampleRate;
  final int? bitDepth;      // null for lossy formats (MP3, AAC, OGG…)
  final int? bitrateKbps;   // null for lossless formats
  final int channels;

  const AudioFileInfo({
    required this.sampleRate,
    this.bitDepth,
    this.bitrateKbps,
    required this.channels,
  });
}

/// Analyses WAV files and produces mastering-relevant loudness metrics.
/// All heavy work runs in a background isolate.
class AudioAnalysisService {
  /// Returns basic audio metadata for WAV, MP3, FLAC, OGG, and AIFF files.
  /// Returns null if the format is unrecognised or the file cannot be read.
  static Future<AudioFileInfo?> getFileInfo(String filePath) async {
    try {
      return await Isolate.run(() => _readFileInfo(filePath));
    } catch (_) {
      return null;
    }
  }

  /// Analyse a WAV file. Returns null for non-WAV or unsupported formats.
  static Future<AudioAnalysisResult?> analyzeFile(String filePath) async {
    if (!filePath.toLowerCase().endsWith('.wav')) return null;
    try {
      return await Isolate.run(() => _analyzeWavFile(filePath));
    } catch (_) {
      return null;
    }
  }

  /// Write a mono-mixed version of [inputPath] to [outputPath].
  /// Returns true on success. Both paths must be accessible to the isolate.
  /// Returns false for non-WAV, already-mono, or unsupported formats.
  static Future<bool> writeMonoWavFile(String inputPath, String outputPath) async {
    final ext = inputPath.toLowerCase().split('.').last;
    if (ext == 'wav') {
      try {
        return await Isolate.run(() => _writeMonoWavIsolate(inputPath, outputPath));
      } catch (_) {
        return false;
      }
    }
    File(outputPath).parent.createSync(recursive: true);

    // macOS / iOS — built-in afconvert handles MP3, FLAC, AIFF, AAC, M4A.
    if (Platform.isMacOS || Platform.isIOS) {
      const supported = {'mp3', 'flac', 'aif', 'aiff', 'aac', 'm4a'};
      if (supported.contains(ext)) {
        try {
          final result = await Process.run('afconvert', [
            '-f', 'WAVE', '-d', 'LEI16', '-c', '1',
            inputPath, outputPath,
          ]);
          if (result.exitCode != 0) {
            debugPrint('[Mono] afconvert failed (${result.exitCode}): ${result.stderr}');
            return false;
          }
          return true;
        } catch (e) {
          debugPrint('[Mono] afconvert exception: $e');
          return false;
        }
      }
    }

    // Windows / Android / Linux — try ffmpeg if available in PATH.
    const ffmpegSupported = {'mp3', 'flac', 'aif', 'aiff', 'ogg', 'aac', 'm4a'};
    if (ffmpegSupported.contains(ext)) {
      try {
        final result = await Process.run('ffmpeg', [
          '-y', '-i', inputPath, '-ac', '1', '-f', 'wav', outputPath,
        ]);
        if (result.exitCode != 0) {
          debugPrint('[Mono] ffmpeg failed (${result.exitCode}): ${result.stderr}');
          return false;
        }
        return true;
      } catch (e) {
        debugPrint('[Mono] ffmpeg not available: $e');
        return false;
      }
    }

    return false;
  }

  /// Extensions that some messaging apps (confirmed: WhatsApp, which rejects
  /// them with "file not supported" even via plain OS drag-and-drop) refuse
  /// as a direct audio attachment, but accept once converted to a
  /// widely-supported compressed format (MP3 or AAC/M4A).
  static const Set<String> extensionsNeedingConversionForSharing = {
    'wav', 'aiff', 'aif', 'flac',
  };

  /// Whether [path]'s extension is one that should be converted before
  /// sharing to messaging apps. Pure/testable — no I/O.
  static bool needsConversionForSharing(String path) {
    final ext = path.toLowerCase().split('.').last;
    return extensionsNeedingConversionForSharing.contains(ext);
  }

  /// Where a Windows build of ffmpeg is bundled alongside the app, if any —
  /// so end users never need to install anything themselves. Resolved the
  /// same way tray_manager/windows_taskbar resolve bundled assets: relative
  /// to the built executable, not the source tree.
  ///
  /// `<bundle>/tools/`, populated by the install() rule in
  /// windows/CMakeLists.txt — not a Flutter asset, because that would ship
  /// this 97 MB Windows binary to Android, macOS and Linux too. Keep the two
  /// in sync.
  static String get _bundledFfmpegPath => p.joinAll([
        p.dirname(Platform.resolvedExecutable),
        'tools', 'ffmpeg.exe',
      ]);

  /// Resolves which ffmpeg binary to invoke: the bundled Windows build if
  /// present, otherwise whatever's on PATH (covers macOS/Linux dev machines
  /// with ffmpeg installed, and Windows dev builds without the bundled exe).
  static Future<String> _resolveFfmpegCommand() async {
    if (Platform.isWindows && await File(_bundledFfmpegPath).exists()) {
      return _bundledFfmpegPath;
    }
    return 'ffmpeg';
  }

  /// The ffmpeg arguments used for every MP3 conversion, whatever runs them.
  /// `-qscale:a 2` is VBR ≈190 kbps — transparent enough for a bounce someone
  /// will listen to on a phone, small enough to actually send.
  static List<String> mp3ConversionArgs(String inputPath, String outputPath) =>
      ['-y', '-i', inputPath, '-codec:a', 'libmp3lame', '-qscale:a', '2', outputPath];

  /// Runs ffmpeg with [args] and reports whether it succeeded.
  ///
  /// Test seam: production leaves this null, which selects the real runner
  /// (a bundled or PATH binary). Reset to null in `tearDown`.
  @visibleForTesting
  static Future<bool> Function(List<String> args)? ffmpegRunnerOverride;

  static Future<bool> _runFfmpeg(List<String> args) async {
    final override = ffmpegRunnerOverride;
    if (override != null) return override(args);

    final result = await Process.run(await _resolveFfmpegCommand(), args);
    if (result.exitCode == 0) return true;
    debugPrint('[ShareConvert] ffmpeg failed (${result.exitCode}): ${result.stderr}');
    return false;
  }

  /// Platform channel implemented natively on both mobile platforms:
  /// `AudioShareConverter.kt` (MediaCodec) on Android and
  /// `AudioShareConverter.swift` (AVAssetExportSession) on iOS. Same channel
  /// name, method and arguments on each, so Dart has one path for both.
  static const MethodChannel _mobileConvertChannel = MethodChannel(
    'com.bandpassrecords.dpm/audio_convert',
  );

  /// Test seam for the native mobile transcode. Production leaves this null
  /// and goes over [_mobileConvertChannel]. Reset to null in `tearDown`.
  @visibleForTesting
  static Future<void> Function(String input, String output)?
      mobileConverterOverride;

  /// Transcodes to AAC/`.m4a` using the OS's own encoder, since neither
  /// mobile platform can spawn an ffmpeg subprocess (`Process.run` failed
  /// silently on Android, which is why WAV bounces went out unconverted and
  /// got dropped by the receiving app, leaving only the message text).
  ///
  /// AAC rather than MP3 because neither Android nor Apple ships an MP3
  /// *encoder* — the same reason the macOS branch below produces `.m4a` via
  /// afconvert, so `.m4a` is a format this app already sends.
  ///
  /// Visible for testing because [convertForSharing] only routes here on
  /// Android or iOS, which no test host satisfies.
  @visibleForTesting
  static Future<File?> convertWithMobileCodec(
    String inputPath,
    String outputDir,
  ) async {
    final base = p.basenameWithoutExtension(inputPath);
    var outPath = p.join(outputDir, '$base.m4a');
    if (p.equals(outPath, inputPath)) {
      outPath = p.join(outputDir, '${base}_share.m4a');
    }

    try {
      final override = mobileConverterOverride;
      if (override != null) {
        await override(inputPath, outPath);
      } else {
        await _mobileConvertChannel.invokeMethod<String>('toM4a', {
          'input': inputPath,
          'output': outPath,
        });
      }
    } catch (e) {
      // Android's MediaExtractor cannot open AIFF, so that input legitimately
      // lands here (AVFoundation on iOS can). The caller falls back to
      // sharing the original file.
      debugPrint('[ShareConvert] native transcode failed: $e');
      return null;
    }

    final out = File(outPath);
    if (await out.exists() && await out.length() > 0) return out;
    debugPrint('[ShareConvert] native transcode produced nothing at $outPath');
    return null;
  }

  /// Converts [inputPath] to a messaging-app-compatible file inside
  /// [outputDir], using whatever encoder the current OS already has — no
  /// platform gets a new redistributable for this:
  /// - macOS: AAC/M4A via `afconvert`, which ships with every Mac (Apple's
  ///   frameworks have never included an MP3 encoder).
  /// - Android and iOS: AAC/M4A over a platform channel — MediaCodec and
  ///   AVAssetExportSession respectively — for the same reason, neither OS
  ///   has an MP3 encoder, and neither can spawn an ffmpeg subprocess.
  /// - Windows: MP3 via the ffmpeg binary bundled with the app, falling
  ///   back to PATH for dev builds without it.
  /// - Linux: MP3 via ffmpeg on PATH (soft dependency).
  ///
  /// Returns the converted file, or null if conversion wasn't possible —
  /// callers should fall back to sharing the original file rather than
  /// blocking the share entirely.
  static Future<File?> convertForSharing(String inputPath, String outputDir) async {
    final base = p.basenameWithoutExtension(inputPath);
    Directory(outputDir).createSync(recursive: true);

    if (Platform.isAndroid || Platform.isIOS) {
      return convertWithMobileCodec(inputPath, outputDir);
    }

    if (Platform.isMacOS) {
      final outPath = p.join(outputDir, '$base.m4a');
      try {
        final result = await Process.run('afconvert', [
          '-f', 'm4af', '-d', 'aac', inputPath, outPath,
        ]);
        if (result.exitCode == 0) return File(outPath);
        debugPrint('[ShareConvert] afconvert failed (${result.exitCode}): ${result.stderr}');
      } catch (e) {
        debugPrint('[ShareConvert] afconvert exception: $e');
      }
      return null;
    }

    // Never write the output over the input: on mobile the caller's temp
    // directory is also where the source may already live, and ffmpeg
    // truncates its output file before reading.
    var outPath = p.join(outputDir, '$base.mp3');
    if (p.equals(outPath, inputPath)) {
      outPath = p.join(outputDir, '${base}_share.mp3');
    }

    try {
      if (await _runFfmpeg(mp3ConversionArgs(inputPath, outPath))) {
        final out = File(outPath);
        // ffmpeg can exit 0 having written nothing useful (an unsupported
        // input it decided to skip). An empty attachment is worse than an
        // unconverted one, so treat it as a failure.
        if (await out.exists() && await out.length() > 0) return out;
        debugPrint('[ShareConvert] ffmpeg produced no usable output at $outPath');
      }
    } catch (e) {
      debugPrint('[ShareConvert] ffmpeg not available: $e');
    }
    return null;
  }

  /// Returns the channel count of a WAV file, or null for non-WAV / parse errors.
  static Future<int?> getChannelCount(String filePath) async {
    if (!filePath.toLowerCase().endsWith('.wav')) return null;
    try {
      return await Isolate.run(() => _readWavChannelCount(filePath));
    } catch (_) {
      return null;
    }
  }

  /// Compute per-100 ms level data for a WAV file using a streaming algorithm
  /// (constant memory regardless of file length). Returns null for non-WAV or errors.
  static Future<AudioLevelData?> computeLevelData(String filePath) async {
    if (!filePath.toLowerCase().endsWith('.wav')) return null;
    try {
      return await Isolate.run(() => _computeLevelDataIsolate(filePath));
    } catch (_) {
      return null;
    }
  }

  /// Extract min/max peak data for waveform visualization.
  /// For MP3 files, uses a pure-Dart side-information parser (no ffmpeg required).
  /// For other non-WAV formats, converts to a temp mono WAV via ffmpeg/afconvert.
  /// Returns null if the file cannot be parsed.
  static Future<WaveformPeaks?> extractWaveformPeaks(
    String filePath, {
    int targetFrames = 2000,
  }) async {
    final ext = filePath.toLowerCase().split('.').last;

    // Fast path: MP3 files are parsed directly from frame headers — no temp file,
    // no external tools, works on every platform.
    if (ext == 'mp3') {
      try {
        final peaks = await Isolate.run(
            () => _extractMp3PeaksDirectIsolate(filePath, targetFrames));
        if (peaks != null) return peaks;
      } catch (_) {}
      // Fall through to ffmpeg-based conversion if direct parsing failed.
    }

    if (ext == 'wav') {
      try {
        return await Isolate.run(() => _extractPeaksIsolate(filePath, targetFrames));
      } catch (_) {
        return null;
      }
    }

    // Non-WAV, non-MP3: convert via afconvert (macOS) or ffmpeg (Windows/Linux).
    final tmpDir = await getTemporaryDirectory();
    final tmpPath = '${tmpDir.path}/wfpk_${filePath.hashCode.abs()}.wav';
    final ok = await writeMonoWavFile(filePath, tmpPath);
    if (!ok) return null;
    try {
      return await Isolate.run(() => _extractPeaksIsolate(tmpPath, targetFrames));
    } catch (_) {
      return null;
    } finally {
      try { File(tmpPath).deleteSync(); } catch (_) {}
    }
  }
}

// ─── Waveform peaks ──────────────────────────────────────────────────────────

/// Min/max peak data for each display frame, used to render a waveform.
class WaveformPeaks {
  final List<double> minValues; // per-frame minimum sample (-1..0)
  final List<double> maxValues; // per-frame maximum sample (0..1)
  final int sampleRate;
  final double durationSeconds;

  const WaveformPeaks({
    required this.minValues,
    required this.maxValues,
    required this.sampleRate,
    required this.durationSeconds,
  });

  int get frameCount => maxValues.length;
}

WaveformPeaks? _extractPeaksIsolate(String wavPath, int targetFrames) {
  final bytes = File(wavPath).readAsBytesSync();
  final info = _parseWavInfo(bytes);
  if (info == null) return null;

  final channels = _extractSamples(bytes, info);
  final numSamples = channels[0].length;
  if (numSamples == 0) return null;

  // Mix to mono
  final mono = channels.length == 1
      ? channels[0]
      : List<double>.generate(numSamples, (i) {
          double sum = 0;
          for (final ch in channels) { sum += ch[i]; }
          return sum / channels.length;
        });

  final frames = targetFrames.clamp(1, numSamples);
  final frameSize = numSamples ~/ frames;
  final minValues = List<double>.filled(frames, 0.0);
  final maxValues = List<double>.filled(frames, 0.0);

  for (int f = 0; f < frames; f++) {
    final start = f * frameSize;
    final end = min(start + frameSize, numSamples);
    double minV = 0, maxV = 0;
    for (int i = start; i < end; i++) {
      if (mono[i] < minV) minV = mono[i];
      if (mono[i] > maxV) maxV = mono[i];
    }
    minValues[f] = minV;
    maxValues[f] = maxV;
  }

  return WaveformPeaks(
    minValues: minValues,
    maxValues: maxValues,
    sampleRate: info.sampleRate,
    durationSeconds: numSamples / info.sampleRate,
  );
}

// ─── Pure-Dart MP3 peak extractor ────────────────────────────────────────────
//
// Reads the `global_gain` field from every MPEG Layer3 granule side-information
// header.  global_gain controls the overall quantization step for a granule, so
// it correlates well with the signal amplitude — enough for waveform display
// without needing a full Huffman/MDCT decoder or any external tool.
//
// Bit offsets verified against ISO/IEC 11172-3 §2.4.3.3 and ISO/IEC 13818-3:
//
//   MPEG1 stereo (32-byte side info):
//     9 main_data_begin + 3 private + 8 scfsi = 20 bits preamble
//     granule_info = 59 bits each
//     g0c0=41  g0c1=100  g1c0=159  g1c1=218
//
//   MPEG1 mono (17-byte side info):
//     9 main_data_begin + 5 private + 4 scfsi = 18 bits preamble
//     g0=39  g1=98
//
//   MPEG2/2.5 stereo (17-byte side info, 63-bit granule_info):
//     8 main_data_begin + 2 private = 10 bits preamble
//     c0=31  c1=94
//
//   MPEG2/2.5 mono (9-byte side info):
//     8 main_data_begin + 1 private = 9 bits preamble
//     c0=30

/// Read [numBits] bits (MSB-first) from [bytes] starting at
/// byte [byteOffset] + bit [bitOffset].
int _readBits(Uint8List bytes, int byteOffset, int bitOffset, int numBits) {
  int result = 0;
  for (int b = 0; b < numBits; b++) {
    final total = bitOffset + b;
    final idx = byteOffset + (total >> 3);
    if (idx >= bytes.length) break;
    result = (result << 1) | ((bytes[idx] >> (7 - (total & 7))) & 1);
  }
  return result;
}

WaveformPeaks? _extractMp3PeaksDirectIsolate(String filePath, int targetFrames) {
  final Uint8List bytes;
  try {
    bytes = File(filePath).readAsBytesSync();
  } catch (_) {
    return null;
  }

  int pos = 0;

  // Skip ID3v2 tag (synchsafe size at bytes 6-9).
  if (bytes.length > 10 &&
      bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
    final id3Size = ((bytes[6] & 0x7F) << 21) | ((bytes[7] & 0x7F) << 14) |
                    ((bytes[8] & 0x7F) << 7)  |  (bytes[9] & 0x7F);
    pos = 10 + id3Size;
  }

  // One amplitude entry per granule (≈13 ms each at 44100 Hz).
  final gains = <double>[];
  int srDetected = 44100;
  int totalSamples = 0;

  const srTable = [
    [44100, 48000, 32000], // MPEG 1
    [22050, 24000, 16000], // MPEG 2
    [11025, 12000,  8000], // MPEG 2.5
  ];
  const brV1L3 = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320];
  const brV2L3 = [0,  8, 16, 24, 32, 40, 48, 56,  64,  80,  96, 112, 128, 144, 160];

  while (pos + 4 <= bytes.length) {
    // Sync word: 0xFF + top-3-bits of next byte all set.
    if (bytes[pos] != 0xFF || (bytes[pos + 1] & 0xE0) != 0xE0) { pos++; continue; }

    final h1 = bytes[pos + 1];
    final h2 = bytes[pos + 2];
    final h3 = bytes[pos + 3];

    final mpegVerBits = (h1 >> 3) & 0x03; // 11=V1, 10=V2, 00=V2.5
    final layer       = (h1 >> 1) & 0x03; // 01=L3

    // Only MPEG Layer 3.
    if (layer != 1) { pos++; continue; }

    final bitrateIdx  = (h2 >> 4) & 0x0F;
    final srIdx       = (h2 >> 2) & 0x03;
    final padding     = (h2 >> 1) & 0x01;
    final channelMode = (h3 >> 6) & 0x03; // 3 = mono

    if (bitrateIdx == 0 || bitrateIdx == 0xF || srIdx == 3) { pos++; continue; }

    final isV1    = mpegVerBits == 3;
    final verIdx  = isV1 ? 0 : (mpegVerBits == 2 ? 1 : 2);
    final isMono  = channelMode == 3;

    final sr       = srTable[verIdx][srIdx];
    final bitrate  = (isV1 ? brV1L3 : brV2L3)[bitrateIdx];
    final frameBytes = (144 * bitrate * 1000 ~/ sr) + padding;

    if (frameBytes < 10 || pos + frameBytes > bytes.length) { pos++; continue; }

    srDetected = sr;

    // Side information immediately follows the 4-byte header.
    final sb = pos + 4;

    if (isV1) {
      // MPEG1: 2 granules per frame.  Extract global_gain for each granule,
      // take the louder channel when stereo.
      if (isMono) {
        gains.add(max(_readBits(bytes, sb, 39, 8), _readBits(bytes, sb, 98, 8)).toDouble());
      } else {
        gains.add(max(_readBits(bytes, sb, 41, 8), _readBits(bytes, sb, 100, 8)).toDouble());
        gains.add(max(_readBits(bytes, sb, 159, 8), _readBits(bytes, sb, 218, 8)).toDouble());
      }
      totalSamples += 1152; // 2 × 576
    } else {
      // MPEG2/2.5: 1 granule per frame.
      if (isMono) {
        gains.add(_readBits(bytes, sb, 30, 8).toDouble());
      } else {
        gains.add(max(_readBits(bytes, sb, 31, 8), _readBits(bytes, sb, 94, 8)).toDouble());
      }
      totalSamples += 576;
    }

    pos += frameBytes;
  }

  if (gains.isEmpty) return null;

  // Normalise to 0..1 relative to the loudest granule in this file.
  final maxGain = gains.reduce(max);
  if (maxGain <= 0) return null;
  final norm = gains.map((g) => (g / maxGain).clamp(0.0, 1.0)).toList();

  // Subsample/bin into targetFrames, preserving the loudest value per bin.
  final count = norm.length;
  final minVals = List<double>.filled(targetFrames, 0.0);
  final maxVals = List<double>.filled(targetFrames, 0.0);
  for (int f = 0; f < targetFrames; f++) {
    final s = f * count ~/ targetFrames;
    final e = ((f + 1) * count ~/ targetFrames).clamp(s + 1, count);
    double v = 0;
    for (int k = s; k < e; k++) {
      if (norm[k] > v) v = norm[k];
    }
    maxVals[f] = v;
    minVals[f] = -v; // Symmetric envelope
  }

  return WaveformPeaks(
    minValues: minVals,
    maxValues: maxVals,
    sampleRate: srDetected,
    durationSeconds: totalSamples / srDetected,
  );
}

// ─── Per-frame level data ─────────────────────────────────────────────────────

/// Per-100 ms loudness data for a WAV file, used to drive the real-time meter.
class AudioLevelData {
  /// Left-channel RMS in dBFS for each 100 ms frame.
  final List<double> lRmsDb;

  /// Right-channel RMS in dBFS (equals [lRmsDb] for mono files).
  final List<double> rRmsDb;

  /// Short-term LUFS (3 s window) updated every 100 ms.
  final List<double> lufsShort;

  final double frameDuration; // always 0.1 s
  final int sampleRate;
  final int bitDepth;
  final int channels;

  const AudioLevelData({
    required this.lRmsDb,
    required this.rRmsDb,
    required this.lufsShort,
    required this.frameDuration,
    required this.sampleRate,
    required this.bitDepth,
    required this.channels,
  });

  int get frameCount => lRmsDb.length;

  /// Returns (lRmsDb, rRmsDb, lufsDb) at the given playback position.
  (double, double, double) valuesAt(Duration position) {
    if (lRmsDb.isEmpty) return (-100, -100, -100);
    final idx = (position.inMilliseconds / (frameDuration * 1000))
        .floor()
        .clamp(0, frameCount - 1);
    return (lRmsDb[idx], rRmsDb[idx], lufsShort[idx]);
  }
}

// ─── Top-level functions (required for Isolate.run) ──────────────────────────

AudioFileInfo? _readFileInfo(String filePath) {
  try {
    final file = File(filePath);
    final size = file.lengthSync();
    final bufSize = min(16384, size);
    final buf = Uint8List(bufSize);
    final raf = file.openSync()..setPositionSync(0);
    raf.readIntoSync(buf);
    raf.closeSync();

    final ext = filePath.toLowerCase().split('.').last;
    if (kDebugMode) print('[AudioFileInfo] file=$filePath ext=$ext totalSize=$size bufSize=$bufSize');

    // WAV / AIFF — use existing parsers
    if (ext == 'wav') {
      final info = _parseWavInfo(buf);
      if (info != null) {
        if (kDebugMode) print('[AudioFileInfo] WAV ok sr=${info.sampleRate} ch=${info.numChannels} bd=${info.bitDepth}');
        return AudioFileInfo(
          sampleRate: info.sampleRate,
          bitDepth: info.bitDepth,
          channels: info.numChannels,
        );
      }
      if (kDebugMode) print('[AudioFileInfo] WAV parse failed');
    }

    if (ext == 'aif' || ext == 'aiff') {
      final info = _parseAiffInfo(buf);
      if (kDebugMode) print('[AudioFileInfo] AIFF result=$info');
      return info;
    }

    // FLAC — parse STREAMINFO metadata block
    if (ext == 'flac') {
      final info = _parseFlacInfo(buf);
      if (kDebugMode) print('[AudioFileInfo] FLAC result=$info');
      return info;
    }

    // MP3 — scan for first valid MPEG frame header
    if (ext == 'mp3') {
      final info = _parseMp3Info(buf, totalFileSize: size, filePath: filePath);
      if (kDebugMode) print('[AudioFileInfo] MP3 result=$info');
      return info;
    }

    // OGG Vorbis — parse identification header
    if (ext == 'ogg') {
      final info = _parseOggInfo(buf);
      if (kDebugMode) print('[AudioFileInfo] OGG result=$info');
      return info;
    }

    if (kDebugMode) print('[AudioFileInfo] unrecognized extension: $ext');
    return null;
  } catch (e, st) {
    if (kDebugMode) print('[AudioFileInfo] exception: $e\n$st');
    return null;
  }
}

AudioFileInfo? _parseFlacInfo(Uint8List buf) {
  // Magic: "fLaC" at offset 0
  if (buf.length < 42) return null;
  if (buf[0] != 0x66 || buf[1] != 0x4C || buf[2] != 0x61 || buf[3] != 0x43) return null;
  // First metadata block must be STREAMINFO (type 0), starting at byte 4.
  // Header: 1 byte flags+type, 3 bytes length. STREAMINFO data starts at byte 8.
  if ((buf[4] & 0x7F) != 0) return null; // not STREAMINFO
  // STREAMINFO layout (offsets relative to byte 8):
  // [0-1] min block size, [2-3] max block size, [4-6] min frame, [7-9] max frame
  // [10] sr[19:12], [11] sr[11:4], [12] sr[3:0]<<4 | ch[2:0]<<1 | bps[4]
  // [13] bps[3:0]<<4 | ...
  final d = buf;
  const o = 8; // STREAMINFO data offset in file
  final sr = (d[o + 10] << 12) | (d[o + 11] << 4) | (d[o + 12] >> 4);
  final ch = ((d[o + 12] >> 1) & 0x07) + 1;
  final bps = (((d[o + 12] & 0x01) << 4) | (d[o + 13] >> 4)) + 1;
  if (sr == 0 || ch == 0) return null;
  return AudioFileInfo(sampleRate: sr, bitDepth: bps, channels: ch);
}

AudioFileInfo? _parseMp3Info(Uint8List buf, {int totalFileSize = 0, String filePath = ''}) {
  int offset = 0;
  // Skip ID3v2 tag if present ("ID3")
  if (buf.length > 10 &&
      buf[0] == 0x49 && buf[1] == 0x44 && buf[2] == 0x33) {
    // Size is synchsafe integer at bytes 6-9
    final id3Size = (buf[6] << 21) | (buf[7] << 14) | (buf[8] << 7) | buf[9];
    offset = 10 + id3Size;
    if (kDebugMode) print('[MP3] ID3v2 tag detected, id3Size=$id3Size, scan starts at offset=$offset, bufLen=${buf.length}');
    if (offset >= buf.length) {
      if (kDebugMode) print('[MP3] ID3v2 tag ($id3Size bytes) exceeds buffer (${buf.length} bytes) — no frame header in buffer');
    }
  } else {
    if (kDebugMode) print('[MP3] No ID3v2 tag. First bytes: ${buf.take(4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
  }

  int syncCandidates = 0;
  for (int i = offset; i < buf.length - 3; i++) {
    if (buf[i] != 0xFF) continue;
    final b1 = buf[i + 1];
    if ((b1 & 0xE0) != 0xE0) continue; // not a sync
    syncCandidates++;
    final mpegVer = (b1 >> 3) & 0x03;
    if (mpegVer == 1) { if (kDebugMode) print('[MP3] @$i sync found but mpegVer=1 (reserved), skip'); continue; }
    final layer = (b1 >> 1) & 0x03;
    if (layer == 0) { if (kDebugMode) print('[MP3] @$i sync found but layer=0 (reserved), skip'); continue; }

    final b2 = buf[i + 2];
    final bitrateIdx = (b2 >> 4) & 0x0F;
    if (bitrateIdx == 0x0F) { if (kDebugMode) print('[MP3] @$i bitrateIdx=0xF (invalid), skip'); continue; }
    if (bitrateIdx == 0x00) { if (kDebugMode) print('[MP3] @$i bitrateIdx=0 (free bitrate), skip'); continue; }
    final srIdx = (b2 >> 2) & 0x03;
    if (srIdx == 3) { if (kDebugMode) print('[MP3] @$i srIdx=3 (reserved), skip'); continue; }

    final b3 = buf[i + 3];
    final channelMode = (b3 >> 6) & 0x03;
    final channels = channelMode == 3 ? 1 : 2;

    const srTable = [
      [44100, 48000, 32000], // MPEG 1
      [22050, 24000, 16000], // MPEG 2
      [11025, 12000,  8000], // MPEG 2.5
    ];
    final verIdx = mpegVer == 3 ? 0 : (mpegVer == 2 ? 1 : 2);
    final sr = srTable[verIdx][srIdx];

    // Bitrate lookup: [verIdx 0=MPEG1 / 1=MPEG2/2.5][layer 3=L1 2=L2 1=L3]
    const bitrateTable = {
      // MPEG 1
      0: {
        3: [0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448], // L1
        2: [0, 32, 48, 56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320, 384], // L2
        1: [0, 32, 40, 48,  56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320], // L3
      },
      // MPEG 2 / 2.5
      1: {
        3: [0, 32, 48, 56,  64,  80,  96, 112, 128, 144, 160, 176, 192, 224, 256], // L1
        2: [0,  8, 16, 24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160], // L2
        1: [0,  8, 16, 24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160], // L3
      },
    };
    final brIdx = verIdx == 0 ? 0 : 1;
    final kbps = bitrateTable[brIdx]?[layer]?[bitrateIdx];

    if (kDebugMode) print('[MP3] Frame found @$i mpegVer=$mpegVer layer=$layer bitrateIdx=$bitrateIdx srIdx=$srIdx channelMode=$channelMode → sr=$sr ch=$channels kbps=$kbps');
    return AudioFileInfo(sampleRate: sr, channels: channels, bitrateKbps: kbps); // bitDepth null (lossy)
  }
  if (kDebugMode) print('[MP3] No valid frame header found. syncCandidates=$syncCandidates scanned=${buf.length - offset} bytes (offset=$offset..${buf.length})');
  return null;
}

AudioFileInfo? _parseOggInfo(Uint8List buf) {
  // OGG capture pattern: "OggS" at byte 0; Vorbis identification header
  // starts in the first Ogg page. Search for vorbis ident header magic.
  // Magic: 0x01 + "vorbis" (7 bytes)
  const magic = [0x01, 0x76, 0x6F, 0x72, 0x62, 0x69, 0x73];
  outer:
  for (int i = 0; i < buf.length - 28; i++) {
    for (int j = 0; j < magic.length; j++) {
      if (buf[i + j] != magic[j]) continue outer;
    }
    // Found at i. Vorbis ident header layout after magic (7 bytes):
    // [7-10] vorbis_version (LE uint32, must be 0)
    // [11]   audio_channels
    // [12-15] audio_sample_rate (LE uint32)
    final version = ByteData.sublistView(buf, i + 7, i + 11).getUint32(0, Endian.little);
    if (version != 0) continue;
    final ch = buf[i + 11];
    final sr = ByteData.sublistView(buf, i + 12, i + 16).getUint32(0, Endian.little);
    if (sr == 0 || ch == 0) continue;
    return AudioFileInfo(sampleRate: sr, channels: ch);
  }
  return null;
}

AudioFileInfo? _parseAiffInfo(Uint8List buf) {
  // FORM….AIFF or AIFF-C
  if (buf.length < 12) return null;
  if (buf[0] != 0x46 || buf[1] != 0x4F || buf[2] != 0x52 || buf[3] != 0x4D) return null;
  final isAifc = buf[8] == 0x41 && buf[9] == 0x49 && buf[10] == 0x46 && buf[11] == 0x43;
  final isAiff = buf[8] == 0x41 && buf[9] == 0x49 && buf[10] == 0x46 && buf[11] == 0x46;
  if (!isAiff && !isAifc) return null;

  final bd = ByteData.sublistView(buf);
  int offset = 12;
  while (offset + 8 <= buf.length) {
    final chunkId = String.fromCharCodes(buf.sublist(offset, offset + 4));
    final chunkSize = bd.getUint32(offset + 4); // big-endian
    offset += 8;
    if (chunkId == 'COMM' && chunkSize >= 18) {
      final ch = bd.getUint16(offset);           // numChannels
      final bps = bd.getUint16(offset + 6);      // sampleSize (bit depth)
      // Sample rate is 80-bit extended at offset+8; read top 16 bits for exponent.
      final exp = bd.getUint16(offset + 8) & 0x7FFF;
      final mantHi = bd.getUint32(offset + 10);
      final sr = (mantHi >> (30 - (exp - 16383))).toInt();
      return AudioFileInfo(sampleRate: sr, bitDepth: bps, channels: ch);
    }
    offset += chunkSize + (chunkSize & 1);
  }
  return null;
}

int? _readWavChannelCount(String filePath) {
  try {
    final file = File(filePath);
    final hBuf = Uint8List(min(512, file.lengthSync()));
    final raf = file.openSync()..setPositionSync(0);
    raf.readIntoSync(hBuf);
    raf.closeSync();
    return _parseWavInfo(hBuf)?.numChannels;
  } catch (_) {
    return null;
  }
}

AudioAnalysisResult? _analyzeWavFile(String filePath) {
  try {
    final bytes = File(filePath).readAsBytesSync();
    return _analyzeWavBytes(bytes);
  } catch (_) {
    return null;
  }
}

bool _writeMonoWavIsolate(String inputPath, String outputPath) {
  try {
    final file = File(inputPath);
    final fileSize = file.lengthSync();

    // Read just the header (64 KB is enough for any sane WAV header).
    final rafH = file.openSync()..setPositionSync(0);
    final hBuf = Uint8List(min(65536, fileSize));
    rafH.readIntoSync(hBuf);
    rafH.closeSync();

    final info = _parseWavInfo(hBuf);
    if (info == null) {
      stderr.writeln('[AudioAnalysis] writeMonoWav: header parse failed');
      return false;
    }
    if (info.numChannels < 2) return false; // already mono — caller handles this

    final bytesPerSample = info.bitDepth ~/ 8;
    final inBytesPerFrame = info.numChannels * bytesPerSample;
    final actualDataSize = fileSize - info.dataOffset;
    final numFrames = actualDataSize ~/ inBytesPerFrame;
    final monoDataSize = numFrames * bytesPerSample;

    // Write WAV header for mono output.
    final header = Uint8List(44);
    final hd = ByteData.sublistView(header);
    header.setAll(0, [0x52, 0x49, 0x46, 0x46]); // "RIFF"
    hd.setUint32(4, 36 + monoDataSize, Endian.little);
    header.setAll(8, [0x57, 0x41, 0x56, 0x45]); // "WAVE"
    header.setAll(12, [0x66, 0x6D, 0x74, 0x20]); // "fmt "
    hd.setUint32(16, 16, Endian.little);
    hd.setUint16(20, info.audioFormat == 3 ? 3 : 1, Endian.little);
    hd.setUint16(22, 1, Endian.little); // mono
    hd.setUint32(24, info.sampleRate, Endian.little);
    hd.setUint32(28, info.sampleRate * bytesPerSample, Endian.little);
    hd.setUint16(32, bytesPerSample, Endian.little);
    hd.setUint16(34, info.bitDepth, Endian.little);
    header.setAll(36, [0x64, 0x61, 0x74, 0x61]); // "data"
    hd.setUint32(40, monoDataSize, Endian.little);

    const chunkFrames = 4096;
    final inBuf = Uint8List(chunkFrames * inBytesPerFrame);
    final outBuf = Uint8List(chunkFrames * bytesPerSample);
    final outBd = ByteData.sublistView(outBuf);

    File(outputPath).parent.createSync(recursive: true);
    final outFile = File(outputPath).openSync(mode: FileMode.write);
    try {
      outFile.writeFromSync(header);

      final inRaf = file.openSync()..setPositionSync(info.dataOffset);
      int remaining = actualDataSize;
      try {
        while (remaining >= inBytesPerFrame) {
          final toRead = min(inBuf.length, (remaining ~/ inBytesPerFrame) * inBytesPerFrame);
          final got = inRaf.readIntoSync(inBuf, 0, toRead);
          if (got < inBytesPerFrame) break;
          remaining -= got;

          final frames = got ~/ inBytesPerFrame;
          for (int f = 0; f < frames; f++) {
            double sum = 0;
            for (int ch = 0; ch < info.numChannels; ch++) {
              final off = f * inBytesPerFrame + ch * bytesPerSample;
              sum += _decodeSample(inBuf, off, info.audioFormat, info.bitDepth);
            }
            final s = (sum / info.numChannels).clamp(-1.0, 1.0);
            final moff = f * bytesPerSample;
            if (info.audioFormat == 3 && info.bitDepth == 32) {
              outBd.setFloat32(moff, s, Endian.little);
            } else if (info.bitDepth == 16) {
              outBd.setInt16(moff, (s * 32767).round(), Endian.little);
            } else if (info.bitDepth == 24) {
              final v = (s * 8388607).round();
              outBuf[moff] = v & 0xFF;
              outBuf[moff + 1] = (v >> 8) & 0xFF;
              outBuf[moff + 2] = (v >> 16) & 0xFF;
            } else {
              outBd.setInt32(moff, (s * 2147483647).round(), Endian.little);
            }
          }
          outFile.writeFromSync(outBuf, 0, frames * bytesPerSample);
        }
      } finally {
        inRaf.closeSync();
      }
    } finally {
      outFile.closeSync();
    }
    return true;
  } catch (e, st) {
    stderr.writeln('[AudioAnalysis] writeMonoWav exception: $e\n$st');
    return false;
  }
}

// ─── Streaming level-data computation ────────────────────────────────────────

/// Stateful biquad filter — processes one sample at a time so it can span
/// across read chunks without needing the full file in memory.
class _StreamBiquad {
  final List<double> c; // [b0, b1, b2, a1, a2]
  double _x1 = 0, _x2 = 0, _y1 = 0, _y2 = 0;
  _StreamBiquad(this.c);

  double process(double x) {
    final y = c[0] * x + c[1] * _x1 + c[2] * _x2 - c[3] * _y1 - c[4] * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }
}

/// Decode one sample from [buf] at byte [off] to a −1…+1 double.
double _decodeSample(Uint8List buf, int off, int audioFormat, int bitDepth) {
  final bd = ByteData.sublistView(buf);
  if (audioFormat == 3 && bitDepth == 32) {
    return bd.getFloat32(off, Endian.little).toDouble();
  } else if (bitDepth == 16) {
    return bd.getInt16(off, Endian.little) / 32768.0;
  } else if (bitDepth == 24) {
    int v = buf[off] | (buf[off + 1] << 8) | (buf[off + 2] << 16);
    if (v >= 0x800000) v -= 0x1000000;
    return v / 8388608.0;
  } else {
    return bd.getInt32(off, Endian.little) / 2147483648.0;
  }
}

AudioLevelData? _computeLevelDataIsolate(String filePath) {
  try {
    final file = File(filePath);
    final fileSize = file.lengthSync();

    // Read up to 64 KB for the WAV header (sufficient for any sane WAV file).
    final headerBytes = file.openSync()
      ..setPositionSync(0);
    final hBuf = Uint8List(min(65536, fileSize));
    headerBytes.readIntoSync(hBuf);
    headerBytes.closeSync();

    final info = _parseWavInfo(hBuf);
    if (info == null) return null;

    // Actual data size is the remaining file after the data chunk header.
    final actualDataSize = fileSize - info.dataOffset;

    final bytesPerSample = info.bitDepth ~/ 8;
    final bytesPerFrame = (info.sampleRate * 0.1).round()   // 100 ms
        * info.numChannels * bytesPerSample;

    // K-weighting filter chains — one pair per channel, persistent across chunks.
    final kw1 = List.generate(
        info.numChannels, (_) => _StreamBiquad(_kWeightStage1(info.sampleRate.toDouble())));
    final kw2 = List.generate(
        info.numChannels, (_) => _StreamBiquad(_kWeightStage2(info.sampleRate.toDouble())));

    // 3 s circular buffer for short-term LUFS (K-weighted squared samples per channel).
    final lufsWin = (info.sampleRate * 3.0).round();
    final kwSqBuf = List.generate(info.numChannels, (_) => Float64List(lufsWin));
    final kwSqSum = Float64List(info.numChannels);
    int bufIdx = 0, bufFill = 0;

    final lRms = <double>[];
    final rRms = <double>[];
    final lufs = <double>[];

    final chunkBuf = Uint8List(bytesPerFrame);
    final raf = file.openSync()..setPositionSync(info.dataOffset);
    int remaining = actualDataSize;

    try {
      while (remaining > 0) {
        final toRead = min(bytesPerFrame, remaining);
        final got = raf.readIntoSync(chunkBuf, 0, toRead);
        if (got == 0) break;
        remaining -= got;

        final frameSamples = got ~/ (info.numChannels * bytesPerSample);
        if (frameSamples == 0) break;

        final rmsSq = Float64List(info.numChannels);

        for (int s = 0; s < frameSamples; s++) {
          for (int ch = 0; ch < info.numChannels; ch++) {
            final off = (s * info.numChannels + ch) * bytesPerSample;
            final raw = _decodeSample(chunkBuf, off, info.audioFormat, info.bitDepth);
            final kw = kw2[ch].process(kw1[ch].process(raw));
            final kwSq = kw * kw;

            rmsSq[ch] += raw * raw;

            // Rolling 3 s LUFS window.
            kwSqSum[ch] += kwSq - kwSqBuf[ch][bufIdx];
            kwSqBuf[ch][bufIdx] = kwSq;
          }
          bufIdx = (bufIdx + 1) % lufsWin;
          if (bufFill < lufsWin) bufFill++;
        }

        // Per-channel RMS for this 100 ms frame.
        final n = frameSamples.toDouble();
        final lDb = rmsSq[0] > 0 ? 20.0 * log(sqrt(rmsSq[0] / n)) / _ln10 : -100.0;
        final rDb = info.numChannels > 1 && rmsSq[1] > 0
            ? 20.0 * log(sqrt(rmsSq[1] / n)) / _ln10
            : lDb;
        lRms.add(lDb);
        rRms.add(rDb);

        // Short-term LUFS from the 3 s window.
        if (bufFill > 0) {
          double z = 0;
          for (int ch = 0; ch < info.numChannels; ch++) {
            z += kwSqSum[ch] / bufFill;
          }
          lufs.add(z > 0 ? -0.691 + 10.0 * log(z) / _ln10 : -100.0);
        } else {
          lufs.add(-100.0);
        }
      }
    } finally {
      raf.closeSync();
    }

    return AudioLevelData(
      lRmsDb: lRms,
      rRmsDb: rRms,
      lufsShort: lufs,
      frameDuration: 0.1,
      sampleRate: info.sampleRate,
      bitDepth: info.bitDepth,
      channels: info.numChannels,
    );
  } catch (_) {
    return null;
  }
}

// ─── WAV parsing ─────────────────────────────────────────────────────────────

class _WavInfo {
  final int audioFormat; // 1 = PCM integer, 3 = IEEE float
  final int numChannels;
  final int sampleRate;
  final int bitDepth;
  final int dataOffset; // byte offset of first sample in `bytes`
  final int dataSize;   // byte count of sample data

  const _WavInfo({
    required this.audioFormat,
    required this.numChannels,
    required this.sampleRate,
    required this.bitDepth,
    required this.dataOffset,
    required this.dataSize,
  });
}

_WavInfo? _parseWavInfo(Uint8List bytes) {
  if (bytes.length < 44) return null;
  final bd = ByteData.sublistView(bytes);

  // RIFF….WAVE header
  if (bytes[0] != 0x52 || bytes[1] != 0x49 || bytes[2] != 0x46 || bytes[3] != 0x46) return null;
  if (bytes[8] != 0x57 || bytes[9] != 0x41 || bytes[10] != 0x56 || bytes[11] != 0x45) return null;

  int offset = 12;
  int? audioFormat, numChannels, sampleRate, bitDepth, dataOffset, dataSize;

  while (offset + 8 <= bytes.length) {
    final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final chunkSize = bd.getUint32(offset + 4, Endian.little);
    offset += 8;

    if (chunkId == 'fmt ') {
      if (chunkSize < 16) return null;
      audioFormat = bd.getUint16(offset, Endian.little);
      numChannels = bd.getUint16(offset + 2, Endian.little);
      sampleRate = bd.getUint32(offset + 4, Endian.little);
      bitDepth = bd.getUint16(offset + 14, Endian.little);
      // WAVE_FORMAT_EXTENSIBLE: read the actual subformat GUID bytes 0-1
      if (audioFormat == 0xFFFE && chunkSize >= 40) {
        audioFormat = bd.getUint16(offset + 24, Endian.little);
      }
    } else if (chunkId == 'data') {
      dataOffset = offset;
      dataSize = min(chunkSize, bytes.length - offset);
      break;
    }

    // Advance to next chunk (word-aligned)
    offset += chunkSize + (chunkSize & 1);
  }

  if (audioFormat == null || numChannels == null || sampleRate == null ||
      bitDepth == null || dataOffset == null || dataSize == null) {
    return null;
  }
  if (audioFormat != 1 && audioFormat != 3) { return null; } // only PCM & float
  if (bitDepth != 16 && bitDepth != 24 && bitDepth != 32) { return null; }
  if (numChannels < 1 || numChannels > 8) { return null; }

  return _WavInfo(
    audioFormat: audioFormat,
    numChannels: numChannels,
    sampleRate: sampleRate,
    bitDepth: bitDepth,
    dataOffset: dataOffset,
    dataSize: dataSize,
  );
}

/// Extract interleaved samples into per-channel Float64 lists (normalised –1…+1).
List<List<double>> _extractSamples(Uint8List bytes, _WavInfo info) {
  final bd = ByteData.sublistView(bytes);
  final bytesPerSample = info.bitDepth ~/ 8;
  final bytesPerFrame = bytesPerSample * info.numChannels;
  final numFrames = info.dataSize ~/ bytesPerFrame;

  final channels = List.generate(info.numChannels, (_) => List<double>.filled(numFrames, 0.0));

  for (int frame = 0; frame < numFrames; frame++) {
    for (int ch = 0; ch < info.numChannels; ch++) {
      final off = info.dataOffset + frame * bytesPerFrame + ch * bytesPerSample;
      if (off + bytesPerSample > bytes.length) break;

      double s;
      if (info.audioFormat == 3 && info.bitDepth == 32) {
        s = bd.getFloat32(off, Endian.little);
      } else if (info.bitDepth == 16) {
        s = bd.getInt16(off, Endian.little) / 32768.0;
      } else if (info.bitDepth == 24) {
        final lo = bytes[off], mi = bytes[off + 1], hi = bytes[off + 2];
        int v = lo | (mi << 8) | (hi << 16);
        if (v >= 0x800000) v -= 0x1000000;
        s = v / 8388608.0;
      } else {
        s = bd.getInt32(off, Endian.little) / 2147483648.0;
      }
      channels[ch][frame] = s;
    }
  }
  return channels;
}

// ─── K-weighting filter (ITU-R BS.1770-4) ────────────────────────────────────

/// Pre-filter biquad coefficients [b0, b1, b2, a1, a2] for any sample rate.
/// High-shelf: f0 ≈ 1500.5 Hz, G = +4 dB, Q = 1/√2.
List<double> _kWeightStage1(double fs) {
  const f0 = 1500.5, g = 4.0, q = 0.7071067811865476;
  final k = tan(pi * f0 / fs);
  final vh = pow(10.0, g / 20.0) as double;
  final vb = pow(vh, 0.4996667741545416) as double;
  final n = 1.0 / (1.0 + k / q + k * k);
  return [
    (vh + vb * k / q + k * k) * n,
    2.0 * (k * k - vh) * n,
    (vh - vb * k / q + k * k) * n,
    2.0 * (k * k - 1.0) * n,
    (1.0 - k / q + k * k) * n,
  ];
}

/// RLB high-pass biquad coefficients: fc ≈ 38 Hz, Q ≈ 0.5003.
List<double> _kWeightStage2(double fs) {
  const fc = 38.0, q = 0.5003270373238773;
  final k = tan(pi * fc / fs);
  final n = 1.0 / (1.0 + k / q + k * k);
  return [
    n,
    -2.0 * n,
    n,
    2.0 * (k * k - 1.0) * n,
    (1.0 - k / q + k * k) * n,
  ];
}

/// Direct-form II transposed biquad filter.
List<double> _applyBiquad(List<double> input, List<double> c) {
  final out = List<double>.filled(input.length, 0.0);
  double x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (int i = 0; i < input.length; i++) {
    final x = input[i];
    final y = c[0] * x + c[1] * x1 + c[2] * x2 - c[3] * y1 - c[4] * y2;
    x2 = x1; x1 = x; y2 = y1; y1 = y;
    out[i] = y;
  }
  return out;
}

List<double> _applyKWeighting(List<double> samples, double fs) =>
    _applyBiquad(_applyBiquad(samples, _kWeightStage1(fs)), _kWeightStage2(fs));

// ─── LUFS (integrated, BS.1770-4 gating) ─────────────────────────────────────

const _ln10 = 2.302585092994046;

double _computeIntegratedLufs(List<List<double>> channels, int sampleRate) {
  final kw = channels.map((ch) => _applyKWeighting(ch, sampleRate.toDouble())).toList();

  final blockSize = (sampleRate * 0.4).round(); // 400 ms
  final hopSize = (sampleRate * 0.1).round();   // 100 ms (75 % overlap)
  final numSamples = kw[0].length;
  if (numSamples < blockSize) return double.negativeInfinity;

  // Channel gains G_i: L,R,C = 1.0; Ls,Rs = 1.41; LFE = 0
  final g = channels.length <= 2
      ? List.filled(channels.length, 1.0)
      : [1.0, 1.0, 1.0, 0.0, 1.41, 1.41];

  // Compute weighted mean-square z for each block
  final blockZ = <double>[];
  for (int start = 0; start + blockSize <= numSamples; start += hopSize) {
    double z = 0.0;
    for (int ch = 0; ch < kw.length && ch < g.length; ch++) {
      if (g[ch] == 0) continue;
      double sum = 0.0;
      final chData = kw[ch];
      for (int i = start; i < start + blockSize; i++) {
        sum += chData[i] * chData[i];
      }
      z += g[ch] * sum / blockSize;
    }
    blockZ.add(z);
  }

  // Block loudness L_j = −0.691 + 10·log10(z_j)
  final blockL = blockZ.map((z) => z > 0 ? -0.691 + 10.0 * log(z) / _ln10 : -144.0).toList();

  // Pass 1: absolute gate at −70 LUFS → mean z₁
  double sumZ1 = 0; int n1 = 0;
  for (int i = 0; i < blockZ.length; i++) {
    if (blockL[i] >= -70.0) { sumZ1 += blockZ[i]; n1++; }
  }
  if (n1 == 0) return double.negativeInfinity;

  final gammaR = -0.691 + 10.0 * log(sumZ1 / n1) / _ln10 - 10.0;

  // Pass 2: relative gate at Γ_R
  double sumZ2 = 0; int n2 = 0;
  for (int i = 0; i < blockZ.length; i++) {
    if (blockL[i] >= -70.0 && blockL[i] >= gammaR) { sumZ2 += blockZ[i]; n2++; }
  }
  if (n2 == 0) return double.negativeInfinity;

  return -0.691 + 10.0 * log(sumZ2 / n2) / _ln10;
}

// ─── True Peak & DR ──────────────────────────────────────────────────────────

double _computeTruePeak(List<List<double>> channels) {
  double peak = 0.0;
  for (final ch in channels) {
    for (final s in ch) {
      final a = s.abs();
      if (a > peak) peak = a;
    }
  }
  return peak > 0 ? 20.0 * log(peak) / _ln10 : -144.0;
}

/// Returns (peakDbFs, rmsDbFs, dynamicRange).
(double, double, double) _computePeakRmsDr(List<List<double>> channels) {
  double peakLin = 0.0, sumSq = 0.0;
  int total = 0;
  for (final ch in channels) {
    for (final s in ch) {
      final a = s.abs();
      if (a > peakLin) peakLin = a;
      sumSq += s * s;
    }
    total += ch.length;
  }
  final peakDb = peakLin > 0 ? 20.0 * log(peakLin) / _ln10 : -144.0;
  final rmsLin = total > 0 ? sqrt(sumSq / total) : 0.0;
  final rmsDb = rmsLin > 0 ? 20.0 * log(rmsLin) / _ln10 : -144.0;
  return (peakDb, rmsDb, peakDb - rmsDb);
}

// ─── Full analysis ────────────────────────────────────────────────────────────

AudioAnalysisResult? _analyzeWavBytes(Uint8List bytes) {
  final info = _parseWavInfo(bytes);
  if (info == null) return null;

  final channels = _extractSamples(bytes, info);
  if (channels.isEmpty) return null;

  final duration = channels[0].length / info.sampleRate;
  final lufs = _computeIntegratedLufs(channels, info.sampleRate);
  final truePeak = _computeTruePeak(channels);
  final (peak, rms, dr) = _computePeakRmsDr(channels);

  return AudioAnalysisResult(
    integratedLufs: lufs,
    truePeakDbTp: truePeak,
    peakDbFs: peak,
    rmsDbFs: rms,
    dynamicRange: dr,
    sampleRate: info.sampleRate,
    bitDepth: info.bitDepth,
    channels: info.numChannels,
    durationSeconds: duration,
  );
}

