import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'dart:convert';

import '../models/music_project.dart';
import '../models/pending_folder.dart';
import '../models/scan_root.dart';
import '../models/ignored_path.dart';
import '../models/release.dart';
import '../models/release_file.dart';
import '../models/todo_item.dart';
import '../models/todo_template.dart';
import '../models/playlist.dart';
import '../models/project_event.dart';
import '../services/metadata_extractor.dart';
import '../services/notification_background_service.dart';
import '../utils/app_paths.dart';
import 'profile_repository.dart';
import '../models/profile.dart';

class ProjectRepository {
  final String profileId;
  final Box<MusicProject> projectsBox;
  final Box<ScanRoot> rootsBox;
  final Box<IgnoredPath> ignoredPathsBox;
  final Box<Release> releasesBox;
  final Box<Playlist> playlistsBox;
  final Box<ProjectEvent> eventsBox;
  // Global (profile-agnostic) key-value settings box
  final Box<String> appSettingsBox;
  final _uuid = const Uuid();

  static const _keyCustomMixdownFolder = 'customMixdownFolder';
  static const _keyCustomMixdownFolders = 'customMixdownFolders';

  ProjectRepository({
    required this.profileId,
    required this.projectsBox,
    required this.rootsBox,
    required this.ignoredPathsBox,
    required this.releasesBox,
    required this.playlistsBox,
    required this.eventsBox,
    required this.appSettingsBox,
  });

  // Subfolder names (relative to each project's own folder) checked, in
  // order, before falling back to DAW-specific and generic defaults.
  List<String> getCustomMixdownFolders() {
    final raw = appSettingsBox.get(_keyCustomMixdownFolders);
    if (raw != null) {
      try {
        return List.unmodifiable((jsonDecode(raw) as List).cast<String>());
      } catch (_) {}
    }
    // Migrate the legacy single-folder key.
    final legacy = appSettingsBox.get(_keyCustomMixdownFolder);
    if (legacy != null && legacy.isNotEmpty) return [legacy];
    return const [];
  }

