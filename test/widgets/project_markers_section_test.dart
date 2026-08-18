import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/project_marker.dart';
import 'package:daw_project_manager/ui/widgets/project_markers_section.dart';

/// #91 — the marker list is a session's table of contents. It takes plain
/// values rather than a `MusicProject` or a `Ref`, so all of this runs without
/// opening Hive.
void main() {
  const intro = ProjectMarker(index: 1, name: 'Intro', positionSeconds: 0);
  const verse = ProjectMarker(index: 2, name: 'Verse', positionSeconds: 91);
  const unnamed = ProjectMarker(index: 7, name: '', positionSeconds: 30);
  const unnamedRegion = ProjectMarker(
    index: 3,
    name: '',
    positionSeconds: 10,
    endSeconds: 70,
  );

  Widget wrap(
    List<ProjectMarker> markers, {
    void Function(ProjectMarker)? onTap,
    int collapsedCount = 8,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProjectMarkersSection(
              markers: markers,
              title: 'MARKERS',
              unnamedMarkerLabel: (i) => 'Marker $i',
              unnamedRegionLabel: (i) => 'Region $i',
              showAllLabel: 'Show All',
              collapseLabel: 'Collapse',
              jumpTooltip: 'Jump',
              disabledTooltip: 'No preview song',
              collapsedCount: collapsedCount,
              onTap: onTap,
            ),
          ),
        ),
      );

  testWidgets('renders nothing at all when there are no markers',
      (tester) async {
    await tester.pumpWidget(wrap(const []));

    expect(find.text('MARKERS'), findsNothing);
  });

  testWidgets('shows each marker with its timecode', (tester) async {
    await tester.pumpWidget(wrap(const [intro, verse]));

    expect(find.text('MARKERS'), findsOneWidget);
    expect(find.text('Intro'), findsOneWidget);
    expect(find.text('Verse'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('01:31'), findsOneWidget);
  });

  testWidgets('shows the count next to the heading', (tester) async {
    await tester.pumpWidget(wrap(const [intro, verse, unnamed]));

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('an unnamed entry falls back to a localized label',
      (tester) async {
    // The fallback is built here rather than stored, so it follows the app's
    // language instead of whatever locale was active during the scan.
    await tester.pumpWidget(wrap(const [unnamed, unnamedRegion]));

    expect(find.text('Marker 7'), findsOneWidget);
    expect(find.text('Region 3'), findsOneWidget);
  });

  testWidgets('a region also shows its length', (tester) async {
    await tester.pumpWidget(wrap(const [unnamedRegion]));

    expect(find.text('00:10'), findsOneWidget, reason: 'start');
    expect(find.text('01:00'), findsOneWidget, reason: 'length');
  });

  testWidgets('tapping reports the marker that was tapped', (tester) async {
    final tapped = <ProjectMarker>[];
    await tester.pumpWidget(wrap(const [intro, verse], onTap: tapped.add));

    await tester.tap(find.text('Verse'));
    await tester.pump();

    expect(tapped, [verse]);
  });

  testWidgets('rows stay visible but inert with nothing to seek in',
      (tester) async {
    await tester.pumpWidget(wrap(const [intro]));

    expect(find.text('Intro'), findsOneWidget);
    final inkWell = tester.widget<InkWell>(
      find.ancestor(of: find.text('Intro'), matching: find.byType(InkWell)),
    );
    expect(inkWell.onTap, isNull);
    expect(
      find.byTooltip('No preview song'),
      findsOneWidget,
      reason: 'the row should say why it does nothing',
    );
  });

  testWidgets('an enabled row carries the jump tooltip', (tester) async {
    await tester.pumpWidget(wrap(const [intro], onTap: (_) {}));

    expect(find.byTooltip('Jump'), findsOneWidget);
  });

  group('long lists', () {
    List<ProjectMarker> many(int n) => [
          for (var i = 1; i <= n; i++)
            ProjectMarker(
              index: i,
              name: 'Cue $i',
              positionSeconds: i.toDouble(),
            ),
        ];

    testWidgets('a short list has no toggle', (tester) async {
      await tester.pumpWidget(wrap(many(4)));

      expect(find.text('Show All'), findsNothing);
    });

    testWidgets('a long list folds behind a toggle', (tester) async {
      // A post-production session can carry hundreds; unfolded they would bury
      // everything below them on the page.
      await tester.pumpWidget(wrap(many(30)));

      expect(find.text('Cue 8'), findsOneWidget);
      expect(find.text('Cue 9'), findsNothing);
      expect(find.text('Show All'), findsOneWidget);
    });

    testWidgets('the toggle expands and collapses again', (tester) async {
      await tester.pumpWidget(wrap(many(30)));

      await tester.tap(find.text('Show All'));
      await tester.pump();
      expect(find.text('Cue 30'), findsOneWidget);
      expect(find.text('Collapse'), findsOneWidget);

      // Expanded, the toggle has been pushed below the fold.
      await tester.ensureVisible(find.text('Collapse'));
      await tester.pump();
      await tester.tap(find.text('Collapse'));
      await tester.pump();
      expect(find.text('Cue 30'), findsNothing);
      expect(find.text('Show All'), findsOneWidget);
    });
  });
}
