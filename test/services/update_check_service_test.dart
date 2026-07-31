import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/update_check_service.dart';

void main() {
  group('UpdateCheckService.isSupported', () {
    // The GitHub-releases update check is redundant under Flatpak (Flathub
    // already owns update delivery) and its dialog links out to a GitHub
    // release page, which isn't even the right flow for a Flatpak user — so
    // it's switched off on Linux entirely, the same way Drive sync is (see
    // GoogleDriveSyncService.isSupported). Asserted relative to
    // Platform.isLinux rather than a fixed expectation, so this actually
    // exercises the isFalse branch for real on the unit_tests CI job
    // (ubuntu-latest), not just on a Windows/macOS dev machine.
    test('is false only on Linux', () {
      expect(UpdateCheckService.isSupported, Platform.isLinux ? isFalse : isTrue);
    });
  });
}
