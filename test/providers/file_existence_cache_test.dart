import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/providers.dart';

void main() {
  group('FileExistenceCache', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('file_existence_cache_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns true for an existing file', () {
      final file = File('${tempDir.path}/song.als')..writeAsStringSync('data');
      final cache = FileExistenceCache();

      expect(cache.exists(file.path), isTrue);
    });

    test('returns true for an existing directory (bundle-style project)', () {
      final dir = Directory('${tempDir.path}/Song.logicx')..createSync();
      final cache = FileExistenceCache();

      expect(cache.exists(dir.path), isTrue);
    });

    test('returns false for a path that does not exist', () {
      final cache = FileExistenceCache();

      expect(cache.exists('${tempDir.path}/missing.als'), isFalse);
    });

    test('caches a false result — a file created after the first check still reads as missing', () {
      final path = '${tempDir.path}/song.als';
      final cache = FileExistenceCache();

      expect(cache.exists(path), isFalse);
      File(path).writeAsStringSync('data');

      expect(cache.exists(path), isFalse);
    });

    test('invalidateAll clears the cache so a later check reflects current disk state', () {
      final path = '${tempDir.path}/song.als';
      final cache = FileExistenceCache();

      expect(cache.exists(path), isFalse);
      File(path).writeAsStringSync('data');
      cache.invalidateAll();

      expect(cache.exists(path), isTrue);
    });
  });

  // fileExistenceCacheProvider's invalidation-on-project-list-change wiring
  // (ref.listen(allProjectsStreamProvider, ...)) is a single line that
  // delegates directly to FileExistenceCache.invalidateAll, covered above;
  // exercising the wiring itself would require a full repository + Hive
  // fixture and adds no meaningful coverage beyond what's tested here.
}
