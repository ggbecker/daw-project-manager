import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:audio_service/audio_service.dart' show MediaItem;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../utils/app_paths.dart';
import '../utils/mobile_utils.dart';
import '../utils/phase_colors.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart';
import '../services/audio_analysis_service.dart';
import '../services/waveform_disk_cache.dart';
import '../models/scan_root.dart';
import '../models/ignored_path.dart';
import '../models/release.dart';
import '../models/profile.dart';
import '../models/playlist.dart';
import '../models/todo_template.dart';
import '../models/project_event.dart';
import '../repository/project_repository.dart';
import '../utils/search_utils.dart';
import '../repository/profile_repository.dart';
import '../services/google_drive_sync_service.dart';
import '../services/deadline_notification_service.dart';
import '../models/auto_backup_interval.dart';
import '../models/pending_folder.dart';

// Profile Repository Provider
final profileRepositoryProvider = FutureProvider<ProfileRepository>((ref) async {
  return ProfileRepository.init();
});

// Current Profile Provider
final currentProfileProvider = StreamProvider<Profile?>((ref) async* {
  final profileRepo = await ref.watch(profileRepositoryProvider.future);
  final currentId = profileRepo.getCurrentProfileId();
  if (currentId != null) {
    yield profileRepo.getProfileById(currentId);
  } else {
    yield null;
  }
  
  // Watch for profile changes
  yield* profileRepo.watchProfiles().asyncMap((_) async {
    final currentId = profileRepo.getCurrentProfileId();
    return currentId != null ? profileRepo.getProfileById(currentId) : null;
  });
});

// All Profiles Provider
final allProfilesProvider = StreamProvider<List<Profile>>((ref) async* {
  final profileRepo = await ref.watch(profileRepositoryProvider.future);
  yield* profileRepo.watchAllProfiles();
});

// Project Repository Provider - depends on ProfileRepository and current profile
final repositoryProvider = FutureProvider<ProjectRepository>((ref) async {
  final profileRepo = await ref.watch(profileRepositoryProvider.future);
  // Watch current profile to invalidate when profile changes
  final currentProfile = await ref.watch(currentProfileProvider.future);
  if (currentProfile == null) {
    throw Exception('No active profile found');
  }
  return ProjectRepository.init(profileRepo);
});

final customMixdownFoldersProvider = FutureProvider<List<String>>((ref) async {
  final repo = await ref.watch(repositoryProvider.future);
  return repo.getCustomMixdownFolders();
});

final rootsWatchProvider = StreamProvider<void>((ref) async* {
  final repo = await ref.watch(repositoryProvider.future);
  yield* repo.watchRoots().map((_) {});
});

final scanRootsProvider = Provider<List<ScanRoot>>((ref) {
  // Rebuild when roots box changes
  ref.watch(rootsWatchProvider);
  final repoAsync = ref.watch(repositoryProvider);
  return repoAsync.maybeWhen(
    data: (repo) => repo.getRoots(),
    orElse: () => const <ScanRoot>[],
  );
});

final ignoredPathsWatchProvider = StreamProvider<void>((ref) async* {
  final repo = await ref.watch(repositoryProvider.future);
  yield* repo.watchIgnoredPaths().map((_) {});
});

final ignoredPathsProvider = Provider<List<IgnoredPath>>((ref) {
  // Rebuild when ignored paths box changes
  ref.watch(ignoredPathsWatchProvider);
  final repoAsync = ref.watch(repositoryProvider);
  return repoAsync.maybeWhen(
    data: (repo) => repo.getIgnoredPaths(),
    orElse: () => const <IgnoredPath>[],
  );
});

// scanning state is managed in UI now

class QueryParams {
  final String searchText;
  final bool sortDesc;
  const QueryParams({this.searchText = '', this.sortDesc = true});
  
  // Adiciona o método copyWith para facilitar a atualização
  QueryParams copyWith({
    String? searchText,
    bool? sortDesc,
  }) {
    return QueryParams(
      searchText: searchText ?? this.searchText,
      sortDesc: sortDesc ?? this.sortDesc,
    );
  }
}

// CORREÇÃO ESSENCIAL PARA RIVERPOD V3: Usa Notifier<T> (em vez de StateNotifier<T>)
class QueryParamsNotifier extends Notifier<QueryParams> {
  
  // CORREÇÃO ESSENCIAL PARA RIVERPOD V3: O construtor v3 é o método build()
  @override
  QueryParams build() {
    return const QueryParams();
  }

  void setSearchText(String text) {
    state = state.copyWith(searchText: text);
  }

  void toggleSortDesc() {
    state = state.copyWith(sortDesc: !state.sortDesc);
  }
}

// CORREÇÃO ESSENCIAL PARA RIVERPOD V3: Usa NotifierProvider (em vez de StateNotifierProvider)
final queryParamsNotifierProvider = NotifierProvider<QueryParamsNotifier, QueryParams>(() {
  return QueryParamsNotifier();
});

// Separate search providers for Projects and Releases tabs
class ProjectsSearchNotifier extends Notifier<String> {
  @override
  String build() {
    return '';
  }

  void setSearchText(String text) {
    state = text;
  }

  void clear() {
    state = '';
  }
}

final projectsSearchProvider = NotifierProvider<ProjectsSearchNotifier, String>(() {
  return ProjectsSearchNotifier();
});

class ReleasesSearchNotifier extends Notifier<String> {
  @override
  String build() {
    return '';
  }

  void setSearchText(String text) {
    state = text;
  }

  void clear() {
    state = '';
  }
}

final releasesSearchProvider = NotifierProvider<ReleasesSearchNotifier, String>(() {
  return ReleasesSearchNotifier();
});

enum ReleasesSort { dateDesc, dateAsc, titleAsc, titleDesc }

class ReleasesSortNotifier extends Notifier<ReleasesSort> {
  @override
  ReleasesSort build() => ReleasesSort.dateDesc;

  void setSort(ReleasesSort sort) => state = sort;
}

final releasesSortProvider = NotifierProvider<ReleasesSortNotifier, ReleasesSort>(() {
  return ReleasesSortNotifier();
});

class PlaylistsSearchNotifier extends Notifier<String> {
  @override
  String build() {
    return '';
  }

  void setSearchText(String text) {
    state = text;
  }

  void clear() {
    state = '';
  }
}

final playlistsSearchProvider = NotifierProvider<PlaylistsSearchNotifier, String>(() {
  return PlaylistsSearchNotifier();
});

// Show hidden projects state provider
// 0 = show only visible (default)
// 1 = show all (visible + hidden)
// 2 = show only hidden
//
// Intentionally session-only (not persisted to Hive). This used to be saved
// across restarts, but "show only hidden" filters out every normal project —
// leaving it on from a forgotten earlier session (or, since the underlying
// key wasn't profile-scoped, a *different* profile) made the whole project
// list silently disappear on next launch with no obvious cause.
class ShowHiddenProjectsNotifier extends Notifier<int> {
  @override
  int build() => 0; // Always starts showing only visible projects.

  void setShowAll(bool show) {
    state = show ? 1 : 0;
  }

  void setShowOnlyHidden(bool show) {
    state = show ? 2 : 0;
  }

  bool get isShowingAll => state == 1;
  bool get isShowingOnlyHidden => state == 2;
  bool get isShowingVisible => state == 0;
}

final showHiddenProjectsProvider = NotifierProvider<ShowHiddenProjectsNotifier, int>(() {
  return ShowHiddenProjectsNotifier();
});

// REMOVEMOS: projectsWatchProvider (substituído pela reatividade do stream abaixo)

// NOVO PROVIDER CORRIGIDO: Stream que emite a lista bruta de projetos
// Ele usa o novo método watchAllProjects() do repositório (que você precisa garantir que existe)
// This provider automatically invalidates when repositoryProvider changes (profile switch)
final allProjectsStreamProvider = StreamProvider<List<MusicProject>>((ref) async* {
  // Watch repositoryProvider to automatically restart stream when profile changes
  final repo = await ref.watch(repositoryProvider.future);
  
  if (kDebugMode) {
    print('allProjectsStreamProvider: Starting stream for profile ${repo.profileId}');
  }
  
  // OBSERVAÇÃO: Este método (repo.watchAllProjects()) deve existir e retornar Stream<List<MusicProject>>
  yield* repo.watchAllProjects();
});


