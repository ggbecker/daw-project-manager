import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
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
  group('shouldBlockForOperation', () {
    // Regression test: the full-screen loading overlay used to key off a
    // flag that also went true during the background initial scan at app
    // launch and a plain user-triggered rescan, locking the user out of the
    // app for the duration of either. Both are diff-based scans safe to
    // browse through (newly-found projects surface via the "New" badge
    // instead), so neither should block — only deep scan (which rewrites
    // existing projects' metadata in place) and operations that mutate state
    // out from under the user (switching profiles, extracting metadata)
    // still do.
    bool call({
      bool scanning = false,
      bool deepScanning = false,
      bool profileSwitching = false,
      bool extractingMetadata = false,
    }) =>
        shouldBlockForOperation(
          scanning: scanning,
          deepScanning: deepScanning,
          profileSwitching: profileSwitching,
          extractingMetadata: extractingMetadata,
        );

    test('does not block when nothing is happening', () {
      expect(call(), isFalse);
    });

    test('does not block for a plain user-initiated rescan', () {
      expect(call(scanning: true), isFalse);
    });

    test('blocks for a deep scan', () {
      // Deep scan always implies `scanning` too (see _scanAll), so exercise
      // that realistic combination rather than deepScanning in isolation.
      expect(call(scanning: true, deepScanning: true), isTrue);
    });

    test('blocks while switching profiles', () {
      expect(call(profileSwitching: true), isTrue);
    });

    test('blocks while extracting metadata', () {
      expect(call(extractingMetadata: true), isTrue);
    });
  });

  group('rescanIconState', () {
    test('shows a spinner while a plain scan runs', () {
      expect(
        rescanIconState(isScanning: true, deepScanning: false, justSucceeded: false),
        ScanIconState.spinning,
      );
    });

    test('defers to the dedicated Deep Scan button while deep-scanning', () {
      // isScanning is true here too (deep scan implies it via _scanAll),
      // but the Rescan button must not also spin — it has its own icon.
      expect(
        rescanIconState(isScanning: true, deepScanning: true, justSucceeded: false),
        ScanIconState.idle,
      );
    });

    test('shows the checkmark once scanning has stopped', () {
      expect(
        rescanIconState(isScanning: false, deepScanning: false, justSucceeded: true),
        ScanIconState.justSucceeded,
      );
    });

    test('spinner takes priority over a stale justSucceeded flag', () {
      expect(
        rescanIconState(isScanning: true, deepScanning: false, justSucceeded: true),
        ScanIconState.spinning,
      );
    });

    test('idle otherwise', () {
      expect(
        rescanIconState(isScanning: false, deepScanning: false, justSucceeded: false),
        ScanIconState.idle,
      );
    });
  });

  group('deepScanIconState', () {
    test('shows a spinner while deep-scanning', () {
      expect(deepScanIconState(deepScanning: true, justSucceeded: false), ScanIconState.spinning);
    });

    test('shows the checkmark once deep-scanning has stopped', () {
      expect(deepScanIconState(deepScanning: false, justSucceeded: true), ScanIconState.justSucceeded);
    });

    test('idle otherwise', () {
      expect(deepScanIconState(deepScanning: false, justSucceeded: false), ScanIconState.idle);
    });
  });

  group('sortDirectionFromPrefsValue / sortDirectionToPrefsValue', () {
    // Regression coverage for persisting the Projects grid's column sort
    // across app restarts (see _PlutoProjectsTableState.initState /
    // _persistSortPreference): these two are the only translation between
    // TrinaColumnSort and what actually gets written to the `settings` Hive
    // box, so a bug here would either lose the persisted sort silently or
    // crash trying to reparse it.

    test('parses the two values ever written', () {
      expect(sortDirectionFromPrefsValue('ascending'), TrinaColumnSort.ascending);
      expect(sortDirectionFromPrefsValue('descending'), TrinaColumnSort.descending);
    });

    test('treats a missing or corrupt stored value as no persisted sort', () {
      expect(sortDirectionFromPrefsValue(null), isNull);
      expect(sortDirectionFromPrefsValue(''), isNull);
      expect(sortDirectionFromPrefsValue('sideways'), isNull);
    });

    test('serializes ascending/descending back to the same strings it parses', () {
      expect(sortDirectionToPrefsValue(TrinaColumnSort.ascending), 'ascending');
      expect(sortDirectionToPrefsValue(TrinaColumnSort.descending), 'descending');
    });

    test('serializes a cleared/absent sort to null rather than a sentinel value', () {
      expect(sortDirectionToPrefsValue(TrinaColumnSort.none), isNull);
      expect(sortDirectionToPrefsValue(null), isNull);
    });

    test('round-trips through both directions', () {
      for (final direction in [TrinaColumnSort.ascending, TrinaColumnSort.descending]) {
        final value = sortDirectionToPrefsValue(direction);
        expect(sortDirectionFromPrefsValue(value), direction);
      }
    });
  });

  group('groupChildProjectIds', () {
    test('collects ids of every project inside a group row', () {
      final group = _groupHeaderRow('Mixes', [_flatRow('a'), _flatRow('b')]);

      expect(groupChildProjectIds(group), {'a', 'b'});
    });

    test('is empty for a non-group (flat) row', () {
      expect(groupChildProjectIds(_flatRow('a')), isEmpty);
    });

    test('is empty for an empty group', () {
      expect(groupChildProjectIds(_groupHeaderRow('Empty', [])), isEmpty);
    });
  });

  group('missingProjectIds', () {
    // Regression coverage for the "Delete Missing" bulk action: scans no
    // longer auto-delete a project the moment its file disappears (see
    // ProjectRepository.deleteProjectsPermanently's doc comment) — deleting
    // is now this explicit, selection-driven action instead, and it must
    // only ever touch the selected projects whose file is actually gone.

    test('returns only selected projects whose file does not exist', () async {
      final dir = await Directory.systemTemp.createTemp('missing_project_ids_');
      try {
        final existingFile = File('${dir.path}/exists.als');
        await existingFile.create();
        final present = TestFactories.makeProject(id: 'present', filePath: existingFile.path);
        final missing = TestFactories.makeProject(id: 'missing', filePath: '${dir.path}/gone.als');

        final result = missingProjectIds([present, missing], ['present', 'missing']);

        expect(result, ['missing']);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('ignores a missing project that was not selected', () {
      final missing = TestFactories.makeProject(id: 'missing', filePath: '/nonexistent/gone.als');

      expect(missingProjectIds([missing], []), isEmpty);
    });

    test('is empty when every selected project still has its file', () async {
      final dir = await Directory.systemTemp.createTemp('missing_project_ids_');
      try {
        final file = File('${dir.path}/exists.als');
        await file.create();
        final present = TestFactories.makeProject(id: 'present', filePath: file.path);

        expect(missingProjectIds([present], ['present']), isEmpty);
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });

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

    test('excludeGroupsFromSort keeps a group row out of the top-level reorder', () {
      // Regression coverage for excludeSmartFoldersFromSortProvider: a
      // smart-folder group used to move around the table just like any
      // other row whenever the user sorted by a column — annoying for
      // workflows where folders represent a fixed structure (e.g. project
      // phases) rather than something meant to be sorted alongside files.
      final group = _groupHeaderRow(
        'Zeta Folder', // sorts last alphabetically, but must stay put
        [_namedFlatRow('Charlie'), _namedFlatRow('Alpha')],
      );
      final rows = [_namedFlatRow('Bravo'), group, _namedFlatRow('Delta')];

      applySortSnapshot(rows, 'name', TrinaColumnSort.ascending, excludeGroupsFromSort: true);

      // The group stayed at index 1 (its original slot); the flat rows
      // around it sorted into the remaining slots.
      expect(rows.map((r) => r.cells['name']!.value), ['Bravo', 'Zeta Folder', 'Delta']);
      // Children still sort normally — only the top level is exempt.
      expect(
        group.type.group.children.originalList.map((r) => r.cells['name']!.value),
        ['Alpha', 'Charlie'],
      );
    });
  });

  group('smartFolderGroupKey', () {
    // Regression coverage for issue #67: a user with the same top-level
    // folder layout (e.g. "0-Ideas") replicated under two different scan
    // roots (one per DAW, e.g. Cubase and Studio One) got two separate,
    // identically-labeled smart-folder groups instead of one. This is the
    // pure grouping-key logic behind the opt-in
    // mergeSmartFoldersByNameProvider that lets those collapse into one.

    test('keys by the full top-level path when not merging by name', () {
      final key = smartFolderGroupKey(
        '/Music/Cubase Projects',
        ['0-Ideas', 'Song.cpr'],
        mergeSameName: false,
      );

      expect(key, path.join('/Music/Cubase Projects', '0-Ideas'));
    });

    test('two roots with an identically-named subfolder produce different keys when off', () {
      final cubaseKey = smartFolderGroupKey(
        '/Music/Cubase Projects',
        ['0-Ideas', 'Song.cpr'],
        mergeSameName: false,
      );
      final studioOneKey = smartFolderGroupKey(
        '/Music/Studio One Projects',
        ['0-Ideas', 'Song.song'],
        mergeSameName: false,
      );

      expect(cubaseKey, isNot(studioOneKey));
    });

    test('two roots with an identically-named subfolder collapse to the same key when on', () {
      final cubaseKey = smartFolderGroupKey(
        '/Music/Cubase Projects',
        ['0-Ideas', 'Song.cpr'],
        mergeSameName: true,
      );
      final studioOneKey = smartFolderGroupKey(
        '/Music/Studio One Projects',
        ['0-Ideas', 'Song.song'],
        mergeSameName: true,
      );

      expect(cubaseKey, studioOneKey);
      expect(cubaseKey, '0-Ideas');
    });

    test('differently-named subfolders still key separately even when merging by name', () {
      final ideasKey = smartFolderGroupKey(
        '/Music/Cubase Projects',
        ['0-Ideas', 'Song.cpr'],
        mergeSameName: true,
      );
      final activeKey = smartFolderGroupKey(
        '/Music/Cubase Projects',
        ['1-Active Projects', 'Song.cpr'],
        mergeSameName: true,
      );

      expect(ideasKey, isNot(activeKey));
    });

    test('only the top-level segment participates in the key, nested depth is ignored', () {
      final shallow = smartFolderGroupKey(
        '/Music/Cubase Projects',
        ['0-Ideas', 'Song.cpr'],
        mergeSameName: false,
      );
      final nested = smartFolderGroupKey(
        '/Music/Cubase Projects',
        ['0-Ideas', 'Sub', 'Song.cpr'],
        mergeSameName: false,
      );

      expect(shallow, nested);
    });
  });

  group('smartFolderShouldRenderAsGroup', () {
    // Regression coverage for a follow-up report on issue #67: a lone
    // Cubase project newly dropped into a "1-Active Projects" folder merged
    // correctly with an existing same-named Studio One folder while showing
    // all DAWs (member count > 1 after merging), but filtering the DAW
    // type down to Cubase only hid the Studio One siblings, dropping the
    // visible member count back to 1 and demoting the group to a flat,
    // seemingly "orphaned" row — even though the folder is a real,
    // intentionally-merged one. With mergeByName on, a group must never
    // demote just because a filter narrowed its currently-visible members
    // down to one.

    test('demotes a lone project to flat when both settings are off', () {
      expect(smartFolderShouldRenderAsGroup(1, mergeByName: false, alwaysShow: false), isFalse);
    });

    test('keeps rendering as a group once there are 2+ members, both settings off', () {
      expect(smartFolderShouldRenderAsGroup(2, mergeByName: false, alwaysShow: false), isTrue);
    });

    test('never demotes to flat when merge-by-name is on, even with a single visible member', () {
      expect(smartFolderShouldRenderAsGroup(1, mergeByName: true, alwaysShow: false), isTrue);
    });

    test('still renders as a group with 2+ members when merge-by-name is on', () {
      expect(smartFolderShouldRenderAsGroup(2, mergeByName: true, alwaysShow: false), isTrue);
    });

    // alwaysShowSmartFoldersProvider: a general-purpose version of the same
    // override, independent of merge-by-name — for anyone who wants a smart
    // folder to never collapse away, whatever narrowed it down to one
    // visible member (a search, a phase filter, a DAW filter with no merge
    // involved at all, etc.).

    test('never demotes to flat when always-show is on, even with a single visible member', () {
      expect(smartFolderShouldRenderAsGroup(1, mergeByName: false, alwaysShow: true), isTrue);
    });

    test('still renders as a group with 2+ members when always-show is on', () {
      expect(smartFolderShouldRenderAsGroup(2, mergeByName: false, alwaysShow: true), isTrue);
    });

    test('either setting alone is enough to keep a lone member grouped', () {
      expect(smartFolderShouldRenderAsGroup(1, mergeByName: true, alwaysShow: true), isTrue);
    });
  });

  group('sortFlatRowsKeepingGroupsInPlace', () {
    int byName(TrinaRow a, TrinaRow b) =>
        (a.cells['name']!.value as String).compareTo(b.cells['name']!.value as String);

    test('leaves every group at its current index', () {
      final groupA = _groupHeaderRow('Group A', [_namedFlatRow('x')]);
      final groupB = _groupHeaderRow('Group B', [_namedFlatRow('y')]);
      final current = [_namedFlatRow('Zeta'), groupA, _namedFlatRow('Alpha'), groupB];

      final result = sortFlatRowsKeepingGroupsInPlace(current, byName);

      expect(result[1], same(groupA));
      expect(result[3], same(groupB));
    });

    test('sorts the flat rows into the remaining slots, in order', () {
      final group = _groupHeaderRow('Folder', [_namedFlatRow('x')]);
      final current = [_namedFlatRow('Zeta'), group, _namedFlatRow('Alpha'), _namedFlatRow('Mid')];

      final result = sortFlatRowsKeepingGroupsInPlace(current, byName);

      expect(
        result.map((r) => r.cells['name']!.value),
        ['Alpha', 'Folder', 'Mid', 'Zeta'],
      );
    });

    test('is unchanged when there are no groups', () {
      final current = [_namedFlatRow('Zeta'), _namedFlatRow('Alpha'), _namedFlatRow('Mid')];

      final result = sortFlatRowsKeepingGroupsInPlace(current, byName);

      expect(result.map((r) => r.cells['name']!.value), ['Alpha', 'Mid', 'Zeta']);
    });

    test('is unchanged when every row is a group', () {
      final groupA = _groupHeaderRow('B', [_namedFlatRow('x')]);
      final groupB = _groupHeaderRow('A', [_namedFlatRow('y')]);
      final current = [groupA, groupB];

      final result = sortFlatRowsKeepingGroupsInPlace(current, byName);

      // Groups are never reordered by this function, even though 'A' < 'B'.
      expect(result, [groupA, groupB]);
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

  group('sort-icon restore must use the persistent snapshot, not the live column', () {
    // Regression test for: after switching theme, the header's sort-
    // direction icon reverted to neutral even though the table was still
    // genuinely sorted. Root cause: on a remount, TrinaGrid gets brand new
    // TrinaColumn objects (built fresh in build()) whose .sort always starts
    // at none. _mapProjectsToRows() pre-sorts the row *data* so the table
    // looks right immediately, but nothing had set the new column's own
    // .sort flag by the time the theme-switch path's deferred rebuild ran
    // its "read the currently sorted column" step — because that step used
    // to read stateManager.getSortedColumn (which finds nothing on a fresh,
    // never-clicked column) instead of the persisted snapshot of what field
    // *should* be sorted.
    List<TrinaColumn> columns() => [
          TrinaColumn(title: 'Name', field: 'name', type: TrinaColumnType.text()),
        ];

    TrinaRow flat(String name) => TrinaRow(cells: {'name': TrinaCell(value: name)});

    Future<TrinaGridStateManager> pumpGrid(WidgetTester tester, Key key, List<TrinaRow> rows) async {
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
              onLoaded: (e) => sm = e.stateManager,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return sm;
    }

    testWidgets('reading sm.getSortedColumn on a fresh remount finds nothing to restore', (tester) async {
      // The persisted snapshot says "name" should be sorted ascending (the
      // exact direction doesn't matter for this test — only that *some*
      // sort is known but the live column doesn't reflect it yet).
      const knownSortField = 'name';

      // ...but the freshly-mounted grid's column has never been clicked, so
      // its own .sort flag is still none — this is the state right after a
      // theme-switch remount, before anything restores the column flag.
      final freshRows = [flat('Alpha'), flat('Bravo')]; // data already pre-sorted
      final sm = await pumpGrid(tester, const ValueKey('fresh'), freshRows);

      // The old, buggy approach: derive what to (re-)sort from the live
      // column instead of the snapshot.
      final sortedColumn = sm.getSortedColumn;
      expect(sortedColumn, isNull,
          reason: 'demonstrates the bug: nothing on the fresh grid is flagged as sorted yet');

      // knownSortField/knownSortDirection (the actual source of truth) are
      // simply never consulted by that approach, so the header icon for
      // "name" never gets set to ascending even though the table is sorted.
      final nameColumn = sm.columns.firstWhere((c) => c.field == knownSortField);
      expect(nameColumn.sort, TrinaColumnSort.none);
    });

    testWidgets('reading the persistent snapshot correctly restores the sort-icon flag', (tester) async {
      const knownSortField = 'name';
      const knownSortDirection = TrinaColumnSort.ascending;

      final freshRows = [flat('Alpha'), flat('Bravo')];
      final sm = await pumpGrid(tester, const ValueKey('fixed'), freshRows);

      // Mirrors _applyKnownSort(): look up the column by the snapshot's
      // field name, not by asking the grid what's currently flagged.
      for (final column in sm.columns) {
        if (column.field != knownSortField) continue;
        if (knownSortDirection.isAscending) {
          sm.sortAscending(column, notify: false);
        } else if (knownSortDirection.isDescending) {
          sm.sortDescending(column, notify: false);
        }
        break;
      }

      final nameColumn = sm.columns.firstWhere((c) => c.field == knownSortField);
      expect(nameColumn.sort, TrinaColumnSort.ascending);
    });
  });
}
