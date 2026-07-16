import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_event.dart';
import 'package:daw_project_manager/models/release.dart';
import 'package:daw_project_manager/models/todo_template.dart';
import 'package:daw_project_manager/repository/profile_repository.dart';
import 'package:daw_project_manager/services/demo_data_service.dart';

import '../helpers/hive_test_helper.dart';
import '../helpers/test_factories.dart';

void main() {
  late Directory tempDir;
  late ProfileRepository profileRepo;

  Future<String> fakePreviewSongsPath() async {
    final dir = Directory(p.join(tempDir.path, 'previews'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
    profileRepo = await HiveTestHelper.createProfileRepository();
  });

  tearDown(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  group('DemoDataService.generate', () {
    test('creates a profile named "Demo — Screenshots"', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
      );

      expect(profile.name, DemoDataService.demoProfileName);
      expect(profileRepo.getAllProfiles().length, 1);
    });

    test('running twice reuses the same profile and does not duplicate data', () async {
      final first = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
      );
      final firstProjects = await Hive.openBox<MusicProject>('${first.id}_projects');
      final firstCount = firstProjects.length;
      await firstProjects.close();

      final second = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
      );

      expect(second.id, first.id);
      expect(profileRepo.getAllProfiles().length, 1);

      final secondProjects = await Hive.openBox<MusicProject>('${second.id}_projects');
      expect(secondProjects.length, firstCount);
    });

    test('spans every supported DAW type and every canonical status', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
      );
      final projects = await Hive.openBox<MusicProject>('${profile.id}_projects');

      final dawTypes = projects.values.map((p) => p.dawType).toSet();
      final statuses = projects.values.map((p) => p.status).toSet();

      expect(
        dawTypes,
        {
          'Ableton Live', 'Bitwig Studio', 'Cubase', 'FL Studio', 'Logic Pro',
          'Maschine', 'Nuendo', 'Pro Tools', 'Reaper', 'Studio One', 'Waveform',
          'LUNA',
        },
      );
      expect(statuses, {'Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'});
    });

    test('every release trackId resolves to a generated project', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
      );
      final projects = await Hive.openBox<MusicProject>('${profile.id}_projects');
      final releases = await Hive.openBox<Release>('${profile.id}_releases');

      final projectIds = projects.keys.toSet();
      expect(releases.values, isNotEmpty);
      for (final release in releases.values) {
        for (final trackId in release.trackIds) {
          expect(projectIds.contains(trackId), isTrue,
              reason: 'Release "${release.title}" references missing project $trackId');
        }
      }
    });

    test('status-change events are within the last 12 months with valid payloads', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
      );
      final events = await Hive.openBox<ProjectEvent>('${profile.id}_events');
      expect(events.values, isNotEmpty);

      final cutoff = DateTime.now().subtract(const Duration(days: 366));
      const validStatuses = {'Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'};

      for (final event in events.values) {
        expect(event.occurredAt.isAfter(cutoff), isTrue,
            reason: 'Event ${event.id} occurred outside the last 12 months');

        if (event.eventType == ProjectEvent.statusChange) {
          final payload = jsonDecode(event.payload as String) as Map;
          expect(validStatuses.contains(payload['from']), isTrue);
          expect(validStatuses.contains(payload['to']), isTrue);
        }
      }
    });

    test('does not touch a separate profile\'s real project data', () async {
      final realRepo = await HiveTestHelper.createRepository(profileId: 'real-user-profile');
      final realProject = TestFactories.makeProject(id: 'real-project-1');
      await realRepo.projectsBox.put(realProject.id, realProject);

      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
      );

      expect(realRepo.projectsBox.length, 1);
      expect(realRepo.getById('real-project-1'), isNotNull);
    });

    test('does not touch the global todoTemplates box', () async {
      final templatesBox = await Hive.openBox<TodoTemplate>('todoTemplates');
      final template = TodoTemplate(
        id: 'real-template-1',
        name: 'My Real Template',
        items: const ['Step 1', 'Step 2'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await templatesBox.put(template.id, template);

      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
      );

      expect(templatesBox.length, 1);
      expect(templatesBox.get('real-template-1')?.name, 'My Real Template');
    });
  });

  group('DemoDataService.remove', () {
    test('returns false when no demo profile exists', () async {
      final removed = await DemoDataService().remove(profileRepo);
      expect(removed, isFalse);
    });

    test('deletes the demo profile entirely when another profile exists', () async {
      await profileRepo.createProfile('Real Profile');
      final demoProfile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
      );

      final removed = await DemoDataService().remove(profileRepo);

      expect(removed, isTrue);
      expect(profileRepo.getAllProfiles().any((p) => p.id == demoProfile.id), isFalse);
      expect(profileRepo.getAllProfiles().length, 1);
    });

    test('empties but keeps the demo profile when it is the only profile', () async {
      final demoProfile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
      );

      final removed = await DemoDataService().remove(profileRepo);

      expect(removed, isTrue);
      expect(profileRepo.getAllProfiles().length, 1);
      final projects = await Hive.openBox<MusicProject>('${demoProfile.id}_projects');
      expect(projects, isEmpty);
    });

    test('deletes generated preview audio files from disk', () async {
      await profileRepo.createProfile('Real Profile');
      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
      );
      final previewDir = Directory(p.join(tempDir.path, 'previews'));
      final filesBefore = previewDir.listSync().whereType<File>().toList();
      expect(filesBefore, isNotEmpty);

      await DemoDataService().remove(profileRepo);

      final filesAfter = previewDir.listSync().whereType<File>().toList();
      expect(filesAfter, isEmpty);
    });

    test('does not touch a separate profile\'s real project data', () async {
      final realRepo = await HiveTestHelper.createRepository(profileId: 'real-user-profile');
      final realProject = TestFactories.makeProject(id: 'real-project-1');
      await realRepo.projectsBox.put(realProject.id, realProject);
      await profileRepo.createProfile('Real Profile');

      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
      );
      await DemoDataService().remove(profileRepo);

      expect(realRepo.projectsBox.length, 1);
      expect(realRepo.getById('real-project-1'), isNotNull);
    });
  });
}
