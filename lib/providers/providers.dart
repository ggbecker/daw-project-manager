import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../utils/app_paths.dart';
import '../utils/mobile_utils.dart';

import '../models/music_project.dart';
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
class ShowHiddenProjectsNotifier extends Notifier<int> {
  @override
  int build() {
    // Load saved state asynchronously after build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadShowHiddenState();
    });
    return 0; // Default to showing only visible projects
  }
  
  Future<void> _loadShowHiddenState() async {
    try {
      await ensureHiveInitialized();
      final settingsBox = await Hive.openBox<String>('settings');
      final savedState = settingsBox.get('showHiddenProjects');
      if (savedState != null) {
        final intState = int.tryParse(savedState);
        if (intState != null && (intState >= 0 && intState <= 2)) {
          state = intState;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load show hidden state: $e');
      }
    }
  }
  
  Future<void> setShowAll(bool show) async {
    final newState = show ? 1 : 0;
    state = newState;
    await _saveState(newState);
  }
  
  Future<void> setShowOnlyHidden(bool show) async {
    final newState = show ? 2 : 0;
    state = newState;
    await _saveState(newState);
  }
  
  Future<void> _saveState(int newState) async {
    try {
      await ensureHiveInitialized();
      final settingsBox = await Hive.openBox<String>('settings');
      await settingsBox.put('showHiddenProjects', newState.toString());
      if (kDebugMode) {
        print('Show hidden projects state saved: $newState');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save show hidden state: $e');
      }
    }
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
    if (finishedMode == 1) {
      // Hide finished projects
      projects = projects.where((p) => p.status != 'Finished').toList();
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
          .where((p) => fuzzyMatchAll(p.displayName, projectsSearch))
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
  // Note: service.dispose() is intentionally NOT called on provider dispose.
  // dispose() closes _authStateController which would break googleDriveAuthStateProvider
  // if the provider is re-created (e.g. after backup import triggers repository re-init).
  return GoogleDriveSyncService();
});

// Reactive auth state — emits whenever the user signs in or out.
// Widgets can watch this instead of polling, so they update the moment
// lightweight authentication completes (no fixed-delay race condition).
final googleDriveAuthStateProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(googleDriveSyncServiceProvider);
  return service.authStateStream;
});

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
    return false;
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

  final allProjects = projectsAsync.asData?.value ?? [];
  final projects = hideFinished
      ? allProjects.where((p) => p.status != 'Finished').toList()
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

  final allProjects = projectsAsync.asData?.value;
  final events = eventsAsync.asData?.value;
  if (allProjects == null || events == null) return GlobalStats.empty;

  final projects = hideFinished
      ? allProjects.where((p) => p.status != 'Finished').toList()
      : allProjects;

  // Basic counts
  final total = projects.length;
  final finished = projects.where((p) => p.status == 'Finished').toList();
  final inProgress = projects.where((p) => p.status != 'Finished').toList();

  // Average completion time (from model field, only for finished projects)
  Duration? avgCompletion;
  final completionTimes = finished
      .map((p) => p.timeToCompletion)
      .whereType<Duration>()
      .toList();
  if (completionTimes.isNotEmpty) {
    final totalMs =
        completionTimes.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    avgCompletion = Duration(milliseconds: totalMs ~/ completionTimes.length);
  }

  // Count per phase
  const phases = ['Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'];
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
