import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:daw_project_manager/models/music_project.dart';
import 'package:daw_project_manager/models/project_event.dart';
import 'package:daw_project_manager/models/project_template.dart';
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

  Future<String> fakeDemoFilesPath() async {
    final dir = Directory(p.join(tempDir.path, 'demo_projects'));
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
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      expect(profile.name, DemoDataService.demoProfileName);
      // Plus the two lighter-weight secondary demo profiles (see
      // DemoDataService._secondaryDemoProfileNames), used to give the
      // Profile Manager more than one profile to show in screenshots.
      expect(profileRepo.getAllProfiles().length, 3);
    });

    test('running twice reuses the same profile and does not duplicate data', () async {
      final first = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final firstProjects = await Hive.openBox<MusicProject>('${first.id}_projects');
      final firstCount = firstProjects.length;
      await firstProjects.close();

      final second = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      expect(second.id, first.id);
      expect(profileRepo.getAllProfiles().length, 3);

      final secondProjects = await Hive.openBox<MusicProject>('${second.id}_projects');
      expect(secondProjects.length, firstCount);
    });

    test('spans every supported DAW type and every canonical status', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final projects = await Hive.openBox<MusicProject>('${profile.id}_projects');

      final dawTypes = projects.values.map((p) => p.dawType).toSet();
      final statuses = projects.values.map((p) => p.status).toSet();

      expect(
        dawTypes,
        {
          'Ableton Live', 'Bitwig Studio', 'Cubase', 'FL Studio', 'Logic Pro',
          'Maschine', 'MAGDA', 'Nuendo', 'Pro Tools', 'Reaper', 'Sonar',
          'Studio One', 'Waveform', 'LUNA',
          'Ardour', 'GarageBand', 'Renoise', 'LMMS', 'Audacity', 'Qtractor',
          'Rosegarden', 'Reason', 'Digital Performer', 'Adobe Audition',
          'Samplitude / Sequoia', 'ACID Pro', 'Mixcraft',
        },
      );
      expect(statuses, {'Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'});
    });

    test('every project has a real placeholder on disk at its filePath', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final projects = await Hive.openBox<MusicProject>('${profile.id}_projects');

      for (final project in projects.values) {
        final existsAsFile = File(project.filePath).existsSync();
        final existsAsDirectory = Directory(project.filePath).existsSync();
        expect(existsAsFile || existsAsDirectory, isTrue,
            reason: '${project.filePath} should exist on disk');
      }
    });

    test('package-bundle DAWs (Logic Pro, LUNA, GarageBand) get a real directory, not a file', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final projects = await Hive.openBox<MusicProject>('${profile.id}_projects');

      final bundleProjects = projects.values
          .where((p) => p.fileExtension == '.logicx' || p.fileExtension == '.luna' || p.fileExtension == '.band');
      expect(bundleProjects, isNotEmpty);
      for (final project in bundleProjects) {
        expect(Directory(project.filePath).existsSync(), isTrue,
            reason: '${project.filePath} (${project.fileExtension}) should be a directory');
        expect(File(project.filePath).existsSync(), isFalse);
      }

      final fileProjects = projects.values.where((p) => p.fileExtension == '.als');
      expect(fileProjects, isNotEmpty);
      for (final project in fileProjects) {
        expect(File(project.filePath).existsSync(), isTrue,
            reason: '${project.filePath} (${project.fileExtension}) should be a file');
      }
    });

    test('every release trackId resolves to a generated project', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
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
        demoFilesPathProvider: fakeDemoFilesPath,
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
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      expect(realRepo.projectsBox.length, 1);
      expect(realRepo.getById('real-project-1'), isNotNull);
    });

    test('adds demo-tagged entries to the global todoTemplates box without touching a real one', () async {
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
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      expect(templatesBox.get('real-template-1')?.name, 'My Real Template');
      final demoEntries = templatesBox.values.where((t) => t.name.startsWith('Demo — '));
      expect(demoEntries, isNotEmpty);
    });

    test('adds demo-tagged Project Templates with a real placeholder source folder', () async {
      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      final templatesBox = await Hive.openBox<ProjectTemplate>('projectTemplates');
      final demoTemplates = templatesBox.values.where((t) => t.name.startsWith('Demo — ')).toList();
      expect(demoTemplates, isNotEmpty);

      for (final template in demoTemplates) {
        expect(Directory(template.sourceFolderPath).existsSync(), isTrue);
        final mainFilePath = p.join(template.sourceFolderPath, template.mainFileRelativePath);
        final existsAsFile = File(mainFilePath).existsSync();
        final existsAsDirectory = Directory(mainFilePath).existsSync();
        expect(existsAsFile || existsAsDirectory, isTrue);
      }
    });

    test('main profile releases have artwork and attached files pointing to real placeholders', () async {
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final releases = await Hive.openBox<Release>('${profile.id}_releases');

      expect(releases.values, isNotEmpty);
      for (final release in releases.values) {
        expect(release.artworkImagePath, isNotNull);
        expect(File(release.artworkImagePath!).existsSync(), isTrue);
        expect(release.files, isNotEmpty);
        for (final file in release.files) {
          expect(File(file.filePath).existsSync(), isTrue);
        }
      }
    });

    test('release artwork is a real decodable 512x512 PNG, not just a file that exists', () async {
      // Regression coverage for the hand-rolled PNG encoder in
      // DemoDataService — a malformed chunk/CRC would make the file exist
      // on disk but fail to decode, showing a broken-image icon in
      // screenshots instead of real cover art.
      final profile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final releases = await Hive.openBox<Release>('${profile.id}_releases');
      final artworkPath = releases.values.first.artworkImagePath!;
      final bytes = await File(artworkPath).readAsBytes();

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      expect(frame.image.width, 512);
      expect(frame.image.height, 512);
    });

    test('creates the secondary demo profiles alongside the main one', () async {
      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      final names = profileRepo.getAllProfiles().map((p) => p.name).toSet();
      expect(names, {
        DemoDataService.demoProfileName,
        'Demo — Solo Artist',
        'Demo — Studio B',
      });
    });
  });

  group('DemoDataService.remove', () {
    test('returns false when no demo profile exists', () async {
      final removed = await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);
      expect(removed, isFalse);
    });

    test('deletes the demo profile entirely when another profile exists', () async {
      await profileRepo.createProfile('Real Profile');
      final demoProfile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      final removed = await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

      expect(removed, isTrue);
      expect(profileRepo.getAllProfiles().any((p) => p.id == demoProfile.id), isFalse);
      expect(profileRepo.getAllProfiles().length, 1);
    });

    test('empties but keeps the demo profile when it is the only profile', () async {
      final demoProfile = await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      final removed = await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

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
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final previewDir = Directory(p.join(tempDir.path, 'previews'));
      final filesBefore = previewDir.listSync().whereType<File>().toList();
      expect(filesBefore, isNotEmpty);

      await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

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
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

      expect(realRepo.projectsBox.length, 1);
      expect(realRepo.getById('real-project-1'), isNotNull);
    });

    test('deletes the placeholder project files/folders directory from disk', () async {
      await profileRepo.createProfile('Real Profile');
      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      final demoFilesDir = Directory(p.join(tempDir.path, 'demo_projects'));
      expect(demoFilesDir.existsSync(), isTrue);
      expect(demoFilesDir.listSync(), isNotEmpty);

      await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

      expect(demoFilesDir.existsSync(), isFalse);
    });

    test('deletes the secondary demo profiles too when another profile exists', () async {
      await profileRepo.createProfile('Real Profile');
      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

      final names = profileRepo.getAllProfiles().map((p) => p.name).toSet();
      expect(names, {'Real Profile'});
    });

    test('keeps exactly one demo profile (emptied) when demo profiles are the only ones', () async {
      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );

      await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

      expect(profileRepo.getAllProfiles().length, 1);
      expect(profileRepo.getAllProfiles().first.name, DemoDataService.demoProfileName);
    });

    test('removes demo-tagged template entries without touching a real one', () async {
      final todoBox = await Hive.openBox<TodoTemplate>('todoTemplates');
      final realTemplate = TodoTemplate(
        id: 'real-template-1',
        name: 'My Real Template',
        items: const ['Step 1'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await todoBox.put(realTemplate.id, realTemplate);

      await profileRepo.createProfile('Real Profile');
      await DemoDataService().generate(
        profileRepo,
        previewSongsPathProvider: fakePreviewSongsPath,
        demoFilesPathProvider: fakeDemoFilesPath,
      );
      expect(todoBox.values.any((t) => t.name.startsWith('Demo — ')), isTrue);

      await DemoDataService().remove(profileRepo, demoFilesPathProvider: fakeDemoFilesPath);

      expect(todoBox.values.any((t) => t.name.startsWith('Demo — ')), isFalse);
      expect(todoBox.get('real-template-1')?.name, 'My Real Template');
    });
  });
}
