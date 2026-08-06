import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Thrown by [AppImageUpdateService.applyUpdate] when [UpdateCancelToken.cancel]
/// was called mid-update. Callers should treat this as "the user backed out",
/// not as a failure — the partially downloaded file has already been cleaned
/// up by the time this is thrown.
class UpdateCancelledException implements Exception {
  const UpdateCancelledException();

  @override
  String toString() => 'Update cancelled.';
}

/// Lets a caller ask an in-progress [AppImageUpdateService.applyUpdate] to
/// stop. One token is good for one update attempt — create a fresh one per
/// [AppImageUpdateService.applyUpdate] call.
class UpdateCancelToken {
  final Completer<void> _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;

  /// Future that completes the moment [cancel] is called. `applyUpdate`
  /// races this against the network stream so a cancel takes effect
  /// immediately instead of waiting for the current chunk/step to finish.
  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

/// GitHub repo to fetch release assets from. Kept as its own private consts
/// (rather than importing UpdateCheckService's) to match this codebase's
/// existing convention of redeclaring these per-file — see APP_VERSION in
/// main.dart, update_check_service.dart and update_available_dialog.dart.
const String _kGithubOwner = String.fromEnvironment('GITHUB_OWNER', defaultValue: 'bandpassrecords');
const String _kGithubRepo  = String.fromEnvironment('GITHUB_REPO',  defaultValue: 'daw-project-manager');

/// The AppImage asset and its checksum asset for a given release, as
/// published by .github/workflows/release.yml (`DAW_Project_Manager_Linux_
/// vX.Y.Z.AppImage` + a sibling `.sha256` file containing "hex digest, two
/// spaces, filename").
class AppImageReleaseAssets {
  final Uri appImageUrl;
  final Uri checksumUrl;
  final int? appImageSizeBytes;

  const AppImageReleaseAssets({
    required this.appImageUrl,
    required this.checksumUrl,
    this.appImageSizeBytes,
  });
}

/// Self-update support for the Linux AppImage build: finds the AppImage
/// asset on a GitHub release, downloads it, verifies it against the
/// published sha256 checksum, and replaces the running AppImage file in
/// place — the same mechanism electron-updater uses under the hood for
/// AppImage targets (there is no separate Flutter package for this; see
/// the auto_updater/desktop_updater survey that motivated writing this).
///
/// Only meaningful when [isRunningAsAppImage] is true. Flatpak and plain
/// tarball Linux builds never set the `APPIMAGE` env var, so this stays
/// inert for them — they keep the existing update story (`flatpak update`,
/// manual re-download) untouched.
class AppImageUpdateService {
  final http.Client _client;

  /// Overrides [currentAppImagePath] for this instance only — the `APPIMAGE`
  /// env var can't be set from within a test process, so this is the seam
  /// tests use to point [applyUpdate] at a throwaway file instead. Always
  /// null in production, where the env var is the only source of truth.
  final String? _currentAppImagePathOverride;

  AppImageUpdateService({http.Client? client, String? currentAppImagePathOverride})
      : _client = client ?? http.Client(),
        _currentAppImagePathOverride = currentAppImagePathOverride;

  /// Absolute path of the currently running AppImage file, from the
  /// `APPIMAGE` env var that appimagetool-built AppImages set at launch.
  /// Null when not running as an AppImage at all.
  static String? get currentAppImagePath => Platform.environment['APPIMAGE'];

  static bool get isRunningAsAppImage => currentAppImagePath != null;

  void close() => _client.close();