  Future<void> setCustomMixdownFolders(List<String> folders) async {
    final cleaned = folders
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) {
      await appSettingsBox.delete(_keyCustomMixdownFolders);
    } else {
      await appSettingsBox.put(_keyCustomMixdownFolders, jsonEncode(cleaned));
    }
  }

  // Custom Phases — ordered list of phase names, per-profile
  static const _defaultPhases = ['Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'];
  String get _customPhasesKey => '${profileId}_phases';

  List<String> getCustomPhases() {
    final raw = appSettingsBox.get(_customPhasesKey);
    if (raw == null) return List.unmodifiable(_defaultPhases);
    try {
      return List.unmodifiable((jsonDecode(raw) as List).cast<String>());
    } catch (_) {
      return List.unmodifiable(_defaultPhases);
    }
  }

  Future<void> setCustomPhases(List<String> phases) async =>
      appSettingsBox.put(_customPhasesKey, jsonEncode(phases));

  // Phase Colors — per-profile map of phase name → '#RRGGBB' hex string
  String get _phaseColorsKey => '${profileId}_phase_colors';

  Map<String, String> getPhaseColors() {
    final raw = appSettingsBox.get(_phaseColorsKey);
    if (raw == null) return const {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return const {};
    }
  }

  Future<void> setPhaseColors(Map<String, String> colors) async =>
      appSettingsBox.put(_phaseColorsKey, jsonEncode(colors));

  // Finished Phases — which phase names are treated as "done" for filters/stats
  String get _finishedPhasesKey => '${profileId}_finished_phases';

  Set<String> getFinishedPhases() {
    final raw = appSettingsBox.get(_finishedPhasesKey);
    if (raw != null) {
      try { return (jsonDecode(raw) as List).cast<String>().toSet(); }
      catch (_) {}
    }
    // Migrate legacy single-phase key
    final legacy = appSettingsBox.get('${profileId}_finished_phase');
    if (legacy != null) return {legacy};
    return {'Finished'};
  }

  Future<void> setFinishedPhases(Set<String> phases) async =>
      appSettingsBox.put(_finishedPhasesKey, jsonEncode(phases.toList()));

  Future<void> setFinishedPhase(String phase) async =>
      setFinishedPhases({phase});

  // Pending Folders — stored as JSON list in the per-profile app_settings slot
  String get _pendingFoldersKey => '${profileId}_pending_folders';

  List<PendingFolder> getPendingFolders() {
    final raw = appSettingsBox.get(_pendingFoldersKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => PendingFolder.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addPendingFolder(PendingFolder folder) async {
    final current = getPendingFolders()..removeWhere((f) => f.path == folder.path);
    current.add(folder);
    await appSettingsBox.put(_pendingFoldersKey, jsonEncode(current.map((f) => f.toJson()).toList()));
  }

  Future<void> removePendingFolder(String id) async {
    final current = getPendingFolders()..removeWhere((f) => f.id == id);
    await appSettingsBox.put(_pendingFoldersKey, jsonEncode(current.map((f) => f.toJson()).toList()));
  }

  Future<void> updatePendingFolder(PendingFolder folder) async {
    final current = getPendingFolders()..removeWhere((f) => f.id == folder.id);
    current.add(folder);
    await appSettingsBox.put(_pendingFoldersKey, jsonEncode(current.map((f) => f.toJson()).toList()));
  }

  /// Removes pending folders that now contain a real DAW project file, or whose
  /// folder no longer exists on disk. Returns the removed IDs.
  Future<List<String>> resolveCompletedPendingFolders() async {
    final current = getPendingFolders();
    final toRemove = current
        .where((pf) => !pf.folderExists || pf.hasProjectFile())
        .map((pf) => pf.id)
        .toList();
    if (toRemove.isNotEmpty) {
      final remaining = current.where((f) => !toRemove.contains(f.id)).toList();
      await appSettingsBox.put(_pendingFoldersKey, jsonEncode(remaining.map((f) => f.toJson()).toList()));
    }
    return toRemove;
  }

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
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ProjectEventAdapter());
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
    final events = await Hive.openBox<ProjectEvent>('${profileId}_events');
    final appSettings = await Hive.openBox<String>('app_settings');

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
      eventsBox: events,
      appSettingsBox: appSettings,
    );
  }

  /// Reinitialize with a different profile
  static Future<ProjectRepository> initWithProfile(ProfileRepository profileRepo, String profileId) async {
    // Ensure Hive is initialized (only once)
    await ensureHiveInitialized();

    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ProjectEventAdapter());
    }

    // Use profile-specific box names
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

  Future<void> updateRootScanDepth(String rootId, int depth) async {
    final root = rootsBox.get(rootId);
    if (root != null) {
      await rootsBox.put(rootId, root.copyWith(scanDepth: depth));
    }
  }

  /// Permanently deletes [projectIds] and all their data (notes, deadlines,
  /// session/timer history, etc.) — irreversible. Scans never call this on
  /// their own (see `upsertFromFileSystemEntity`): a project whose file goes
  /// missing just stays in the list flagged missing (a live filesystem
  /// check, done in the UI) until the user explicitly deletes it, e.g. via
  /// the "Delete Missing" bulk action.
  Future<void> deleteProjectsPermanently(Iterable<String> projectIds) async {
    await projectsBox.deleteAll(projectIds);
  }

  List<ScanRoot> getRoots() => rootsBox.values.toList(growable: false);

  /// Updates the stored path for a scan root and rewrites the `filePath`,
  /// `previewSongPath`, and `previewSongAutoPath` of every project whose path
  /// starts with the old root path. No files are moved on disk.
  /// Returns the number of projects whose paths were updated.
  Future<int> relocateRoot(String rootId, String newPath) async {
    final root = rootsBox.get(rootId);
    if (root == null) return 0;

    final oldPath = p.normalize(root.path);
    final newNorm = p.normalize(newPath);
    final oldPrefix = oldPath.endsWith(p.separator) ? oldPath : oldPath + p.separator;
    final newPrefix = newNorm.endsWith(p.separator) ? newNorm : newNorm + p.separator;

    String repath(String src) {
      final norm = p.normalize(src);
      if (norm.startsWith(oldPrefix)) { return newPrefix + norm.substring(oldPrefix.length); }
      if (norm == oldPath) { return newNorm; }
      return src;
    }

    // Update the root itself
    await rootsBox.put(rootId, root.copyWith(path: newNorm));

    int count = 0;
    for (final project in projectsBox.values.toList()) {
      if (!p.normalize(project.filePath).startsWith(oldPrefix) &&
          p.normalize(project.filePath) != oldPath) { continue; }

      final updated = project.copyWith(
        filePath: repath(project.filePath),
        fileName: p.basename(repath(project.filePath)),
        previewSongPath: project.previewSongPath != null ? repath(project.previewSongPath!) : null,
        previewSongAutoPath: project.previewSongAutoPath != null ? repath(project.previewSongAutoPath!) : null,
      );
      await projectsBox.put(updated.id, updated);
      count++;
    }
    return count;
  }

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
  MusicProject? getById(String id) => projectsBox.get(id);

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
  Future<void> upsertFromFileSystemEntity(FileSystemEntity entity, {bool fullMetadata = false, String? parentProjectId}) async {
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
      previewSongAutoPath: existing?.previewSongAutoPath, // <--- PRESERVA AUTO-DETECTED PATH
      fileCreatedAt: fileCreatedAt,                   // <--- FILE CREATION DATE (never override once set)
      statusChangedAt: existing?.statusChangedAt,     // <--- PRESERVA STATUS CHANGE DATE
      deadline: existing?.deadline,                   // <--- PRESERVA DEADLINE
      parentProjectId: parentProjectId ?? existing?.parentProjectId,
      totalWorkSeconds: existing?.totalWorkSeconds ?? 0, // <--- CRITICAL: PRESERVA SESSION TIME
      sessions: existing?.sessions ?? const [],          // <--- CRITICAL: PRESERVA SESSION HISTORY
      metadataScanned: fullMetadata ? true : (existing?.metadataScanned ?? false),
    );

    await projectsBox.put(projectToSave.id, projectToSave);

    // Record a file_changed event if an existing project had its file mutated
    if (existing != null &&
        (existing.fileSizeBytes != size ||
            existing.lastModifiedAt != lastModified)) {
      final event = ProjectEvent(
        id: _uuid.v4(),
        projectId: projectToSave.id,
        eventType: ProjectEvent.fileChanged,
        occurredAt: DateTime.now(),
        payload: jsonEncode({
          'sizeChanged': existing.fileSizeBytes != size,
          'lastModifiedChanged': existing.lastModifiedAt != lastModified,
          'newSizeBytes': size,
        }),
      );
      await eventsBox.put(event.id, event);
    }
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

  /// Saves a project exactly as-is, preserving all dates.
  /// Use this for backup/sync restore, NOT for user-initiated edits.
  Future<void> restoreProject(MusicProject project) async {
    await projectsBox.put(project.id, project);
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

  // --- Event methods ---

  Future<void> addEvent(ProjectEvent event) async {
    await eventsBox.put(event.id, event);
  }

  List<ProjectEvent> getEventsForProject(String projectId) {
    return eventsBox.values
        .where((e) => e.projectId == projectId)
        .toList(growable: false)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  List<ProjectEvent> getAllEvents() => eventsBox.values.toList(growable: false);

  Stream<BoxEvent> watchEvents() => eventsBox.watch();

  Future<void> clearEventsForProject(String projectId) async {
    final keys = eventsBox.values
        .where((e) => e.projectId == projectId)
        .map((e) => e.id)
        .toList(growable: false);
    await eventsBox.deleteAll(keys);
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

    // Clear event log
    await eventsBox.clear();
  }

  /// Wipes every Hive box across all profiles and all global settings,
  /// leaving the app in a clean first-launch state with a fresh default profile.
  static Future<void> deleteAllAppData() async {
    // Collect profile IDs while boxes are still open (avoids type-mismatch
    // errors from trying to reopen a typed box as Box<dynamic>).
    final List<String> profileIds;
    if (Hive.isBoxOpen(ProfileRepository.profilesBoxName)) {
      profileIds = Hive.box<Profile>(ProfileRepository.profilesBoxName)
          .keys.cast<String>().toList();
    } else {
      final box = await Hive.openBox<Profile>(ProfileRepository.profilesBoxName);
      profileIds = box.keys.cast<String>().toList();
    }

    // Close every open box so we can re-open them without type conflicts.
    await Hive.close();

    // Clear per-profile boxes.
    const perProfileBoxes = [
      'projects', 'roots', 'ignored_paths', 'releases', 'playlists', 'events',
    ];
    for (final profileId in profileIds) {
      for (final suffix in perProfileBoxes) {
        try {
          final box = await Hive.openBox<dynamic>('${profileId}_$suffix');
          await box.clear();
          await box.close();
        } catch (_) {}
      }
    }

    // Clear global boxes.
    const globalBoxNames = [
      'settings', 'app_settings', 'notification_preferences',
      'todoTemplates', 'profiles', 'backup_timestamps',
      // Legacy / misc boxes.
      'music_projects', 'projects', 'releases', 'roots',
    ];
    for (final name in globalBoxNames) {
      try {
        final box = await Hive.openBox<dynamic>(name);
        await box.clear();
        await box.close();
      } catch (_) {}
    }

    // Delete locally downloaded preview song files.
    try {
      final previewSongsPath = await getPreviewSongsPath();
      final dir = Directory(previewSongsPath);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}

    // Re-initialize with a fresh default profile so the app starts cleanly.
    await ProfileRepository.init();
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
