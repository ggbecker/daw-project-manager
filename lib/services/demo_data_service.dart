import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../models/ignored_path.dart';
import '../models/music_project.dart';
import '../models/playlist.dart';
import '../models/profile.dart';
import '../models/project_event.dart';
import '../models/release.dart';
import '../models/scan_root.dart';
import '../models/todo_item.dart';
import '../repository/profile_repository.dart';
import '../repository/project_repository.dart';
import '../utils/app_paths.dart';

class _DawSpec {
  final String extension;
  final String dawType;
  final String dawVersion;
  const _DawSpec(this.extension, this.dawType, this.dawVersion);
}

/// Generates a large, varied catalog of fake projects/releases/playlists in a
/// dedicated Hive profile, so promotional screenshots never touch real user
/// data. Re-running [generate] reuses the same profile and replaces its
/// contents rather than accumulating duplicates.
class DemoDataService {
  static const demoProfileName = 'Demo — Screenshots';

  static const _daws = [
    _DawSpec('.als', 'Ableton Live', '11'),
    _DawSpec('.bwproject', 'Bitwig Studio', '5'),
    _DawSpec('.cpr', 'Cubase', '13'),
    _DawSpec('.flp', 'FL Studio', '21'),
    _DawSpec('.logicx', 'Logic Pro', '11'),
    _DawSpec('.maschine', 'Maschine', '2'),
    _DawSpec('.npr', 'Nuendo', '13'),
    _DawSpec('.ptx', 'Pro Tools', '2024'),
    _DawSpec('.rpp', 'Reaper', '7'),
    _DawSpec('.song', 'Studio One', '6'),
    _DawSpec('.tracktionedit', 'Waveform', '13'),
    _DawSpec('.luna', 'LUNA', '2'),
  ];

  static const _statuses = ['Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'];

  static const _trackNames = [
    'Midnight Dreams', 'Solar Flare', 'Neon Horizon', 'Velvet Storm', 'Glass City',
    'Afterglow', 'Paper Planes', 'Electric Bloom', 'Wildfire', 'Lost Signal',
    'Golden Hour', 'Static Rain', 'Northern Lights', 'Broken Mirror', 'Deep Water',
    'Chrome Heart', 'Fever Dream', 'Silver Lining', 'Ghost Town', 'Ultraviolet',
    'Slow Burn', 'Crystal Echo', 'Night Drive', 'Paradise Lost', 'Analog Sky',
    'Empty Room', 'Falling Stars', 'Copper Sun', 'Distant Shore', 'Static Bloom',
    'Winter Light', 'Reckless', 'Halcyon',
  ];

  static const _keys = [
    'C major', 'G major', 'D major', 'A major', 'E major', 'F major',
    'Bb major', 'Eb major', 'Am', 'Em', 'F#m', 'Bm', 'Dm', 'Gm', 'C#m',
  ];

  static const _notes = [
    'Deep house track with atmospheric pads. Working on the breakdown section.',
    'Upbeat tropical house track. Need to add more percussion elements.',
    'Aggressive techno track. Final mix completed.',
    'Experimental ambient piece with field recordings.',
    'Dubstep track with heavy bass drops.',
    'Relaxing downtempo track.',
    'Uplifting progressive house track.',
    'Melodic techno with a driving bassline.',
    'Chill lofi beat for late-night sessions.',
    'Drum and bass roller with a rolling sub.',
    'Cinematic trailer-style piece with big risers.',
    'Garage-influenced groove with a swung hi-hat.',
  ];

  static const _todoPool = [
    'Finish arrangement', 'Record vocals', 'Mixdown', 'Master track',
    'Add automation', 'Clean up low end', 'Sample clearance check',
    'Export stems', 'Send to collab for feedback', 'Design cover art',
    'Upload to distributor', 'Write track description', 'Check phase alignment',
    'Layer additional percussion', 'Sidechain the bass',
  ];

  static const _releaseTitles = [
    'Night Drive EP', 'Neon Collection', 'Afterglow Sessions',
    'Golden Hour Vol. 1', 'Deep Water Remixes',
  ];

  static const _playlistNames = ['Favorites', 'Late Night Session', 'Ready to Master'];

