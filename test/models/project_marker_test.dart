import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_marker.dart';
import 'package:daw_project_manager/services/backup_service.dart';
import 'package:daw_project_manager/services/google_drive_sync_service.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

/// #91 — markers extracted from a DAW project file are user-visible content,
/// so they have to survive a Hive round-trip, a Drive restore and a local
/// backup restore. Any one of those skipped is silent data loss rather than a
/// missing feature.
void main() {
  const intro = ProjectMarker(index: 1, name: 'Intro', positionSeconds: 0);
  const verse = ProjectMarker(index: 2, name: 'Verse', positionSeconds: 91.5);
  const chorus = ProjectMarker(
    index: 1,
    name: 'Chorus',
    positionSeconds: 120,
    endSeconds: 154.25,
  );

  group('ProjectMarker', () {
    test('a marker has no end and no length', () {
      expect(intro.isRegion, isFalse);
      expect(intro.end, isNull);
      expect(intro.length, isNull);
    });

    test('a region reports its span', () {
      expect(chorus.isRegion, isTrue);
      expect(chorus.position, const Duration(seconds: 120));
      expect(chorus.end, const Duration(milliseconds: 154250));
      expect(chorus.length, const Duration(milliseconds: 34250));
    });

    test('a zero or negative span has no length rather than a nonsense one',
        () {
      const degenerate = ProjectMarker(
        index: 1,
        name: 'Empty',
        positionSeconds: 10,
        endSeconds: 10,
      );

      expect(degenerate.isRegion, isTrue);
      expect(degenerate.length, isNull);
    });

    test('fractional positions survive the Duration conversion', () {
      const m = ProjectMarker(
        index: 1,
        name: 'Odd',
        positionSeconds: 1035.7203188705985,
      );

      expect(m.position, const Duration(milliseconds: 1035720));
    });

    test('map round-trip preserves every field', () {
      expect(ProjectMarker.fromMap(chorus.toMap()), chorus);
      expect(ProjectMarker.fromMap(intro.toMap()), intro);
    });

    test('a map missing keys reads as a usable marker rather than throwing',
        () {
      final m = ProjectMarker.fromMap(const {});

      expect(m.name, isEmpty);
      expect(m.positionSeconds, 0);
      expect(m.isRegion, isFalse);
    });

    test('integer positions from JSON are accepted as doubles', () {
      // A whole-second position survives a JSON round-trip as an int.
      final m = ProjectMarker.fromMap(const {
        'index': 2,
        'name': 'Drop',
        'position': 60,
        'end': 90,
      });

      expect(m.positionSeconds, 60.0);
      expect(m.endSeconds, 90.0);
    });

    test('equality is by value, so an unchanged rescan is recognisable', () {
      expect(
        const ProjectMarker(index: 1, name: 'Intro', positionSeconds: 0),
        intro,
      );
      expect(
        const ProjectMarker(index: 1, name: 'Intro', positionSeconds: 0.5),
        isNot(intro),
      );
    });
  });

  group('MusicProject.markers', () {
    test('defaults to empty', () {
      expect(TestFactories.makeProject().markers, isEmpty);
    });

    test('copyWith carries markers through', () {
      final p = TestFactories.makeProject().copyWith(markers: [intro, verse]);

      expect(p.markers, [intro, verse]);
      expect(p.copyWith(notes: 'unrelated').markers, [intro, verse],
          reason: 'an unrelated edit must not drop them');
    });
  });

  group('MusicProjectAdapter', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await HiveTestHelper.setUp();
    });

    tearDownAll(() async {
      await HiveTestHelper.tearDown(tempDir);
    });

    test('markers survive a Hive round-trip', () async {
      final original = TestFactories.makeProject(
        id: 'markers-round-trip',
        markers: [intro, verse, chorus],
      );

      final box = await Hive.openBox<MusicProject>('marker_round_trip_test');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;

      expect(restored.markers, [intro, verse, chorus]);
      expect(restored.markers[2].endSeconds, 154.25);
    });

    test('a record written before markers existed reads as an empty list',
        () async {
      // The real backwards-compatibility case: every project already in a
      // user's box was written with 32 fields and no index 37 at all.
      final reader = _LegacyRecordReader({
        0: 'legacy-id',
        1: '/Users/artist/Sessions/Old.rpp',
        2: 'Old.rpp',
        3: 1024,
        4: DateTime(2024, 1, 1),
        7: 'Idea',
        8: '.rpp',
        9: DateTime(2024, 1, 1),
        10: DateTime(2024, 1, 2),
      });

      final restored = MusicProjectAdapter().read(reader);

      expect(restored.markers, isEmpty);
      expect(restored.id, 'legacy-id');
    });
  });

  group('serialization', () {
    test('Drive sync round-trip preserves markers', () {
      final service = GoogleDriveSyncService();
      final original = TestFactories.makeProject(markers: [intro, chorus]);

      final restored = service.deserializeProjectForTest(
        service.serializeProjectForTest(original),
      );

      expect(restored.markers, [intro, chorus]);
    });

    test('a Drive record from before markers existed restores as empty', () {
      final service = GoogleDriveSyncService();
      final data = service.serializeProjectForTest(
        TestFactories.makeProject(markers: [intro]),
      )..remove('markers');

      expect(service.deserializeProjectForTest(data).markers, isEmpty);
    });

    test('local backup round-trip preserves markers', () {
      // Flatpak's only backup path — a field skipped here can never be backed
      // up at all by those users.
      final original = TestFactories.makeProject(markers: [intro, chorus]);

      final restored = BackupService.projectFromJson(
        BackupService.projectToJson(original),
      );

      expect(restored.markers, [intro, chorus]);
    });

    test('a backup file from before markers existed restores as empty', () {
      final json = BackupService.projectToJson(
        TestFactories.makeProject(markers: [intro]),
      )..remove('markers');

      expect(BackupService.projectFromJson(json).markers, isEmpty);
    });
  });
}

/// A [BinaryReader] that replays one Hive record's field map — enough to drive
/// `MusicProjectAdapter.read`, which only ever calls [readByte] and [read].
///
/// Lets a record written by an older version of the adapter (no index 37) be
/// fed to the current one, which is the case no round-trip through a live box
/// can reproduce: writing always uses today's field list.
class _LegacyRecordReader implements BinaryReader {
  _LegacyRecordReader(Map<int, dynamic> fields)
      : _script = [
          fields.length,
          for (final entry in fields.entries) ...[entry.key, entry.value],
        ];

  final List<dynamic> _script;
  int _cursor = 0;

  @override
  int readByte() => _script[_cursor++] as int;

  @override
  dynamic read([int? typeId]) => _script[_cursor++];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} is not needed here');
}
