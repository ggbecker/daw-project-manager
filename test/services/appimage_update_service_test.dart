import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/appimage_update_service.dart';

void main() {
  group('AppImageUpdateService.isRunningAsAppImage', () {
    // Mirrors the same "assert relative to the real platform/env, not a
    // fixed expectation" approach as UpdateCheckService's isSupported test —
    // this actually exercises the false branch for real on the unit_tests
    // CI job (ubuntu-latest, not running inside an AppImage).
    test('reflects the APPIMAGE env var', () {
      expect(
        AppImageUpdateService.isRunningAsAppImage,
        Platform.environment['APPIMAGE'] != null,
      );
    });

    test('currentAppImagePath mirrors the APPIMAGE env var', () {
      expect(AppImageUpdateService.currentAppImagePath, Platform.environment['APPIMAGE']);
    });
  });

  group('AppImageUpdateService.assetsFrom', () {
    test('picks the .AppImage asset and its matching .sha256 checksum', () {
      final assets = [
        {'name': 'DAW_Project_Manager_Linux_v1.2.3.AppImage', 'browser_download_url': 'https://example.com/app.AppImage', 'size': 12345},
        {'name': 'DAW_Project_Manager_Linux_v1.2.3.AppImage.sha256', 'browser_download_url': 'https://example.com/app.AppImage.sha256'},
        {'name': 'DAW_Project_Manager_Linux_v1.2.3.tar.gz', 'browser_download_url': 'https://example.com/app.tar.gz'},
      ];

      final result = AppImageUpdateService.assetsFrom(assets);

      expect(result, isNotNull);
      expect(result!.appImageUrl.toString(), 'https://example.com/app.AppImage');
      expect(result.checksumUrl.toString(), 'https://example.com/app.AppImage.sha256');
      expect(result.appImageSizeBytes, 12345);
    });

    test('is case-insensitive about the .AppImage extension', () {
      final assets = [
        {'name': 'app.appimage', 'browser_download_url': 'https://example.com/app.appimage'},
        {'name': 'app.appimage.sha256', 'browser_download_url': 'https://example.com/app.appimage.sha256'},
      ];

      expect(AppImageUpdateService.assetsFrom(assets), isNotNull);
    });

    test('returns null when there is no .AppImage asset', () {
      final assets = [
        {'name': 'DAW_Project_Manager_macOS_v1.2.3.dmg', 'browser_download_url': 'https://example.com/app.dmg'},
      ];

      expect(AppImageUpdateService.assetsFrom(assets), isNull);
    });

    test('returns null when the .AppImage has no matching .sha256 asset', () {
      final assets = [
        {'name': 'app.AppImage', 'browser_download_url': 'https://example.com/app.AppImage'},
      ];

      expect(AppImageUpdateService.assetsFrom(assets), isNull);
    });

    test('does not match a differently-named checksum file', () {
      final assets = [
        {'name': 'app.AppImage', 'browser_download_url': 'https://example.com/app.AppImage'},
        {'name': 'other-file.sha256', 'browser_download_url': 'https://example.com/other-file.sha256'},
      ];

      expect(AppImageUpdateService.assetsFrom(assets), isNull);
    });
  });

  group('AppImageUpdateService.pickAsset', () {
    test('returns the first asset whose name matches the predicate', () {
      final assets = [
        {'name': 'a.txt'},
        {'name': 'b.AppImage'},
        {'name': 'c.AppImage'},
      ];

      final result = AppImageUpdateService.pickAsset(assets, (name) => name.endsWith('.AppImage'));

      expect(result, {'name': 'b.AppImage'});
    });

    test('returns null when nothing matches', () {
      final assets = [
        {'name': 'a.txt'},
      ];

      expect(AppImageUpdateService.pickAsset(assets, (name) => name.endsWith('.AppImage')), isNull);
    });

    test('skips assets with a null name instead of throwing', () {
      final assets = [
        {'browser_download_url': 'https://example.com/no-name'},
        {'name': 'a.AppImage'},
      ];

      final result = AppImageUpdateService.pickAsset(assets, (name) => name.endsWith('.AppImage'));

      expect(result, {'name': 'a.AppImage'});
    });
  });

  group('AppImageUpdateService.parseSha256', () {
    test('extracts the hex digest from a sha256sum-style line', () {
      const contents = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  DAW_Project_Manager_Linux_v1.2.3.AppImage\n';

      expect(
        AppImageUpdateService.parseSha256(contents),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('is case-insensitive and trims surrounding whitespace', () {
      const contents = '  E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855  app.AppImage  \n';

      expect(
        AppImageUpdateService.parseSha256(contents),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('returns null for an unparseable checksum file', () {
      expect(AppImageUpdateService.parseSha256('not a checksum file'), isNull);
      expect(AppImageUpdateService.parseSha256(''), isNull);
    });
  });

  group('AppImageUpdateService.applyUpdate', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('appimage_update_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('throws when not running as an AppImage', () async {
      // No APPIMAGE env var is set in the test process, so
      // currentAppImagePath is null and applyUpdate must refuse outright
      // rather than attempting to replace... nothing.
      final service = AppImageUpdateService();
      final assets = AppImageReleaseAssets(
        appImageUrl: Uri.parse('https://example.com/app.AppImage'),
        checksumUrl: Uri.parse('https://example.com/app.AppImage.sha256'),
      );

      expect(
        () => service.applyUpdate(assets),
        throwsA(isA<StateError>()),
      );
    });

    // The download + verify + atomic-replace path itself needs a live
    // APPIMAGE env var and an injectable HTTP client to unit test end to
    // end; UpdateCheckService's own network path has the same gap (see its
    // test file). What IS covered above, at the unit level with no I/O or
    // network involved: asset selection (assetsFrom/pickAsset) and checksum
    // parsing (parseSha256) — the two places a malformed GitHub release
    // would actually break this feature.
    test('sha256 digest of a known file matches the expected published format', () {
      final file = File('${tempDir.path}/fake.AppImage')..writeAsBytesSync([1, 2, 3, 4]);
      final digest = sha256.convert(file.readAsBytesSync()).toString();

      expect(AppImageUpdateService.parseSha256('$digest  fake.AppImage'), digest);
    });
  });
}
