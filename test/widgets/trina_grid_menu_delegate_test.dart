import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trina_grid/trina_grid.dart';

import 'package:daw_project_manager/ui/widgets/trina_grid_menu_delegate.dart';

void main() {
  const delegate = FitAllColumnsMenuDelegate();

  List<TrinaColumn> columns() => [
    TrinaColumn(title: 'Name', field: 'name', type: TrinaColumnType.text()),
    TrinaColumn(title: 'BPM', field: 'bpm', type: TrinaColumnType.text()),
  ];

  List<TrinaRow> rows() => [
    TrinaRow(
      cells: {'name': TrinaCell(value: 'Track 1'), 'bpm': TrinaCell(value: '120')},
    ),
  ];

  Future<TrinaGridStateManager> pumpGrid(WidgetTester tester) async {
    late TrinaGridStateManager stateManager;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: TrinaGrid(
              columns: columns(),
              rows: rows(),
              columnMenuDelegate: delegate,
              onLoaded: (event) => stateManager = event.stateManager,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return stateManager;
  }

  testWidgets(
    'buildMenuItems appends a fit-all entry after the library defaults',
    (tester) async {
      final stateManager = await pumpGrid(tester);
      final defaultItems = const TrinaColumnMenuDelegateDefault().buildMenuItems(
        stateManager: stateManager,
        column: stateManager.columns.first,
      );

      final items = delegate.buildMenuItems(
        stateManager: stateManager,
        column: stateManager.columns.first,
      );

      // Every library-default entry is preserved, plus a divider and one
      // extra PopupMenuItem<String> carrying the 'fitAll' value.
      expect(items.length, defaultItems.length + 2);
      expect(items[defaultItems.length], isA<PopupMenuDivider>());
      final fitAllItem = items.last as PopupMenuItem<String>;
      expect(fitAllItem.value, 'fitAll');
    },
  );

  testWidgets(
    'onSelected with the fitAll value resizes every column to fit its content',
    (tester) async {
      final stateManager = await pumpGrid(tester);
      final nameColumn = stateManager.columns.firstWhere(
        (c) => c.field == 'name',
      );

      // Shrink the column first so autoFitColumn has something to correct —
      // otherwise a no-op resize could pass even if onSelected never invoked
      // autoFitColumn on it at all.
      stateManager.resizeColumn(nameColumn, -300);
      await tester.pumpAndSettle();
      final shrunkWidth = nameColumn.width;

      delegate.onSelected(
        context: tester.element(find.byType(TrinaGrid)),
        stateManager: stateManager,
        column: nameColumn,
        mounted: true,
        selected: 'fitAll',
      );
      await tester.pumpAndSettle();

      expect(nameColumn.width, isNot(shrunkWidth));
    },
  );

  testWidgets(
    'onSelected with an unrelated value delegates to the library default '
    'instead of resizing columns',
    (tester) async {
      final stateManager = await pumpGrid(tester);
      final nameColumn = stateManager.columns.firstWhere(
        (c) => c.field == 'name',
      );
      stateManager.resizeColumn(nameColumn, -300);
      await tester.pumpAndSettle();
      final shrunkWidth = nameColumn.width;

      delegate.onSelected(
        context: tester.element(find.byType(TrinaGrid)),
        stateManager: stateManager,
        column: nameColumn,
        mounted: true,
        selected: 'not-a-recognized-value',
      );
      await tester.pumpAndSettle();

      expect(nameColumn.width, shrunkWidth);
    },
  );
}