// PROVIDER CORRIGIDO: Agora observa o allProjectsStreamProvider e o Notifier
final projectsProvider = Provider<List<MusicProject>>((ref) {
  // 1. Observa o stream de todos os projetos (retorna um AsyncValue)
  final allProjectsAsync = ref.watch(allProjectsStreamProvider);
  
  // 2. Observa o estado ATUAL (QueryParams) do nosso novo Notifier
  final params = ref.watch(queryParamsNotifierProvider);
  
  // 3. Observa releases e scan roots para filter preserved projects
  final releasesAsync = ref.watch(releasesProvider);
  final scanRoots = ref.watch(scanRootsProvider);

  // 4. Usa .whenData para acessar a lista quando estiver pronta e aplicar o filtro/ordenação
  return allProjectsAsync.whenData((allProjects) {
    var projects = allProjects;

    // --- Filter out stale preserved projects ---
    // A "preserved" project is one attached to a release. We hide it only when its
    // source file DOES exist locally but falls outside every active scan root (the
    // user removed the root). Projects whose files are NOT present locally are always
    // shown — they are metadata-only entries restored from a backup on another machine.
    if (!MobileUtils.isMobile()) {
      final releases = releasesAsync.value ?? [];
      final protectedProjectIds = <String>{};
      for (final release in releases) {
        protectedProjectIds.addAll(release.trackIds);
      }

      final activeRootPaths = scanRoots.map((root) {
        final normalized = p.normalize(root.path);
        return normalized.endsWith(p.separator) ? normalized : normalized + p.separator;
      }).toList();

      projects = projects.where((project) {
        // Projects not attached to any release are always shown.
        if (!protectedProjectIds.contains(project.id)) return true;

        // File not present locally → metadata-only from backup / different machine.
        // Always show so the user can inspect / edit metadata.
        final fileExistsLocally = File(project.filePath).existsSync() ||
            Directory(project.filePath).existsSync();
        if (!fileExistsLocally) return true;

        // File exists locally: only show if it's under an active scan root.
        final projectPath = p.normalize(project.filePath);
        return activeRootPaths.any((rootPath) => projectPath.startsWith(rootPath));
      }).toList();
    } else {
      // Android: show all projects (metadata-only mode, no file system checks).
      if (kDebugMode) {
        print('projectsProvider (Android): Showing all ${projects.length} projects (metadata-only mode)');
      }
    }

    // --- Filter hidden projects ---
    final hiddenMode = ref.watch(showHiddenProjectsProvider);
    if (hiddenMode == 0) {
      // Show only visible projects
      projects = projects.where((p) => !p.hidden).toList();
    } else if (hiddenMode == 2) {
      // Show only hidden projects
      projects = projects.where((p) => p.hidden).toList();
    }
    // If hiddenMode == 1, show all (both visible and hidden)
    
    // --- Filter by phase ---
    final phaseFilter = ref.watch(phaseFilterProvider);
    if (phaseFilter != null) {
      projects = projects.where((p) => p.status == phaseFilter).toList();
    }
    
    // --- Filter by deadline ---
    final deadlineFilter = ref.watch(deadlineFilterProvider);
    if (deadlineFilter != DeadlineFilter.all) {
      switch (deadlineFilter) {
        case DeadlineFilter.hasDeadline:
          projects = projects.where((p) => p.deadline != null).toList();
          break;
        case DeadlineFilter.overdue:
          projects = projects.where((p) {
            if (p.deadline == null) return false;
            final daysUntil = p.daysUntilDeadline ?? 0;
            return daysUntil < 0;
          }).toList();
          break;
        case DeadlineFilter.dueSoon:
          projects = projects.where((p) {
            if (p.deadline == null) return false;
            final daysUntil = p.daysUntilDeadline ?? 0;
            return daysUntil >= 0 && daysUntil <= 7;
          }).toList();
          break;
        case DeadlineFilter.dueToday:
          projects = projects.where((p) {
            if (p.deadline == null) return false;
            final daysUntil = p.daysUntilDeadline ?? 0;
            return daysUntil == 0;
          }).toList();
          break;
        case DeadlineFilter.all:
          break;
      }
    }
    
    // --- Filter finished projects ---
    final finishedMode = ref.watch(showFinishedProjectsProvider);
    final finishedPhases = ref.watch(finishedPhaseProvider);
    if (finishedMode == 1) {
      // Hide finished projects
      projects = projects.where((p) => !finishedPhases.contains(p.status)).toList();
    }
    
    // --- Show only projects with deadline ---
    final showOnlyWithDeadline = ref.watch(showOnlyWithDeadlineProvider);
    if (showOnlyWithDeadline) {
      // Filter to show only projects with deadline
      projects = projects.where((p) => p.deadline != null).toList();
    }
    
    // --- Aplicação dos Filtros ---
    // Use projects search provider instead of queryParams
    final projectsSearch = ref.watch(projectsSearchProvider);
    if (projectsSearch.trim().isNotEmpty) {
      projects = projects
          .where((p) =>
              fuzzyMatchAll(p.displayName, projectsSearch) ||
              (p.notes != null && fuzzyMatchAll(p.notes!, projectsSearch)))
          .toList();
    }
    
    // --- Ordenação ---
    // When "show only with deadline" is active, sort by deadline (nearest first)
    if (showOnlyWithDeadline) {
      projects.sort((a, b) {
        final aDaysUntil = a.daysUntilDeadline;
        final bDaysUntil = b.daysUntilDeadline;
        
        // Both should have deadline at this point, but safety check
        if (aDaysUntil == null && bDaysUntil == null) return 0;
        if (aDaysUntil == null) return 1;
        if (bDaysUntil == null) return -1;
        
        // Sort by urgency: overdue first, then due soon, then further out
        // Negative values (overdue) come before positive values (upcoming)
        return aDaysUntil.compareTo(bDaysUntil);
      });
    } else if (deadlineFilter != DeadlineFilter.all) {
      // When deadline filter is active (not 'all'), sort by deadline urgency
      projects.sort((a, b) {
        final aDaysUntil = a.daysUntilDeadline;
        final bDaysUntil = b.daysUntilDeadline;
        
        // Projects without deadline go to the end
        if (aDaysUntil == null && bDaysUntil == null) return 0;
        if (aDaysUntil == null) return 1;
        if (bDaysUntil == null) return -1;
        
        // Sort by urgency: overdue first, then due soon, then further out
        // Negative values (overdue) come before positive values (upcoming)
        return aDaysUntil.compareTo(bDaysUntil);
      });
    } else {
      // Default sorting by last modified
      projects.sort((a, b) => a.lastModifiedAt.compareTo(b.lastModifiedAt));
      if (params.sortDesc) {
        projects = projects.reversed.toList();
      }
    }
    
    return projects;
  }).when(
    data: (projects) => projects,
    // Garante que a lista não é nula, mesmo carregando ou com erro
    loading: () => const <MusicProject>[], 
    error: (_, _) => const <MusicProject>[],
  );
});

final dateFormatProvider = Provider<DateFormat>((ref) {
  final locale = ref.watch(localeProvider);
  return DateFormat.yMMMd(locale.toString()).add_jm();
});

// Releases Provider
final releasesProvider = StreamProvider<List<Release>>((ref) async* {
  final repo = await ref.watch(repositoryProvider.future);
  yield* repo.watchAllReleases();
});

// Initial scan state provider
final initialScanStateProvider = NotifierProvider<InitialScanNotifier, bool>(() {
  return InitialScanNotifier();
});

class InitialScanNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true; // Start as true (scanning)
  }
  
  void setScanning(bool scanning) {
    state = scanning;
  }
  
  void complete() {
    state = false;
  }
}

// Profile switching state provider
final profileSwitchingProvider = NotifierProvider<ProfileSwitchingNotifier, bool>(() {
  return ProfileSwitchingNotifier();
});

class ProfileSwitchingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }
  
  void setSwitching(bool switching) {
    state = switching;
  }
  
  void complete() {
    state = false;
  }
}

// Profile switching notifier
class ProfileSwitchNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null;
  }
  
  void setProfileId(String? profileId) {
    state = profileId;
  }
}

final profileSwitchProvider = NotifierProvider<ProfileSwitchNotifier, String?>(() {
  return ProfileSwitchNotifier();
});

// Locale Provider - manages app language preference
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    // Load locale asynchronously after build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadLocale();
    });
    return const Locale('en');
  }

  Future<void> _loadLocale() async {
    try {
      await ensureHiveInitialized();
      final settingsBox = await Hive.openBox<String>('settings');
      final savedLocale = settingsBox.get('locale');
      if (savedLocale != null && savedLocale.isNotEmpty) {
        final parts = savedLocale.split('_');
        if (parts.isNotEmpty) {
          state = Locale(parts[0], parts.length > 1 && parts[1].isNotEmpty ? parts[1] : '');
        }
      }
    } catch (_) {
      // Use default locale if loading fails
    }
  }

  Future<void> setLocale(Locale locale) async {
    // Update state synchronously to trigger immediate rebuild
    state = locale;
    if (kDebugMode) {
      print('Locale changed to: ${locale.languageCode}');
    }
    try {
      await ensureHiveInitialized();
      final settingsBox = await Hive.openBox<String>('settings');
      await settingsBox.put('locale', '${locale.languageCode}_${locale.countryCode ?? ''}');
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save locale: $e');
      }
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

// Selected Projects Provider - persists selection across language changes
final selectedProjectsProvider = NotifierProvider<SelectedProjectsNotifier, Set<String>>(() {
  return SelectedProjectsNotifier();
});

class SelectedProjectsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return <String>{};
  }
  
  void toggle(String projectId) {
    final current = Set<String>.from(state);
    if (current.contains(projectId)) {
      current.remove(projectId);
    } else {
      current.add(projectId);
    }
    state = current;
  }
  
  void selectAll(List<String> projectIds) {
    state = Set<String>.from(projectIds);
  }
  
  void clear() {
    state = <String>{};
  }
  
  void addAll(List<String> projectIds) {
    final current = Set<String>.from(state);
    current.addAll(projectIds);
    state = current;
  }
}

