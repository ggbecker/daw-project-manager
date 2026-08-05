import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

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

  AppImageUpdateService({http.Client? client}) : _client = client ?? http.Client();

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

  /// Downloads, verifies, and installs [assets] over the currently running
  /// AppImage. Reports progress in `[0, 1]` via [onProgress] (null total
  /// size reports null, meaning "indeterminate"). Throws on any failure —
  /// the original AppImage is left untouched until the new one is verified.
  Future<void> applyUpdate(
    AppImageReleaseAssets assets, {
    void Function(double? progress)? onProgress,
  }) async {
    final currentPath = currentAppImagePath;
    if (currentPath == null) {
      throw StateError('Not running as an AppImage.');
    }

    final checksumResponse = await _client.get(assets.checksumUrl).timeout(const Duration(seconds: 15));
    if (checksumResponse.statusCode != 200) {
      throw StateError('Failed to download checksum (HTTP ${checksumResponse.statusCode}).');
    }
    final expectedHash = parseSha256(checksumResponse.body);
    if (expectedHash == null) {
      throw StateError('Could not parse checksum file.');
    }

    // Downloaded into the same directory as the running AppImage (not a
    // system temp dir) so the final replace below is a same-filesystem
    // rename — a cross-device rename (e.g. tmpfs -> home partition) would
    // fail outright instead of atomically swapping the file.
    final downloadPath = '$currentPath.update';
    final downloadFile = File(downloadPath);
    final sink = downloadFile.openWrite();

    try {
      final request = http.Request('GET', assets.appImageUrl);
      final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 30));
      if (streamedResponse.statusCode != 200) {
        throw StateError('Failed to download update (HTTP ${streamedResponse.statusCode}).');
      }
      final total = streamedResponse.contentLength;
      var received = 0;
      onProgress?.call(total == null ? null : 0);
      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total != null && total > 0) onProgress?.call(received / total);
      }
    } finally {
      await sink.close();
    }

    final actualHash = sha256.convert(await downloadFile.readAsBytes()).toString();
    if (actualHash != expectedHash) {
      await downloadFile.delete();
      throw StateError('Checksum mismatch: downloaded update did not match published sha256.');
    }

    if (Platform.isLinux) {
      final chmod = await Process.run('chmod', ['+x', downloadPath]);
      if (chmod.exitCode != 0) {
        await downloadFile.delete();
        throw StateError('Failed to make the downloaded update executable: ${chmod.stderr}');
      }
    }

    await downloadFile.rename(currentPath);
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