  /// Fetches the release tagged `v$version` and picks out its AppImage +
  /// checksum assets. Returns null if the release, the AppImage asset, or
  /// the checksum asset can't be found.
  Future<AppImageReleaseAssets?> fetchReleaseAssets(String version) async {
    if (_kGithubOwner.isEmpty || _kGithubRepo.isEmpty) return null;
    final uri = Uri.parse(
      'https://api.github.com/repos/$_kGithubOwner/$_kGithubRepo/releases/tags/v$version',
    );
    final response = await _client
        .get(uri, headers: {'Accept': 'application/vnd.github+json'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final assets = (json['assets'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return assetsFrom(assets);
  }

  /// Pure asset-picking logic, split out from [fetchReleaseAssets] so it's
  /// testable without a network call. [assets] is the GitHub API's raw
  /// `assets` array (each with `name` and `browser_download_url`).
  static AppImageReleaseAssets? assetsFrom(List<Map<String, dynamic>> assets) {
    final appImage = pickAsset(assets, (name) => name.toLowerCase().endsWith('.appimage'));
    if (appImage == null) return null;
    final checksum = pickAsset(assets, (name) => name == '${appImage['name']}.sha256');
    if (checksum == null) return null;
    return AppImageReleaseAssets(
      appImageUrl: Uri.parse(appImage['browser_download_url'] as String),
      checksumUrl: Uri.parse(checksum['browser_download_url'] as String),
      appImageSizeBytes: appImage['size'] as int?,
    );
  }

  static Map<String, dynamic>? pickAsset(
    List<Map<String, dynamic>> assets,
    bool Function(String name) test,
  ) {
    for (final asset in assets) {
      final name = asset['name'] as String?;
      if (name != null && test(name)) return asset;
    }
    return null;
  }

  /// Parses a `sha256sum`-style checksum file (`<hex>  <filename>`, as
  /// produced by the "Generate AppImage SHA256 checksum" CI step) and
  /// returns the hex digest. Returns null if the line can't be parsed.
  static String? parseSha256(String checksumFileContents) {
    final match = RegExp(r'^([0-9a-fA-F]{64})\s+\S+').firstMatch(checksumFileContents.trim());
    return match?.group(1)?.toLowerCase();
  }

  /// Decides whether a progress update should actually be delivered to
  /// [onProgress], given how much progress has been made and how long it's
  /// been since the last delivered update. [applyUpdate] calls this once
  /// per network chunk — there can be thousands of those for a ~100MB
  /// AppImage — and callers like [AppImageSelfUpdateDialog] rebuild UI on
  /// every delivered update, so delivering on every single chunk would
  /// stall the stream's read loop behind UI work on the same isolate.
  /// [lastReported] is null before the first update has been delivered.
  static bool shouldReportProgress({
    required double? lastReported,
    required double current,
    required Duration sinceLastReport,
  }) {
    if (lastReported == null || current >= 1.0) return true;
    return current - lastReported >= 0.01 || sinceLastReport >= const Duration(milliseconds: 100);
  }

  /// Downloads, verifies, and installs [assets] over the currently running
  /// AppImage. Reports progress in `[0, 1]` via [onProgress] (null total
  /// size reports null, meaning "indeterminate"), throttled via
  /// [shouldReportProgress] so large downloads don't fire a UI update per
  /// network chunk.
  ///
  /// If [cancelToken] is cancelled at any point, the in-flight download is
  /// interrupted and this throws [UpdateCancelledException]. On *any*
  /// failure — cancellation, a network error, a checksum mismatch, whatever
  /// — the partially-downloaded `.update` file is deleted before the error
  /// propagates, so a failed or cancelled attempt never leaves stray files
  /// next to the running AppImage. The original AppImage itself is only
  /// ever touched by the final rename, once the download is verified.
  Future<void> applyUpdate(
    AppImageReleaseAssets assets, {
    void Function(double? progress)? onProgress,
    UpdateCancelToken? cancelToken,
  }) async {
    final currentPath = _currentAppImagePathOverride ?? currentAppImagePath;
    if (currentPath == null) {
      throw StateError('Not running as an AppImage.');
    }

    // Downloaded into the same directory as the running AppImage (not a
    // system temp dir) so the final replace below is a same-filesystem
    // rename — a cross-device rename (e.g. tmpfs -> home partition) would
    // fail outright instead of atomically swapping the file.
    final downloadPath = '$currentPath.update';
    final downloadFile = File(downloadPath);

    try {
      if (cancelToken?.isCancelled ?? false) throw const UpdateCancelledException();

      final checksumResponse = await _client.get(assets.checksumUrl).timeout(const Duration(seconds: 15));
      if (checksumResponse.statusCode != 200) {
        throw StateError('Failed to download checksum (HTTP ${checksumResponse.statusCode}).');
      }
      final expectedHash = parseSha256(checksumResponse.body);
      if (expectedHash == null) {
        throw StateError('Could not parse checksum file.');
      }

      await _downloadToFile(
        assets.appImageUrl,
        downloadFile,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
      if (cancelToken?.isCancelled ?? false) throw const UpdateCancelledException();

      final actualHash = sha256.convert(await downloadFile.readAsBytes()).toString();
      if (actualHash != expectedHash) {
        throw StateError('Checksum mismatch: downloaded update did not match published sha256.');
      }

      if (Platform.isLinux) {
        final chmod = await Process.run('chmod', ['+x', downloadPath]);
        if (chmod.exitCode != 0) {
          throw StateError('Failed to make the downloaded update executable: ${chmod.stderr}');
        }
      }

      await downloadFile.rename(currentPath);
    } catch (_) {
      if (await downloadFile.exists()) await downloadFile.delete();
      rethrow;
    }
  }

  /// Streams [url] into [destination], throttling [onProgress] via
  /// [shouldReportProgress]. Uses `stream.listen` rather than `await for` so
  /// [cancelToken] can interrupt the subscription immediately instead of
  /// waiting for the next chunk to arrive.
  Future<void> _downloadToFile(
    Uri url,
    File destination, {
    void Function(double? progress)? onProgress,
    UpdateCancelToken? cancelToken,
  }) async {
    final sink = destination.openWrite();
    try {
      final request = http.Request('GET', url);
      final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 30));
      if (streamedResponse.statusCode != 200) {
        throw StateError('Failed to download update (HTTP ${streamedResponse.statusCode}).');
      }
      final total = streamedResponse.contentLength;
      var received = 0;
      onProgress?.call(total == null ? null : 0);
      double? lastReported = total == null ? null : 0;
      final stopwatch = Stopwatch()..start();

      final completer = Completer<void>();
      late final StreamSubscription<List<int>> subscription;
      subscription = streamedResponse.stream.listen(
        (chunk) {
          sink.add(chunk);
          received += chunk.length;
          if (total != null && total > 0) {
            final progress = received / total;
            if (shouldReportProgress(
              lastReported: lastReported,
              current: progress,
              sinceLastReport: stopwatch.elapsed,
            )) {
              onProgress?.call(progress);
              lastReported = progress;
              stopwatch.reset();
            }
          }
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!completer.isCompleted) completer.completeError(error, stackTrace);
        },
        cancelOnError: true,
      );

      unawaited(cancelToken?.whenCancelled.then((_) {
        subscription.cancel();
        if (!completer.isCompleted) completer.completeError(const UpdateCancelledException());
      }));

      await completer.future;
    } finally {
      await sink.close();
    }
  }

  /// Launches the (now-updated) AppImage as a new detached process. Callers
  /// are expected to exit the current process right after this returns.
  Future<void> relaunch() async {
    final path = currentAppImagePath;
    if (path == null) {
      throw StateError('Not running as an AppImage.');
    }
    await Process.start(path, const [], mode: ProcessStartMode.detached);
  }
}
