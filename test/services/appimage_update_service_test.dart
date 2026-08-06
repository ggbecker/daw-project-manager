import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:daw_project_manager/services/appimage_update_service.dart';

/// Minimal fake [http.Client] that dispatches every request (both the plain
/// `.get()` used for the checksum and the `.send()` used for the streamed
/// AppImage download — `.get()` is implemented in terms of `.send()`) to a
/// caller-supplied handler. Gives tests full control over response streams,
/// including ones that never finish until the test says so (needed to
/// exercise mid-download cancellation).
class _FakeClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) handler;
  _FakeClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => handler(request);
}

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

  group('AppImageUpdateService.shouldReportProgress', () {
    test('always reports the first update', () {
      expect(
        AppImageUpdateService.shouldReportProgress(
          lastReported: null,
          current: 0.001,
          sinceLastReport: Duration.zero,
        ),
        isTrue,
      );
    });

    test('always reports completion, even for a tiny final chunk', () {
      expect(
        AppImageUpdateService.shouldReportProgress(
          lastReported: 0.999,
          current: 1.0,
          sinceLastReport: Duration.zero,
        ),
        isTrue,
      );
    });

    test('suppresses updates that are neither a big enough jump nor enough time', () {
      expect(
        AppImageUpdateService.shouldReportProgress(
          lastReported: 0.50,
          current: 0.505,
          sinceLastReport: const Duration(milliseconds: 10),
        ),
        isFalse,
      );
    });

    test('reports once progress has moved at least 1% since the last report', () {
      expect(
        AppImageUpdateService.shouldReportProgress(
          lastReported: 0.50,
          current: 0.51,
          sinceLastReport: const Duration(milliseconds: 10),
        ),
        isTrue,
      );
    });

    test('reports once enough time has passed even without a 1% jump', () {
      expect(
        AppImageUpdateService.shouldReportProgress(
          lastReported: 0.50,
          current: 0.501,
          sinceLastReport: const Duration(milliseconds: 100),
        ),
        isTrue,
      );
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

    test('sha256 digest of a known file matches the expected published format', () {
      final file = File('${tempDir.path}/fake.AppImage')..writeAsBytesSync([1, 2, 3, 4]);
      final digest = sha256.convert(file.readAsBytesSync()).toString();

      expect(AppImageUpdateService.parseSha256('$digest  fake.AppImage'), digest);
    });

    // The `APPIMAGE` env var can't be set from within a test process, so
    // these use `currentAppImagePathOverride` (the seam added alongside
    // cancellation support) plus a fake http.Client to unit test the real
    // download/verify/cleanup path end to end, closing the gap the previous
    // version of this comment used to note.
    test('downloads, verifies against the checksum, and installs over the current path', () async {
      final bytes = utf8.encode('fake appimage contents');
      final expectedHash = sha256.convert(bytes).toString();
      final client = _FakeClient((request) async {
        if (request.url.toString().endsWith('.sha256')) {
          return http.StreamedResponse(Stream.value(utf8.encode('$expectedHash  app.AppImage')), 200);
        }
        return http.StreamedResponse(Stream.value(bytes), 200, contentLength: bytes.length);
      });
      final currentPath = '${tempDir.path}/app.AppImage';
      final service = AppImageUpdateService(client: client, currentAppImagePathOverride: currentPath);
      final assets = AppImageReleaseAssets(
        appImageUrl: Uri.parse('https://example.com/app.AppImage'),
        checksumUrl: Uri.parse('https://example.com/app.AppImage.sha256'),
      );

      await service.applyUpdate(assets);

      expect(await File(currentPath).readAsBytes(), bytes);
      expect(File('$currentPath.update').existsSync(), isFalse);
    });

    test('deletes the partial download and rethrows on checksum mismatch', () async {
      final client = _FakeClient((request) async {
        if (request.url.toString().endsWith('.sha256')) {
          return http.StreamedResponse(Stream.value(utf8.encode('${'0' * 64}  app.AppImage')), 200);
        }
        return http.StreamedResponse(Stream.value(utf8.encode('wrong contents')), 200, contentLength: 14);
      });
      final currentPath = '${tempDir.path}/app.AppImage';
      final service = AppImageUpdateService(client: client, currentAppImagePathOverride: currentPath);
      final assets = AppImageReleaseAssets(
        appImageUrl: Uri.parse('https://example.com/app.AppImage'),
        checksumUrl: Uri.parse('https://example.com/app.AppImage.sha256'),
      );

      await expectLater(() => service.applyUpdate(assets), throwsA(isA<StateError>()));
      expect(File('$currentPath.update').existsSync(), isFalse);
      expect(File(currentPath).existsSync(), isFalse);
    });

    test('cancelling mid-download throws UpdateCancelledException and deletes the partial file', () async {
      final downloadController = StreamController<List<int>>();
      final client = _FakeClient((request) async {
        if (request.url.toString().endsWith('.sha256')) {
          return http.StreamedResponse(Stream.value(utf8.encode('${'0' * 64}  app.AppImage')), 200);
        }
        return http.StreamedResponse(downloadController.stream, 200, contentLength: 100);
      });
      final currentPath = '${tempDir.path}/app.AppImage';
      final service = AppImageUpdateService(client: client, currentAppImagePathOverride: currentPath);
      final assets = AppImageReleaseAssets(
        appImageUrl: Uri.parse('https://example.com/app.AppImage'),
        checksumUrl: Uri.parse('https://example.com/app.AppImage.sha256'),
      );
      final cancelToken = UpdateCancelToken();

      final future = service.applyUpdate(assets, cancelToken: cancelToken);
      downloadController.add(List.filled(10, 1)); // a chunk arrives before the cancel
      cancelToken.cancel();

      await expectLater(future, throwsA(isA<UpdateCancelledException>()));
      expect(File('$currentPath.update').existsSync(), isFalse);
      expect(File(currentPath).existsSync(), isFalse);

      await downloadController.close();
    });

    test('cancelling before the download starts is honored without ever hitting the network', () async {
      var requestCount = 0;
      final client = _FakeClient((request) async {
        requestCount++;
        throw StateError('should never be called once already cancelled');
      });
      final currentPath = '${tempDir.path}/app.AppImage';
      final service = AppImageUpdateService(client: client, currentAppImagePathOverride: currentPath);
      final assets = AppImageReleaseAssets(
        appImageUrl: Uri.parse('https://example.com/app.AppImage'),
        checksumUrl: Uri.parse('https://example.com/app.AppImage.sha256'),
      );
      final cancelToken = UpdateCancelToken()..cancel();

      await expectLater(
        () => service.applyUpdate(assets, cancelToken: cancelToken),
        throwsA(isA<UpdateCancelledException>()),
      );
      expect(requestCount, 0);
    });
  });

  group('UpdateCancelToken', () {
    test('isCancelled reflects whether cancel has been called', () {
      final token = UpdateCancelToken();
      expect(token.isCancelled, isFalse);
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test('whenCancelled completes once cancel is called', () async {
      final token = UpdateCancelToken();
      var completed = false;
      unawaited(token.whenCancelled.then((_) => completed = true));

      expect(completed, isFalse);
      token.cancel();
      await pumpEventQueue();
      expect(completed, isTrue);
    });

    test('calling cancel twice is a no-op the second time', () {
      final token = UpdateCancelToken();
      token.cancel();
      expect(() => token.cancel(), returnsNormally);
    });
  });
}
