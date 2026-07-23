import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/services/metadata_extractor.dart';

void main() {
  // _getDawTypeFromExtension is private; exercise it via the public
  // extractLightweightMetadata method which delegates to it immediately.
  // The method does not open or read the file, so a fake path is fine.
  Future<String?> dawTypeFor(String ext) async {
    final m = await MetadataExtractor.extractLightweightMetadata('/fake/project$ext');
    return m.dawType;
  }

  group('MetadataExtractor — DAW type detection from extension', () {
    test('.als → Ableton Live', () async {
      expect(await dawTypeFor('.als'), 'Ableton Live');
    });

    test('.alp → Ableton Live', () async {
      expect(await dawTypeFor('.alp'), 'Ableton Live');
    });

    test('.bwproject → Bitwig Studio', () async {
      expect(await dawTypeFor('.bwproject'), 'Bitwig Studio');
    });

    test('.cpr → Cubase', () async {
      expect(await dawTypeFor('.cpr'), 'Cubase');
    });

    test('.flp → FL Studio', () async {
      expect(await dawTypeFor('.flp'), 'FL Studio');
    });

    test('.logicx → Logic Pro', () async {
      expect(await dawTypeFor('.logicx'), 'Logic Pro');
    });

    test('.maschine → Maschine', () async {
      expect(await dawTypeFor('.maschine'), 'Maschine');
    });

    test('.maschine2 → Maschine', () async {
      expect(await dawTypeFor('.maschine2'), 'Maschine');
    });

    test('.npr → Nuendo', () async {
      expect(await dawTypeFor('.npr'), 'Nuendo');
    });

    test('.ptx → Pro Tools', () async {
      expect(await dawTypeFor('.ptx'), 'Pro Tools');
    });

    test('.pts → Pro Tools', () async {
      expect(await dawTypeFor('.pts'), 'Pro Tools');
    });

    test('.rpp → Reaper', () async {
      expect(await dawTypeFor('.rpp'), 'Reaper');
    });

    test('.song → Studio One', () async {
      expect(await dawTypeFor('.song'), 'Studio One');
    });

    test('.tracktionedit → Waveform', () async {
      expect(await dawTypeFor('.tracktionedit'), 'Waveform');
    });

    test('.tracktion → Waveform', () async {
      expect(await dawTypeFor('.tracktion'), 'Waveform');
    });

    test('.cwp → Sonnar', () async {
      expect(await dawTypeFor('.cwp'), 'Sonnar');
    });

    test('.wrk → Sonnar', () async {
      expect(await dawTypeFor('.wrk'), 'Sonnar');
    });

    test('.bun → Sonnar', () async {
      expect(await dawTypeFor('.bun'), 'Sonnar');
    });

    test('.luna → LUNA', () async {
      expect(await dawTypeFor('.luna'), 'LUNA');
    });

    test('.mgd → MAGDA', () async {
      expect(await dawTypeFor('.mgd'), 'MAGDA');
    });

    test('unknown extension → null', () async {
      expect(await dawTypeFor('.unknown'), isNull);
    });

    test('no extension → null', () async {
      expect(await dawTypeFor(''), isNull);
    });

    test('extension matching is case-insensitive', () async {
      final m = await MetadataExtractor.extractLightweightMetadata('/fake/PROJECT.ALS');
      expect(m.dawType, 'Ableton Live');
    });

    test('returns null BPM and key from lightweight extraction', () async {
      final m = await MetadataExtractor.extractLightweightMetadata('/fake/project.als');
      expect(m.bpm, isNull);
      expect(m.key, isNull);
      expect(m.dawVersion, isNull);
    });
  });

  group('MetadataExtractor — Reaper (.rpp) full extraction', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('rpp_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('extracts version, BPM, and key signature from Reaper text project files', () async {
      final file = File('${tempDir.path}/project.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPO 120 4 4 0
<KEYSIG
  0 11 1 0x4E9
>
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.dawType, 'Reaper');
      expect(metadata.bpm, 120.0);
      expect(metadata.key, 'B Blues Minor');
      expect(metadata.dawVersion, '7.78');
    });

    test('extracts major and minor Reaper scale values from the text signature block', () async {
      final majorFile = File('${tempDir.path}/project_major.rpp');
      await majorFile.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPO 120 4 4 0
<KEYSIG
  0 11 1 0x0AB5
>
''');

      final majorMetadata = await MetadataExtractor.extractMetadata(majorFile.path);
      expect(majorMetadata.key, 'B Major');

      final minorFile = File('${tempDir.path}/project_minor.rpp');
      await minorFile.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPO 120 4 4 0
<KEYSIG
  0 0 -1 0x05AD
>
''');

      final minorMetadata = await MetadataExtractor.extractMetadata(minorFile.path);
      expect(minorMetadata.key, 'C Minor');
    });

    test('accepts both integer and decimal Reaper tempo values', () async {
      final integerFile = File('${tempDir.path}/project_integer.rpp');
      await integerFile.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPO 120 4 4 0
''');

      final integerMetadata = await MetadataExtractor.extractMetadata(integerFile.path);
      expect(integerMetadata.bpm, 120.0);

      final decimalFile = File('${tempDir.path}/project_decimal.rpp');
      await decimalFile.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPO 120.2 4 4 0
''');

      final decimalMetadata = await MetadataExtractor.extractMetadata(decimalFile.path);
      expect(decimalMetadata.bpm, 120.2);
    });

    test('resolves a Reaper scale mask from the same 12-slot bit pattern methodology used by the .reascale file', () async {
      final file = File('${tempDir.path}/project_scale_mask.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPO 120 4 4 0
<KEYSIG
  0 0 0 0x0295
>
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.key, 'C Major Pentatonic');
    });

    test('matches only the whole TEMPO token, not TEMPOENVLOCKMODE', () async {
      final file = File('${tempDir.path}/project_tempoenvlock.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPOENVLOCKMODE 1
TEMPO 120 4 4 0
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.bpm, 120.0);
    });

    test('extracts Title, Author and Notes into a single combined projectNotes string', () async {
      final file = File('${tempDir.path}/project_notes.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
  TITLE "Notes 1"
  AUTHOR "Audio Crawler"
  <NOTES 0 2
    |This is notes of the project to be displayed in DAW Project Manager
    |
    |Multiple lines
    |
    |1
    |
    |2
    |
    |Test
  >
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(
        metadata.projectNotes,
        'Notes 1\n'
        'by Audio Crawler\n'
        '\n'
        'This is notes of the project to be displayed in DAW Project Manager\n'
        '\n'
        'Multiple lines\n'
        '\n'
        '1\n'
        '\n'
        '2\n'
        '\n'
        'Test',
      );
    });

    test('projectNotes is null when there is no NOTES/TITLE/AUTHOR block', () async {
      final file = File('${tempDir.path}/project_no_notes.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPO 120 4 4 0
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.projectNotes, isNull);
    });

    test('projectNotes falls back to just the notes body when TITLE/AUTHOR are absent', () async {
      final file = File('${tempDir.path}/project_notes_only.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
  <NOTES 0 2
    |Just a quick note
  >
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.projectNotes, 'Just a quick note');
    });
  });

  group('MetadataExtractor — MAGDA (.mgd) full extraction', () {
    // .mgd files are a single zlib-compressed (RFC 1950) JSON document with a
    // top-level `magdaVersion` and a `project` object holding `tempo`,
    // `keyRoot` (0=C..11=B, -1=none) and `keyQuality` (0=major, 1=minor).
    // Verified against a real project file exported by MAGDA 0.15.0.
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('mgd_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    Future<String> writeMgdFixture(Map<String, dynamic> json) async {
      final file = File('${tempDir.path}/project.mgd');
      final compressed = zlib.encode(utf8.encode(jsonEncode(json)));
      await file.writeAsBytes(compressed);
      return file.path;
    }

    test('extracts BPM, key, and major DAW version', () async {
      final path = await writeMgdFixture({
        'magdaVersion': '0.15.0',
        'project': {
          'tempo': 125.0,
          'keyRoot': 1, // C#/Db
          'keyQuality': 0, // Major
        },
      });

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.dawType, 'MAGDA');
      expect(metadata.bpm, 125.0);
      expect(metadata.key, 'C#/Db Major');
      expect(metadata.dawVersion, '0.15');
    });

    test('minor key quality', () async {
      final path = await writeMgdFixture({
        'magdaVersion': '0.15.0',
        'project': {'tempo': 90.0, 'keyRoot': 9, 'keyQuality': 1},
      });

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.key, 'A Minor');
    });

    test('keyRoot -1 means no key set', () async {
      final path = await writeMgdFixture({
        'magdaVersion': '0.15.0',
        'project': {'tempo': 120.0, 'keyRoot': -1, 'keyQuality': 0},
      });

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.key, isNull);
      expect(metadata.bpm, 120.0);
    });

    test('malformed file returns empty metadata instead of throwing', () async {
      final file = File('${tempDir.path}/broken.mgd');
      await file.writeAsBytes([0x00, 0x01, 0x02]);

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.bpm, isNull);
      expect(metadata.key, isNull);
      expect(metadata.dawVersion, isNull);
      expect(metadata.dawType, 'MAGDA');
    });

    test('missing file returns empty metadata', () async {
      final metadata =
          await MetadataExtractor.extractMetadata('${tempDir.path}/missing.mgd');
      expect(metadata.bpm, isNull);
      expect(metadata.key, isNull);
      expect(metadata.dawVersion, isNull);
    });
  });
}
