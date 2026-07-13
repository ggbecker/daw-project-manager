import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/tray_service.dart';

void main() {
  group('TrayService.formatLastBackupLabel', () {
    test('formats a fixed timestamp as month, day and 24h time', () {
      final label = TrayService.formatLastBackupLabel(DateTime(2026, 3, 5, 14, 7));
      expect(label, 'Mar 5, 14:07');
    });

    test('pads single-digit minutes', () {
      final label = TrayService.formatLastBackupLabel(DateTime(2026, 1, 1, 9, 2));
      expect(label, 'Jan 1, 09:02');
    });
  });
}