  // Pentatonic-scale frequencies (A2-D4) used to give each preview a distinct audible pitch.
  static const _previewFrequencies = [110.0, 130.8, 146.8, 164.8, 196.0, 220.0, 261.6, 293.7];

  final _uuid = const Uuid();
  final _random = Random(42);

  /// Creates (or reuses and clears) the demo profile, fills it with a varied
  /// catalog spanning every supported DAW and phase, and returns the profile.
  ///
  /// [previewSongsPathProvider] defaults to the real [getPreviewSongsPath]
  /// (which touches `path_provider`/the OS app-data dir); tests inject a
  /// provider that resolves inside their own temp directory instead.
  Future<Profile> generate(
    ProfileRepository profileRepo, {
    Future<String> Function() previewSongsPathProvider = getPreviewSongsPath,
  }) async {
    final existing = profileRepo
        .getAllProfiles()
        .where((p) => p.name == demoProfileName);
    final demoProfile = existing.isNotEmpty
        ? existing.first
        : await profileRepo.createProfile(demoProfileName);

    final repo = await _openRepository(demoProfile.id);

    await repo.projectsBox.clear();
    await repo.releasesBox.clear();
    await repo.playlistsBox.clear();
    await repo.eventsBox.clear();

    final now = DateTime.now();
    final previewSongsPath = await previewSongsPathProvider();

    const projectCount = 30;
    final projects = <MusicProject>[];

    for (var i = 0; i < projectCount; i++) {
      final daw = _daws[i % _daws.length];
      final statusIndex = i % _statuses.length;
      final status = _statuses[statusIndex];
      final name = _trackNames[i % _trackNames.length];

      final daysAgoCreated = (340 - i * 11).clamp(1, 340);
      final createdAt = now.subtract(Duration(days: daysAgoCreated));
      final daysAgoUpdated = (daysAgoCreated / 3).round().clamp(0, daysAgoCreated);
      final updatedAt = now.subtract(Duration(days: daysAgoUpdated));

      final numTodos = 2 + (i % 3);
      final completedCount = statusIndex == _statuses.length - 1
          ? numTodos
          : min(numTodos, statusIndex);
      final todos = List.generate(numTodos, (k) {
        final createdOffset = (updatedAt.difference(createdAt).inHours * (k + 1) / (numTodos + 1)).round();
        return TodoItem(
          id: _uuid.v4(),
          text: _todoPool[(i + k) % _todoPool.length],
          completed: k < completedCount,
          createdAt: createdAt.add(Duration(hours: createdOffset)),
        );
      });

      DateTime? deadline;
      if (i % 5 == 0) {
        deadline = now.subtract(Duration(days: 5 + i)); // overdue
      } else if (i % 5 == 2) {
        deadline = now.add(Duration(days: 5 + i)); // upcoming
      }

      final hidden = i % 8 == 5;
      final hasPreview = i % 2 == 0;
      final projectId = _uuid.v4();

      var project = MusicProject(
        id: projectId,
        filePath: '/Demo Projects/$name${daw.extension}',
        fileName: '$name${daw.extension}',
        fileSizeBytes: 3000000 + i * 250000,
        lastModifiedAt: updatedAt,
        fileExtension: daw.extension,
        createdAt: createdAt,
        updatedAt: updatedAt,
        customDisplayName: name,
        status: status,
        bpm: (70 + _random.nextInt(106)).toDouble(),
        musicalKey: _keys[i % _keys.length],
        notes: _notes[i % _notes.length],
        dawType: daw.dawType,
        dawVersion: daw.dawVersion,
        todos: todos,
        hidden: hidden,
        fileCreatedAt: createdAt,
        deadline: deadline,
        statusChangedAt: statusIndex == 0 ? null : updatedAt,
        totalWorkSeconds: (statusIndex + 1) * 3600 * (2 + i % 4),
      );

      if (hasPreview) {
        final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
        final previewFileName = 'demo_${i}_${safeName}_preview.wav';
        final previewFile = File(path.join(previewSongsPath, previewFileName));
        await previewFile.writeAsBytes(_generatePreviewWavBytes(
          frequencyHz: _previewFrequencies[i % _previewFrequencies.length],
        ));
        project = project.copyWith(
          previewSongPath: previewFile.path,
          previewSongFileName: previewFileName,
        );
      }

      await repo.projectsBox.put(projectId, project);
      projects.add(project);

      // Status-change events: walk Idea -> ... -> status, spaced across the project's lifetime.
      if (statusIndex > 0) {
        final span = updatedAt.difference(createdAt);
        for (var k = 0; k < statusIndex; k++) {
          final occurredAt = createdAt.add(span * ((k + 1) / statusIndex));
          await repo.addEvent(ProjectEvent(
            id: _uuid.v4(),
            projectId: projectId,
            eventType: ProjectEvent.statusChange,
            occurredAt: occurredAt,
            payload: jsonEncode({'from': _statuses[k], 'to': _statuses[k + 1]}),
          ));
        }
      }

      // A completed todo becomes a todoCompleted event for chart variety.
      TodoItem? firstCompleted;
      for (final t in todos) {
        if (t.completed) {
          firstCompleted = t;
          break;
        }
      }
      if (firstCompleted != null) {
        await repo.addEvent(ProjectEvent(
          id: _uuid.v4(),
          projectId: projectId,
          eventType: ProjectEvent.todoCompleted,
          occurredAt: updatedAt,
          payload: jsonEncode({'todoId': firstCompleted.id, 'todoText': firstCompleted.text}),
        ));
      }

      // A handful of metadata-edit events for chart variety.
      if (i % 3 == 0) {
        final midpoint = createdAt.add(updatedAt.difference(createdAt) ~/ 2);
        await repo.addEvent(ProjectEvent(
          id: _uuid.v4(),
          projectId: projectId,
          eventType: ProjectEvent.metadataEdit,
          occurredAt: midpoint,
          payload: jsonEncode({'fields': ['bpm', 'musicalKey']}),
        ));
      }
    }

    // Releases: group Mixing/Mastering/Finished projects.
    final releaseCandidates = projects.where((p) => p.status != 'Idea' && p.status != 'Arranging').toList();
    var candidateIndex = 0;
    for (var r = 0; r < _releaseTitles.length && candidateIndex < releaseCandidates.length; r++) {
      final trackIds = <String>[];
      for (var t = 0; t < 3 && candidateIndex < releaseCandidates.length; t++, candidateIndex++) {
        trackIds.add(releaseCandidates[candidateIndex].id);
      }
      if (trackIds.isEmpty) break;

      final releaseDate = r.isEven
          ? now.add(Duration(days: 20 + r * 10))
          : now.subtract(Duration(days: 20 + r * 10));

      final release = Release(
        id: _uuid.v4(),
        title: _releaseTitles[r],
        releaseDate: releaseDate,
        description: 'A curated collection of tracks for the "${_releaseTitles[r]}" release.',
        trackIds: trackIds,
        todos: [
          TodoItem(id: _uuid.v4(), text: 'Design cover art', completed: r.isOdd, createdAt: now),
          TodoItem(id: _uuid.v4(), text: 'Master all tracks', completed: false, createdAt: now),
          TodoItem(id: _uuid.v4(), text: 'Upload to streaming platforms', completed: false, createdAt: now),
        ],
      );
      await repo.releasesBox.put(release.id, release);
    }

    // Playlists: mixed subsets spanning different DAWs/statuses.
    for (var pl = 0; pl < _playlistNames.length; pl++) {
      final playlistProjects = [
        for (var i = pl; i < projects.length; i += _playlistNames.length) projects[i].id,
      ];
      final playlist = Playlist(
        id: _uuid.v4(),
        name: _playlistNames[pl],
        projectIds: playlistProjects,
        createdAt: now.subtract(Duration(days: 10 + pl)),
        updatedAt: now,
      );
      await repo.playlistsBox.put(playlist.id, playlist);
    }

    return demoProfile;
  }

