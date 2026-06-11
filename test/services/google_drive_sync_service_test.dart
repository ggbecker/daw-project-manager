import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:http/http.dart' as http;
import 'package:daw_project_manager/services/google_drive_sync_service.dart';

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
}
