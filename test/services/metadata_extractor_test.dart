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
}