// Phase Filter Provider - filters projects by phase/status
final phaseFilterProvider = NotifierProvider<PhaseFilterNotifier, String?>(() {
  return PhaseFilterNotifier();
});

class PhaseFilterNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null; // null means show all phases
  }
  
  void setPhase(String? phase) {
    state = phase; // null to show all, or a specific phase like 'Idea', 'Arranging', etc.
  }
  
  void clear() {
    state = null;
  }
}

// Custom phases provider — reads per-profile phases from repository
final customPhasesProvider = Provider<List<String>>((ref) {
  final repo = ref.watch(repositoryProvider).asData?.value;
  return repo?.getCustomPhases() ??
      const ['Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'];
});

// Phase color provider — per-profile map of phase name → Color
final phaseColorsProvider = Provider<Map<String, Color>>((ref) {
  final repo = ref.watch(repositoryProvider).asData?.value;
  if (repo == null) return const {};
  return repo.getPhaseColors().map(
    (phase, hex) => MapEntry(phase, hexToColor(hex)),
  );
});

// Finished phases provider — which phase names are treated as "done"
final finishedPhaseProvider = Provider<Set<String>>((ref) {
  final repo = ref.watch(repositoryProvider).asData?.value;
  return repo?.getFinishedPhases() ?? {'Finished'};
});

// Deadline Filter Enum
enum DeadlineFilter {
  all,           // Show all projects
  hasDeadline,   // Only projects with deadlines (sorted by urgency)
  overdue,       // Only overdue projects
  dueSoon,       // Due within 7 days
  dueToday,      // Due today
}

// Deadline Filter Provider - filters projects by deadline status
final deadlineFilterProvider = NotifierProvider<DeadlineFilterNotifier, DeadlineFilter>(() {
  return DeadlineFilterNotifier();
});

class DeadlineFilterNotifier extends Notifier<DeadlineFilter> {
  @override
  DeadlineFilter build() {
    return DeadlineFilter.all; // Default: show all
  }
  
  void setFilter(DeadlineFilter filter) {
    state = filter;
  }
  
  void clear() {
    state = DeadlineFilter.all;
  }
}

// Show Finished Projects Provider - hide/show finished projects
// 0 = show finished (default)
// 1 = hide finished
final showFinishedProjectsProvider = NotifierProvider<ShowFinishedProjectsNotifier, int>(() {
  return ShowFinishedProjectsNotifier();
});

class ShowFinishedProjectsNotifier extends Notifier<int> {
  @override
  int build() {
    // Load saved state asynchronously after build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadHideFinishedState();
    });
    return 0; // Default: show finished projects
  }
  
  Future<void> _loadHideFinishedState() async {
    try {
      await ensureHiveInitialized();
      final settingsBox = await Hive.openBox<String>('settings');
      final savedState = settingsBox.get('hideFinishedProjects');
      if (savedState != null) {
        state = savedState == '1' ? 1 : 0;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load hide finished state: $e');
      }
    }
  }
  
  Future<void> setHideFinished(bool hide) async {
    final newState = hide ? 1 : 0;
    state = newState;
    
    // Save to Hive
    try {
      await ensureHiveInitialized();
      final settingsBox = await Hive.openBox<String>('settings');
      await settingsBox.put('hideFinishedProjects', newState.toString());
      if (kDebugMode) {
        print('Hide finished projects state saved: $newState');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save hide finished state: $e');
      }
    }
  }
  
  bool get isHidingFinished => state == 1;
}

// Show Only Projects with Deadline Provider
// false = show all projects (default)
// true = show only projects with deadline, sorted by deadline
final showOnlyWithDeadlineProvider = NotifierProvider<ShowOnlyWithDeadlineNotifier, bool>(() {
  return ShowOnlyWithDeadlineNotifier();
});

class ShowOnlyWithDeadlineNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Load saved state asynchronously after build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadShowOnlyWithDeadlineState();
    });
    return false; // Default: show all projects
  }
  
  Future<void> _loadShowOnlyWithDeadlineState() async {
    try {
      await ensureHiveInitialized();
      final settingsBox = await Hive.openBox<String>('settings');
      final savedState = settingsBox.get('showOnlyWithDeadline');
      if (savedState != null) {
        state = savedState == 'true';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load show only with deadline state: $e');
      }
    }
  }
  
  Future<void> setShowOnlyWithDeadline(bool show) async {
    state = show;
    
    // Save to Hive
    try {
      await ensureHiveInitialized();
      final settingsBox = await Hive.openBox<String>('settings');
      await settingsBox.put('showOnlyWithDeadline', show.toString());
      if (kDebugMode) {
        print('Show only with deadline state saved: $show');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save show only with deadline state: $e');
      }
    }
  }
}

// Provider for GoogleDriveSyncService (singleton instance)
final googleDriveSyncServiceProvider = Provider<GoogleDriveSyncService>((ref) {
  return GoogleDriveSyncService();
});

// ---------------------------------------------------------------------------
// Auto Backup Interval
// ---------------------------------------------------------------------------

class AutoBackupIntervalNotifier extends Notifier<AutoBackupInterval> {
  static const _key = 'autoBackupInterval';

  @override
  AutoBackupInterval build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return AutoBackupInterval.off;
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('app_settings');
      state = AutoBackupInterval.fromStorageKey(box.get(_key));
    } catch (_) {}
  }

  Future<void> setInterval(AutoBackupInterval interval) async {
    state = interval;
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('app_settings');
      await box.put(_key, interval.name);
    } catch (_) {}
  }
}

final autoBackupIntervalProvider =
    NotifierProvider<AutoBackupIntervalNotifier, AutoBackupInterval>(
        AutoBackupIntervalNotifier.new);

// ---------------------------------------------------------------------------
// Upload Auto-Detected Preview Songs
// ---------------------------------------------------------------------------

class UploadAutoPreviewSongsNotifier extends Notifier<bool> {
  static const _key = 'uploadAutoPreviewSongs';

  @override
  bool build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return false;
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('app_settings');
      final saved = box.get(_key);
      if (saved != null) state = saved == 'true';
    } catch (_) {}
  }

  Future<void> toggle() async {
    state = !state;
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('app_settings');
      await box.put(_key, state.toString());
    } catch (_) {}
  }
}

final uploadAutoPreviewSongsProvider =
    NotifierProvider<UploadAutoPreviewSongsNotifier, bool>(
        UploadAutoPreviewSongsNotifier.new);

// ---------------------------------------------------------------------------
// Update Check Setting
// ---------------------------------------------------------------------------

class CheckForUpdatesNotifier extends Notifier<bool> {
  static const _key = 'checkForUpdates';

  @override
  bool build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return false;
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('app_settings');
      final saved = box.get(_key);
      if (saved != null) state = saved == 'true';
    } catch (_) {}
  }

  Future<void> toggle() async {
    state = !state;
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('app_settings');
      await box.put(_key, state.toString());
    } catch (_) {}
  }
}

final checkForUpdatesProvider =
    NotifierProvider<CheckForUpdatesNotifier, bool>(CheckForUpdatesNotifier.new);

/// Holds the latest available version string when a newer release is found; null otherwise.
class AvailableUpdateNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? version) => state = version;
}

final availableUpdateProvider =
    NotifierProvider<AvailableUpdateNotifier, String?>(AvailableUpdateNotifier.new);

/// Tracks whether the first-run onboarding wizard has been completed.
class OnboardingCompleteNotifier extends Notifier<bool> {
  static const _key = 'onboardingComplete';

  @override
  bool build() {
    _loadAsync();
    try {
      // Box is already open on subsequent launches — read synchronously.
      final box = Hive.box<String>('settings');
      return box.get(_key) == 'true';
    } catch (_) {
      // Box not open yet on very first frame; _loadAsync will set the real value.
      return false;
    }
  }

  void _loadAsync() async {
    final box = await Hive.openBox<String>('settings');
    state = box.get(_key) == 'true';
  }

  Future<void> complete() async {
    state = true;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, 'true');
  }

  Future<void> reset() async {
    state = false;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, 'false');
  }
}

final onboardingCompleteProvider =
    NotifierProvider<OnboardingCompleteNotifier, bool>(OnboardingCompleteNotifier.new);

/// Tracks the project most recently launched in a DAW, shown as a quick-access
/// chip in the title bar.
class ActiveProjectNotifier extends Notifier<MusicProject?> {
  @override
  MusicProject? build() {
    // Keep the active project's data in sync with the repository. When a deep
    // scan or metadata extraction updates the project, the new BPM, key, phase
    // etc. are reflected here without ending or restarting the session.
    ref.listen(allProjectsStreamProvider, (_, next) {
      final active = state;
      if (active == null) return;
      final updated = next.value?.where((p) => p.id == active.id).firstOrNull;
      if (updated != null) state = updated;
    });
    return null;
  }
  void set(MusicProject project) => state = project;
  void clear() => state = null;
}

final activeProjectProvider =
    NotifierProvider<ActiveProjectNotifier, MusicProject?>(ActiveProjectNotifier.new);

// Playlists Provider
final playlistsProvider = StreamProvider<List<Playlist>>((ref) async* {
  final repo = await ref.watch(repositoryProvider.future);
  yield* repo.watchAllPlaylists();
});

