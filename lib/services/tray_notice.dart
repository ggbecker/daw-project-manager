import 'package:hive_ce/hive.dart';

import '../utils/app_paths.dart';

/// Tracks whether the one-time "app is still running in the tray" notice has
/// been shown. Closing to tray is silent by design after the first time, but
/// on the very first hide users tend to assume the app quit — so we get one
/// chance to explain, ever.
class TrayNotice {
  TrayNotice._();

  static const _key = 'trayNoticeShown';

  /// Returns true exactly once per install: the first call marks the notice
  /// as shown and returns true; every later call (including after restarts)
  /// returns false. On storage errors returns false — failing to persist the
  /// flag must not cause the notice to nag on every hide.
  ///
  /// [box] is a test seam; production callers use the default 'settings' box.
  static Future<bool> claimFirstHide({Box<String>? box}) async {
    try {
      final b = box ?? await _openSettingsBox();
      if (b.get(_key) != null) return false;
      await b.put(_key, 'true');
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Box<String>> _openSettingsBox() async {
    await ensureHiveInitialized();
    return Hive.openBox<String>('settings');
  }
}
