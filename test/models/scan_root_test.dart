import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/models/scan_root.dart';

import '../helpers/hive_test_helper.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await HiveTestHelper.setUp();
  });

  tearDownAll(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  ScanRoot makeRoot({
    String id = 'root-1',
    String path = '/home/artist/Music/Projects',
    DateTime? addedAt,
    DateTime? lastScanAt,
    int scanDepth = 0,
    String? displayName,
  }) {
    return ScanRoot(
      id: id,
      path: path,
      addedAt: addedAt ?? DateTime(2025, 1, 1),
      lastScanAt: lastScanAt,
      scanDepth: scanDepth,
      displayName: displayName,
    );
  }

  group('ScanRoot.effectiveDisplayName', () {
    test('uses displayName when set', () {
      final root = makeRoot(
        path: '/home/artist/Music/Projects',
        displayName: 'My LMMS Projects',
      );
      expect(root.effectiveDisplayName, 'My LMMS Projects');
    });

    test('falls back to the folder\'s own name when displayName is unset', () {
      final root = makeRoot(
        path: '/home/artist/Music/Projects',
        displayName: null,
      );
      expect(root.effectiveDisplayName, 'Projects');
    });

    test('falls back correctly for a Windows-style path', () {
      // p.basename() uses the current platform's path style, so this
      // assertion is only meaningful when actually running on Windows —
      // gated below rather than asserted unconditionally.
      final root = makeRoot(
        path: r'C:\Users\Artist\Music\Projects',
        displayName: null,
      );
      expect(root.effectiveDisplayName, 'Projects');
    }, testOn: 'windows');
  });

  group('ScanRoot.copyWith', () {
    test('preserves displayName when no argument is given', () {
      final root = makeRoot(displayName: 'Projects');
      final copy = root.copyWith();

      expect(copy.displayName, 'Projects');
    });

    test('updates only displayName', () {
      final root = makeRoot(displayName: 'Projects');
      final renamed = root.copyWith(displayName: 'My LMMS Projects');

      expect(renamed.displayName, 'My LMMS Projects');
      expect(renamed.id, root.id);
      expect(renamed.path, root.path);
    });
  });

  group('ScanRootAdapter (Hive round-trip)', () {
    test('preserves displayName after write and read', () async {
      final original = makeRoot(displayName: 'Projects');

      final box = await Hive.openBox<ScanRoot>('scan_root_round_trip_test');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;
      await box.close();

      expect(restored.displayName, 'Projects');
    });

    test('reads back a null displayName correctly (pre-existing roots)', () async {
      final original = makeRoot(id: 'root-2', displayName: null);

      final box = await Hive.openBox<ScanRoot>('scan_root_round_trip_test_2');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;
      await box.close();

      expect(restored.displayName, isNull);
    });
  });
}
