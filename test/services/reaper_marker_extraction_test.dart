import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/services/metadata_extractor.dart';

/// #91 — Reaper stores markers and regions as plain `MARKER` lines in the
/// `.rpp` state chunk. A session holding several songs is one opaque row in
/// the app until those are read; these cover the line syntax as documented in
/// ReaTeam's State Chunk Definitions, plus the shapes real files turn out to
/// have.
void main() {
  group('extractReaperMarkers — point markers', () {
    test('reads index, position and name', () {
      final markers = MetadataExtractor.extractReaperMarkers('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
  MARKER 1 0 "Intro" 0 0 1 R {A9E967B2-1CDD-4976-96FE-8BEC7C692609} 0 2
  MARKER 2 91.5 "Chorus" 0 0 1 R {7ABFE34A-D6F8-4BE4-8838-596E8157D9DB} 0 2
>
''');

      expect(markers.length, 2);
      expect(markers[0].index, 1);
      expect(markers[0].name, 'Intro');
      expect(markers[0].positionSeconds, 0);
      expect(markers[0].isRegion, isFalse);
      expect(markers[1].name, 'Chorus');
      expect(markers[1].positionSeconds, 91.5);
    });

    test('reads the marker lines from a real multi-song session', () {
      // Verbatim from the sample .rpp attached to the issue — four track
      // markers, one of them flagged selected (8), which is exactly the field
      // that would be misread as "is region" if flags were treated as a bool.
      final markers = MetadataExtractor.extractReaperMarkers('''
  RULERLANE 2 8 "" 0 -1 0
  MARKER 1 0 "Track 1: HelloDAW Project Manager" 0 0 1 R {A9E967B2-1CDD-4976-96FE-8BEC7C692609} 0 2
  MARKER 2 1035.7203188705985 "Track 2: This is the result of a recording session" 0 0 1 R {7ABFE34A-D6F8-4BE4-8838-596E8157D9DB} 0 2
  MARKER 3 2052.2986120458991 "Track 3: I made a simple example for you to parse" 0 0 1 R {D316EB0F-5B30-4E24-9B59-B08C018CE5CC} 0 2
  MARKER 4 2553.4094989978121 "Track 4: But I could have adapted other parameters" 8 0 1 R {73055394-4E7D-4D9B-94D1-6DEBB40A500F} 0 2
''');

      expect(markers.length, 4);
      expect(markers.every((m) => !m.isRegion), isTrue,
          reason: 'flags 8 is "selected", not "region"');
      expect(markers.map((m) => m.index), [1, 2, 3, 4]);
      expect(markers.last.name,
          'Track 4: But I could have adapted other parameters');
      expect(markers[1].position.inSeconds, 1035);
    });

    test('keeps unnamed markers — a position is still worth having', () {
      final markers = MetadataExtractor.extractReaperMarkers(
        'MARKER 3 12.25 "" 0 0 1 B {AFD8C34F-4325-2000-0000-000000000000} 0',
      );

      expect(markers.single.name, isEmpty);
      expect(markers.single.index, 3);
      expect(markers.single.positionSeconds, 12.25);
    });

    test('drops markers hidden in the ruler', () {
      final markers = MetadataExtractor.extractReaperMarkers('''
MARKER 1 1 "Shown" 0 0 1 B {AAAA} 0
MARKER 2 2 "Hidden" 16 0 1 B {BBBB} 0
''');

      expect(markers.map((m) => m.name), ['Shown']);
    });

    test('ignores everything that is not a MARKER line', () {
      final markers = MetadataExtractor.extractReaperMarkers('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
  TEMPO 120 4 4 0
  <TRACK
    NAME "Drums"
    TKM 0.5 "Take marker" 21036800 0.5
  >
>
''');

      expect(markers, isEmpty);
    });
  });

  group('extractReaperMarkers — quoting', () {
    test('reads the alternate quote characters Reaper falls back to', () {
      // Reaper picks the first of " ' ` that the value itself doesn't contain.
      final markers = MetadataExtractor.extractReaperMarkers('''
MARKER 1 1 'He said "go"' 0 0 1 B {AAAA} 0
MARKER 2 2 `mixed "quotes" and 'ticks'` 0 0 1 B {BBBB} 0
''');

      expect(markers[0].name, 'He said "go"');
      expect(markers[1].name, "mixed \"quotes\" and 'ticks'");
    });

    test('reads a bare single-word name', () {
      final markers = MetadataExtractor.extractReaperMarkers(
        'MARKER 1 4 Bridge 0 0 1 B {AAAA} 0',
      );

      expect(markers.single.name, 'Bridge');
      expect(markers.single.isRegion, isFalse);
    });
  });

  group('extractReaperMarkers — regions', () {
    test('pairs the two lines sharing an index into one span', () {
      final markers = MetadataExtractor.extractReaperMarkers('''
MARKER 1 2 "Edit Region" 9 0 1 B {AFD8C34F-4325-2000-0000-000000000000} 0
MARKER 1 4 "" 9
''');

      final region = markers.single;
      expect(region.isRegion, isTrue);
      expect(region.name, 'Edit Region');
      expect(region.positionSeconds, 2);
      expect(region.endSeconds, 4);
      expect(region.length, const Duration(seconds: 2));
    });

    test('markers and regions numbered separately do not pair with each other',
        () {
      // Reaper counts the two sequences independently, so index 1 can be both
      // a marker and a region in the same project.
      final markers = MetadataExtractor.extractReaperMarkers('''
MARKER 1 0 "A marker" 0 0 1 B {AAAA} 0
MARKER 1 10 "A region" 1 0 1 B {BBBB} 0
MARKER 1 20 "" 1
''');

      expect(markers.length, 2);
      expect(markers[0].name, 'A marker');
      expect(markers[0].isRegion, isFalse);
      expect(markers[1].name, 'A region');
      expect(markers[1].endSeconds, 20);
    });

    test('a region whose closing line is missing degrades to a marker', () {
      final markers = MetadataExtractor.extractReaperMarkers(
        'MARKER 1 5 "Truncated" 1 0 1 B {AAAA} 0',
      );

      expect(markers.single.name, 'Truncated');
      expect(markers.single.isRegion, isFalse,
          reason: 'the place survives even though the length is unknowable');
    });

    test('takes the span even if the halves are written out of order', () {
      final markers = MetadataExtractor.extractReaperMarkers('''
MARKER 1 30 "" 1
MARKER 1 10 "Backwards" 1 0 1 B {AAAA} 0
''');

      expect(markers.single.positionSeconds, 10);
      expect(markers.single.endSeconds, 30);
      expect(markers.single.name, 'Backwards');
    });
  });

  group('extractReaperMarkers — ordering and bounds', () {
    test('sorts by position rather than trusting file order', () {
      final markers = MetadataExtractor.extractReaperMarkers('''
MARKER 3 90 "Last" 0 0 1 B {CCCC} 0
MARKER 1 10 "First" 0 0 1 B {AAAA} 0
MARKER 2 50 "Middle" 0 0 1 B {BBBB} 0
''');

      expect(markers.map((m) => m.name), ['First', 'Middle', 'Last']);
    });

    test('caps the list — it is persisted, backed up and synced', () {
      final lines = [
        for (var i = 1; i <= MetadataExtractor.maxMarkersPerProject + 50; i++)
          'MARKER $i $i "Marker $i" 0 0 1 B {AAAA} 0',
      ].join('\n');

      final markers = MetadataExtractor.extractReaperMarkers(lines);

      expect(markers.length, MetadataExtractor.maxMarkersPerProject);
      expect(markers.first.name, 'Marker 1',
          reason: 'the cap keeps the earliest markers, not an arbitrary slice');
    });

    test('a file with no markers yields an empty list, not a failure', () {
      expect(MetadataExtractor.extractReaperMarkers(''), isEmpty);
    });
  });

  group('extractMetadata wiring', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('rpp_markers_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('a full extract of an .rpp carries the markers', () async {
      final file = File('${tempDir.path}/session.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
  TEMPO 120 4 4 0
  MARKER 1 0 "Song One" 0 0 1 R {AAAA} 0 2
  MARKER 2 210.5 "Song Two" 0 0 1 R {BBBB} 0 2
>
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);

      expect(metadata.markers, isNotNull);
      expect(metadata.markers!.map((m) => m.name), ['Song One', 'Song Two']);
    });

    test('an .rpp with no markers reports an empty list, not null', () async {
      // The difference decides whether a rescan clears markers the user
      // deleted in the DAW or leaves them behind forever.
      final file = File('${tempDir.path}/bare.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
  TEMPO 120 4 4 0
>
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);

      expect(metadata.markers, isEmpty);
    });

    test('a lightweight extract reports null — it never looked', () async {
      final metadata =
          await MetadataExtractor.extractLightweightMetadata('/fake/x.rpp');

      expect(metadata.markers, isNull);
    });

    test('a DAW with no marker support reports null', () async {
      final file = File('${tempDir.path}/project.als');
      await file.writeAsString('not really a Live set');

      final metadata = await MetadataExtractor.extractMetadata(file.path);

      expect(metadata.markers, isNull);
    });
  });
}
