import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_event.dart';
import 'package:daw_project_manager/providers/providers.dart';

import '../helpers/test_factories.dart';

// ---------------------------------------------------------------------------
// Stub notifier — overrides build() to avoid SchedulerBinding.instance calls.
// ---------------------------------------------------------------------------

class _FakeStatsHideFinishedNotifier extends StatsHideFinishedNotifier {
  @override
  bool build() => false;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer({
  List<MusicProject> projects = const [],
  List<ProjectEvent> events = const [],
}) {
  return ProviderContainer(overrides: [
    allProjectsStreamProvider.overrideWith(
        (ref) => Stream.value(projects)),
    allEventsStreamProvider.overrideWith(
        (ref) => Stream.value(events)),
    finishedPhaseProvider.overrideWith(
        (ref) => const <String>{'Finished'}),
    customPhasesProvider.overrideWith(
        (ref) => ['Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished']),
    statsHideFinishedProvider.overrideWith(
        _FakeStatsHideFinishedNotifier.new),
  ]);
}

/// Riverpod 3 pauses stream subscriptions when a provider has no active
/// listener (a bare `read()` call doesn't count). Hold an active subscription
/// until the first emission, then release it.
Future<GlobalStats> _readStats(ProviderContainer c) async {
  final comp1 = Completer<void>();
  final comp2 = Completer<void>();

  final sub1 = c.listen<AsyncValue<List<MusicProject>>>(
    allProjectsStreamProvider,
    (_, next) { if (next.hasValue && !comp1.isCompleted) comp1.complete(); },
    fireImmediately: true,
  );
  final sub2 = c.listen<AsyncValue<List<ProjectEvent>>>(
    allEventsStreamProvider,
    (_, next) { if (next.hasValue && !comp2.isCompleted) comp2.complete(); },
    fireImmediately: true,
  );

  await comp1.future;
  await comp2.future;
  sub1.close();
  sub2.close();

  return c.read(globalStatsProvider);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('globalStatsProvider — totals', () {
    test('empty project list returns zero totals', () async {
      final c = _makeContainer();
      addTearDown(c.dispose);

      final stats = await _readStats(c);
      expect(stats.totalProjects, 0);
      expect(stats.inProgressCount, 0);
      expect(stats.finishedCount, 0);
      expect(stats.avgCompletionTime, isNull);
    });

    test('totalProjects reflects the number of seeded projects', () async {
      final c = _makeContainer(projects: [
        TestFactories.makeProject(id: '1', status: 'Idea'),
        TestFactories.makeProject(id: '2', status: 'Mixing'),
        TestFactories.makeProject(id: '3', status: 'Mastering'),
      ]);
      addTearDown(c.dispose);

      expect((await _readStats(c)).totalProjects, 3);
    });

    test('inProgressCount and finishedCount split correctly', () async {
      final c = _makeContainer(projects: [
        TestFactories.makeProject(id: '1', status: 'Mixing'),
        TestFactories.makeProject(id: '2', status: 'Idea'),
        TestFactories.makeProject(id: '3', status: 'Finished'),
      ]);
      addTearDown(c.dispose);

      final stats = await _readStats(c);
      expect(stats.inProgressCount, 2);
      expect(stats.finishedCount, 1);
    });
  });

  group('globalStatsProvider — countPerPhase', () {
    test('countPerPhase reflects per-phase project distribution', () async {
      final c = _makeContainer(projects: [
        TestFactories.makeProject(id: '1', status: 'Idea'),
        TestFactories.makeProject(id: '2', status: 'Idea'),
        TestFactories.makeProject(id: '3', status: 'Mixing'),
      ]);
      addTearDown(c.dispose);

      final stats = await _readStats(c);
      expect(stats.countPerPhase['Idea'], 2);
      expect(stats.countPerPhase['Mixing'], 1);
      expect(stats.countPerPhase['Mastering'], 0);
    });

    test('countPerPhase initialises every custom phase to zero when no projects',
        () async {
      final c = _makeContainer();
      addTearDown(c.dispose);

      final stats = await _readStats(c);
      for (final phase in [
        'Idea',
        'Arranging',
        'Mixing',
        'Mastering',
        'Finished'
      ]) {
        expect(stats.countPerPhase[phase], 0,
            reason: '"$phase" should be 0 with no projects');
      }
    });
  });

  group('globalStatsProvider — avgCompletionTime', () {
    test('avgCompletionTime is null when no finished projects', () async {
      final c = _makeContainer(projects: [
        TestFactories.makeProject(id: '1', status: 'Mixing'),
      ]);
      addTearDown(c.dispose);

      expect((await _readStats(c)).avgCompletionTime, isNull);
    });

    test(
        'avgCompletionTime is null for finished project without statusChangedAt',
        () async {
      final c = _makeContainer(projects: [
        // statusChangedAt defaults to null in TestFactories.makeProject
        TestFactories.makeProject(id: '1', status: 'Finished'),
      ]);
      addTearDown(c.dispose);

      expect((await _readStats(c)).avgCompletionTime, isNull);
    });

    test('avgCompletionTime averages completion durations across projects',
        () async {
      // p1 finished in 10 days, p2 finished in 20 days → avg = 15 days
      final c = _makeContainer(projects: [
        TestFactories.makeProject(
          id: 'f1',
          status: 'Finished',
          createdAt: DateTime(2025, 1, 1),
          statusChangedAt: DateTime(2025, 1, 11),
        ),
        TestFactories.makeProject(
          id: 'f2',
          status: 'Finished',
          createdAt: DateTime(2025, 1, 1),
          statusChangedAt: DateTime(2025, 1, 21),
        ),
      ]);
      addTearDown(c.dispose);

      final stats = await _readStats(c);
      expect(stats.avgCompletionTime, const Duration(days: 15));
    });
  });

  group('globalStatsProvider — monthly activity', () {
    test('createdPerMonth counts project created this month', () async {
      final now = DateTime.now();
      final c = _makeContainer(projects: [
        TestFactories.makeProject(id: '1', createdAt: now),
      ]);
      addTearDown(c.dispose);

      final stats = await _readStats(c);
      final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      expect(stats.createdPerMonth[key], 1);
    });

    test('finishedPerMonth counts Finished project updated this month',
        () async {
      final now = DateTime.now();
      final c = _makeContainer(projects: [
        TestFactories.makeProject(
          id: '1',
          status: 'Finished',
          updatedAt: now,
        ),
      ]);
      addTearDown(c.dispose);

      final stats = await _readStats(c);
      final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      expect(stats.finishedPerMonth[key], 1);
    });

    test(
        'projects created more than 12 months ago are not in createdPerMonth',
        () async {
      final old = DateTime.now().subtract(const Duration(days: 400));
      final c = _makeContainer(projects: [
        TestFactories.makeProject(id: '1', createdAt: old),
      ]);
      addTearDown(c.dispose);

      final stats = await _readStats(c);
      expect(stats.createdPerMonth.values.every((v) => v == 0), isTrue);
    });
  });

  group('globalStatsProvider — statsHideFinished flag', () {
    test('statsHideFinished=true excludes finished projects from all counts',
        () async {
      final c = _makeContainer(projects: [
        TestFactories.makeProject(id: '1', status: 'Mixing'),
        TestFactories.makeProject(id: '2', status: 'Idea'),
        TestFactories.makeProject(id: '3', status: 'Finished'),
      ]);
      addTearDown(c.dispose);
      // toggle() sets state synchronously; Hive write is fire-and-forget
      unawaited(c.read(statsHideFinishedProvider.notifier).toggle());

      final stats = await _readStats(c);
      expect(stats.totalProjects, 2);
      expect(stats.finishedCount, 0);
    });
  });
}
