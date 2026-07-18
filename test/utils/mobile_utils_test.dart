import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/utils/mobile_utils.dart';

/// Locks in the exact contract several call sites now rely on directly
/// (e.g. app_paths.dart, main.dart, profile_repository.dart) instead of
/// re-deriving `Platform.isAndroid || Platform.isIOS` themselves — a drift
/// this project's CLAUDE.md explicitly warns against.
void main() {
  group('MobileUtils.isMobile', () {
    test('is exactly Android or iOS', () {
      expect(MobileUtils.isMobile(), Platform.isAndroid || Platform.isIOS);
    });

    test('is false wherever isDesktop is true (mutually exclusive)', () {
      if (MobileUtils.isDesktop()) {
        expect(MobileUtils.isMobile(), isFalse);
      }
    });
  });
}
