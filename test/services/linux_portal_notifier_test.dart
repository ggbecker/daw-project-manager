import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xdg_desktop_portal/xdg_desktop_portal.dart';

import 'package:daw_project_manager/services/linux_portal_notifier.dart';

/// Stands in for the real org.freedesktop.portal.Desktop object exposed by
/// xdg-desktop-portal — records whatever method call it receives so the test
/// can assert on it, instead of needing a real portal (or even a real Linux
/// session) to run.
class _FakeNotificationPortal extends DBusObject {
  _FakeNotificationPortal() : super(DBusObjectPath('/org/freedesktop/portal/desktop'));

  DBusMethodCall? lastCall;

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    lastCall = methodCall;
    return DBusMethodSuccessResponse();
  }
}

void main() {
  // Needs a real Unix domain socket for the private test bus — reliable on
  // Linux (where this code actually runs in production, and where CI's
  // unit_tests job runs `flutter test`), but hangs rather than failing fast
  // on this project's Windows dev machines. Skipping there keeps local runs
  // from hanging while still getting real coverage where it matters.
  if (!Platform.isLinux) {
    test('sendNotification (skipped outside Linux — see comment above)', () {}, skip: true);
    return;
  }

  late DBusServer server;
  late DBusClient serverClient;
  late DBusClient callerBus;
  late XdgDesktopPortalClient portalClient;
  late _FakeNotificationPortal portal;

  setUp(() async {
    server = DBusServer();
    final address = await server.listenAddress(DBusAddress.unix(dir: Directory.systemTemp));
    serverClient = DBusClient(address);
    portal = _FakeNotificationPortal();
    await serverClient.registerObject(portal);
    await serverClient.requestName('org.freedesktop.portal.Desktop');
    callerBus = DBusClient(address);
    portalClient = XdgDesktopPortalClient(bus: callerBus);
  });

  tearDown(() async {
    await portalClient.close();
    await serverClient.close();
    await server.close();
  });

  test('calls AddNotification on org.freedesktop.portal.Notification with title/body/priority', () async {
    await LinuxPortalNotifier.sendNotification(
      portalClient,
      title: 'Mix ready',
      body: '3 days left for "Song Alpha"',
    );

    final call = portal.lastCall;
    expect(call, isNotNull);
    expect(call!.interface, 'org.freedesktop.portal.Notification');
    expect(call.name, 'AddNotification');
    expect(call.values, hasLength(2));
    expect(call.values[0], isA<DBusString>());

    final params = call.values[1] as DBusDict;
    final map = {
      for (final entry in params.children.entries)
        (entry.key as DBusString).value: (entry.value as DBusVariant).value,
    };
    expect((map['title'] as DBusString).value, 'Mix ready');
    expect((map['body'] as DBusString).value, '3 days left for "Song Alpha"');
    expect((map['priority'] as DBusString).value, 'normal');
  });

  test('each call uses a distinct notification id', () async {
    await LinuxPortalNotifier.sendNotification(portalClient, title: 'First', body: 'a');
    final firstId = (portal.lastCall!.values[0] as DBusString).value;

    await LinuxPortalNotifier.sendNotification(portalClient, title: 'Second', body: 'b');
    final secondId = (portal.lastCall!.values[0] as DBusString).value;

    expect(firstId, isNot(equals(secondId)));
  });
}