// Todo Templates Provider
final todoTemplatesProvider = StreamProvider<List<TodoTemplate>>((ref) async* {
  await ensureHiveInitialized();
  final box = await Hive.openBox<TodoTemplate>('todoTemplates');
  
  // Emit initial value
  yield box.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  
  // Watch for changes
  await for (final _ in box.watch()) {
    yield box.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
});

// Todo Templates Notifier
class TodoTemplatesNotifier extends Notifier<void> {
  @override
  void build() {}
  
  Future<void> addTemplate(TodoTemplate template) async {
    await ensureHiveInitialized();
    final box = await Hive.openBox<TodoTemplate>('todoTemplates');
    await box.put(template.id, template);
  }
  
  Future<void> updateTemplate(TodoTemplate template) async {
    await ensureHiveInitialized();
    final box = await Hive.openBox<TodoTemplate>('todoTemplates');
    await box.put(template.id, template);
  }
  
  Future<void> deleteTemplate(String id) async {
    await ensureHiveInitialized();
    final box = await Hive.openBox<TodoTemplate>('todoTemplates');
    await box.delete(id);
  }
}

final todoTemplatesNotifierProvider = NotifierProvider<TodoTemplatesNotifier, void>(() {
  return TodoTemplatesNotifier();
});

// Warn Before Quit Setting
class WarnBeforeQuitNotifier extends Notifier<bool> {
  @override
  bool build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return true;
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      final saved = box.get('warnBeforeQuit');
      if (saved != null) state = saved == 'true';
    } catch (e) {
      if (kDebugMode) print('Failed to load warnBeforeQuit: $e');
    }
  }

  Future<void> toggle() async {
    state = !state;
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      await box.put('warnBeforeQuit', state.toString());
    } catch (e) {
      if (kDebugMode) print('Failed to save warnBeforeQuit: $e');
    }
  }
}

final warnBeforeQuitProvider = NotifierProvider<WarnBeforeQuitNotifier, bool>(() {
  return WarnBeforeQuitNotifier();
});

// ---------------------------------------------------------------------------
// Close to Tray (desktop-only device-local preference)
// ---------------------------------------------------------------------------

/// Whether closing the window (the X button) minimizes the app to the
/// system tray / menu bar instead of quitting it. Defaults to true so
/// background services (auto-backup, deadline notifications) keep running.
class CloseToTrayNotifier extends Notifier<bool> {
  @override
  bool build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return true;
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      final saved = box.get('closeToTray');
      if (saved != null) state = saved == 'true';
    } catch (e) {
      if (kDebugMode) print('Failed to load closeToTray: $e');
    }
  }

  Future<void> set(bool value) async {
    state = value;
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      await box.put('closeToTray', value.toString());
    } catch (e) {
      if (kDebugMode) print('Failed to save closeToTray: $e');
    }
  }
}

final closeToTrayProvider = NotifierProvider<CloseToTrayNotifier, bool>(() {
  return CloseToTrayNotifier();
});

// ---------------------------------------------------------------------------
// Tab Visibility
// ---------------------------------------------------------------------------

enum AppTab { projects, releases, playlists, queue, statistics, player }

class VisibleTabsNotifier extends Notifier<Set<AppTab>> {
  static const _key = 'visibleTabs';

  // Canonical display order for all tabs.
  static const List<AppTab> canonicalOrder = [
    AppTab.projects,
    AppTab.releases,
    AppTab.playlists,
    AppTab.queue,
    AppTab.statistics,
    AppTab.player,
  ];

  @override
  Set<AppTab> build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    final defaults = {AppTab.projects, AppTab.releases, AppTab.playlists, AppTab.queue, AppTab.statistics, AppTab.player};
    if (MobileUtils.isMobile()) defaults.remove(AppTab.player);
    return defaults;
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      final saved = box.get(_key);
      if (saved != null && saved.isNotEmpty) {
        // Format: each entry is either "tabName" (visible) or "!tabName" (hidden).
        // Old format had only visible tab names (no "!" prefix) — those are treated
        // the same way. Any canonical tab absent from the string is a newly
        // introduced tab and defaults to visible.
        final entries = saved.split(',').where((s) => s.isNotEmpty).toList();
        final explicitlyHidden = <AppTab>{};
        final explicitlyVisible = <AppTab>{};

        for (final entry in entries) {
          final hidden = entry.startsWith('!');
          final name = hidden ? entry.substring(1) : entry;
          final tab = AppTab.values.where((t) => t.name == name).firstOrNull;
          if (tab == null) continue;
          if (hidden) {
            explicitlyHidden.add(tab);
          } else {
            explicitlyVisible.add(tab);
          }
        }

        // Build result: explicitly visible, plus any canonical tab not mentioned
        // at all (newly added tabs inherit default = visible).
        final result = Set<AppTab>.from(explicitlyVisible);
        for (final tab in canonicalOrder) {
          if (!explicitlyHidden.contains(tab) && !explicitlyVisible.contains(tab)) {
            result.add(tab); // new tab not yet seen → show by default
          }
        }
        result.add(AppTab.projects); // always visible
        if (MobileUtils.isMobile()) result.remove(AppTab.player);
        state = result;
      }
    } catch (e) {
      if (kDebugMode) print('Failed to load visibleTabs: $e');
    }
  }

  Future<void> setTabVisible(AppTab tab, bool visible) async {
    if (tab == AppTab.projects) return;
    // Player tab is desktop-only; never allow it to be enabled on mobile.
    if (tab == AppTab.player && MobileUtils.isMobile()) return;
    final updated = Set<AppTab>.from(state);
    if (visible) {
      updated.add(tab);
    } else {
      updated.remove(tab);
    }
    state = updated;
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      // Save all canonical tabs with visibility marker so new future tabs can be
      // distinguished from explicitly-hidden ones.
      final entries = canonicalOrder.map((t) {
        return updated.contains(t) ? t.name : '!${t.name}';
      }).join(',');
      await box.put(_key, entries);
    } catch (e) {
      if (kDebugMode) print('Failed to save visibleTabs: $e');
    }
  }
}

final visibleTabsProvider = NotifierProvider<VisibleTabsNotifier, Set<AppTab>>(() {
  return VisibleTabsNotifier();
});

// ---------------------------------------------------------------------------
// Tab Position (top vs left rail)
// ---------------------------------------------------------------------------

enum TabPosition { top, left }

class TabPositionNotifier extends Notifier<TabPosition> {
  static const _key = 'tabPosition';

  @override
  TabPosition build() {
    _load();
    return TabPosition.left;
  }

  void _load() async {
    final box = await Hive.openBox<String>('settings');
    final saved = box.get(_key);
    if (saved == 'top') state = TabPosition.top;
    if (saved == 'left') state = TabPosition.left;
  }

  void set(TabPosition pos) async {
    state = pos;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, pos == TabPosition.left ? 'left' : 'top');
  }
}

final tabPositionProvider = NotifierProvider<TabPositionNotifier, TabPosition>(() {
  return TabPositionNotifier();
});

class RailCollapsedNotifier extends Notifier<bool> {
  static const _key = 'railCollapsed';

  @override
  bool build() {
    _load();
    return false;
  }

  void _load() async {
    final box = await Hive.openBox<String>('settings');
    final saved = box.get(_key);
    if (saved != null) state = saved == 'true';
  }

  void set(bool collapsed) async {
    state = collapsed;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, collapsed ? 'true' : 'false');
  }
}

final railCollapsedProvider = NotifierProvider<RailCollapsedNotifier, bool>(() {
  return RailCollapsedNotifier();
});

// ---------------------------------------------------------------------------
// Statistics — Event Providers + GlobalStats
// ---------------------------------------------------------------------------

/// Computed aggregate statistics across all projects and events.
class GlobalStats {
  final int totalProjects;
  final int inProgressCount;
  final int finishedCount;
  final Duration? avgCompletionTime;
  /// phase name → project count
  final Map<String, int> countPerPhase;
  /// phase name → average days spent in that phase (completed intervals only)
  final Map<String, double> avgDaysPerPhase;
  /// month key "yyyy-MM" → count of projects created that month (last 12 months)
  final Map<String, int> createdPerMonth;
  /// month key "yyyy-MM" → count of projects finished that month (last 12 months)
  final Map<String, int> finishedPerMonth;
  /// projectId → most recent event occurredAt (for sorting by activity)
  final Map<String, DateTime> lastEventPerProject;

  const GlobalStats({
    required this.totalProjects,
    required this.inProgressCount,
    required this.finishedCount,
    required this.avgCompletionTime,
    required this.countPerPhase,
    required this.avgDaysPerPhase,
    required this.createdPerMonth,
    required this.finishedPerMonth,
    required this.lastEventPerProject,
  });

  static const empty = GlobalStats(
    totalProjects: 0,
    inProgressCount: 0,
    finishedCount: 0,
    avgCompletionTime: null,
    countPerPhase: {},
    avgDaysPerPhase: {},
    createdPerMonth: {},
    finishedPerMonth: {},
    lastEventPerProject: {},
  );
}

/// Stream of all events — restarts automatically on profile switch.
final allEventsStreamProvider = StreamProvider<List<ProjectEvent>>((ref) async* {
  final repo = await ref.watch(repositoryProvider.future);
  yield repo.getAllEvents();
  yield* repo.watchEvents().map((_) => repo.getAllEvents());
});

