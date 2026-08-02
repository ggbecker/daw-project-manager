import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/repository/project_repository.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
  });

  tearDown(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  group('repositoryProvider profile switching', () {
    // Regression for a HiveError ("Box has already been closed") thrown
    // during profile switches. repositoryProvider used to close the
    // outgoing profile's boxes via ref.onDispose to save memory, but
    // Riverpod's FutureProvider keeps exposing the previous profile's
    // ProjectRepository as .value while the new one is still loading
    // (AsyncValue's "keep previous data during reload" behavior). Any
    // build-time code reading that stale .value synchronously — e.g.
    // dashboard_page.dart's first-launch check, `repoAsync.value!
    // .getAllProjects()` — could still be holding the exact repo object
    // whose boxes onDispose had already closed underneath it. The fix was
    // to stop auto-closing boxes on switch; this test locks that in.
    test(
      'does not close the outgoing profile\'s boxes, so a stale reference stays usable',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Keep repositoryProvider (and its currentProfileProvider /
        // profilesBox-watch dependency) actively subscribed. Riverpod
        // pauses stream-backed providers with no listener, so a bare
        // read() wouldn't reliably pick up the profile switch below.
        final resolvedProfileIds = <String>[];
        final sawSecondProfile = Completer<void>();
        final sub = container.listen<AsyncValue<ProjectRepository>>(
          repositoryProvider,
          (_, next) {
            final repo = next.asData?.value;
            if (repo == null) return;
            resolvedProfileIds.add(repo.profileId);
            if (resolvedProfileIds.toSet().length >= 2 && !sawSecondProfile.isCompleted) {
              sawSecondProfile.complete();
            }
          },
          fireImmediately: true,
        );
        addTearDown(sub.close);

        final profileRepo = await container.read(profileRepositoryProvider.future);
        final repoA = await container.read(repositoryProvider.future);
        final profileAId = repoA.profileId;
        expect(repoA.projectsBox.isOpen, isTrue);

        final profileB = await profileRepo.createProfile('Profile B');
        await profileRepo.setCurrentProfileId(profileB.id);

        await sawSecondProfile.future.timeout(const Duration(seconds: 5));

        final repoB = await container.read(repositoryProvider.future);
        expect(repoB.profileId, profileB.id);
        expect(repoB.profileId, isNot(profileAId));

        // The regression check: repoA's boxes must still be open after the
        // switch, and a synchronous call into it — exactly what a stale
        // AsyncValue.value read during the transition would do — must not
        // throw HiveError.
        expect(repoA.projectsBox.isOpen, isTrue);
        expect(() => repoA.getAllProjects(), returnsNormally);
      },
    );
  });

  group('Delete All Data provider refresh', () {
    // settings_page.dart's Delete All Data handler calls
    // ProjectRepository.deleteAllAppData() (which closes every Hive box
    // across every profile) and then invalidates a specific list of
    // providers before re-priming profileRepositoryProvider and
    // repositoryProvider. This reproduces that exact sequence and checks
    // that allProjectsStreamProvider — what the dashboard grid actually
    // renders from — settles on the fresh, empty state afterwards rather
    // than getting stuck on stale data.
    test(
      'allProjectsStreamProvider settles to empty after the same '
      'invalidate sequence settings_page.dart runs',
      () async {
        final profileRepo = await HiveTestHelper.createProfileRepository();
        final profileA = await profileRepo.createProfile('A');
        await profileRepo.setCurrentProfileId(profileA.id);
        final repoA = await HiveTestHelper.createRepository(
          profileId: profileA.id,
        );
        await repoA.restoreProject(TestFactories.makeProject(id: 'a1'));

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Keep the stream actively subscribed — Riverpod pauses
        // stream-backed providers with no listener.
        final sub = container.listen<AsyncValue<List<MusicProject>>>(
          allProjectsStreamProvider,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        final before = await container.read(allProjectsStreamProvider.future);
        expect(before, hasLength(1));

        await ProjectRepository.deleteAllAppData();
        container.invalidate(profileRepositoryProvider);
        container.invalidate(currentProfileProvider);
        container.invalidate(allProfilesProvider);
        container.invalidate(repositoryProvider);
        container.invalidate(rootsWatchProvider);
        container.invalidate(scanRootsProvider);
        container.invalidate(ignoredPathsWatchProvider);
        container.invalidate(ignoredPathsProvider);
        container.invalidate(allProjectsStreamProvider);
        await container.read(profileRepositoryProvider.future);
        await container.read(repositoryProvider.future);

        final after = await container
            .read(allProjectsStreamProvider.future)
            .timeout(const Duration(seconds: 5));
        expect(after, isEmpty);
      },
    );
  });
}
