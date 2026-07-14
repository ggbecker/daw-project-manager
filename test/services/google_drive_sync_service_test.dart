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
}