/// Events for a specific project (family, parametrized by projectId).
final eventsForProjectProvider =
    Provider.family<List<ProjectEvent>, String>((ref, projectId) {
  final eventsAsync = ref.watch(allEventsStreamProvider);
  return eventsAsync.whenData((events) {
    final filtered = events.where((e) => e.projectId == projectId).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return filtered;
  }).asData?.value ?? [];
});

/// Projects sorted by most recent event activity (most active first).
/// Projects with no events are sorted by updatedAt at the end.
final projectsWithRecentActivityProvider =
    Provider<List<MusicProject>>((ref) {
  final projectsAsync = ref.watch(allProjectsStreamProvider);
  final eventsAsync = ref.watch(allEventsStreamProvider);
  final hideFinished = ref.watch(statsHideFinishedProvider);
  final finishedPhases = ref.watch(finishedPhaseProvider);

  final allProjects = projectsAsync.asData?.value ?? [];
  final projects = hideFinished
      ? allProjects.where((p) => !finishedPhases.contains(p.status)).toList()
      : allProjects;
  final events = eventsAsync.asData?.value ?? [];

  // Build map projectId → most recent event time
  final lastEvent = <String, DateTime>{};
  for (final e in events) {
    final existing = lastEvent[e.projectId];
    if (existing == null || e.occurredAt.isAfter(existing)) {
      lastEvent[e.projectId] = e.occurredAt;
    }
  }

  final sorted = List<MusicProject>.from(projects)
    ..sort((a, b) {
      final aTime = lastEvent[a.id];
      final bTime = lastEvent[b.id];
      if (aTime == null && bTime == null) {
        return b.updatedAt.compareTo(a.updatedAt);
      }
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
  return sorted;
});

/// Whether the statistics page should exclude finished projects from all computations.
final statsHideFinishedProvider =
    NotifierProvider<StatsHideFinishedNotifier, bool>(
        StatsHideFinishedNotifier.new);

class StatsHideFinishedNotifier extends Notifier<bool> {
  static const _key = 'statsHideFinished';

  @override
  bool build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return false;
  }

  Future<void> _load() async {
    try {
      final box = await Hive.openBox<String>('settings');
      final saved = box.get(_key);
      if (saved != null) state = saved == 'true';
    } catch (_) {}
  }

  Future<void> toggle() async {
    state = !state;
    try {
      final box = await Hive.openBox<String>('settings');
      await box.put(_key, state.toString());
    } catch (_) {}
  }
}

/// Fully computed global statistics derived from projects + events.
final globalStatsProvider = Provider<GlobalStats>((ref) {
  final projectsAsync = ref.watch(allProjectsStreamProvider);
  final eventsAsync = ref.watch(allEventsStreamProvider);
  final hideFinished = ref.watch(statsHideFinishedProvider);
  final finishedPhases = ref.watch(finishedPhaseProvider);

  final allProjects = projectsAsync.asData?.value;
  final events = eventsAsync.asData?.value;
  if (allProjects == null || events == null) return GlobalStats.empty;

  final projects = hideFinished
      ? allProjects.where((p) => !finishedPhases.contains(p.status)).toList()
      : allProjects;

  // Basic counts
  final total = projects.length;
  final finished = projects.where((p) => finishedPhases.contains(p.status)).toList();
  final inProgress = projects.where((p) => !finishedPhases.contains(p.status)).toList();

  // Average completion time (from model field, only for finished projects)
  Duration? avgCompletion;
  final completionTimes = finished
      .map((p) => p.timeToCompletion(finishedPhases))
      .whereType<Duration>()
      .toList();
  if (completionTimes.isNotEmpty) {
    final totalMs =
        completionTimes.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    avgCompletion = Duration(milliseconds: totalMs ~/ completionTimes.length);
  }

  // Count per phase
  final phases = ref.watch(customPhasesProvider);
  final countPerPhase = <String, int>{for (final ph in phases) ph: 0};
  for (final p in projects) {
    final ph = p.status;
    countPerPhase[ph] = (countPerPhase[ph] ?? 0) + 1;
  }

  // Average days per phase from status_change event log
  // For each project: iterate consecutive status_change events sorted asc.
  // The time spent in phase X = time between entering X and leaving X.
  final daysPerPhase = <String, List<int>>{};
  final statusEventsByProject = <String, List<ProjectEvent>>{};
  for (final e in events) {
    if (e.eventType == ProjectEvent.statusChange) {
      statusEventsByProject.putIfAbsent(e.projectId, () => []).add(e);
    }
  }
  for (final evList in statusEventsByProject.values) {
    evList.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    for (int i = 0; i < evList.length - 1; i++) {
      try {
        final payload = jsonDecode(evList[i].payload ?? '{}') as Map<String, dynamic>;
        final phaseEntered = payload['to'] as String?;
        if (phaseEntered == null) continue;
        final days =
            evList[i + 1].occurredAt.difference(evList[i].occurredAt).inDays;
        daysPerPhase.putIfAbsent(phaseEntered, () => []).add(days);
      } catch (_) {
        // Malformed payload — skip
      }
    }
  }
  final avgDaysPerPhase = <String, double>{};
  daysPerPhase.forEach((phase, daysList) {
    avgDaysPerPhase[phase] =
        daysList.fold<int>(0, (sum, d) => sum + d) / daysList.length;
  });

  // Productivity: projects created / finished per month (last 12 months)
  final now = DateTime.now();
  final createdPerMonth = <String, int>{};
  final finishedPerMonth = <String, int>{};
  for (int i = 11; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    createdPerMonth[key] = 0;
    finishedPerMonth[key] = 0;
  }
  for (final p in projects) {
    final key =
        '${p.createdAt.year}-${p.createdAt.month.toString().padLeft(2, '0')}';
    if (createdPerMonth.containsKey(key)) {
      createdPerMonth[key] = createdPerMonth[key]! + 1;
    }
    if (p.status == 'Finished') {
      final finKey =
          '${p.updatedAt.year}-${p.updatedAt.month.toString().padLeft(2, '0')}';
      if (finishedPerMonth.containsKey(finKey)) {
        finishedPerMonth[finKey] = finishedPerMonth[finKey]! + 1;
      }
    }
  }

  // Last event per project map (for projectsWithRecentActivityProvider)
  final lastEventPerProject = <String, DateTime>{};
  for (final e in events) {
    final existing = lastEventPerProject[e.projectId];
    if (existing == null || e.occurredAt.isAfter(existing)) {
      lastEventPerProject[e.projectId] = e.occurredAt;
    }
  }

  return GlobalStats(
    totalProjects: total,
    inProgressCount: inProgress.length,
    finishedCount: finished.length,
    avgCompletionTime: avgCompletion,
    countPerPhase: countPerPhase,
    avgDaysPerPhase: avgDaysPerPhase,
    createdPerMonth: createdPerMonth,
    finishedPerMonth: finishedPerMonth,
    lastEventPerProject: lastEventPerProject,
  );
});

/// Search text within the Statistics tab's project history list.
class StatisticsSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String text) => state = text;
  void clear() => state = '';
}

final statisticsSearchProvider =
    NotifierProvider<StatisticsSearchNotifier, String>(
        StatisticsSearchNotifier.new);

class QueueSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String text) => state = text;
  void clear() => state = '';
}

final queueSearchProvider =
    NotifierProvider<QueueSearchNotifier, String>(QueueSearchNotifier.new);

// ─── Desktop embedded player ──────────────────────────────────────────────────

/// Carries the project and fully-resolved file path to play in the bottom bar.
/// A new [generation] number is assigned on each play request so that
/// [ValueKey(request.generation)] forces a fresh widget state per track.
class DesktopPlayerRequest {
  final MusicProject project;
  final String resolvedPath;
  final int generation;
  /// True when the track is playing as part of the music-player queue.
  /// False for single-track previews (projects list, player bar quick-play).
  final bool isQueuedPlayback;

  const DesktopPlayerRequest({
    required this.project,
    required this.resolvedPath,
    required this.generation,
    this.isQueuedPlayback = false,
  });
}

class DesktopPlayerNotifier extends Notifier<DesktopPlayerRequest?> {
  @override
  DesktopPlayerRequest? build() => null;

  void play(MusicProject project, String resolvedPath, {bool isQueuedPlayback = false}) {
    final gen = (state?.generation ?? 0) + 1;
    state = DesktopPlayerRequest(
      project: project,
      resolvedPath: resolvedPath,
      generation: gen,
      isQueuedPlayback: isQueuedPlayback,
    );
  }

  void close() => state = null;
}

final desktopPlayerProvider =
    NotifierProvider<DesktopPlayerNotifier, DesktopPlayerRequest?>(
        DesktopPlayerNotifier.new);

/// True while the desktop player is actively playing (false when paused/stopped).
class DesktopIsPlayingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final desktopIsPlayingProvider =
    NotifierProvider<DesktopIsPlayingNotifier, bool>(DesktopIsPlayingNotifier.new);

