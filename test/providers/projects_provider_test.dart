import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/release.dart';
import 'package:daw_project_manager/models/scan_root.dart';
import 'package:daw_project_manager/providers/providers.dart';

import '../helpers/test_factories.dart';

// ---------------------------------------------------------------------------
// Stub notifiers — override build() to avoid SchedulerBinding.instance calls
// and Hive reads, while preserving the public state-mutation API.
// ---------------------------------------------------------------------------

class _FakeShowHiddenNotifier extends ShowHiddenProjectsNotifier {
  @override
  int build() => 0;
}

class _FakeShowFinishedNotifier extends ShowFinishedProjectsNotifier {
  @override
  int build() => 0;
}

class _FakeShowOnlyWithDeadlineNotifier extends ShowOnlyWithDeadlineNotifier {
  @override
  bool build() => false;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer(List<MusicProject> projects) {
  return ProviderContainer(overrides: [
    allProjectsStreamProvider.overrideWith(
        (ref) => Stream.value(projects)),
    releasesProvider.overrideWith(
        (ref) => Stream.value(<Release>[])),
    scanRootsProvider.overrideWith(
        (ref) => <ScanRoot>[]),
    finishedPhaseProvider.overrideWith(
        (ref) => const <String>{'Finished'}),
    showHiddenProjectsProvider.overrideWith(_FakeShowHiddenNotifier.new),
    showFinishedProjectsProvider.overrideWith(_FakeShowFinishedNotifier.new),
    showOnlyWithDeadlineProvider.overrideWith(
        _FakeShowOnlyWithDeadlineNotifier.new),
  ]);
}

/// Riverpod 3 pauses stream subscriptions when a provider has no active
/// listener (a bare `read()` call doesn't count). We must hold an active
/// subscription open until the stream emits, then release it.
Future<List<MusicProject>> _readProjects(ProviderContainer c) async {
  final completer = Completer<void>();
  final sub = c.listen<AsyncValue<List<MusicProject>>>(
    allProjectsStreamProvider,
    (_, next) {
      if (next.hasValue && !completer.isCompleted) completer.complete();
    },
    fireImmediately: true,
  );
  await completer.future;
  sub.close();
  return c.read(projectsProvider);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('projectsProvider — default behaviour', () {
    test('hides hidden projects by default', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'visible', hidden: false),
        TestFactories.makeProject(id: 'hidden', hidden: true),
      ]);
      addTearDown(c.dispose);

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['visible']);
    });

    test('sorts by lastModifiedAt descending — newest first', () async {
      final c = _makeContainer([
        TestFactories.makeProject(
            id: 'old', lastModifiedAt: DateTime(2024, 1, 1)),
        TestFactories.makeProject(
            id: 'new', lastModifiedAt: DateTime(2025, 1, 1)),
      ]);
      addTearDown(c.dispose);

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['new', 'old']);
    });
  });

  group('projectsProvider — phase filter', () {
    test('null phase filter shows all non-hidden projects', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'a', status: 'Idea'),
        TestFactories.makeProject(id: 'b', status: 'Mixing'),
      ]);
      addTearDown(c.dispose);

      expect((await _readProjects(c)).length, 2);
    });

    test('setting phase filter = Idea returns only Idea projects', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'idea1', status: 'Idea'),
        TestFactories.makeProject(id: 'mixing', status: 'Mixing'),
        TestFactories.makeProject(id: 'idea2', status: 'Idea'),
      ]);
      addTearDown(c.dispose);
      c.read(phaseFilterProvider.notifier).setPhase('Idea');

      final ids = (await _readProjects(c)).map((p) => p.id).toSet();
      expect(ids, {'idea1', 'idea2'});
    });

    test('phase filter with no matching projects returns empty list', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: '1', status: 'Mixing'),
      ]);
      addTearDown(c.dispose);
      c.read(phaseFilterProvider.notifier).setPhase('Mastering');

      expect(await _readProjects(c), isEmpty);
    });
  });

  group('projectsProvider — hidden project filter', () {
    test('mode=1 (show all) includes hidden projects', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'v', hidden: false),
        TestFactories.makeProject(id: 'h', hidden: true),
      ]);
      addTearDown(c.dispose);
      c.read(showHiddenProjectsProvider.notifier).setShowAll(true);

      expect((await _readProjects(c)).length, 2);
    });

    test('mode=2 (only hidden) returns only hidden projects', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'v', hidden: false),
        TestFactories.makeProject(id: 'h', hidden: true),
      ]);
      addTearDown(c.dispose);
      c.read(showHiddenProjectsProvider.notifier).setShowOnlyHidden(true);

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['h']);
    });
  });

  group('projectsProvider — deadline filter', () {
    test('overdue filter returns only projects with past deadline', () async {
      final c = _makeContainer([
        TestFactories.makeProject(
          id: 'overdue',
          deadline: DateTime.now().subtract(const Duration(days: 3)),
        ),
        TestFactories.makeProject(
          id: 'future',
          deadline: DateTime.now().add(const Duration(days: 10)),
        ),
        TestFactories.makeProject(id: 'none'),
      ]);
      addTearDown(c.dispose);
      c.read(deadlineFilterProvider.notifier).setFilter(DeadlineFilter.overdue);

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['overdue']);
    });

    test('dueSoon filter returns projects due within 7 days', () async {
      final c = _makeContainer([
        TestFactories.makeProject(
          id: 'soon',
          deadline: DateTime.now().add(const Duration(days: 3)),
        ),
        TestFactories.makeProject(
          id: 'far',
          deadline: DateTime.now().add(const Duration(days: 30)),
        ),
      ]);
      addTearDown(c.dispose);
      c
          .read(deadlineFilterProvider.notifier)
          .setFilter(DeadlineFilter.dueSoon);

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['soon']);
    });

    test('dueToday filter returns projects with deadline today', () async {
      final c = _makeContainer([
        TestFactories.makeProject(
          id: 'today',
          deadline: DateTime.now(),
        ),
        TestFactories.makeProject(
          id: 'tomorrow',
          deadline: DateTime.now().add(const Duration(days: 1)),
        ),
      ]);
      addTearDown(c.dispose);
      c
          .read(deadlineFilterProvider.notifier)
          .setFilter(DeadlineFilter.dueToday);

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['today']);
    });
  });

  group('projectsProvider — text search', () {
    test('search filters by project displayName', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'bass', fileName: 'BassTrack.als'),
        TestFactories.makeProject(id: 'drum', fileName: 'DrumLoop.als'),
      ]);
      addTearDown(c.dispose);
      c.read(projectsSearchProvider.notifier).setSearchText('Bass');

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['bass']);
    });

    test('empty search text returns all visible projects', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: '1', fileName: 'A.als'),
        TestFactories.makeProject(id: '2', fileName: 'B.als'),
      ]);
      addTearDown(c.dispose);

      expect((await _readProjects(c)).length, 2);
    });
  });

  group('projectsProvider — sort order', () {
    test('sortDesc=false gives oldest-first order', () async {
      final c = _makeContainer([
        TestFactories.makeProject(
            id: 'old', lastModifiedAt: DateTime(2024, 1, 1)),
        TestFactories.makeProject(
            id: 'new', lastModifiedAt: DateTime(2025, 6, 1)),
      ]);
      addTearDown(c.dispose);
      // toggleSortDesc flips from default true → false (ascending)
      c.read(queryParamsNotifierProvider.notifier).toggleSortDesc();

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['old', 'new']);
    });
  });

  group('projectsProvider — finished phase filter', () {
    test('hide finished removes projects in finished phases', () async {
      final c = _makeContainer([
        TestFactories.makeProject(id: 'mixing', status: 'Mixing'),
        TestFactories.makeProject(id: 'done', status: 'Finished'),
      ]);
      addTearDown(c.dispose);
      unawaited(c
          .read(showFinishedProjectsProvider.notifier)
          .setHideFinished(true));

      expect(
          (await _readProjects(c)).map((p) => p.id).toList(), ['mixing']);
    });
  });
}
