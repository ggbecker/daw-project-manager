import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/services/google_drive_sync_service.dart';
import '../helpers/test_factories.dart';

void main() {
  group('GoogleDriveSyncService.hasMetadataChanged', () {
    late GoogleDriveSyncService service;

    setUp(() {
      service = GoogleDriveSyncService();
    });

    test('returns false when projects are identical', () {
      final project = TestFactories.makeProject(
        lastModifiedAt: DateTime(2025, 6, 1, 14, 30),
      );
      expect(service.hasMetadataChangedForTesting(project, project), isFalse);
    });

    test('returns true when lastModifiedAt differs', () {
      final local = TestFactories.makeProject(
        lastModifiedAt: DateTime(2025, 1, 10, 8, 0),
      );
      final remote = TestFactories.makeProject(
        lastModifiedAt: DateTime(2025, 6, 20, 16, 45),
      );
      expect(service.hasMetadataChangedForTesting(remote, local), isTrue);
    });

    test('returns false when lastModifiedAt is the same', () {
      final date = DateTime(2025, 6, 20, 16, 45);
      final local = TestFactories.makeProject(lastModifiedAt: date);
      final remote = TestFactories.makeProject(lastModifiedAt: date);
      expect(service.hasMetadataChangedForTesting(remote, local), isFalse);
    });

    test('returns true when fileCreatedAt differs', () {
      final local = TestFactories.makeProject(
        fileCreatedAt: DateTime(2024, 1, 1),
      );
      final remote = TestFactories.makeProject(
        fileCreatedAt: DateTime(2024, 6, 15),
      );
      expect(service.hasMetadataChangedForTesting(remote, local), isTrue);
    });

    test('returns true when notes differ', () {
      final local = TestFactories.makeProject(notes: 'old notes');
      final remote = TestFactories.makeProject(notes: 'new notes');
      expect(service.hasMetadataChangedForTesting(remote, local), isTrue);
    });

    test('returns true when status differs', () {
      final local = TestFactories.makeProject(status: 'In Progress');
      final remote = TestFactories.makeProject(status: 'Mixing');
      expect(service.hasMetadataChangedForTesting(remote, local), isTrue);
    });

    test('returns true when bpm differs', () {
      final local = TestFactories.makeProject(bpm: 120.0);
      final remote = TestFactories.makeProject(bpm: 140.0);
      expect(service.hasMetadataChangedForTesting(remote, local), isTrue);
    });

    test('returns true when musicalKey differs', () {
      final local = TestFactories.makeProject(musicalKey: 'C major');
      final remote = TestFactories.makeProject(musicalKey: 'A minor');
      expect(service.hasMetadataChangedForTesting(remote, local), isTrue);
    });

    test('returns true when hidden flag differs', () {
      final local = TestFactories.makeProject(hidden: false);
      final remote = TestFactories.makeProject(hidden: true);
      expect(service.hasMetadataChangedForTesting(remote, local), isTrue);
    });

    test('returns true when todos differ', () {
      final local = TestFactories.makeProject(todos: []);
      final remote = TestFactories.makeProject(
        todos: [TestFactories.makeTodo(text: 'Mix kick')],
      );
      expect(service.hasMetadataChangedForTesting(remote, local), isTrue);
    });

    test('returns true when deadline is added', () {
      final local = TestFactories.makeProject(deadline: null);
      final remote = TestFactories.makeProject(
        deadline: DateTime(2025, 12, 31),
      );
      expect(service.hasMetadataChangedForTesting(remote, local), isTrue);
    });

    test('does not treat updatedAt change alone as metadata change', () {
      // updatedAt is intentionally excluded — it can change when file is
      // modified on disk, so it is not reliable as a change signal.
      final base = TestFactories.makeProject(
        lastModifiedAt: DateTime(2025, 6, 1),
      );
      final withNewerUpdatedAt = TestFactories.makeProject(
        lastModifiedAt: DateTime(2025, 6, 1),
        updatedAt: DateTime(2025, 12, 1),
      );
      expect(
        service.hasMetadataChangedForTesting(withNewerUpdatedAt, base),
        isFalse,
      );
    });
  });
}