/// Bumped to ask whoever owns the desktop player's AudioPlayer (currently
/// _DesktopPlayerBarState) to toggle play/pause on the current track, from
/// UI that doesn't have direct access to that widget's state — e.g. the
/// play button on a project row when that row's track is already loaded.
class DesktopPlayerToggleNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final desktopPlayerToggleRequestProvider =
    NotifierProvider<DesktopPlayerToggleNotifier, int>(DesktopPlayerToggleNotifier.new);

/// Incremented each time the desktop player finishes a track naturally.
/// Music player listens to this to trigger queue auto-advance.
class DesktopPlayerCompletedNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void increment() => state++;
}

final desktopPlayerCompletedProvider =
    NotifierProvider<DesktopPlayerCompletedNotifier, int>(
        DesktopPlayerCompletedNotifier.new);

// ─── Queue navigation (prev / next from bottom player bar) ────────────────────

/// Callbacks registered by [MusicPlayerPage] so [_DesktopPlayerBar] can
/// trigger previous/next track navigation without coupling the two widgets.
class QueueNavigationNotifier extends Notifier<({void Function()? playNext, void Function()? playPrev})> {
  @override
  ({void Function()? playNext, void Function()? playPrev}) build() =>
      (playNext: null, playPrev: null);

  void register({required void Function() playNext, required void Function() playPrev}) {
    state = (playNext: playNext, playPrev: playPrev);
  }

  void unregister() => state = (playNext: null, playPrev: null);
}

final queueNavigationProvider = NotifierProvider<
    QueueNavigationNotifier,
    ({void Function()? playNext, void Function()? playPrev})>(
    QueueNavigationNotifier.new);

// ─── Waveform peaks cache ─────────────────────────────────────────────────────

/// In-memory cache: resolved file path → extracted [WaveformPeaks].
/// Survives widget rebuilds and navigation so peaks are never re-extracted for
/// the same file within a single app session.
class WaveformCacheNotifier extends Notifier<Map<String, WaveformPeaks>> {
  /// Source-file mtime (µs since epoch) recorded when each entry was cached.
  /// Used to detect files that have been overwritten with new content.
  final Map<String, int> _mtimes = {};

  @override
  Map<String, WaveformPeaks> build() => {};

  WaveformPeaks? get(String path) => state[path];

  void put(String path, WaveformPeaks peaks) {
    try {
      _mtimes[path] = File(path).statSync().modified.microsecondsSinceEpoch;
    } catch (_) {}
    state = {...state, path: peaks};
    WaveformDiskCache.save(path, peaks); // fire-and-forget
  }

  /// Returns cached peaks (memory → disk → fresh extraction), storing the
  /// result so subsequent calls for the same path are instant.
  ///
  /// [onStale] is called synchronously if the memory-cached entry is found to
  /// be stale (source file modified since caching). Use it to clear local
  /// peak state and show a "refreshing" notification before re-extraction begins.
  Future<WaveformPeaks?> getOrExtract(String path, {VoidCallback? onStale}) async {
    final mem = state[path];
    if (mem != null) {
      // Cheap stat to detect files overwritten with new content at the same path.
      bool stale = false;
      try {
        final currentMtime = File(path).statSync().modified.microsecondsSinceEpoch;
        stale = currentMtime != _mtimes[path];
      } catch (_) {
        return mem; // File inaccessible — return cached data as-is.
      }
      if (!stale) return mem;
      // Evict stale entry and fall through to re-extract.
      onStale?.call();
      state = Map.of(state)..remove(path);
      _mtimes.remove(path);
    }

    final disk = await WaveformDiskCache.load(path);
    if (disk != null) {
      try {
        _mtimes[path] = File(path).statSync().modified.microsecondsSinceEpoch;
      } catch (_) {}
      state = {...state, path: disk};
      return disk;
    }

    final peaks = await AudioAnalysisService.extractWaveformPeaks(path);
    if (peaks != null) put(path, peaks);
    return peaks;
  }
}

final waveformCacheProvider =
    NotifierProvider<WaveformCacheNotifier, Map<String, WaveformPeaks>>(
        WaveformCacheNotifier.new);

// ---------------------------------------------------------------------------
// Mobile Preview Player (global singleton — persists across navigation)
// ---------------------------------------------------------------------------

enum PlaybackMode { normal, repeatOne, repeatAll, shuffle }

class MobilePlayerState {
  final MusicProject? currentProject;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final List<MusicProject> queue;
  final int queueIndex;
  final PlaybackMode playbackMode;

  const MobilePlayerState({
    this.currentProject,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.queueIndex = 0,
    this.playbackMode = PlaybackMode.normal,
  });

  bool get hasTrack => currentProject != null;

  String? get effectivePath =>
      currentProject?.previewSongPath?.isNotEmpty == true
          ? currentProject!.previewSongPath
          : currentProject?.previewSongAutoPath;

  MobilePlayerState copyWith({
    MusicProject? currentProject,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    List<MusicProject>? queue,
    int? queueIndex,
    PlaybackMode? playbackMode,
  }) =>
      MobilePlayerState(
        currentProject: currentProject ?? this.currentProject,
        isPlaying: isPlaying ?? this.isPlaying,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        queue: queue ?? this.queue,
        queueIndex: queueIndex ?? this.queueIndex,
        playbackMode: playbackMode ?? this.playbackMode,
      );
}

// ── helpers ───────────────────────────────────────────────────────────────────

bool get _isAndroid => !kIsWeb && Platform.isAndroid;

/// Setado como true em main.dart quando JustAudioBackground.init() completa.
/// Enquanto false, o player Android usa audioplayers como fallback seguro.
bool _jabInitialized = false;

void markJabInitialized() => _jabInitialized = true;

class MobilePlayerNotifier extends Notifier<MobilePlayerState> {
  static const _tag = '[MobilePlayer]';

  // Android: just_audio player — background gerenciado pelo just_audio_background.
  ja.AudioPlayer? _jaPlayer;
  ja.ConcatenatingAudioSource? _jaSource;

  // Subscriptions Android (vivas durante todo o ciclo de vida do notifier).
  StreamSubscription<int?>? _indexSub;
  StreamSubscription<bool>? _jaPlayingSub;
  StreamSubscription<Duration>? _jaPosSub;
  StreamSubscription<Duration?>? _jaDurSub;
  StreamSubscription<ja.PlayerState>? _jaCompleteSub;

  // Desktop fallback: audioplayers (subscriptions re-criadas por play).
  AudioPlayer? _fallbackPlayer;
  StreamSubscription<PlayerState>? _fbStateSub;
  StreamSubscription<Duration>? _fbPosSub;
  StreamSubscription<Duration>? _fbDurSub;
  StreamSubscription<void>? _fbCompleteSub;

  // Rastreia qual player foi realmente usado no último _play().
  // _jabInitialized pode virar true DEPOIS de _play() ter usado audioplayers,
  // então _useJa não pode depender só de _jabInitialized.
  bool _usingJaPlayer = false;

  @override
  MobilePlayerState build() {
    ref.onDispose(_dispose);
    if (_isAndroid) {
      _jaPlayer = ja.AudioPlayer();
      _attachJaListeners();
    }
    return const MobilePlayerState();
  }

  // ── Listeners Android ─────────────────────────────────────────────────────

