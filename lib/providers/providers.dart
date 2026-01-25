import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../utils/app_paths.dart';

import '../models/music_project.dart';
import '../models/scan_root.dart';
import '../models/ignored_path.dart';
import '../models/release.dart';
import '../models/profile.dart';
import '../models/playlist.dart';
import '../models/todo_template.dart';
import '../repository/project_repository.dart';
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
  yield* repo.watchRoots().map((_) => null);
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
  yield* repo.watchIgnoredPaths().map((_) => null);
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

    // --- Filter out preserved projects (in releases but not in any active scan root) ---
    // On Android, we're only syncing metadata, so show ALL projects (both in releases and not)
    // On desktop, filter preserved projects that aren't in active scan roots
    if (!Platform.isAndroid) {
      // Desktop: filter preserved projects that aren't in active scan roots
      final releases = releasesAsync.value ?? [];
      final protectedProjectIds = <String>{};
      for (final release in releases) {
        protectedProjectIds.addAll(release.trackIds);
      }
      
      // Get all active scan root paths (normalized for comparison)
      final activeRootPaths = scanRoots.map((root) {
        final normalized = p.normalize(root.path);
        // Ensure root path ends with separator for proper prefix matching
        return normalized.endsWith(p.separator) ? normalized : normalized + p.separator;
      }).toList();
      
      // Filter out preserved projects: those in releases but not in any active root
      projects = projects.where((project) {
        // If project is not in any release, always show it
        if (!protectedProjectIds.contains(project.id)) {
          return true;
        }
        
        // If project is in a release, check if it's in any active scan root
        final projectPath = p.normalize(project.filePath);
        final isInActiveRoot = activeRootPaths.any((rootPath) {
          // Check if project path starts with the root path
          return projectPath.startsWith(rootPath);
        });
        
        // Only show if it's in an active root (preserved projects not in active roots are hidden)
        return isInActiveRoot;
      }).toList();
    } else {
      // Android: show all projects (metadata-only mode, no file system checks)
      // Don't filter based on scan roots since files don't exist locally
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
      final needle = projectsSearch.toLowerCase();
      projects = projects.where((p) => p.displayName.toLowerCase().contains(needle)).toList();
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
    error: (_, __) => const <MusicProject>[],
  );
});

final dateFormatProvider = Provider<DateFormat>((ref) => DateFormat.yMMMd().add_jm());

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
  return GoogleDriveSyncService();
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
