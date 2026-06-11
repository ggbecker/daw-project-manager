import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/services/mixdown_detector_service.dart';
import '../helpers/test_factories.dart';

void main() {
  group('MixdownDetectorService.findNewerFileInSameFolder', () {
    test('returns null when current file does not exist', () {
      final result = MixdownDetectorService.findNewerFileInSameFolder(
        '/nonexistent/path/file.wav',
      );
      expect(result, isNull);
    });

    test('returns null when the current file is the only audio file', () async {
      final dir = await Directory.systemTemp.createTemp('mixdown_only_');
      try {
        final file = File('${dir.path}/only.wav');
        await file.create();
        expect(
          MixdownDetectorService.findNewerFileInSameFolder(file.path),
          isNull,
        );
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('returns the newer audio file', () async {
      final dir = await Directory.systemTemp.createTemp('mixdown_newer_');
      try {
        final older = File('${dir.path}/v1.wav');
        final newer = File('${dir.path}/v2.wav');
        await older.create();
        await newer.create();
        // Set explicit modification times to avoid timing flakiness
        older.setLastModifiedSync(DateTime(2024, 1, 1));
        newer.setLastModifiedSync(DateTime(2025, 1, 1));

        final result = MixdownDetectorService.findNewerFileInSameFolder(older.path);
        expect(result, isNotNull);
        expect(result!.path, contains('v2'));
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('ignores non-audio files when looking for a newer file', () async {
      final dir = await Directory.systemTemp.createTemp('mixdown_nonaud_');
      try {
        final audio = File('${dir.path}/mix.wav');
        final nonAudio = File('${dir.path}/notes.txt');
        await audio.create();
        await nonAudio.create();
        nonAudio.setLastModifiedSync(DateTime(2025, 1, 1)); // newer but not audio

        // Only one audio file — nothing newer
        expect(
          MixdownDetectorService.findNewerFileInSameFolder(audio.path),
          isNull,
        );
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('returns null when the newest file matches ignoredPath', () async {
      final dir = await Directory.systemTemp.createTemp('mixdown_ignored_');
      try {
        final older = File('${dir.path}/v1.wav');
        final newer = File('${dir.path}/v2.wav');
        await older.create();
        await newer.create();
        older.setLastModifiedSync(DateTime(2024, 1, 1));
        newer.setLastModifiedSync(DateTime(2025, 1, 1));

        final result = MixdownDetectorService.findNewerFileInSameFolder(
          older.path,
          ignoredPath: newer.path,
        );
        expect(result, isNull);
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });

  group('MixdownDetectorService.findLatestMixdown', () {
    test('returns null when project filePath is empty', () {
      final project = TestFactories.makeProject(filePath: '');
      expect(MixdownDetectorService.findLatestMixdown(project), isNull);
    });

    test('returns null when no candidate directories exist', () {
      final project = TestFactories.makeProject(
        filePath: '/nonexistent/path/project.als',
        dawType: 'Ableton Live',
      );
      expect(MixdownDetectorService.findLatestMixdown(project), isNull);
    });

    test('returns newest audio file from DAW-specific bounce folder', () async {
      final dir = await Directory.systemTemp.createTemp('daw_bounce_');
      try {
        final bouncesDir = Directory('${dir.path}/Bounces');
        await bouncesDir.create();
        final older = File('${bouncesDir.path}/v1.wav');
        final newer = File('${bouncesDir.path}/v2.wav');
        await older.create();
        await newer.create();
        older.setLastModifiedSync(DateTime(2024, 1, 1));
        newer.setLastModifiedSync(DateTime(2025, 1, 1));

        final project = TestFactories.makeProject(
          filePath: '${dir.path}/project.als',
          dawType: 'Ableton Live',
        );
        final result = MixdownDetectorService.findLatestMixdown(project);
        expect(result, isNotNull);
        expect(result!.path, contains('v2'));
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('checks customFolder before DAW-specific folder', () async {
      final dir = await Directory.systemTemp.createTemp('daw_custom_');
      try {
        final customDir = Directory('${dir.path}/MyBounces');
        final dawDir = Directory('${dir.path}/Bounces');
        await customDir.create();
        await dawDir.create();

        final dawFile = File('${dawDir.path}/from_daw.wav');
        final customFile = File('${customDir.path}/from_custom.wav');
        await dawFile.create();
        await customFile.create();
        dawFile.setLastModifiedSync(DateTime(2024, 1, 1));
        customFile.setLastModifiedSync(DateTime(2025, 1, 1));

        final project = TestFactories.makeProject(
          filePath: '${dir.path}/project.als',
          dawType: 'Ableton Live',
        );
        final result = MixdownDetectorService.findLatestMixdown(
          project,
          customFolder: 'MyBounces',
        );
        expect(result, isNotNull);
        expect(result!.path, contains('from_custom'));
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('skips non-audio files in bounce folder', () async {
      final dir = await Directory.systemTemp.createTemp('daw_skip_');
      try {
        final bouncesDir = Directory('${dir.path}/Bounces');
        await bouncesDir.create();
        await File('${bouncesDir.path}/readme.txt').create();
        await File('${bouncesDir.path}/image.png').create();

        final project = TestFactories.makeProject(
          filePath: '${dir.path}/project.als',
          dawType: 'Ableton Live',
        );
        expect(MixdownDetectorService.findLatestMixdown(project), isNull);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('falls back to generic Mixdown folder for unknown DAW type', () async {
      final dir = await Directory.systemTemp.createTemp('daw_fallback_');
      try {
        final mixdownDir = Directory('${dir.path}/Mixdown');
        await mixdownDir.create();
        final file = File('${mixdownDir.path}/export.mp3');
        await file.create();

        final project = TestFactories.makeProject(
          filePath: '${dir.path}/project.proj',
          dawType: null,
        );
        final result = MixdownDetectorService.findLatestMixdown(project);
        expect(result, isNotNull);
        expect(result!.path, contains('export.mp3'));
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