  void _attachJaListeners() {
    final p = _jaPlayer!;
    // ConcatenatingAudioSource avança automaticamente; sincronizamos o estado.
    _indexSub = p.currentIndexStream.listen((idx) {
      if (idx == null) return;
      final q = state.queue;
      if (idx < q.length && idx != state.queueIndex) {
        state = state.copyWith(currentProject: q[idx], queueIndex: idx);
      }
    });
    _jaPlayingSub = p.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });
    _jaPosSub = p.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _jaDurSub = p.durationStream.listen((dur) {
      if (dur != null) state = state.copyWith(duration: dur);
    });
    // Toda a fila terminou.
    _jaCompleteSub = p.playerStateStream
        .where((s) => s.processingState == ja.ProcessingState.completed)
        .listen((_) {
      state = state.copyWith(isPlaying: false, position: Duration.zero);
    });
  }

  // ── Listeners Desktop ─────────────────────────────────────────────────────

  void _cancelFallbackSubs() {
    _fbStateSub?.cancel();
    _fbPosSub?.cancel();
    _fbDurSub?.cancel();
    _fbCompleteSub?.cancel();
  }

  void _attachFallbackListeners() {
    final p = _fallbackPlayer!;
    _fbStateSub = p.onPlayerStateChanged.listen((s) {
      state = state.copyWith(isPlaying: s == PlayerState.playing);
    });
    _fbPosSub = p.onPositionChanged.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _fbDurSub = p.onDurationChanged.listen((dur) {
      state = state.copyWith(duration: dur);
    });
    _fbCompleteSub = p.onPlayerComplete.listen((_) {
      state = state.copyWith(isPlaying: false, position: Duration.zero);
      _autoAdvanceFallback();
    });
  }

  void _autoAdvanceFallback() {
    final q = state.queue;
    if (q.isEmpty) return;

    int nextIdx;
    switch (state.playbackMode) {
      case PlaybackMode.shuffle:
        nextIdx = Random().nextInt(q.length);
      case PlaybackMode.repeatOne:
        nextIdx = state.queueIndex; // mesma faixa
      case PlaybackMode.repeatAll:
        nextIdx = (state.queueIndex + 1) % q.length;
      case PlaybackMode.normal:
        nextIdx = state.queueIndex + 1;
        if (nextIdx >= q.length) return;
    }

    final next = q[nextIdx];
    final path = next.previewSongPath?.isNotEmpty == true
        ? next.previewSongPath!
        : next.previewSongAutoPath;
    if (path != null) _play(next, path, q, nextIdx);
  }

  // ── Play ──────────────────────────────────────────────────────────────────

  Future<void> playProject(
    MusicProject project,
    String path, {
    List<MusicProject>? queue,
    int? queueIndex,
  }) async {
    final q = queue ?? [project];
    final idx = queueIndex ?? 0;
    await _play(project, path, q, idx);
  }

  Future<void> _play(
    MusicProject project,
    String path,
    List<MusicProject> queue,
    int queueIndex,
  ) async {
    debugPrint('$_tag playing ${project.displayName} at $path');
    // Preservar o modo de playback — o reset de estado não deve apagar a
    // escolha do usuário (repeat/shuffle) ao trocar de faixa.
    final savedMode = state.playbackMode;
    state = MobilePlayerState(
      currentProject: project,
      queue: queue,
      queueIndex: queueIndex,
      playbackMode: savedMode,
    );

    if (_isAndroid && _jabInitialized) {
      _usingJaPlayer = true;
      // ConcatenatingAudioSource para que skip prev/next da notificação funcione.
      final sources = queue.map((p) {
        final trackPath = p.previewSongPath?.isNotEmpty == true
            ? p.previewSongPath!
            : p.previewSongAutoPath ?? '';
        return ja.AudioSource.uri(
          Uri.file(trackPath),
          tag: MediaItem(id: trackPath, title: p.displayName, artist: ''),
        );
      }).toList();
      _jaSource = ja.ConcatenatingAudioSource(children: sources);
      await _jaPlayer!.setAudioSource(
        _jaSource!,
        initialIndex: queueIndex,
        initialPosition: Duration.zero,
      );
      await _applyPlaybackMode(savedMode);
      await _jaPlayer!.play();
    } else {
      _usingJaPlayer = false;
      _cancelFallbackSubs();
      _fallbackPlayer ??= AudioPlayer();
      _attachFallbackListeners();
      await _fallbackPlayer!.stop();
      await _fallbackPlayer!.play(DeviceFileSource(path));
    }
  }

  // ── Controles ─────────────────────────────────────────────────────────────

  bool get _useJa => _usingJaPlayer;

  Future<void> togglePlayPause() async {
    if (_useJa) {
      if (state.isPlaying) {
        await _jaPlayer?.pause();
      } else if (state.hasTrack) {
        await _jaPlayer?.play();
      }
    } else {
      if (state.isPlaying) {
        await _fallbackPlayer?.pause();
      } else if (state.hasTrack) {
        await _fallbackPlayer?.resume();
      }
    }
  }

  Future<void> pause() async {
    if (_useJa) {
      await _jaPlayer?.pause();
    } else {
      await _fallbackPlayer?.pause();
    }
  }

  Future<void> seek(Duration position) async {
    if (_useJa) {
      await _jaPlayer?.seek(position);
    } else {
      await _fallbackPlayer?.seek(position);
    }
  }

  Future<void> playNext() async {
    final q = state.queue;
    final nonNormal = state.playbackMode != PlaybackMode.normal;
    if (_useJa) {
      if (nonNormal || state.queueIndex < q.length - 1) {
        await _jaPlayer?.seekToNext();
      }
    } else {
      int nextIdx = state.queueIndex + 1;
      if (nonNormal && nextIdx >= q.length) nextIdx = 0;
      if (q.isEmpty || nextIdx >= q.length) return;
      final next = q[nextIdx];
      final path = next.previewSongPath?.isNotEmpty == true
          ? next.previewSongPath!
          : next.previewSongAutoPath;
      if (path != null) await _play(next, path, q, nextIdx);
    }
  }

  Future<void> playPrev() async {
    final q = state.queue;
    final nonNormal = state.playbackMode != PlaybackMode.normal;
    if (_useJa) {
      if (nonNormal || state.queueIndex > 0) {
        await _jaPlayer?.seekToPrevious();
      }
    } else {
      int prevIdx = state.queueIndex - 1;
      if (nonNormal && prevIdx < 0) prevIdx = q.length - 1;
      if (q.isEmpty || prevIdx < 0) return;
      final prev = q[prevIdx];
      final path = prev.previewSongPath?.isNotEmpty == true
          ? prev.previewSongPath!
          : prev.previewSongAutoPath;
      if (path != null) await _play(prev, path, q, prevIdx);
    }
  }

  /// Troca a fonte sem mudar projeto/fila — usado pelo botão mono.
  Future<void> switchSource(String path, Duration seekTo) async {
    if (_useJa) {
      final tag = MediaItem(
        id: path,
        title: state.currentProject?.displayName ?? '',
        artist: '',
      );
      await _jaPlayer?.setAudioSource(
        ja.AudioSource.uri(Uri.file(path), tag: tag),
      );
      if (seekTo > Duration.zero) await _jaPlayer?.seek(seekTo);
      await _jaPlayer?.play();
    } else {
      _cancelFallbackSubs();
      _attachFallbackListeners();
      await _fallbackPlayer?.stop();
      await _fallbackPlayer?.play(
        DeviceFileSource(path),
        position: seekTo > Duration.zero ? seekTo : null,
      );
    }
  }

  Future<void> setPlaybackMode(PlaybackMode mode) async {
    state = state.copyWith(playbackMode: mode);
    if (_useJa) await _applyPlaybackMode(mode);
  }

  Future<void> cyclePlaybackMode() async {
    final next = switch (state.playbackMode) {
      PlaybackMode.normal    => PlaybackMode.repeatOne,
      PlaybackMode.repeatOne => PlaybackMode.repeatAll,
      PlaybackMode.repeatAll => PlaybackMode.normal,
      PlaybackMode.shuffle   => PlaybackMode.normal,
    };
    await setPlaybackMode(next);
  }

  Future<void> _applyPlaybackMode(PlaybackMode mode) async {
    switch (mode) {
      case PlaybackMode.normal:
        await _jaPlayer?.setLoopMode(ja.LoopMode.off);
        await _jaPlayer?.setShuffleModeEnabled(false);
      case PlaybackMode.repeatOne:
        await _jaPlayer?.setLoopMode(ja.LoopMode.one);
        await _jaPlayer?.setShuffleModeEnabled(false);
      case PlaybackMode.repeatAll:
        await _jaPlayer?.setLoopMode(ja.LoopMode.all);
        await _jaPlayer?.setShuffleModeEnabled(false);
      case PlaybackMode.shuffle:
        await _jaPlayer?.setLoopMode(ja.LoopMode.off);
        await _jaPlayer?.setShuffleModeEnabled(true);
    }
  }

  Future<void> stop() async {
    if (_useJa) {
      await _jaPlayer?.stop();
    } else {
      _cancelFallbackSubs();
      await _fallbackPlayer?.stop();
    }
    state = const MobilePlayerState();
  }

  void _dispose() {
    _indexSub?.cancel();
    _jaPlayingSub?.cancel();
    _jaPosSub?.cancel();
    _jaDurSub?.cancel();
    _jaCompleteSub?.cancel();
    _cancelFallbackSubs();
    _jaPlayer?.dispose();
    _fallbackPlayer?.dispose();
  }
}

final mobilePlayerProvider =
    NotifierProvider<MobilePlayerNotifier, MobilePlayerState>(
        MobilePlayerNotifier.new);

/// Projects with a preview song, in the same order as the current dashboard list.
final mobilePlayerQueueProvider = Provider<List<MusicProject>>((ref) {
  final projects = ref.watch(projectsProvider);
  return projects
      .where((p) =>
          (p.previewSongPath?.isNotEmpty ?? false) ||
          (p.previewSongAutoPath?.isNotEmpty ?? false))
      .toList();
});

// ---------------------------------------------------------------------------
// Session Mode (subscribe-before-launch vs direct launch)
// ---------------------------------------------------------------------------

class SessionModeNotifier extends Notifier<bool> {
  static const _key = 'sessionMode';

  @override
  bool build() {
    _load();
    return false; // default: direct launch
  }

  Future<void> _load() async {
    final box = await Hive.openBox<String>('settings');
    final saved = box.get(_key);
    if (saved != null) state = saved == 'true';
  }

  Future<void> set(bool value) async {
    state = value;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, value.toString());
  }

  Future<void> toggle() async => set(!state);
}

final sessionModeProvider =
    NotifierProvider<SessionModeNotifier, bool>(SessionModeNotifier.new);

// ---------------------------------------------------------------------------
// Session Suggestions Enabled
// ---------------------------------------------------------------------------

class SuggestionsEnabledNotifier extends Notifier<bool> {
  static const _key = 'suggestionsEnabled';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final box = await Hive.openBox<String>('settings');
    final saved = box.get(_key);
    if (saved != null) state = saved == 'true';
  }

  Future<void> set(bool value) async {
    state = value;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, value.toString());
  }
}

final suggestionsEnabledProvider =
    NotifierProvider<SuggestionsEnabledNotifier, bool>(
        SuggestionsEnabledNotifier.new);

