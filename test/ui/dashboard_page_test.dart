import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trina_grid/trina_grid.dart';

import 'package:daw_project_manager/ui/dashboard_page.dart';

import '../helpers/test_factories.dart';

TrinaRow _flatRow(String id) {
  return TrinaRow(cells: {'data': TrinaCell(value: TestFactories.makeProject(id: id))});
}

TrinaRow _namedFlatRow(String name) {
  return TrinaRow(cells: {'name': TrinaCell(value: name)});
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

  group('applySortSnapshot', () {
    // Regression coverage for: rapidly switching theme showed a one-frame
    // flash of the default (unsorted) row order before the applied sort
    // snapped back in. TrinaGrid only calls onLoaded (and hence any state-
    // manager-level sort restore) after its first frame has painted, so the
    // fix is to hand the freshly-built grid rows that are *already* sorted,
    // via applySortSnapshot(), rather than sorting them after the fact.

    test('sorts ascending by string comparison of the target field', () {
      final rows = [_namedFlatRow('Charlie'), _namedFlatRow('Alpha'), _namedFlatRow('Bravo')];

      applySortSnapshot(rows, 'name', TrinaColumnSort.ascending);

      expect(rows.map((r) => r.cells['name']!.value), ['Alpha', 'Bravo', 'Charlie']);
    });

    test('sorts descending by string comparison of the target field', () {
      final rows = [_namedFlatRow('Charlie'), _namedFlatRow('Alpha'), _namedFlatRow('Bravo')];

      applySortSnapshot(rows, 'name', TrinaColumnSort.descending);

      expect(rows.map((r) => r.cells['name']!.value), ['Charlie', 'Bravo', 'Alpha']);
    });

    test('is a no-op when direction is none', () {
      final rows = [_namedFlatRow('Charlie'), _namedFlatRow('Alpha'), _namedFlatRow('Bravo')];

      applySortSnapshot(rows, 'name', TrinaColumnSort.none);

      expect(rows.map((r) => r.cells['name']!.value), ['Charlie', 'Alpha', 'Bravo']);
    });

    test('also sorts each group row\'s children, independent of top-level order', () {
      final group = _groupHeaderRow(
        'Mixes',
        [_namedFlatRow('Charlie'), _namedFlatRow('Alpha')],
        expanded: true,
      );
      final rows = [_namedFlatRow('Zeta'), group];

      applySortSnapshot(rows, 'name', TrinaColumnSort.ascending);

      // Top level compares group headers/flat rows by their own 'name' cell:
      // "Mixes" sorts before "Zeta".
      expect(rows.map((r) => r.cells['name']!.value), ['Mixes', 'Zeta']);
      expect(
        group.type.group.children.originalList.map((r) => r.cells['name']!.value),
        ['Alpha', 'Charlie'],
      );
    });
  });

  group('table-state restore orchestration (theme/locale remount)', () {
    // Regression test for a real bug: restoring expand state by calling
    // stateManager.toggleExpandedRowGroup() without notify:false fires
    // notifyListeners() synchronously, mid-restore. Any listener already
    // attached at that point (as _onStateManagerChanged is, by production
    // code, before restore runs) sees a grid that's had its groups
    // re-expanded but NOT yet had its sort reapplied — so a listener that
    // re-snapshots "current sort" on every change captures a false "no sort"
    // reading and clobbers the very value the restore is about to read a few
    // lines later. Net effect: sort restoration silently no-ops on every
    // theme/locale switch that also needs to re-expand a group.
    List<TrinaColumn> columns() => [
          TrinaColumn(title: 'Name', field: 'name', type: TrinaColumnType.text()),
        ];

    TrinaRow flat(String name) => TrinaRow(cells: {'name': TrinaCell(value: name)});

    TrinaRow group(String name, List<TrinaRow> children, {bool expanded = false}) {
      return TrinaRow(
        cells: {'name': TrinaCell(value: name)},
        type: TrinaRowType.group(
          children: FilteredList(initialList: children),
          expanded: expanded,
        ),
      );
    }

    Widget buildGrid(
      Key key,
      List<TrinaRow> rows,
      void Function(TrinaGridStateManager) onLoaded,
    ) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: TrinaGrid(
              key: key,
              columns: columns(),
              rows: rows,
              onLoaded: (e) {
                e.stateManager.setRowGroup(TrinaRowGroupTreeDelegate(
                  resolveColumnDepth: (c) => null,
                  showText: (c) => true,
                  showFirstExpandableIcon: false,
                  showCount: false,
                ));
                onLoaded(e.stateManager);
              },
            ),
          ),
        ),
      );
    }

    testWidgets(
        'expand-state restore must not clobber a not-yet-reapplied sort snapshot',
        (tester) async {
      Set<String> lastKnownExpanded = {};
      String? lastKnownSortField;
      TrinaColumnSort? lastKnownSortDirection;

      // Mirrors _captureTableStateSnapshot(): called from a listener attached
      // to the live stateManager, exactly like _onStateManagerChanged.
      void captureSnapshot(TrinaGridStateManager sm) {
        lastKnownExpanded = expandedGroupNames(sm.rows);
        final sortedColumn = sm.getSortedColumn;
        lastKnownSortField = sortedColumn?.field;
        lastKnownSortDirection = sortedColumn?.sort;
      }

      // Mirrors _restoreTableStateSnapshot() as it exists in production:
      // notify:false on every mutation, single trailing notifyListeners().
      void restoreSnapshot(TrinaGridStateManager sm) {
        for (final row in groupRowsToExpand(sm.rows, lastKnownExpanded)) {
          sm.toggleExpandedRowGroup(rowGroup: row, notify: false);
        }
        final sortField = lastKnownSortField;
        final sortMode = lastKnownSortDirection;
        if (sortField != null && sortMode != null) {
          for (final column in sm.columns) {
            if (column.field != sortField) continue;
            if (sortMode.isAscending) {
              sm.sortAscending(column, notify: false);
            } else if (sortMode.isDescending) {
              sm.sortDescending(column, notify: false);
            }
            break;
          }
        }
        sm.notifyListeners();
      }

      // Grid 1: user sorts by name and has "Mixes" expanded; a listener
      // continuously snapshots state exactly as production does.
      late TrinaGridStateManager sm1;
      final rows1 = [
        flat('Zeta'),
        group('Mixes', [flat('Charlie'), flat('Alpha')], expanded: true),
      ];
      await tester.pumpWidget(buildGrid(const ValueKey('g1'), rows1, (m) {
        sm1 = m;
        m.addListener(() => captureSnapshot(m));
      }));
      await tester.pumpAndSettle();

      sm1.toggleSortColumn(sm1.columns.first);
      await tester.pumpAndSettle();
      expect(lastKnownSortField, 'name');
      expect(lastKnownExpanded, {'Mixes'});

      // Grid 2: simulates the remount a theme/locale switch causes — a brand
      // new grid, freshly built, groups collapsed by default, restore runs
      // with a listener already attached (as it is in onLoaded).
      late TrinaGridStateManager sm2;
      final rows2 = [
        flat('Zeta'),
        group('Mixes', [flat('Charlie'), flat('Alpha')], expanded: false),
      ];
      await tester.pumpWidget(buildGrid(const ValueKey('g2'), rows2, (m) {
        sm2 = m;
        m.addListener(() => captureSnapshot(m));
        restoreSnapshot(m);
      }));
      await tester.pumpAndSettle();

      // The sort must have actually been reapplied to the new grid...
      expect(sm2.getSortedColumn?.field, 'name');
      expect(sm2.rows.firstWhere((r) => r.type.isGroup).type.group.expanded, isTrue);
      // ...and the persistent snapshot must still hold it too, so the NEXT
      // remount (e.g. switching theme again) has something to restore from.
      expect(lastKnownSortField, 'name');
      expect(lastKnownSortDirection, TrinaColumnSort.ascending);
    });
  });

  group('_rebuildRows-style expand restore must be idempotent', () {
    // Regression test for a bug introduced by making _mapProjectsToRows()
    // pre-expand groups from the persisted snapshot (to fix the sort/expand
    // flash on remount): _rebuildRows()'s own restore loop used to assume
    // freshly-built group rows *always* start collapsed and unconditionally
    // called toggleExpandedRowGroup() whenever a group "was" expanded before
    // the rebuild. Once fresh rows could already arrive pre-expanded, that
    // unconditional toggle flipped them straight back to collapsed —
    // theme/locale switches (which trigger a _rebuildRows() by design) then
    // visibly collapsed every smart folder again. The fix compares the
    // desired state against the row's *actual* current state before
    // deciding whether to toggle at all.
    List<TrinaColumn> columns() => [
          TrinaColumn(title: 'Name', field: 'name', type: TrinaColumnType.text()),
        ];

    TrinaRow flat(String name) => TrinaRow(cells: {'name': TrinaCell(value: name)});

    TrinaRow group(String name, List<TrinaRow> children, {bool expanded = false}) {
      return TrinaRow(
        cells: {'name': TrinaCell(value: name)},
        type: TrinaRowType.group(
          children: FilteredList(initialList: children),
          expanded: expanded,
        ),
      );
    }

    // Mirrors _rebuildRows()'s buggy restore loop: toggles unconditionally.
    void restoreExpandBuggy(TrinaGridStateManager sm, Map<String, bool> wasCollapsed) {
      for (final row in sm.rows) {
        if (row.type.isGroup) {
          final name = row.cells['name']!.value as String;
          if (wasCollapsed[name] == false) {
            sm.toggleExpandedRowGroup(rowGroup: row, notify: false);
          }
        }
      }
    }

    // Mirrors the fixed _rebuildRows(): only toggles when state disagrees.
    void restoreExpandFixed(TrinaGridStateManager sm, Map<String, bool> wasCollapsed) {
      for (final row in sm.rows) {
        if (row.type.isGroup) {
          final name = row.cells['name']!.value as String;
          final shouldBeExpanded = wasCollapsed[name] == false;
          if (shouldBeExpanded != row.type.group.expanded) {
            sm.toggleExpandedRowGroup(rowGroup: row, notify: false);
          }
        }
      }
    }

    Future<TrinaGridStateManager> pumpGrid(
      WidgetTester tester,
      Key key,
      List<TrinaRow> rows,
    ) async {
      late TrinaGridStateManager sm;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: TrinaGrid(
              key: key,
              columns: columns(),
              rows: rows,
              onLoaded: (e) {
                e.stateManager.setRowGroup(TrinaRowGroupTreeDelegate(
                  resolveColumnDepth: (c) => null,
                  showText: (c) => true,
                  showFirstExpandableIcon: false,
                  showCount: false,
                ));
                sm = e.stateManager;
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return sm;
    }

    testWidgets(
        'unconditional toggle collapses a group whose fresh row already arrived expanded',
        (tester) async {
      final wasCollapsed = {'Mixes': false}; // group WAS expanded before rebuild

      // Fresh rows built the way _mapProjectsToRows() now builds them: the
      // group already pre-expanded from the persisted snapshot.
      final alreadyExpandedRows = [
        flat('Zeta'),
        group('Mixes', [flat('Charlie'), flat('Alpha')], expanded: true),
      ];
      final sm = await pumpGrid(tester, const ValueKey('buggy'), alreadyExpandedRows);

      restoreExpandBuggy(sm, wasCollapsed);

      expect(
        sm.rows.firstWhere((r) => r.type.isGroup).type.group.expanded,
        isFalse,
        reason: 'demonstrates the regression: an already-expanded row gets toggled shut',
      );
    });

    testWidgets(
        'idempotent toggle leaves an already-expanded fresh row expanded',
        (tester) async {
      final wasCollapsed = {'Mixes': false};

      final alreadyExpandedRows = [
        flat('Zeta'),
        group('Mixes', [flat('Charlie'), flat('Alpha')], expanded: true),
      ];
      final sm = await pumpGrid(tester, const ValueKey('fixed1'), alreadyExpandedRows);

      restoreExpandFixed(sm, wasCollapsed);

      expect(sm.rows.firstWhere((r) => r.type.isGroup).type.group.expanded, isTrue);
    });

    testWidgets(
        'idempotent toggle still expands a fresh row that arrived collapsed',
        (tester) async {
      final wasCollapsed = {'Mixes': false};

      final freshlyCollapsedRows = [
        flat('Zeta'),
        group('Mixes', [flat('Charlie'), flat('Alpha')], expanded: false),
      ];
      final sm = await pumpGrid(tester, const ValueKey('fixed2'), freshlyCollapsedRows);

      restoreExpandFixed(sm, wasCollapsed);

      expect(sm.rows.firstWhere((r) => r.type.isGroup).type.group.expanded, isTrue);
    });
  });
}
