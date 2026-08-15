import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

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

  group('AudioAnalysisService.mp3ConversionArgs', () {
    test('encodes with LAME at the VBR quality the app standardised on', () {
      expect(
        AudioAnalysisService.mp3ConversionArgs('/in/song.wav', '/out/song.mp3'),
        ['-y', '-i', '/in/song.wav', '-codec:a', 'libmp3lame', '-qscale:a', '2',
         '/out/song.mp3'],
      );
    });

    test('passes paths as separate arguments, never a joined string', () {
      // Shell-style quoting would break on the spaces real project names
      // carry ("2026-08-02 - My Track.wav").
      final args = AudioAnalysisService.mp3ConversionArgs(
        '/in/My Track.wav',
        '/out/My Track.mp3',
      );
      expect(args, contains('/in/My Track.wav'));
      expect(args, contains('/out/My Track.mp3'));
    });
  });

  group('AudioAnalysisService.convertForSharing', () {
    // These assertions cover the ffmpeg branch (Windows/Linux). macOS takes
    // the afconvert branch and Android/iOS the native channel, neither of
    // which goes through ffmpegRunnerOverride.
    final onFfmpegPlatform =
        !Platform.isMacOS && !Platform.isAndroid && !Platform.isIOS;

    late Directory tempDir;
    late File input;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('convert_sharing_test_');
      input = File(p.join(tempDir.path, 'My Track.wav'));
      await input.writeAsBytes(List<int>.filled(64, 0));
    });

    tearDown(() async {
      AudioAnalysisService.ffmpegRunnerOverride = null;
      AudioAnalysisService.mobileConverterOverride = null;
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('returns the encoded file when the runner succeeds', () async {
      if (!onFfmpegPlatform) return;
      List<String>? seenArgs;
      AudioAnalysisService.ffmpegRunnerOverride = (args) async {
        seenArgs = args;
        // Stand in for ffmpeg: write something at the requested output path.
        await File(args.last).writeAsString('fake mp3');
        return true;
      };

      final out = await AudioAnalysisService.convertForSharing(
        input.path,
        tempDir.path,
      );

      expect(out, isNotNull);
      expect(p.basename(out!.path), 'My Track.mp3');
      expect(seenArgs, contains('libmp3lame'));
    });

    test('returns null when the runner reports failure', () async {
      if (!onFfmpegPlatform) return;
      AudioAnalysisService.ffmpegRunnerOverride = (_) async => false;

      expect(
        await AudioAnalysisService.convertForSharing(input.path, tempDir.path),
        isNull,
      );
    });

    test('treats a zero-byte output as a failure, not a shareable file',
        () async {
      if (!onFfmpegPlatform) return;
      // ffmpeg can exit 0 having written nothing usable. Sharing the empty
      // result is exactly what "it only sent the text" looks like to the
      // recipient, so it must not be returned.
      AudioAnalysisService.ffmpegRunnerOverride = (args) async {
        await File(args.last).create();
        return true;
      };

      expect(
        await AudioAnalysisService.convertForSharing(input.path, tempDir.path),
        isNull,
      );
    });

    test('returns null when the runner throws', () async {
      if (!onFfmpegPlatform) return;
      AudioAnalysisService.ffmpegRunnerOverride =
          (_) async => throw StateError('no ffmpeg here');

      expect(
        await AudioAnalysisService.convertForSharing(input.path, tempDir.path),
        isNull,
      );
    });

    test('never writes the output over its own input', () async {
      if (!onFfmpegPlatform) return;
      // An .mp3 source in the same directory as the output would otherwise
      // resolve to the identical path, and ffmpeg truncates its output before
      // reading — destroying the file it was asked to convert.
      final mp3Input = File(p.join(tempDir.path, 'Bounce.mp3'));
      await mp3Input.writeAsString('original audio');

      String? outPath;
      AudioAnalysisService.ffmpegRunnerOverride = (args) async {
        outPath = args.last;
        await File(args.last).writeAsString('converted');
        return true;
      };

      final out = await AudioAnalysisService.convertForSharing(
        mp3Input.path,
        tempDir.path,
      );

      expect(outPath, isNot(mp3Input.path));
      expect(out, isNotNull);
      expect(await mp3Input.readAsString(), 'original audio');
    });

    test('creates the output directory when it does not exist yet', () async {
      if (!onFfmpegPlatform) return;
      final nested = p.join(tempDir.path, 'does', 'not', 'exist');
      AudioAnalysisService.ffmpegRunnerOverride = (args) async {
        await File(args.last).writeAsString('fake mp3');
        return true;
      };

      final out = await AudioAnalysisService.convertForSharing(
        input.path,
        nested,
      );

      expect(out, isNotNull);
      expect(p.dirname(out!.path), nested);
    });
  });

  // Neither mobile platform can shell out to ffmpeg, so both go through a
  // native platform channel instead — MediaCodec on Android,
  // AVAssetExportSession on iOS, one channel and one Dart path for both.
  // convertForSharing() only routes there on Android/iOS, which no test host
  // satisfies, hence calling convertWithMobileCodec directly.
  group('AudioAnalysisService.writeMonoWavFile', () {
    // The waveform extractor routes every non-WAV, non-MP3 format through
    // here, so this is what decides whether a FLAC/OGG/M4A gets a waveform.
    final onFfmpegPlatform =
        !Platform.isMacOS && !Platform.isAndroid && !Platform.isIOS;

    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('mono_wav_test_');
    });

    tearDown(() async {
      AudioAnalysisService.ffmpegRunnerOverride = null;
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('goes through the shared ffmpeg runner, so Windows can use the '
        'bundled binary', () async {
      if (!onFfmpegPlatform) return;
      // Regression: this path used to invoke a bare `ffmpeg`, bypassing the
      // resolver that prefers the copy shipped in the app bundle. Waveforms
      // for these formats therefore failed on any Windows machine without
      // ffmpeg on PATH — which is most of them.
      List<String>? seenArgs;
      AudioAnalysisService.ffmpegRunnerOverride = (args) async {
        seenArgs = args;
        return true;
      };

      final ok = await AudioAnalysisService.writeMonoWavFile(
        p.join(tempDir.path, 'in.flac'),
        p.join(tempDir.path, 'out.wav'),
      );

      expect(ok, isTrue);
      expect(seenArgs, isNotNull);
      expect(seenArgs, containsAllInOrder(['-ac', '1']));
      expect(seenArgs, contains('wav'));
      expect(seenArgs!.last, p.join(tempDir.path, 'out.wav'));
    });

    test('reports failure rather than throwing when ffmpeg is absent',
        () async {
      if (!onFfmpegPlatform) return;
      AudioAnalysisService.ffmpegRunnerOverride =
          (_) async => throw ProcessException('ffmpeg', [], 'not found');

      expect(
        await AudioAnalysisService.writeMonoWavFile(
          p.join(tempDir.path, 'in.ogg'),
          p.join(tempDir.path, 'out.wav'),
        ),
        isFalse,
      );
    });

    test('refuses a format no converter on this platform handles', () async {
      if (!onFfmpegPlatform) return;
      var called = false;
      AudioAnalysisService.ffmpegRunnerOverride = (_) async {
        called = true;
        return true;
      };

      expect(
        await AudioAnalysisService.writeMonoWavFile(
          p.join(tempDir.path, 'in.opus'),
          p.join(tempDir.path, 'out.wav'),
        ),
        isFalse,
      );
      expect(called, isFalse, reason: 'should not have shelled out at all');
    });
  });

  group('AudioAnalysisService.writeDecodedWavFile', () {
    // The waveform extractor decodes through here rather than through
    // writeMonoWavFile, so that a stereo source keeps its channels.
    final onFfmpegPlatform =
        !Platform.isMacOS && !Platform.isAndroid && !Platform.isIOS;

    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('decoded_wav_test_');
    });

    tearDown(() async {
      AudioAnalysisService.ffmpegRunnerOverride = null;
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('never downmixes — the channels are what the lanes are drawn from',
        () async {
      if (!onFfmpegPlatform) return;
      List<String>? seenArgs;
      AudioAnalysisService.ffmpegRunnerOverride = (args) async {
        seenArgs = args;
        return true;
      };

      final ok = await AudioAnalysisService.writeDecodedWavFile(
        p.join(tempDir.path, 'song.mp3'),
        p.join(tempDir.path, 'out.wav'),
      );

      expect(ok, isTrue);
      expect(seenArgs, isNotNull);
      expect(seenArgs, isNot(contains('-ac')),
          reason: 'forcing a channel count would collapse the stereo image');
      expect(seenArgs, contains('wav'));
    });

    test('accepts MP3, which now prefers a real decode over frame headers',
        () async {
      if (!onFfmpegPlatform) return;
      AudioAnalysisService.ffmpegRunnerOverride = (_) async => true;
      expect(
        await AudioAnalysisService.writeDecodedWavFile(
          p.join(tempDir.path, 'song.mp3'),
          p.join(tempDir.path, 'out.wav'),
        ),
        isTrue,
      );
    });

    test('refuses a format no decoder on this platform handles', () async {
      if (!onFfmpegPlatform) return;
      var called = false;
      AudioAnalysisService.ffmpegRunnerOverride = (_) async {
        called = true;
        return true;
      };

      expect(
        await AudioAnalysisService.writeDecodedWavFile(
          p.join(tempDir.path, 'song.opus'),
          p.join(tempDir.path, 'out.wav'),
        ),
        isFalse,
      );
      expect(called, isFalse);
    });

    test('reports failure rather than throwing when no decoder exists',
        () async {
      if (!onFfmpegPlatform) return;
      AudioAnalysisService.ffmpegRunnerOverride =
          (_) async => throw ProcessException('ffmpeg', [], 'not found');

      expect(
        await AudioAnalysisService.writeDecodedWavFile(
          p.join(tempDir.path, 'song.mp3'),
          p.join(tempDir.path, 'out.wav'),
        ),
        isFalse,
      );
    });
  });

  group('AudioAnalysisService.convertWithMobileCodec', () {
    late Directory tempDir;
    late File input;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('mobile_convert_test_');
      input = File(p.join(tempDir.path, 'My Track.wav'));
      await input.writeAsBytes(List<int>.filled(64, 0));
    });

    tearDown(() async {
      AudioAnalysisService.mobileConverterOverride = null;
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('produces an .m4a, since neither mobile OS has an MP3 encoder', () async {
      String? seenInput;
      String? seenOutput;
      AudioAnalysisService.mobileConverterOverride = (i, o) async {
        seenInput = i;
        seenOutput = o;
        await File(o).writeAsString('fake aac');
      };

      final out = await AudioAnalysisService.convertWithMobileCodec(
        input.path,
        tempDir.path,
      );

      expect(out, isNotNull);
      expect(p.basename(out!.path), 'My Track.m4a');
      expect(seenInput, input.path);
      expect(seenOutput, out.path);
    });

    test('returns null when the native transcode throws', () async {
      // MediaExtractor cannot open AIFF, so this is a real input case, not
      // just defensive coding.
      AudioAnalysisService.mobileConverterOverride =
          (_, _) async => throw Exception('MediaExtractor: setDataSource failed');

      expect(
        await AudioAnalysisService.convertWithMobileCodec(
          input.path,
          tempDir.path,
        ),
        isNull,
      );
    });

    test('treats a zero-byte result as a failure', () async {
      AudioAnalysisService.mobileConverterOverride =
          (_, o) async => File(o).create();

      expect(
        await AudioAnalysisService.convertWithMobileCodec(
          input.path,
          tempDir.path,
        ),
        isNull,
      );
    });

    test('returns null when the native side writes nothing at all', () async {
      AudioAnalysisService.mobileConverterOverride = (_, _) async {};

      expect(
        await AudioAnalysisService.convertWithMobileCodec(
          input.path,
          tempDir.path,
        ),
        isNull,
      );
    });

    test('never writes the output over its own input', () async {
      // An .m4a source staged in the share cache would otherwise resolve to
      // the identical path, and the muxer truncates before writing.
      final m4aInput = File(p.join(tempDir.path, 'Bounce.m4a'));
      await m4aInput.writeAsString('original audio');

      String? seenOutput;
      AudioAnalysisService.mobileConverterOverride = (_, o) async {
        seenOutput = o;
        await File(o).writeAsString('converted');
      };

      final out = await AudioAnalysisService.convertWithMobileCodec(
        m4aInput.path,
        tempDir.path,
      );

      expect(seenOutput, isNot(m4aInput.path));
      expect(out, isNotNull);
      expect(await m4aInput.readAsString(), 'original audio');
    });
  });
}