// ---------------------------------------------------------------------------
// Work Timer Notification Settings
// ---------------------------------------------------------------------------

class WorkTimerNotifEnabledNotifier extends Notifier<bool> {
  static const _key = 'workTimerNotifEnabled';

  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final box = await Hive.openBox<String>('settings');
    final saved = box.get(_key);
    if (saved != null) state = saved == 'true';
  }

  Future<void> set(bool value) async {
    state = value;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, value.toString());
  }
}

final workTimerNotifEnabledProvider =
    NotifierProvider<WorkTimerNotifEnabledNotifier, bool>(
        WorkTimerNotifEnabledNotifier.new);

class WorkTimerNotifIntervalNotifier extends Notifier<int> {
  // Stored and exposed in SECONDS. Default: 3600 (60 minutes).
  // Legacy values ≤ 120 are treated as minutes and migrated on first load.
  static const _key = 'workTimerNotifIntervalSecs';

  @override
  int build() {
    _load();
    return 3600;
  }

  Future<void> _load() async {
    final box = await Hive.openBox<String>('settings');
    // Try new seconds key first, then fall back to legacy minutes key.
    final savedSecs = box.get(_key);
    if (savedSecs != null) {
      state = int.tryParse(savedSecs) ?? 3600;
    } else {
      final legacyMins = box.get('workTimerNotifInterval');
      if (legacyMins != null) {
        final mins = int.tryParse(legacyMins) ?? 60;
        state = mins * 60;
      }
    }
  }

  Future<void> set(int seconds) async {
    state = seconds;
    final box = await Hive.openBox<String>('settings');
    await box.put(_key, seconds.toString());
  }
}

final workTimerNotifIntervalProvider =
    NotifierProvider<WorkTimerNotifIntervalNotifier, int>(
        WorkTimerNotifIntervalNotifier.new);

// ---------------------------------------------------------------------------
// Work Timer — tracks time on the subscribed project, fires notifications
// ---------------------------------------------------------------------------

class WorkTimerNotifier extends Notifier<int> {
  // State = elapsed seconds of active work (0 when idle; frozen while paused).
  Timer? _ticker;
  DateTime? _startTime; // adjusted on resume to exclude paused durations
  DateTime? _pausedAt;  // set when paused, null otherwise

  @override
  int build() {
    ref.onDispose(() {
      _ticker?.cancel();
      _ticker = null;
    });

    ref.listen<MusicProject?>(activeProjectProvider, (prev, next) {
      // Only save/restart when the project actually changes (different ID or
      // cleared). Same-ID updates are metadata refreshes — don't touch the timer.
      final projectChanged = next == null || next.id != prev?.id;
      if (prev != null && _startTime != null && projectChanged) {
        _saveSession(prev);
      }
      if (next != null && projectChanged) {
        _start();
      } else if (next == null) {
        _stop();
      }
    });

    // If a project is already subscribed when this provider is first read, start tracking.
    if (ref.read(activeProjectProvider) != null) _start();

    return 0;
  }

  void _start() {
    _ticker?.cancel();
    _startTime = DateTime.now();
    _pausedAt = null;
    ref.read(workTimerPausedProvider.notifier).set(false);
    state = 0;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Call immediately after setting the active project when the session was
  /// already in progress (e.g. resolved from a pending folder). Overrides the
  /// start time so elapsed seconds reflect the original session start rather
  /// than the moment the project was set active.
  void continueFrom(DateTime from) {
    _startTime = from;
    state = DateTime.now().difference(from).inSeconds;
  }

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
    _startTime = null;
    _pausedAt = null;
    ref.read(workTimerPausedProvider.notifier).set(false);
    state = 0;
  }

  void pause() {
    if (_startTime == null || _pausedAt != null) return;
    // Freeze the elapsed display at the current second count.
    state = DateTime.now().difference(_startTime!).inSeconds;
    _pausedAt = DateTime.now();
    _ticker?.cancel();
    _ticker = null;
    ref.read(workTimerPausedProvider.notifier).set(true);
  }

  void resume() {
    if (_startTime == null || _pausedAt == null) return;
    // Shift _startTime forward by the pause duration so elapsed seconds
    // remain continuous across pause/resume cycles.
    final pauseDuration = DateTime.now().difference(_pausedAt!);
    _startTime = _startTime!.add(pauseDuration);
    _pausedAt = null;
    ref.read(workTimerPausedProvider.notifier).set(false);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _saveSession(MusicProject project) async {
    final start = _startTime;
    if (start == null) return;
    // Use _pausedAt as the end time if paused; otherwise use now.
    final end = _pausedAt ?? DateTime.now();
    final elapsedSeconds = end.difference(start).inSeconds;
    if (elapsedSeconds <= 0) return;
    final repo = await ref.read(repositoryProvider.future);
    final latest = repo.getById(project.id) ?? project;
    final record = SessionRecord(
      id: start.toIso8601String(),
      startedAt: start,
      endedAt: end,
      durationSeconds: elapsedSeconds,
      phase: latest.status,
    );
    final newSessions = [...latest.sessions, record];
    final updated = latest.copyWith(
      totalWorkSeconds: newSessions.fold<int>(0, (s, r) => s + r.durationSeconds),
      sessions: newSessions,
      updatedAt: DateTime.now(),
    );
    repo.updateProject(updated);
  }

  void _tick() {
    if (_startTime == null) return;
    final elapsed = DateTime.now().difference(_startTime!);
    state = elapsed.inSeconds;

    if (Platform.isAndroid || Platform.isIOS) return;

    final enabled = ref.read(workTimerNotifEnabledProvider);
    if (!enabled) return;

    final intervalSeconds = ref.read(workTimerNotifIntervalProvider);
    if (elapsed.inSeconds > 0 && elapsed.inSeconds % intervalSeconds == 0) {
      final project = ref.read(activeProjectProvider);
      if (project != null) {
        final locale = ref.read(localeProvider);
        final l10n = lookupAppLocalizations(locale);
        final h = elapsed.inHours;
        final m = elapsed.inMinutes.remainder(60);
        final s = elapsed.inSeconds.remainder(60);
        final timeStr = h > 0
            ? (m > 0 ? '${h}h ${m}m' : '${h}h')
            : m > 0
                ? (s > 0 ? '${m}m ${s}s' : '${m}m')
                : '${s}s';
        final allProfiles = ref.read(allProfilesProvider).value ?? [];
        final profile = ref.read(currentProfileProvider).value;
        final title = (allProfiles.length > 1 && profile != null)
            ? '${project.displayName} · ${profile.name}'
            : project.displayName;
        DeadlineNotificationService().showWorkTimerNotification(
          title,
          l10n.workTimerNotifBody(timeStr),
        );
      }
    }
  }
}

final workTimerProvider =
    NotifierProvider<WorkTimerNotifier, int>(WorkTimerNotifier.new);

/// True while the work-timer is paused (ticker stopped, elapsed frozen).
class WorkTimerPausedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final workTimerPausedProvider =
    NotifierProvider<WorkTimerPausedNotifier, bool>(WorkTimerPausedNotifier.new);

// ---------------------------------------------------------------------------
// Last-Modified Color Coding Setting
// Green = Finished status; red gradient = older last-modified date.
// When disabled the column shows plain text color.
// ---------------------------------------------------------------------------
class LastModifiedColorNotifier extends Notifier<bool> {
  static const _key = 'lastModifiedColorEnabled';

  @override
  bool build() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _load());
    return true; // enabled by default
  }

  Future<void> _load() async {
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      final saved = box.get(_key);
      if (saved != null) state = saved == 'true';
    } catch (e) {
      if (kDebugMode) print('Failed to load $_key: $e');
    }
  }

  Future<void> toggle() async {
    state = !state;
    try {
      await ensureHiveInitialized();
      final box = await Hive.openBox<String>('settings');
      await box.put(_key, state.toString());
    } catch (e) {
      if (kDebugMode) print('Failed to save $_key: $e');
    }
  }
}

final lastModifiedColorProvider =
    NotifierProvider<LastModifiedColorNotifier, bool>(LastModifiedColorNotifier.new);

// ── Session idle suggestions panel ──────────────────────────────────────────

class SuggestionsPanelExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

final suggestionsPanelExpandedProvider =
    NotifierProvider<SuggestionsPanelExpandedNotifier, bool>(
        SuggestionsPanelExpandedNotifier.new);

class DismissedSuggestionsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};
  void dismiss(String id) => state = {...state, id};
  void clear() => state = const {};
}

final dismissedSuggestionsProvider =
    NotifierProvider<DismissedSuggestionsNotifier, Set<String>>(
        DismissedSuggestionsNotifier.new);

// Bumped whenever pending folders are added/removed so the UI rebuilds.
class _PendingFoldersDirtyNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state = state + 1;
}

final pendingFoldersDirtyProvider =
    NotifierProvider<_PendingFoldersDirtyNotifier, int>(_PendingFoldersDirtyNotifier.new);

final pendingFoldersProvider = Provider<List<PendingFolder>>((ref) {
  ref.watch(pendingFoldersDirtyProvider);
  final repoAsync = ref.watch(repositoryProvider);
  return repoAsync.maybeWhen(
    data: (repo) => repo.getPendingFolders(),
    orElse: () => const [],
  );
});
