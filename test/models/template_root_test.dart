import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/models/template_root.dart';

import '../helpers/hive_test_helper.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await HiveTestHelper.setUp();
  });

  tearDownAll(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  TemplateRoot makeRoot({
    String id = 'root-1',
    String path = '/Users/artist/Templates',
    DateTime? addedAt,
    DateTime? lastRefreshedAt,
  }) {
    return TemplateRoot(
      id: id,
      path: path,
      addedAt: addedAt ?? DateTime(2025, 1, 1),
      lastRefreshedAt: lastRefreshedAt,
    );
  }

  group('TemplateRoot.copyWith', () {
    test('preserves unchanged fields when no arguments are given', () {
      final root = makeRoot(lastRefreshedAt: DateTime(2025, 2, 1));
      final copy = root.copyWith();

      expect(copy.id, root.id);
      expect(copy.path, root.path);
      expect(copy.addedAt, root.addedAt);
      expect(copy.lastRefreshedAt, root.lastRefreshedAt);
    });

    test('updates only the provided fields', () {
      final root = makeRoot();
      final refreshed = root.copyWith(lastRefreshedAt: DateTime(2025, 6, 1));

      expect(refreshed.lastRefreshedAt, DateTime(2025, 6, 1));
      expect(refreshed.id, root.id);
      expect(refreshed.path, root.path);
      expect(refreshed.addedAt, root.addedAt);
    });
  });

  group('TemplateRootAdapter (Hive round-trip)', () {
    test('preserves all fields after write and read', () async {
      final original = makeRoot(lastRefreshedAt: DateTime(2025, 3, 15));

      final box = await Hive.openBox<TemplateRoot>('template_root_round_trip_test');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;
      await box.close();

      expect(restored.id, original.id);
      expect(restored.path, original.path);
      expect(restored.addedAt, original.addedAt);
      expect(restored.lastRefreshedAt, original.lastRefreshedAt);
    });

    test('reads back a null lastRefreshedAt correctly', () async {
      final original = makeRoot(id: 'root-2');

      final box = await Hive.openBox<TemplateRoot>('template_root_round_trip_test_2');
      await box.put(original.id, original);
      final restored = box.get(original.id)!;
      await box.close();

      expect(restored.lastRefreshedAt, isNull);
    });
  });
}
