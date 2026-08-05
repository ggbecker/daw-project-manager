import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/appimage_update_service.dart';
import 'package:daw_project_manager/services/update_check_service.dart';

void main() {
  group('UpdateCheckService.isSupported', () {
    // The GitHub-releases update check is redundant under Flatpak (Flathub
    // already owns update delivery) and its dialog links out to a GitHub
    // release page, which isn't even the right flow for a Flatpak user — so
    // it's switched off on Linux, the same way Drive sync is (see
    // GoogleDriveSyncService.isSupported) — EXCEPT when running as the
    // AppImage build, which self-updates instead of linking out (see
    // AppImageUpdateService). The unit_tests CI job runs on ubuntu-latest,
    // not inside an AppImage, so AppImageUpdateService.isRunningAsAppImage
    // is false there and this still exercises the isFalse branch for real.
    test('is false on Linux unless running as an AppImage', () {
      final expected = Platform.isLinux && !AppImageUpdateService.isRunningAsAppImage
          ? isFalse
          : isTrue;
      expect(UpdateCheckService.isSupported, expected);
    });
  });
}
