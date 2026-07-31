import 'package:flutter/foundation.dart';
import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

/// Shows desktop notifications on Linux via the xdg-desktop-portal
/// (org.freedesktop.portal.Notification, through Canonical's
/// package:xdg_desktop_portal) instead of flutter_local_notifications,
/// whose Linux backend talks to org.freedesktop.Notifications directly —
/// bypassing the portal, which is why the Flatpak manifest used to need a
/// --talk-name permission for it (see flatpak/README.md). Calls to the
/// portal need no special Flatpak permission; portals are reachable
/// regardless of sandboxing by design.
///
/// Deliberately minimal: this app's only desktop notification uses are
/// plain title+body alerts (work-session reminders, a one-off "still
/// running in the tray" notice) — no actions, no tap-to-open payload, no
/// scheduling — so addNotification's simplest form is all that's needed.
/// If a future feature needs more (icons, action buttons), extend this
/// rather than falling back to flutter_local_notifications_linux for it.
class LinuxPortalNotifier {
  LinuxPortalNotifier._();

  static Future<void> show({required String title, required String body}) async {
    final client = XdgDesktopPortalClient();
    try {
      await sendNotification(client, title: title, body: body);
    } catch (e) {
      if (kDebugMode) print('[LinuxPortalNotifier] Failed to show notification: $e');
    } finally {
      await client.close();
    }
  }

  /// The actual portal call, split out from [show] so a test can point the
  /// client at a private test bus instead of the real session bus.
  @visibleForTesting
  static Future<void> sendNotification(
    XdgDesktopPortalClient client, {
    required String title,
    required String body,
  }) {
    return client.notification.addNotification(
      // Per-notification id — the portal doesn't need this to match
      // anything else since we never update/withdraw a notification by id
      // (each call is a new, independent one-off alert).
      'dpm-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      priority: XdgNotificationPriority.normal,
    );
  }
}
