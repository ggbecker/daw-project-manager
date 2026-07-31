import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/repository/project_repository.dart';

import '../helpers/hive_test_helper.dart';

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
}
