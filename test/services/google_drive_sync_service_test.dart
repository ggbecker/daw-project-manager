import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:daw_project_manager/models/profile.dart';
import 'package:daw_project_manager/repository/profile_repository.dart';
import 'package:daw_project_manager/repository/project_repository.dart';
import 'package:daw_project_manager/services/google_drive_sync_service.dart';
import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

// Minimal stub — extends BaseClient so get/post/etc. are provided; only
// instantiation matters and no methods are ever called in these tests.
class _FakeAuthClient extends http.BaseClient
    implements auth_io.AutoRefreshingAuthClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();

  @override
  auth_io.AccessCredentials get credentials => throw UnimplementedError();

  @override
  Stream<auth_io.AccessCredentials> get credentialUpdates =>
      throw UnimplementedError();
}

void main() {
  group('GoogleDriveSyncService.isSignedIn (desktop)', () {
    // Regression: before fix, isSignedIn only checked _currentUser (the mobile
    // GoogleSignIn field). On desktop, auth sets _desktopAuthClient/_driveApi
    // and never populates _currentUser, so the getter always returned false.

    test('returns false before authentication', () {
      final service = GoogleDriveSyncService();
      expect(service.isSignedIn, isFalse);
    });

    test('returns true after desktopAuthClient and driveApi are set', () {
      final service = GoogleDriveSyncService();
      service.desktopAuthClient = _FakeAuthClient();
      service.driveApi = drive.DriveApi(http.Client());
      expect(service.isSignedIn, isTrue);
    });

    test('returns false when only desktopAuthClient is set', () {
      final service = GoogleDriveSyncService();
      service.desktopAuthClient = _FakeAuthClient();
      expect(service.isSignedIn, isFalse);
    });

    test('returns false when only driveApi is set', () {
      final service = GoogleDriveSyncService();
      service.driveApi = drive.DriveApi(http.Client());
      expect(service.isSignedIn, isFalse);
    });
  });

  group('GoogleDriveSyncService.mergeData - custom mixdown folders and phase settings', () {
    late Directory tempDir;
    late ProjectRepository projectRepo;
    late ProfileRepository profileRepo;
    late Profile profile;
    late Box<String> appSettingsBox;

    setUp(() async {
      tempDir = await HiveTestHelper.setUp();
      if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ProfileAdapter());
      projectRepo = await HiveTestHelper.createRepository();
      final profilesBox = await Hive.openBox<Profile>('profiles');
      final settingsBox = await Hive.openBox<String>('settings');
      profileRepo = ProfileRepository(profilesBox: profilesBox, settingsBox: settingsBox);
      profile = await profileRepo.createProfile('Test Profile');
      appSettingsBox = await Hive.openBox<String>('app_settings');
    });

    tearDown(() async {
      await HiveTestHelper.tearDown(tempDir);
    });

    test('restores custom mixdown folders from a backup with no local folders', () async {
      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'customMixdownFolders': ['Mixdowns', 'Bounces'],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      final raw = appSettingsBox.get('customMixdownFolders');
      expect(raw, isNotNull);
      expect(jsonDecode(raw!), ['Mixdowns', 'Bounces']);
    });

    test('unions local and remote custom mixdown folders without duplicates', () async {
      await appSettingsBox.put('customMixdownFolders', jsonEncode(['Mixdowns', 'exports']));

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'customMixdownFolders': ['Exports', 'Bounces'],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      final raw = appSettingsBox.get('customMixdownFolders');
      final merged = (jsonDecode(raw!) as List).cast<String>();
      // 'Exports' from remote is a case-insensitive duplicate of local 'exports' and is dropped.
      expect(merged, ['Mixdowns', 'exports', 'Bounces']);
    });

    test('fills in phase settings for a profile that has none locally', () async {
      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'phaseSettingsByProfile': {
            profile.id: {
              'phases': ['Idea', 'Tracking', 'Mixing', 'Done'],
              'phaseColors': {'Done': '#00FF00'},
              'finishedPhases': ['Done'],
            },
          },
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(
        jsonDecode(appSettingsBox.get('${profile.id}_phases')!),
        ['Idea', 'Tracking', 'Mixing', 'Done'],
      );
      expect(
        jsonDecode(appSettingsBox.get('${profile.id}_phase_colors')!),
        {'Done': '#00FF00'},
      );
      expect(
        jsonDecode(appSettingsBox.get('${profile.id}_finished_phases')!),
        ['Done'],
      );
    });

    test('never overwrites a profile\'s existing phase customization with backup data', () async {
      await appSettingsBox.put('${profile.id}_phases', jsonEncode(['Local Idea', 'Local Done']));

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'phaseSettingsByProfile': {
            profile.id: {
              'phases': ['Remote Idea', 'Remote Mixing', 'Remote Done'],
            },
          },
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
      );

      expect(
        jsonDecode(appSettingsBox.get('${profile.id}_phases')!),
        ['Local Idea', 'Local Done'],
      );
    });
  });

  group('GoogleDriveSyncService project serialization round-trip', () {
    test('preserves previewSongAutoPath, parentProjectId, and ignoredNewerSongPath', () {
      final service = GoogleDriveSyncService();
      final original = TestFactories.makeProject(
        previewSongAutoPath: '/Users/artist/Live Sets/Bounces/mixdown.wav',
        parentProjectId: 'parent-project-id',
        ignoredNewerSongPath: '/Users/artist/Live Sets/Bounces/rejected.wav',
      );

      final restored = service.deserializeProjectForTest(
        service.serializeProjectForTest(original),
      );

      expect(restored.previewSongAutoPath, '/Users/artist/Live Sets/Bounces/mixdown.wav');
      expect(restored.parentProjectId, 'parent-project-id');
      expect(restored.ignoredNewerSongPath, '/Users/artist/Live Sets/Bounces/rejected.wav');
    });
  });

  group('GoogleDriveSyncService.mergeData - project conflict resolution', () {
    // Regression: mergeData used to always overwrite local project metadata
    // (notes, todos, bpm, status, etc.) with whatever was in the remote
    // backup whenever the two differed, regardless of which side was
    // actually edited more recently. That meant the auto-backup timer (which
    // downloads+merges via syncDatabase before re-uploading) could silently
    // discard a local edit made after the last backup in favor of a stale
    // remote copy. The fix compares updatedAt and only lets remote win when
    // it is genuinely the newer side.
    late Directory tempDir;
    late ProjectRepository projectRepo;
    late ProfileRepository profileRepo;
    late Profile profile;

    setUp(() async {
      tempDir = await HiveTestHelper.setUp();
      if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ProfileAdapter());
      final profilesBox = await Hive.openBox<Profile>('profiles');
      final settingsBox = await Hive.openBox<String>('settings');
      profileRepo = ProfileRepository(profilesBox: profilesBox, settingsBox: settingsBox);
      profile = await profileRepo.createProfile('Test Profile');
      projectRepo = await HiveTestHelper.createRepository(profileId: profile.id);
      await Hive.openBox<String>('app_settings');
    });

    tearDown(() async {
      await HiveTestHelper.tearDown(tempDir);
    });

    Map<String, dynamic> remoteProjectMap({
      required String id,
      required DateTime updatedAt,
      String? notes,
      String? previewSongAutoPath,
      String? parentProjectId,
      String? ignoredNewerSongPath,
    }) {
      return {
        'id': id,
        'filePath': '/remote/$id.als',
        'fileName': '$id.als',
        'fileSizeBytes': 1000,
        'lastModifiedAt': DateTime(2025, 1, 1).toIso8601String(),
        'status': 'Mixing',
        'fileExtension': '.als',
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'notes': notes,
        'previewSongAutoPath': previewSongAutoPath,
        'parentProjectId': parentProjectId,
        'ignoredNewerSongPath': ignoredNewerSongPath,
      };
    }

    test('keeps local edits when local was modified after the remote copy', () async {
      final local = TestFactories.makeProject(
        id: 'p1',
        notes: 'Local edit made after last backup',
        updatedAt: DateTime(2025, 6, 1, 12, 0),
      );
      await projectRepo.projectsBox.put(local.id, local);

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'projects': [
            remoteProjectMap(
              id: 'p1',
              // Older than local's updatedAt — this is a stale remote copy.
              updatedAt: DateTime(2025, 6, 1, 10, 0),
              notes: 'Stale remote note',
            ),
          ],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        downloadPreviewSongs: false,
      );

      final merged = projectRepo.projectsBox.get('p1');
      expect(merged!.notes, 'Local edit made after last backup');
    });

    test('takes remote edits when remote was modified after the local copy', () async {
      final local = TestFactories.makeProject(
        id: 'p2',
        notes: 'Old local note',
        updatedAt: DateTime(2025, 6, 1, 8, 0),
      );
      await projectRepo.projectsBox.put(local.id, local);

      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'projects': [
            remoteProjectMap(
              id: 'p2',
              // Newer than local's updatedAt — remote genuinely has the latest edit.
              updatedAt: DateTime(2025, 6, 1, 12, 0),
              notes: 'Fresh remote note',
            ),
          ],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        downloadPreviewSongs: false,
      );

      final merged = projectRepo.projectsBox.get('p2');
      expect(merged!.notes, 'Fresh remote note');
    });

    test('restores previewSongAutoPath, parentProjectId, and ignoredNewerSongPath for a brand-new project from remote', () async {
      final service = GoogleDriveSyncService();
      await service.mergeData(
        remoteData: {
          'projects': [
            remoteProjectMap(
              id: 'p3',
              updatedAt: DateTime(2025, 6, 1),
              previewSongAutoPath: '/remote/Bounces/mixdown.wav',
              parentProjectId: 'parent-id',
              ignoredNewerSongPath: '/remote/Bounces/rejected.wav',
            ),
          ],
        },
        projectRepo: projectRepo,
        profileRepo: profileRepo,
        downloadPreviewSongs: false,
      );

      final restored = projectRepo.projectsBox.get('p3');
      expect(restored, isNotNull);
      expect(restored!.previewSongAutoPath, '/remote/Bounces/mixdown.wav');
      expect(restored.parentProjectId, 'parent-id');
      expect(restored.ignoredNewerSongPath, '/remote/Bounces/rejected.wav');
    });

    test(
      'keeps local lastModifiedAt/fileCreatedAt on desktop even when remote is newer '
      '(flutter test runs as a desktop process, so MobileUtils.isMobile() is false here; '
      'the mobile branch — where these must come from remote — cannot be exercised by a '
      'unit test without mocking Platform.isAndroid/isIOS, so it is not automated)',
      () async {
        final localFileCreatedAt = DateTime(2024, 3, 1);
        final localLastModifiedAt = DateTime(2025, 5, 1);
        final local = TestFactories.makeProject(
          id: 'p4',
          fileCreatedAt: localFileCreatedAt,
          lastModifiedAt: localLastModifiedAt,
          updatedAt: DateTime(2025, 6, 1, 8, 0),
        );
        await projectRepo.projectsBox.put(local.id, local);

        final service = GoogleDriveSyncService();
        await service.mergeData(
          remoteData: {
            'projects': [
              remoteProjectMap(
                id: 'p4',
                updatedAt: DateTime(2025, 6, 1, 12, 0),
                notes: 'Remote note that makes metadata differ',
              ),
            ],
          },
          projectRepo: projectRepo,
          profileRepo: profileRepo,
          downloadPreviewSongs: false,
        );

        final merged = projectRepo.projectsBox.get('p4');
        expect(merged!.fileCreatedAt, localFileCreatedAt);
        expect(merged.lastModifiedAt, localLastModifiedAt);
      },
    );
  });
}
