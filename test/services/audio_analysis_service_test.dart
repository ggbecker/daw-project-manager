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
    // macOS takes the afconvert branch, which has no runner seam — these
    // assertions are about the ffmpeg branch every other platform uses.
    final onFfmpegPlatform = !Platform.isMacOS;

    late Directory tempDir;
    late File input;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('convert_sharing_test_');
      input = File(p.join(tempDir.path, 'My Track.wav'));
      await input.writeAsBytes(List<int>.filled(64, 0));
    });

    tearDown(() async {
      AudioAnalysisService.ffmpegRunnerOverride = null;
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
}
