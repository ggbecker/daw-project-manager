import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/project_templates_page.dart';

void main() {
  group('compareTemplateModifiedCellValues', () {
    // Same regression this guards against as the main dashboard table's
    // compareLastModifiedCellValues: the cell must carry a raw DateTime (not
    // the formatted display string) so sort is chronological, not alphabetical.

    test('orders chronologically even when alphabetical month order disagrees', () {
      final july = DateTime(2026, 7, 1);
      final january = DateTime(2027, 1, 1); // later date, "smaller" month name

      expect(compareTemplateModifiedCellValues(july, january), lessThan(0));
      expect(compareTemplateModifiedCellValues(january, july), greaterThan(0));
    });

    test('treats equal DateTimes as equal', () {
      final date = DateTime(2026, 7, 21, 20, 0);

      expect(compareTemplateModifiedCellValues(date, DateTime(2026, 7, 21, 20, 0)), 0);
    });

    test('orders within the same day by time of day', () {
      final morning = DateTime(2026, 7, 21, 9, 0);
      final evening = DateTime(2026, 7, 21, 20, 0);

      expect(compareTemplateModifiedCellValues(morning, evening), lessThan(0));
    });

    test('treats two missing-file (null) values as equal', () {
      expect(compareTemplateModifiedCellValues(null, null), 0);
    });

    test('sorts a missing-file (null) value before a dated one', () {
      final date = DateTime(2026, 7, 21);

      expect(compareTemplateModifiedCellValues(null, date), lessThan(0));
      expect(compareTemplateModifiedCellValues(date, null), greaterThan(0));
    });
  });
}
