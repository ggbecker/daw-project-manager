import 'dart:io';
import 'package:flutter/services.dart';
import '../models/music_project.dart';

/// Pushes the five most-recently-modified projects to the macOS Dock menu.
/// No-op on every other platform.
class DockMenuService {
  DockMenuService._();

  static const _channel = MethodChannel('com.bandpassrecords.dpm/dock_menu');

  static Future<void> updateRecentProjects(List<MusicProject> allProjects) async {
    if (!Platform.isMacOS) return;

    final recent = (allProjects.toList()
          ..sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt)))
        .take(5)
        .map((p) => {'name': p.displayName, 'path': p.filePath})
        .toList();

    try {
      await _channel.invokeMethod('setRecentProjects', recent);
    } on MissingPluginException {
      // channel not registered yet (e.g. during tests)
    }
  }
}