  /// Deletes all generated preview audio files and empties the demo
  /// profile's boxes, then removes the profile itself (unless it's the
  /// user's only remaining profile, in which case it's just left empty —
  /// the app always requires at least one profile to exist).
  ///
  /// Returns `true` if a demo profile was found and removed, `false` if
  /// there was nothing to remove.
  Future<bool> remove(ProfileRepository profileRepo) async {
    final existing = profileRepo
        .getAllProfiles()
        .where((p) => p.name == demoProfileName);
    if (existing.isEmpty) return false;
    final demoProfile = existing.first;

    final repo = await _openRepository(demoProfile.id);

    for (final project in repo.projectsBox.values) {
      final previewPath = project.previewSongPath;
      if (previewPath != null && previewPath.isNotEmpty && !previewPath.startsWith('drive://')) {
        final file = File(previewPath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {
            // Non-critical — leftover preview files are harmless.
          }
        }
      }
    }

    // Clear (rather than close+delete from disk) — closing a box with
    // active stream watchers can deadlock on iOS with Hive CE (see the
    // same tradeoff documented in google_drive_sync_service.dart around
    // its profile-cleanup path). Empty box files left on disk are harmless.
    await repo.projectsBox.clear();
    await repo.releasesBox.clear();
    await repo.playlistsBox.clear();
    await repo.eventsBox.clear();
    await repo.rootsBox.clear();
    await repo.ignoredPathsBox.clear();

    if (profileRepo.getAllProfiles().length > 1) {
      await profileRepo.deleteProfile(demoProfile.id);
    }

    return true;
  }

