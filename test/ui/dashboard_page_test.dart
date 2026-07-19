import 'package:flutter_test/flutter_test.dart';
import 'package:trina_grid/trina_grid.dart';

import 'package:daw_project_manager/ui/dashboard_page.dart';

import '../helpers/test_factories.dart';

TrinaRow _flatRow(String id) {
  return TrinaRow(cells: {'data': TrinaCell(value: TestFactories.makeProject(id: id))});
}

TrinaRow _groupHeaderRow(String name, List<TrinaRow> children, {bool expanded = false}) {
  return TrinaRow(
    cells: {
      'name': TrinaCell(value: name),
      // Group header rows never carry a project — smart folders show an
      // empty 'data' cell for the folder itself.
      'data': TrinaCell(value: null),
    },
    type: TrinaRowType.group(
      children: FilteredList(initialList: children),
      expanded: expanded,
    ),
  );
}

void main() {
  group('collectProjectRowIds', () {
    test('collects IDs from flat (ungrouped) rows', () {
      final rows = [_flatRow('p1'), _flatRow('p2')];

      expect(collectProjectRowIds(rows), {'p1', 'p2'});
    });

    test('collects IDs nested inside smart-folder group rows', () {
      // Regression test: smart-folder groups keep their member projects in
      // row.type.group.children, a separate list from the top-level rows.
      // A scan that only looked at top-level rows saw the group's empty
      // header cell and missed every grouped project, which made the
      // refresh-time row/project comparison always report a mismatch —
      // forcing a full row rebuild (collapsing groups, losing the applied
      // sort) on every metadata extraction or scan, even when nothing
      // structurally changed.
      final rows = [
        _flatRow('ungrouped-1'),
        _groupHeaderRow('Mixes', [_flatRow('grouped-1'), _flatRow('grouped-2')]),
      ];

      expect(
        collectProjectRowIds(rows),
        {'ungrouped-1', 'grouped-1', 'grouped-2'},
      );
    });

    test('a collapsed group still contributes its children (collapsing only hides them)', () {
      final children = [_flatRow('grouped-1'), _flatRow('grouped-2')];
      final group = TrinaRow(
        cells: {'name': TrinaCell(value: 'Mixes'), 'data': TrinaCell(value: null)},
        type: TrinaRowType.group(
          children: FilteredList(initialList: children),
          expanded: false,
        ),
      );

      expect(collectProjectRowIds([group]), {'grouped-1', 'grouped-2'});
    });

    test('ignores group header rows themselves (no project attached)', () {
      final rows = [_groupHeaderRow('Empty Folder', [])];

      expect(collectProjectRowIds(rows), isEmpty);
    });
  });

  group('expandedGroupNames / groupRowsToExpand', () {
    // Regression coverage for: switching theme or language collapsed every
    // smart folder. TrinaGrid's key includes locale + theme, so either
    // switch remounts the grid with a brand new TrinaGridStateManager whose
    // groups start collapsed by default. expandedGroupNames() snapshots
    // what was open on the outgoing grid; groupRowsToExpand() then figures
    // out which of the freshly-built (collapsed) rows on the new grid need
    // to be re-expanded to match that snapshot.

    test('expandedGroupNames only reports groups whose expanded flag is true', () {
      final rows = [
        _groupHeaderRow('Mixes', [_flatRow('a')], expanded: true),
        _groupHeaderRow('Stems', [_flatRow('b')], expanded: false),
        _flatRow('ungrouped'),
      ];

      expect(expandedGroupNames(rows), {'Mixes'});
    });

    test('groupRowsToExpand picks out freshly-collapsed rows matching a snapshot name', () {
      // Simulates a remount: the old grid had "Mixes" expanded, the new
      // grid's rows are freshly built and start fully collapsed.
      final freshMixes = _groupHeaderRow('Mixes', [_flatRow('a')], expanded: false);
      final freshStems = _groupHeaderRow('Stems', [_flatRow('b')], expanded: false);
      final freshRows = [freshMixes, freshStems, _flatRow('ungrouped')];

      final toExpand = groupRowsToExpand(freshRows, {'Mixes'});

      expect(toExpand, [freshMixes]);
    });

    test('groupRowsToExpand does not re-select a group that is already expanded', () {
      final alreadyExpanded = _groupHeaderRow('Mixes', [_flatRow('a')], expanded: true);

      expect(groupRowsToExpand([alreadyExpanded], {'Mixes'}), isEmpty);
    });

    test('groupRowsToExpand silently drops snapshot names with no matching row', () {
      // A folder from the snapshot that no longer exists after the rebuild
      // (e.g. its last project was removed) should not error or match
      // anything else.
      final rows = [_groupHeaderRow('Stems', [_flatRow('b')], expanded: false)];

      expect(groupRowsToExpand(rows, {'Mixes (deleted)'}), isEmpty);
    });
  });
}
