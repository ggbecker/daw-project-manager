import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// GitHub repo to check for releases. Set via --dart-define at build time.
const String _kGithubOwner = String.fromEnvironment('GITHUB_OWNER', defaultValue: 'bandpassrecords');
const String _kGithubRepo  = String.fromEnvironment('GITHUB_REPO',  defaultValue: 'daw-project-manager');

class UpdateCheckService {
  /// False on Linux — this pings the GitHub releases API and, if newer,
  /// links out to the release page to download an installer, which is the
  /// wrong pattern under Flatpak: Flathub already owns update delivery
  /// (`flatpak update`, the software center), and a GitHub release page
  /// isn't even the right place to send a Flatpak user. Every UI entry
  /// point (startup check, Settings, onboarding toggle) is gated on this,
  /// which is also what lets the Flatpak manifest drop --share=network
  /// entirely — see flatpak/README.md.
  static bool get isSupported => !Platform.isLinux;

  /// Returns the latest tag name (e.g. "v1.2.3") if it is strictly newer than
  /// [currentVersion], or null if the app is up-to-date or the check fails.
  static Future<String?> checkForUpdate(String currentVersion) async {
    if (_kGithubOwner.isEmpty || _kGithubRepo.isEmpty) return null;
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$_kGithubOwner/$_kGithubRepo/releases/latest',
      );
      final response = await http.get(uri, headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String?)?.replaceAll(RegExp(r'^v'), '') ?? '';
      if (tag.isEmpty) return null;
      if (_isNewer(tag, currentVersion)) return tag;
      return null;
    } catch (e) {
      if (kDebugMode) print('[UpdateCheck] error: $e');
      return null;
    }
  }

  /// Returns true if [remote] semver is strictly greater than [local].
  static bool _isNewer(String remote, String local) {
    final r = _parse(remote);
    final l = _parse(local);
    for (int i = 0; i < 3; i++) {
      if (r[i] > l[i]) return true;
      if (r[i] < l[i]) return false;
    }
    return false;
  }

  static List<int> _parse(String v) {
    final parts = v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    while (parts.length < 3) { parts.add(0); }
    return parts;
  }
}
