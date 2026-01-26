import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/music_project.dart';
import '../models/scan_root.dart';
import '../models/ignored_path.dart';
import '../models/release.dart';
import '../models/release_file.dart';
import '../models/todo_item.dart';
import '../models/todo_template.dart';
import '../models/playlist.dart';
import '../services/metadata_extractor.dart';
import '../services/deadline_notification_service.dart';
import '../services/notification_background_service.dart';
import '../utils/app_paths.dart';
import 'profile_repository.dart';

class ProjectRepository {
  final String profileId;
  final Box<MusicProject> projectsBox;
  final Box<ScanRoot> rootsBox;
  final Box<IgnoredPath> ignoredPathsBox;
  final Box<Release> releasesBox;
  final Box<Playlist> playlistsBox;
  final _uuid = const Uuid();

  ProjectRepository({
    required this.profileId,
    required this.projectsBox,
    required this.rootsBox,
    required this.ignoredPathsBox,
    required this.releasesBox,
    required this.playlistsBox,
  });

  static Future<ProjectRepository> init(ProfileRepository profileRepo) async {
    // Initialize Hive with LocalAppData directory (only once)
    await ensureHiveInitialized();
    
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MusicProjectAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ScanRootAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(IgnoredPathAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ReleaseAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ReleaseFileAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(TodoItemAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(PlaylistAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(TodoTemplateAdapter());
    }

    // Get current profile
    final currentProfile = profileRepo.getCurrentProfile();
    if (currentProfile == null) {
      throw Exception('No active profile found');
    }
    
    final profileId = currentProfile.id;
    
    // Use profile-specific box names
    final projects = await Hive.openBox<MusicProject>('${profileId}_projects');
    final roots = await Hive.openBox<ScanRoot>('${profileId}_roots');
    final ignoredPaths = await Hive.openBox<IgnoredPath>('${profileId}_ignored_paths');
    final releases = await Hive.openBox<Release>('${profileId}_releases');
    final playlists = await Hive.openBox<Playlist>('${profileId}_playlists');
    
    if (kDebugMode) {
      print('ProjectRepository.init: Opened boxes for profile $profileId');
      print('  Projects box: ${projects.length} projects');
    }
    
    return ProjectRepository(
      profileId: profileId,
      projectsBox: projects,
      rootsBox: roots,
      ignoredPathsBox: ignoredPaths,
      releasesBox: releases,
      playlistsBox: playlists,
    );
  }
  
  /// Reinitialize with a different profile
  static Future<ProjectRepository> initWithProfile(ProfileRepository profileRepo, String profileId) async {
    // Ensure Hive is initialized (only once)
    await ensureHiveInitialized();
    
    // Use profile-specific box names
    final projects = await Hive.openBox<MusicProject>('${profileId}_projects');
    final roots = await Hive.openBox<ScanRoot>('${profileId}_roots');
    final ignoredPaths = await Hive.openBox<IgnoredPath>('${profileId}_ignored_paths');
    final releases = await Hive.openBox<Release>('${profileId}_releases');
    final playlists = await Hive.openBox<Playlist>('${profileId}_playlists');
    
    return ProjectRepository(
      profileId: profileId,
      projectsBox: projects,
      rootsBox: roots,
      ignoredPathsBox: ignoredPaths,
      releasesBox: releases,
      playlistsBox: playlists,
    );
  }

  // Roots
  Future<void> addRoot(String path) async {
    final id = _uuid.v4();
    await rootsBox.put(id, ScanRoot(id: id, path: path, addedAt: DateTime.now()));
  }

  Future<void> removeRoot(String id) async {
    final root = rootsBox.get(id);
    if (root == null) return;
    
    // Get the root path and normalize it for comparison
    final rootPath = p.normalize(root.path);
    // Ensure root path ends with separator for proper matching
    final rootPathNormalized = rootPath.endsWith(p.separator) 
        ? rootPath 
        : rootPath + p.separator;
    
    // Get all project IDs that are referenced in releases (to preserve them)
    final releases = getAllReleases();
    final protectedProjectIds = <String>{};
    for (final release in releases) {
      protectedProjectIds.addAll(release.trackIds);
    }
    
    // Remove all projects that belong to this root folder
    // Note: projectsBox is already profile-specific, so we only operate on current profile's projects
    final projectsToDelete = <String>[];
    
    for (final project in projectsBox.values) {
      try {
        // Normalize project file path for comparison
        final projectPath = p.normalize(project.filePath);
        
        // Check if project's file path is within the root folder
        // This is safe because projectsBox is profile-specific (${profileId}_projects)
        if (projectPath.startsWith(rootPathNormalized) || 
            projectPath.startsWith(rootPath + p.separator)) {
          // Preserve projects that are referenced in releases
          if (!protectedProjectIds.contains(project.id)) {
            projectsToDelete.add(project.id);
          }
        }
      } catch (_) {
        // If path normalization fails, skip this project
        // Better to be safe and not delete than to delete incorrectly
      }
    }
    
    // Delete all projects from this root (except those in releases)
    if (projectsToDelete.isNotEmpty) {
      await projectsBox.deleteAll(projectsToDelete);
    }
    
    // Remove the root after deleting projects
    await rootsBox.delete(id);
  }

  Future<void> updateRootLastScanAt(String rootId, DateTime scanTime) async {
    final root = rootsBox.get(rootId);
    if (root != null) {
      await rootsBox.put(rootId, root.copyWith(lastScanAt: scanTime));
    }
  }

  List<ScanRoot> getRoots() => rootsBox.values.toList(growable: false);

  // Ignored paths (directories under roots that should not be scanned)
  Future<void> addIgnoredPath(String path) async {
    final id = _uuid.v4();
    final ignored = IgnoredPath(id: id, path: path, addedAt: DateTime.now());
    await ignoredPathsBox.put(id, ignored);

    // Also delete any already-indexed projects within this path (unless in releases).
    await _deleteProjectsUnderPathPrefix(path);
  }

  Future<void> removeIgnoredPath(String id) async {
    await ignoredPathsBox.delete(id);
  }

  List<IgnoredPath> getIgnoredPaths() => ignoredPathsBox.values.toList(growable: false);

  Stream<BoxEvent> watchIgnoredPaths() => ignoredPathsBox.watch();

  Future<void> _deleteProjectsUnderPathPrefix(String basePath) async {
    // Get all project IDs that are referenced in releases (to preserve them)
    final releases = getAllReleases();
    final protectedProjectIds = <String>{};
    for (final release in releases) {
      protectedProjectIds.addAll(release.trackIds);
    }

    final rootPath = p.normalize(basePath);
    final rootPathNormalized =
        rootPath.endsWith(p.separator) ? rootPath : rootPath + p.separator;

    final projectsToDelete = <String>[];
    for (final project in projectsBox.values) {
      try {
        final projectPath = p.normalize(project.filePath);
        if (projectPath.startsWith(rootPathNormalized) ||
            projectPath.startsWith(rootPath + p.separator)) {
          if (!protectedProjectIds.contains(project.id)) {
            projectsToDelete.add(project.id);
          }
        }
      } catch (_) {
        // Skip on path errors (safer to not delete).
      }
    }

    if (projectsToDelete.isNotEmpty) {
      await projectsBox.deleteAll(projectsToDelete);
    }
  }

  // Projects
  MusicProject? getByPath(String path) {
    try {
      return projectsBox.values.firstWhere((p) => p.filePath == path);
    } catch (_) {
      return null;
    }
  }

  // LÓGICA CORRIGIDA para preservar campos customizados
  /// Upserts a project from a file system entity
  /// [fullMetadata] if true, extracts full metadata (BPM, key, DAW version) - slower
  /// if false, only extracts DAW type from extension - faster
  Future<void> upsertFromFileSystemEntity(FileSystemEntity entity, {bool fullMetadata = false}) async {
    final isLogicBundle = entity is Directory && entity.path.toLowerCase().endsWith('.logicx');
    final filePath = entity.path;
    final stat = await entity.stat();
    final fileName = p.basename(filePath);
    final ext = isLogicBundle ? '.logicx' : p.extension(filePath).toLowerCase();
    final size = stat.size;
    final lastModified = stat.modified;

    final existing = getByPath(filePath);
    
    // Extract metadata from project file
    ProjectMetadata? extractedMetadata;
    try {
      if (fullMetadata) {
        extractedMetadata = await MetadataExtractor.extractMetadata(filePath);
      } else {
        extractedMetadata = await MetadataExtractor.extractLightweightMetadata(filePath);
      }
    } catch (_) {
      // If extraction fails, continue without metadata
    }
    
    // Always update BPM and key from file if available (these can change in the project)
    // Fall back to existing values only if extraction didn't find anything
    final bpm = extractedMetadata?.bpm ?? existing?.bpm;
    final key = extractedMetadata?.key ?? existing?.musicalKey;
    
    // Determine DAW type: always update from file (based on extension)
    final dawType = extractedMetadata?.dawType;
    // Preserve existing DAW version if extraction didn't find anything (e.g., during lightweight scan)
    final dawVersion = extractedMetadata?.dawVersion ?? existing?.dawVersion;
    
    // Detect file creation date from filesystem
    // On Windows, stat.changed is the creation time
    // On other platforms, we fall back to lastModified as an approximation
    // IMPORTANT: Once fileCreatedAt is set, it should NEVER be overridden
    DateTime? fileCreatedAt = existing?.fileCreatedAt;
    if (fileCreatedAt == null) {
      // Try to get file creation time
      // On Windows, stat.changed returns file creation time
      // On Unix-like systems, it returns inode change time (not creation)
      // We use stat.changed on Windows, otherwise fall back to lastModified
      if (Platform.isWindows) {
        fileCreatedAt = stat.changed;
      } else {
        // On macOS/Linux, use the earlier of modified and changed times
        // as a best approximation of creation time
        fileCreatedAt = stat.changed.isBefore(stat.modified) ? stat.changed : stat.modified;
      }
    }
    
    // Cria o objeto base, usando os dados existentes se houver, 
    // mas atualizando os campos que vêm do sistema de arquivos (size, lastModified, fileName, etc.)
    final projectToSave = MusicProject(
      id: existing?.id ?? _uuid.v4(),
      filePath: filePath,
      fileName: fileName,
      fileSizeBytes: size,
      lastModifiedAt: lastModified,
      fileExtension: ext,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      
      // PRESERVAÇÃO: Estes campos foram editados pelo usuário e devem ser mantidos
      customDisplayName: existing?.customDisplayName, // <--- PRESERVA
      status: existing?.status ?? 'Idea',             // <--- PRESERVA (default changed from 'Draft' to 'Idea')
      bpm: bpm,                                        // <--- USA EXISTENTE OU EXTRAÍDO
      musicalKey: key,                                 // <--- USA EXISTENTE OU EXTRAÍDO
      notes: existing?.notes,                         // <--- NOVO: PRESERVA NOTAS
      todos: existing?.todos ?? const [],             // <--- CRITICAL: PRESERVA TODOS
      hidden: existing?.hidden ?? false,               // <--- CRITICAL: PRESERVA HIDDEN STATUS
      dawType: dawType,                                // <--- SEMPRE ATUALIZA DO ARQUIVO
      dawVersion: dawVersion,                          // <--- USA EXISTENTE OU EXTRAÍDO (preserva se já existe)
      previewSongPath: existing?.previewSongPath,     // <--- PRESERVA PREVIEW SONG
      previewSongFileName: existing?.previewSongFileName, // <--- PRESERVA PREVIEW SONG FILENAME
      uploadedPreviewSongHash: existing?.uploadedPreviewSongHash, // <--- PRESERVA PREVIEW SONG HASH
      fileCreatedAt: fileCreatedAt,                   // <--- FILE CREATION DATE (never override once set)
      statusChangedAt: existing?.statusChangedAt,     // <--- PRESERVA STATUS CHANGE DATE
      deadline: existing?.deadline,                   // <--- PRESERVA DEADLINE
    );

    await projectsBox.put(projectToSave.id, projectToSave);
  }

  List<MusicProject> getAllProjects() => projectsBox.values.toList(growable: false);

  Future<void> updateProject(MusicProject project) async {
    final updatedProject = project.copyWith(updatedAt: DateTime.now());
    await projectsBox.put(updatedProject.id, updatedProject);
    
    // Reschedule notifications if on Android and deadline changed
    if (Platform.isAndroid) {
      try {
        await NotificationBackgroundService.triggerCheck();
      } catch (e) {
        if (kDebugMode) print('Error rescheduling notifications: $e');
      }
    }
  }

  /// Extracts full metadata for a single project and updates it
  Future<void> extractFullMetadataForProject(String projectId) async {
    final project = projectsBox.get(projectId);
    if (project == null) return;

    try {
      final extractedMetadata = await MetadataExtractor.extractMetadata(project.filePath);
      
      // Update project with extracted metadata, preserving existing values if extraction didn't find anything
      final updated = project.copyWith(
        bpm: extractedMetadata.bpm ?? project.bpm,
        musicalKey: extractedMetadata.key ?? project.musicalKey,
        dawType: extractedMetadata.dawType ?? project.dawType,
        dawVersion: extractedMetadata.dawVersion ?? project.dawVersion,
        updatedAt: DateTime.now(),
      );
      
      await projectsBox.put(projectId, updated);
    } catch (_) {
      // If extraction fails, silently continue
    }
  }

  // Reactive listeners
  ValueListenable<Box<MusicProject>> projectsListenable() => projectsBox.listenable();
  ValueListenable<Box<ScanRoot>> rootsListenable() => rootsBox.listenable();

  // Stream watch for Riverpod StreamProvider usage
  Stream<BoxEvent> watchProjects() => projectsBox.watch();
  
  // MÉTODO NOVO/CORRIGIDO: Retorna a lista completa a cada mudança do Hive
  Stream<List<MusicProject>> watchAllProjects() async* {
    // Emit initial value immediately
    final initialProjects = projectsBox.values.toList();
    if (kDebugMode) {
      print('watchAllProjects: Emitting initial ${initialProjects.length} projects for profile $profileId');
    }
    yield initialProjects;
    
    // Then watch for changes - this will emit whenever ANY project is added/updated/deleted
    yield* projectsBox.watch().map((event) {
      final projects = projectsBox.values.toList();
    if (kDebugMode) {
      print('watchAllProjects: Box changed, emitting ${projects.length} projects for profile $profileId');
    }
      return projects;
    });
  }
  
  Stream<BoxEvent> watchRoots() => rootsBox.watch();

  Future<void> clearAllData() async {
    // Get all project IDs that are referenced in releases (to preserve them)
    final releases = getAllReleases();
    final protectedProjectIds = <String>{};
    for (final release in releases) {
      protectedProjectIds.addAll(release.trackIds);
    }
    
    // Delete all projects except those referenced in releases
    if (protectedProjectIds.isNotEmpty) {
      final allProjectIds = projectsBox.keys.cast<String>().toSet();
      final projectsToDelete = allProjectIds.difference(protectedProjectIds);
      if (projectsToDelete.isNotEmpty) {
        await projectsBox.deleteAll(projectsToDelete);
      }
    } else {
      // No protected projects, safe to clear all
      await projectsBox.clear();
    }
    
    // Always clear roots
    await rootsBox.clear();

    // Clear ignored paths
    await ignoredPathsBox.clear();
  }

  Future<void> clearMissingFiles() async {
    // On Android, we're only syncing metadata from desktop, so files don't exist locally
    // Don't delete projects on Android - they're metadata-only
    if (Platform.isAndroid) {
      if (kDebugMode) {
        print('clearMissingFiles: Skipping on Android (metadata-only mode)');
      }
      return;
    }
    
    final toDelete = <dynamic>[];
    for (final entry in projectsBox.values) {
      if (!File(entry.filePath).existsSync() && !Directory(entry.filePath).existsSync()) {
        toDelete.add(entry.id);
      }
    }
    await projectsBox.deleteAll(toDelete);
  }

  // Releases
  Future<void> addRelease(Release release) async {
    await releasesBox.put(release.id, release);
  }

  Future<void> updateRelease(Release release) async {
    await releasesBox.put(release.id, release);
  }

  Future<void> deleteRelease(String releaseId) async {
    await releasesBox.delete(releaseId);
  }

  List<Release> getAllReleases() => releasesBox.values.toList(growable: false);

  Release? getReleaseById(String id) {
    try {
      return releasesBox.get(id);
    } catch (_) {
      return null;
    }
  }

  Stream<List<Release>> watchAllReleases() async* {
    // Emit initial value immediately
    yield releasesBox.values.toList();
    // Then watch for changes
    yield* releasesBox.watch().map((_) => releasesBox.values.toList());
  }

  Stream<BoxEvent> watchReleases() => releasesBox.watch();

  // Playlists
  Future<Playlist> createPlaylist(String name, {List<String>? projectIds, List<String>? audioFilePaths}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final playlist = Playlist(
      id: id,
      name: name,
      projectIds: projectIds ?? [],
      audioFilePaths: audioFilePaths ?? [],
      createdAt: now,
      updatedAt: now,
    );
    await playlistsBox.put(id, playlist);
    return playlist;
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    final updated = playlist.copyWith(updatedAt: DateTime.now());
    await playlistsBox.put(playlist.id, updated);
  }

  Future<void> deletePlaylist(String id) async {
    await playlistsBox.delete(id);
  }

  List<Playlist> getAllPlaylists() => playlistsBox.values.toList(growable: false);

  Playlist? getPlaylistById(String id) {
    try {
      return playlistsBox.get(id);
    } catch (_) {
      return null;
    }
  }

  Stream<List<Playlist>> watchAllPlaylists() async* {
    // Emit initial value immediately
    yield playlistsBox.values.toList();
    // Then watch for changes
    yield* playlistsBox.watch().map((_) => playlistsBox.values.toList());
  }

  ValueListenable<Box<Playlist>> playlistsListenable() => playlistsBox.listenable();
}