  /// Opens the profile-scoped boxes directly, without going through
  /// [ProjectRepository.initWithProfile] — that factory calls
  /// `ensureHiveInitialized()`, which would re-point Hive at the real
  /// app-data directory when running under a test's isolated Hive instance.
  /// By the time this service runs (from the running app or from a test that
  /// has already called `Hive.init`), Hive is already initialized correctly,
  /// so opening boxes directly is both safe and test-friendly.
  Future<ProjectRepository> _openRepository(String profileId) async {
    final projects = await Hive.openBox<MusicProject>('${profileId}_projects');
    final roots = await Hive.openBox<ScanRoot>('${profileId}_roots');
    final ignoredPaths = await Hive.openBox<IgnoredPath>('${profileId}_ignored_paths');
    final releases = await Hive.openBox<Release>('${profileId}_releases');
    final playlists = await Hive.openBox<Playlist>('${profileId}_playlists');
    final events = await Hive.openBox<ProjectEvent>('${profileId}_events');
    final appSettings = await Hive.openBox<String>('app_settings');

    return ProjectRepository(
      profileId: profileId,
      projectsBox: projects,
      rootsBox: roots,
      ignoredPathsBox: ignoredPaths,
      releasesBox: releases,
      playlistsBox: playlists,
      eventsBox: events,
      appSettingsBox: appSettings,
    );
  }

  /// Generates a minimal valid mono PCM WAV with a sine wave tone and short fade in/out.
  static Uint8List _generatePreviewWavBytes({required double frequencyHz, int durationSeconds = 3}) {
    const sampleRate = 22050;
    const bitsPerSample = 16;
    final numSamples = sampleRate * durationSeconds;
    final dataSize = numSamples * 2;
    final buffer = ByteData(44 + dataSize);
    int o = 0;

    void ascii(String s) { for (final c in s.codeUnits) { buffer.setUint8(o++, c); } }
    void u16(int v) { buffer.setUint16(o, v, Endian.little); o += 2; }
    void u32(int v) { buffer.setUint32(o, v, Endian.little); o += 4; }

    ascii('RIFF'); u32(36 + dataSize); ascii('WAVE');
    ascii('fmt '); u32(16); u16(1); u16(1); u32(sampleRate); u32(sampleRate * 2); u16(2); u16(bitsPerSample);
    ascii('data'); u32(dataSize);

    const fadeLen = 2000;
    for (int i = 0; i < numSamples; i++) {
      final fade = (i < fadeLen)
          ? i / fadeLen
          : (i > numSamples - fadeLen)
              ? (numSamples - i) / fadeLen
              : 1.0;
      final sample = (sin(2 * pi * frequencyHz * i / sampleRate) * 12000 * fade)
          .round()
          .clamp(-32768, 32767);
      buffer.setInt16(o, sample, Endian.little);
      o += 2;
    }

    return buffer.buffer.asUint8List();
  }
}
