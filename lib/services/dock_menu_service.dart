import 'dart:io';
import 'package:flutter/services.dart';
import '../models/music_project.dart';

/// Pushes the five most-recently-modified projects to the macOS Dock menu /
/// Windows taskbar jump list. No-op on every other platform.
class DockMenuService {
  DockMenuService._();

  static const _channel = MethodChannel('com.bandpassrecords.dpm/dock_menu');

  static Future<void> updateRecentProjects(List<MusicProject> allProjects) async {
    if (!Platform.isMacOS && !Platform.isWindows) return;

    final recent = (allProjects.toList()
          ..sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt)))
        .take(5)
        .map((p) => {'id': p.id, 'name': p.displayName})
        .toList();

    try {
      await _channel.invokeMethod('setRecentProjects', recent);
    } on MissingPluginException {
      // channel not registered yet (e.g. during tests)
    }
  }

  /// Registers the handler for "openProject" calls arriving *from* native
  /// code — used on macOS, where the Dock menu lives in-process and invokes
  /// straight back into Dart (Windows instead relaunches the exe with a
  /// command-line argument, handled entirely in main.dart).
  static void setOpenProjectHandler(Future<void> Function(String id) onOpenProject) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openProject') {
        final id = (call.arguments as Map?)?['id'] as String?;
        if (id != null) await onOpenProject(id);
      }
    });
  }
}
