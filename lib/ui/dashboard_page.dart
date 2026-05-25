import 'dart:async';
import 'dart:io';

import 'package:trina_grid/trina_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, listEquals;
import 'package:flutter/services.dart'; 
import 'package:path/path.dart' as path; // 🚨 NOVO IMPORT
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';

import '../services/scanner_service.dart';
import '../services/audio_analysis_service.dart';
import '../services/mixdown_detector_service.dart';
import 'widgets/shortcuts_help_dialog.dart';
import 'widgets/waveform_widget.dart';
import 'music_player_page.dart';
import 'widgets/startup_dialog.dart';
import 'widgets/tab_customization_dialog.dart';
import '../services/dock_menu_service.dart';
import '../utils/mobile_utils.dart';
import '../providers/theme_provider.dart';
import '../utils/file_launcher.dart';
import '../utils/search_utils.dart';
import '../utils/route_observer.dart';
import 'project_detail_page.dart';
import 'releases_tab_page.dart';
import 'release_detail_page.dart';
import 'profile_manager_page.dart';
import 'project_folders_settings_page.dart';
import 'playlists_page.dart';
import 'google_drive_sync_page.dart';
import 'statistics_page.dart';
import 'queue_page.dart';
import 'notification_settings_page.dart';
import 'widgets/desktop_title_bar.dart';
import 'widgets/language_switcher.dart';
import 'widgets/theme_switcher.dart';
import '../generated/l10n/app_localizations.dart';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/music_project.dart';
import '../models/release.dart';
import '../models/scan_mode.dart';
import '../providers/providers.dart';
import 'package:uuid/uuid.dart';

/// App version embedded at build-time (CI passes `--dart-define=APP_VERSION=x.y.z`).
/// For PR/local builds, we fall back to a dummy version.
const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.0.0');

/// Returns true when any text input (TextField / EditableText) currently has
/// focus. Used by keyboard handlers to avoid stealing Space / arrow keys while
/// the user is typing.
///
/// Reliable approach: the inner [Focus] widget created by [EditableText] is a
/// widget-tree descendant of [EditableText], so walking ancestors from its
/// BuildContext will find [EditableText] as a parent.
bool _isTextInputFocused() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  return context.findAncestorWidgetOfExactType<EditableText>() != null;
}

// Intent classes for keyboard shortcuts
class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _FocusTableIntent extends Intent {
  const _FocusTableIntent();
}

class _RescanIntent extends Intent {
  const _RescanIntent();
}

// Action classes for keyboard shortcuts
class _SearchAction extends Action<_SearchIntent> {
  final VoidCallback onSearch;

  _SearchAction(this.onSearch);

  @override
  Object? invoke(_SearchIntent intent) {
    onSearch();
    return null;
  }
}

class _RescanAction extends Action<_RescanIntent> {
  final VoidCallback onRescan;

  _RescanAction(this.onRescan);

  @override
  Object? invoke(_RescanIntent intent) {
    onRescan();
    return null;
  }
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with TickerProviderStateMixin, RouteAware {
  bool _scanning = false;
  bool _extractingMetadata = false;
  bool _isSearchingMobile = false;
  bool _isSearchingDesktop = false;
  bool _railCollapsed = false;
  double _railWidth = 130.0;
  late TabController _tabController;

  // Startup dialog
  bool _startupDialogShown = false;
  bool _hideStartupDialog = false;

  // Ordered list of currently visible tabs (derived from provider, updated via ref.listen)
  List<AppTab> _currentVisibleTabs = [
    AppTab.projects, AppTab.releases, AppTab.queue, AppTab.statistics,
  ];

  // The tab the user is currently on, by identity (not index).
  AppTab get _currentTab {
    final idx = _tabController.index;
    if (idx < 0 || idx >= _currentVisibleTabs.length) return AppTab.projects;
    return _currentVisibleTabs[idx];
  }

  // Compute the ordered list from the provider's Set, filtered for the current platform.
  List<AppTab> _orderedFrom(Set<AppTab> visible) =>
      VisibleTabsNotifier.canonicalOrder
          .where((t) => visible.contains(t))
          .where((t) => MobileUtils.isMobile() || t != AppTab.playlists)
          .where((t) => !MobileUtils.isMobile() || t != AppTab.player)
          .toList();

  // Generation counter — incremented each time we schedule a tab update so that
  // stale post-frame callbacks (from rapid toggles) are silently dropped.
  int _tabUpdateGen = 0;

  // Schedule a safe, deferred swap of the TabController + visible-tab list.
  // Using addPostFrameCallback avoids running inside build or inside a setState
  // callback, which caused double-dispose and length-mismatch errors.
  void _updateVisibleTabs(Set<AppTab> newVisible) {
    final ordered = _orderedFrom(newVisible);
    if (listEquals(_currentVisibleTabs, ordered)) return;
    final gen = ++_tabUpdateGen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || gen != _tabUpdateGen) return;
      final reordered = _orderedFrom(newVisible);
      if (listEquals(_currentVisibleTabs, reordered)) return;

      final previousTab = _currentTab;
      final newIndex = (reordered.contains(previousTab)
              ? reordered.indexOf(previousTab)
              : 0)
          .clamp(0, reordered.length - 1);

      // Create new controller BEFORE disposing the old one.
      final newCtrl = TabController(
        length: reordered.length,
        vsync: this,
        initialIndex: newIndex,
      );
      newCtrl.addListener(_onTabChanged);

      // Atomic swap so _tabController and _currentVisibleTabs are always in sync.
      final oldCtrl = _tabController;
      _tabController = newCtrl;
      _currentVisibleTabs = reordered;

      oldCtrl.removeListener(_onTabChanged);
      oldCtrl.dispose();

      setState(() {});
    });
  }

  // 1. FocusNode para a barra de pesquisa
  final FocusNode _searchFocusNode = FocusNode();

  // Key to reach the projects table and request focus on it
  final _tableKey = GlobalKey<_PlutoProjectsTableWithSelectionState>();

  // FocusNode para capturar eventos de teclado globalmente (debug)
  final FocusNode _debugKeyboardFocusNode = FocusNode();

  // TextEditingController para a barra de pesquisa
  late final TextEditingController _searchController;
  
  // Flag to track if Ctrl+F was recently pressed (to prevent aggressive focus recovery)
  bool _shouldMaintainSearchFocus = false;
  DateTime? _lastCtrlFPressTime;

  @override
  void initState() {
    super.initState();
    if (MobileUtils.isMobile()) {
      _currentVisibleTabs = [...VisibleTabsNotifier.canonicalOrder];
    }
    _tabController = TabController(length: _currentVisibleTabs.length, vsync: this);
    _searchController = TextEditingController();
    if (!MobileUtils.isMobile()) {
      loadHideStartupDialog().then((v) {
        if (mounted) setState(() => _hideStartupDialog = v);
      });
    }
    
    // Add listener to TabController to rebuild when tab changes (for search placeholder update)
    _tabController.addListener(_onTabChanged);
    
    // Add listener to FocusNode to track focus changes
    // Only aggressively recover focus if Ctrl+F was recently pressed
    _searchFocusNode.addListener(() {
      // Only try to recover focus if Ctrl+F was recently pressed (within last 1 second)
      if (!_searchFocusNode.hasFocus && _shouldMaintainSearchFocus && _searchFocusNode.canRequestFocus) {
        final now = DateTime.now();
        if (_lastCtrlFPressTime != null && now.difference(_lastCtrlFPressTime!).inSeconds < 1) {
          // Check if something else stole the focus
          final thief = FocusManager.instance.primaryFocus;
          if (thief != null && thief != _searchFocusNode) {
            // Unfocus the thief and request focus again
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_searchFocusNode.hasFocus && _shouldMaintainSearchFocus) {
                final currentThief = FocusManager.instance.primaryFocus;
                if (currentThief != null && currentThief != _searchFocusNode) {
                  currentThief.unfocus();
                }
                if (_searchFocusNode.canRequestFocus) {
                  _searchFocusNode.requestFocus();
                }
              }
            });
          }
        } else {
          // Ctrl+F was not recent, stop trying to maintain focus
          _shouldMaintainSearchFocus = false;
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    // Don't close the player here — DropdownButton/showMenu also push ModalRoutes,
    // which would close the player on every filter/combo interaction. Tab changes
    // are handled in _onTabChanged instead.
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      switch (_currentTab) {
        case AppTab.projects:
          final projectsSearch = ref.read(projectsSearchProvider);
          if (_searchController.text != projectsSearch) _searchController.text = projectsSearch;
        case AppTab.releases:
          final releasesSearch = ref.read(releasesSearchProvider);
          if (_searchController.text != releasesSearch) _searchController.text = releasesSearch;
        case AppTab.queue:
          final queueSearch = ref.read(queueSearchProvider);
          if (_searchController.text != queueSearch) _searchController.text = queueSearch;
        case AppTab.statistics:
          final statsSearch = ref.read(statisticsSearchProvider);
          if (_searchController.text != statsSearch) _searchController.text = statsSearch;
        case AppTab.playlists:
        case AppTab.player:
          _searchController.clear();
      }
      if (MobileUtils.isMobile() && _isSearchingMobile) _isSearchingMobile = false;
      setState(() {});
    }
  }

  void _clearCurrentTabSearch() {
    _searchController.clear();
    switch (_currentTab) {
      case AppTab.projects:
        ref.read(projectsSearchProvider.notifier).clear();
      case AppTab.releases:
        ref.read(releasesSearchProvider.notifier).clear();
      case AppTab.queue:
        ref.read(queueSearchProvider.notifier).clear();
      case AppTab.statistics:
      case AppTab.playlists:
      case AppTab.player:
        ref.read(statisticsSearchProvider.notifier).set('');
    }
  }

  void _updateCurrentTabSearch(String text) {
    switch (_currentTab) {
      case AppTab.projects:
        ref.read(projectsSearchProvider.notifier).setSearchText(text);
      case AppTab.releases:
        ref.read(releasesSearchProvider.notifier).setSearchText(text);
      case AppTab.queue:
        ref.read(queueSearchProvider.notifier).set(text);
      case AppTab.statistics:
      case AppTab.playlists:
      case AppTab.player:
        ref.read(statisticsSearchProvider.notifier).set(text);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchFocusNode.dispose();
    _debugKeyboardFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Track last processed key to avoid duplicate processing
  LogicalKeyboardKey? _lastProcessedKey;
  DateTime? _lastProcessedTime;
  
  // Method to track all keyboard events and handle shortcuts directly
  void _handleDebugKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;
    
    final logicalKey = event.logicalKey;
    final isControl = event.isControlPressed;
    final isMeta = event.isMetaPressed;
    
    // Handle Ctrl+F / Cmd+F directly in RawKeyboardListener
    if (logicalKey == LogicalKeyboardKey.keyF && (isControl || isMeta)) {
      // Prevent duplicate processing (same key pressed multiple times in quick succession)
      final now = DateTime.now();
      if (_lastProcessedKey == logicalKey && 
          _lastProcessedTime != null && 
          now.difference(_lastProcessedTime!).inMilliseconds < 100) {
        return;
      }
      
      _lastProcessedKey = logicalKey;
      _lastProcessedTime = now;
      
      // Set flag to maintain focus for the next 1 second (only when Ctrl+F is pressed)
      _shouldMaintainSearchFocus = true;
      _lastCtrlFPressTime = DateTime.now();
      
      // Execute the action directly
      _focusSearchAndSelectAll();
      return;
    }
    
    // Handle Ctrl+R / Cmd+R directly in RawKeyboardListener
    if (logicalKey == LogicalKeyboardKey.keyR && (isControl || isMeta)) {
      // Prevent duplicate processing
      final now = DateTime.now();
      if (_lastProcessedKey == logicalKey &&
          _lastProcessedTime != null &&
          now.difference(_lastProcessedTime!).inMilliseconds < 100) {
        return;
      }

      _lastProcessedKey = logicalKey;
      _lastProcessedTime = now;

      // Execute the action directly
      _scanAll();
      return;
    }

    // Handle Ctrl+T / Cmd+T directly in RawKeyboardListener
    if (logicalKey == LogicalKeyboardKey.keyT && (isControl || isMeta)) {
      final now = DateTime.now();
      if (_lastProcessedKey == logicalKey &&
          _lastProcessedTime != null &&
          now.difference(_lastProcessedTime!).inMilliseconds < 100) {
        return;
      }

      _lastProcessedKey = logicalKey;
      _lastProcessedTime = now;

      _tableKey.currentState?.focusTable();
      return;
    }
  }


  void _collapseDesktopSearch() {
    _clearCurrentTabSearch();
    _shouldMaintainSearchFocus = false;
    _searchFocusNode.unfocus();
    setState(() => _isSearchingDesktop = false);
  }

  // Método para focar na busca e selecionar texto
  void _focusSearchAndSelectAll() {
    if (!MobileUtils.isMobile() && !_isSearchingDesktop) {
      setState(() => _isSearchingDesktop = true);
    }
    // Set flag to maintain focus for the next 1 second (only when Ctrl+F is pressed)
    _shouldMaintainSearchFocus = true;
    _lastCtrlFPressTime = DateTime.now();
    
    // CRITICAL: First, unfocus ALL widgets to prevent PlutoGrid or other widgets from stealing focus
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && primaryFocus != _searchFocusNode) {
      primaryFocus.unfocus();
    }
    
    // Use multiple post-frame callbacks to ensure focus is maintained
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Unfocus again to be sure (in case something grabbed focus in the meantime)
      final currentFocus = FocusManager.instance.primaryFocus;
      if (currentFocus != null && currentFocus != _searchFocusNode) {
        currentFocus.unfocus();
      }
      
      // First attempt: request focus
      if (_searchFocusNode.canRequestFocus) {
        _searchFocusNode.requestFocus();
        
        // Second post-frame callback to ensure focus is maintained and select text
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // If focus was lost or stolen, unfocus the thief and try again
          if (!_searchFocusNode.hasFocus) {
            final thief = FocusManager.instance.primaryFocus;
            if (thief != null && thief != _searchFocusNode) {
              thief.unfocus();
            }
            
            if (_searchFocusNode.canRequestFocus) {
              _searchFocusNode.requestFocus();
            }
          }
          
          // Select text if there is any
          if (_searchController.text.isNotEmpty) {
            _searchController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _searchController.text.length,
            );
          }
          
          // Third post-frame callback as final check
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Final attempt if focus is still lost
            if (!_searchFocusNode.hasFocus) {
              final thief = FocusManager.instance.primaryFocus;
              if (thief != null && thief != _searchFocusNode) {
                thief.unfocus();
              }
              
              if (_searchFocusNode.canRequestFocus) {
                _searchFocusNode.requestFocus();
              }
            }
            
            // Fourth callback - aggressive focus maintenance
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_searchFocusNode.hasFocus && _searchFocusNode.canRequestFocus) {
                final thief = FocusManager.instance.primaryFocus;
                if (thief != null && thief != _searchFocusNode) {
                  thief.unfocus();
                }
                _searchFocusNode.requestFocus();
              }
            });
          });
        });
      }
    });
  }


  Future<void> _quickSwitchProfile(BuildContext context) async {
    final allProfiles = ref.read(allProfilesProvider).value;
    if (allProfiles == null || allProfiles.length < 2) return;

    final currentProfile = ref.read(currentProfileProvider).value;

    if (allProfiles.length == 2) {
      final target = allProfiles.firstWhere(
        (p) => p.id != currentProfile?.id,
        orElse: () => allProfiles[0],
      );
      await _performProfileSwitch(target.id);
    } else {
      if (!context.mounted) return;
      final target = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(AppLocalizations.of(ctx)!.switchProfile),
          children: allProfiles
              .where((p) => p.id != currentProfile?.id)
              .map((p) => SimpleDialogOption(
                    onPressed: () => Navigator.of(ctx).pop(p.id),
                    child: Text(p.name),
                  ))
              .toList(),
        ),
      );
      if (target != null) await _performProfileSwitch(target);
    }
  }

  Future<void> _performProfileSwitch(String profileId) async {
    final profileRepo = await ref.read(profileRepositoryProvider.future);
    final profileSwitchingNotifier = ref.read(profileSwitchingProvider.notifier);
    final container = ProviderScope.containerOf(context);

    try {
      await profileRepo.setCurrentProfileId(profileId);
      profileSwitchingNotifier.setSwitching(true);

      container.invalidate(repositoryProvider);
      container.invalidate(allProjectsStreamProvider);
      container.invalidate(releasesProvider);
      container.invalidate(scanRootsProvider);
      container.invalidate(currentProfileProvider);

      await Future.delayed(const Duration(milliseconds: 100));
      await container.read(repositoryProvider.future);
      profileSwitchingNotifier.complete();
    } catch (e) {
      profileSwitchingNotifier.complete();
    }
  }

  Future<void> _scanAll({bool fullMetadata = false}) async {
    if (_scanning) return;
    final repo = await ref.read(repositoryProvider.future);
    setState(() => _scanning = true);
    try {
      final scanner = ScannerService();
      int foundCount = 0;
      await repo.clearMissingFiles();
      final ignoredPaths = repo.getIgnoredPaths().map((p) => p.path).toList(growable: false);
      final scanTime = DateTime.now();
      for (final root in repo.getRoots()) {
        final foundPaths = <String>{};
        await for (final entity in scanner.scanDirectory(root.path, ignoredPaths: ignoredPaths)) {
          await repo.upsertFromFileSystemEntity(entity, fullMetadata: fullMetadata);
          foundPaths.add(entity.path);
          foundCount++;
        }
        await repo.removeOrphanedProjectsFromRoot(root.path, foundPaths);
        await repo.updateRootLastScanAt(root.id, scanTime);
      }

      // Auto-detect preview songs for projects that have neither a manual nor
      // a previously auto-detected path. Runs after the full scan so all upserts
      // are committed before we read back the project list.
      final customFolder = ref.read(customMixdownFolderProvider).value;
      for (final project in repo.getAllProjects()) {
        if (project.previewSongPath != null || project.previewSongAutoPath != null) continue;
        final detected = MixdownDetectorService.findLatestMixdown(project, customFolder: customFolder);
        if (detected != null) {
          await repo.updateProject(project.copyWith(previewSongAutoPath: detected.path));
        }
      }

      if (mounted) {
        final scanType = fullMetadata ? AppLocalizations.of(context)!.deepScan : AppLocalizations.of(context)!.rescan;
        final msg = foundCount == 0
            ? AppLocalizations.of(context)!.noProjectsFoundInRoots
            : AppLocalizations.of(context)!.scanComplete(scanType, foundCount, foundCount == 1 ? '' : 's');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _fullScanAll() async {
    await _scanAll(fullMetadata: true);
  }

  Future<void> _createReleaseFromSelectedProjects(BuildContext context, WidgetRef ref, List<MusicProject> selectedProjects) async {
    if (selectedProjects.isEmpty) return;

    String releaseTitle;
    
    // If single project, use project name; otherwise create with empty title
    if (selectedProjects.length == 1) {
      releaseTitle = selectedProjects.first.displayName;
    } else {
      releaseTitle = ''; // Empty title, user will fill it in the release page
    }

    final selectedProjectIds = selectedProjects.map((p) => p.id).toList();
    await _createRelease(context, ref, selectedProjectIds, releaseTitle);
    
    // Clear selection after creating release
    ref.read(selectedProjectsProvider.notifier).clear();
  }

  Future<void> _hideProjects(BuildContext context, WidgetRef ref, List<String> selectedProjectIds) async {
    try {
      final repo = await ref.read(repositoryProvider.future);
      final allProjectsAsync = ref.read(allProjectsStreamProvider);
      final allProjects = allProjectsAsync.value ?? [];
      
      for (final projectId in selectedProjectIds) {
        final project = allProjects.firstWhere((p) => p.id == projectId);
        final updated = project.copyWith(hidden: true);
        await repo.updateProject(updated);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.projectsHidden(selectedProjectIds.length, selectedProjectIds.length == 1 ? '' : 's'))),
        );
        // Invalidate to refresh the list
        ref.invalidate(allProjectsStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToHideProjects(e.toString()))),
        );
      }
    }
  }

  Future<void> _unhideProjects(BuildContext context, WidgetRef ref, List<String> selectedProjectIds) async {
    try {
      final repo = await ref.read(repositoryProvider.future);
      final allProjectsAsync = ref.read(allProjectsStreamProvider);
      final allProjects = allProjectsAsync.value ?? [];
      
      // Check if we're in "show only hidden" mode
      final hiddenMode = ref.read(showHiddenProjectsProvider);
      final isShowingOnlyHidden = hiddenMode == 2;
      
      // Unhide all selected projects
      for (final projectId in selectedProjectIds) {
        final project = allProjects.firstWhere((p) => p.id == projectId);
        if (kDebugMode) {
          print('DEBUG [Unhide]: Project ${project.displayName} - hidden before: ${project.hidden}');
        }
        // Always set hidden to false, regardless of current state
        final updated = project.copyWith(hidden: false);
        await repo.updateProject(updated);
        
        // Verify the update was saved
        if (kDebugMode) {
          final verifyProject = repo.getAllProjects().firstWhere((p) => p.id == projectId);
          print('DEBUG [Unhide]: Project ${verifyProject.displayName} - hidden after: ${verifyProject.hidden}');
        }
      }
      
      // Invalidate to refresh the list
      ref.invalidate(allProjectsStreamProvider);
      
      // Wait a bit for the data to refresh, then check if there are any hidden projects left
      await Future.delayed(const Duration(milliseconds: 100));
      final updatedProjectsAsync = ref.read(allProjectsStreamProvider);
      final updatedProjects = updatedProjectsAsync.value ?? [];
      final remainingHiddenCount = updatedProjects.where((p) => p.hidden).length;
      
      // If we were showing only hidden and there are no hidden projects left, switch back to visible
      if (isShowingOnlyHidden && remainingHiddenCount == 0) {
        ref.read(showHiddenProjectsProvider.notifier).setShowOnlyHidden(false);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.projectsUnhidden(selectedProjectIds.length, selectedProjectIds.length == 1 ? '' : 's'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToUnhideProjects(e.toString()))),
        );
      }
    }
  }

  Future<void> _createRelease(BuildContext context, WidgetRef ref, List<String> selectedProjectIds, String releaseTitle) async {
    try {
      final repo = await ref.read(repositoryProvider.future);
      final newRelease = Release(
        id: const Uuid().v4(),
        title: releaseTitle,
        trackIds: selectedProjectIds,
        releaseDate: DateTime.now(),
      );
      await repo.addRelease(newRelease);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.releaseCreated(releaseTitle))),
        );
        // Switch to releases tab and navigate to the new release
        _tabController.animateTo(1);
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReleaseDetailPage(releaseId: newRelease.id),
            ),
          );
          // Refresh releases data when returning from detail page
          if (mounted) {
            ref.invalidate(releasesProvider);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToCreateRelease(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = ref.watch(dateFormatProvider);
    final repoAsync = ref.watch(repositoryProvider);
    final roots = ref.watch(scanRootsProvider);

    // Show first-launch dialog on desktop when the profile is truly blank (no
    // roots AND no projects). Profiles that have projects but no roots (e.g.
    // restored from Google Drive) are already set up and should not see this.
    if (!MobileUtils.isMobile() &&
        !_startupDialogShown &&
        !_hideStartupDialog &&
        repoAsync.hasValue &&
        roots.isEmpty &&
        repoAsync.value!.getAllProjects().isEmpty) {
      _startupDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showStartupDialog(context);
      });
    }

    // Keep visible tabs in sync with the provider.
    ref.listen(visibleTabsProvider, (_, next) {
      if (mounted) setState(() => _updateVisibleTabs(next));
    });

    // Get current search text based on active tab
    final currentSearch = switch (_currentTab) {
      AppTab.projects   => ref.watch(projectsSearchProvider),
      AppTab.releases   => ref.watch(releasesSearchProvider),
      AppTab.queue      => ref.watch(queueSearchProvider),
      AppTab.statistics => ref.watch(statisticsSearchProvider),
      AppTab.playlists  => '',
      AppTab.player     => '',
    };
    final projects = ref.watch(projectsProvider);
    // Keep macOS dock menu (and Windows jump list) in sync with latest projects
    ref.listen(projectsProvider, (_, next) => DockMenuService.updateRecentProjects(next));
    final hiddenMode = ref.watch(showHiddenProjectsProvider);
    final hiddenNotifier = ref.read(showHiddenProjectsProvider.notifier);
    final finishedMode = ref.watch(showFinishedProjectsProvider);
    final finishedNotifier = ref.read(showFinishedProjectsProvider.notifier);
    final phaseFilter = ref.watch(phaseFilterProvider);
    final deadlineFilter = ref.watch(deadlineFilterProvider);
    final initialScanning = ref.watch(initialScanStateProvider);
    final isProfileSwitching = ref.watch(profileSwitchingProvider);
    final isScanning = _scanning || initialScanning;
    final isAnyOperation = isScanning || isProfileSwitching || _extractingMetadata;
    final isLeftRail = !MobileUtils.isMobile() && ref.watch(tabPositionProvider) == TabPosition.left;
    
    // Sync search controller with provider state
    if (_searchController.text != currentSearch) {
      _searchController.text = currentSearch;
      _searchController.selection = TextSelection.fromPosition(TextPosition(offset: currentSearch.length));
    }
    
    // Get all projects and filter out preserved projects (same logic as projectsProvider)
    final allProjectsAsync = ref.watch(allProjectsStreamProvider);
    final allProjects = allProjectsAsync.value ?? [];
    final releasesAsync = ref.watch(releasesProvider);
    final scanRoots = ref.watch(scanRootsProvider);
    
    // Filter out preserved projects (in releases but not in any active scan root)
    // On mobile, we're only syncing metadata, so show ALL projects (both in releases and not)
    // On desktop, filter preserved projects that aren't in active scan roots
    final List<MusicProject> filteredProjects;
    if (MobileUtils.isMobile()) {
      // Mobile: show all projects (metadata-only mode, no file system checks)
      filteredProjects = allProjects;
    } else {
      // Desktop: filter preserved projects that aren't in active scan roots
      final releases = releasesAsync.value ?? [];
      final protectedProjectIds = <String>{};
      for (final release in releases) {
        protectedProjectIds.addAll(release.trackIds);
      }
      
      // Get all active scan root paths (normalized for comparison)
      final activeRootPaths = scanRoots.map((root) {
        final normalized = path.normalize(root.path);
        // Ensure root path ends with separator for proper prefix matching
        return normalized.endsWith(path.separator) ? normalized : normalized + path.separator;
      }).toList();
      
      // Filter out preserved projects before counting
      filteredProjects = allProjects.where((project) {
        // If project is not in any release, always include it
        if (!protectedProjectIds.contains(project.id)) {
          return true;
        }
        
        // If project is in a release, check if it's in any active scan root
        final projectPath = path.normalize(project.filePath);
        final isInActiveRoot = activeRootPaths.any((rootPath) {
          // Check if project path starts with the root path
          return projectPath.startsWith(rootPath);
        });
        
        // Only include if it's in an active root (preserved projects not in active roots are excluded)
        return isInActiveRoot;
      }).toList();
    }
    
    // Count visible and hidden from filtered projects only
    final visibleCount = filteredProjects.where((p) => !p.hidden).length;
    final hiddenCount = filteredProjects.where((p) => p.hidden).length;

    // RawKeyboardListener is now the primary handler for Ctrl+F and Ctrl+R
    // This ensures it works even when other widgets (like PlutoGrid) have focus
    return RawKeyboardListener(
      focusNode: _debugKeyboardFocusNode,
      autofocus: true, // Autofocus to ensure we capture keyboard events
      onKey: _handleDebugKeyEvent,
      child: FocusScope(
        child: Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(
              Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
              LogicalKeyboardKey.keyF,
            ): const _SearchIntent(),
            LogicalKeySet(
              Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
              LogicalKeyboardKey.keyR,
            ): const _RescanIntent(),
            LogicalKeySet(
              Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
              LogicalKeyboardKey.keyT,
            ): const _FocusTableIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _SearchIntent: _SearchAction(() {
                _focusSearchAndSelectAll();
              }),
              _RescanIntent: _RescanAction(() {
                _scanAll();
              }),
              _FocusTableIntent: CallbackAction<_FocusTableIntent>(
                onInvoke: (_) => _tableKey.currentState?.focusTable(),
              ),
            },
          child: Focus(
            autofocus: true,
            canRequestFocus: true,
            child: Stack(
            children: [
              Scaffold(
                appBar: MobileUtils.isMobile()
                    ? AppBar(
                        leading: _isSearchingMobile
                            ? IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () {
                                  setState(() => _isSearchingMobile = false);
                                  _clearCurrentTabSearch();
                                },
                              )
                            : null,
                        title: _isSearchingMobile
                            ? TextField(
                                autofocus: true,
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: switch (_currentTab) {
                                    AppTab.projects   => AppLocalizations.of(context)!.searchProjects,
                                    AppTab.releases   => AppLocalizations.of(context)!.searchReleases,
                                    AppTab.queue      => AppLocalizations.of(context)!.queueSearchHint,
                                    _                 => AppLocalizations.of(context)!.statsSearchProjects,
                                  },
                                  border: InputBorder.none,
                                  hintStyle: const TextStyle(color: Colors.white54),
                                ),
                                style: const TextStyle(color: Colors.white),
                                onChanged: _updateCurrentTabSearch,
                              )
                            : Image.asset('app_icon.png', height: 32),
                        actions: _isSearchingMobile
                            ? [
                                if (currentSearch.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      _clearCurrentTabSearch();
                                    },
                                  ),
                              ]
                            : [
                                // Search icon (hidden on Playlists tab)
                                if (_currentTab != AppTab.playlists)
                                  IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: () => setState(() => _isSearchingMobile = true),
                                  ),
                                // Notification settings button (Android only)
                                if (Platform.isAndroid)
                                  IconButton(
                                    icon: const Icon(Icons.notifications),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const NotificationSettingsPage(),
                                        ),
                                      );
                                    },
                                    tooltip: AppLocalizations.of(context)!.notificationSettings,
                                  ),
                                // Google Drive sync (hidden when left rail — shown there instead)
                                if (!isLeftRail)
                                  IconButton(
                                    icon: const Icon(Icons.cloud_outlined),
                                    tooltip: AppLocalizations.of(context)!.syncWithGoogleDrive,
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const GoogleDriveSyncPage()),
                                    ),
                                  ),
                                // Quick profile switch button (hidden when left rail)
                                if (!isLeftRail)
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final allProfiles = ref.watch(allProfilesProvider).value;
                                      if (allProfiles == null || allProfiles.length < 2) return const SizedBox.shrink();
                                      return IconButton(
                                        icon: const Icon(Icons.swap_horiz),
                                        tooltip: AppLocalizations.of(context)!.switchProfile,
                                        onPressed: () => _quickSwitchProfile(context),
                                      );
                                    },
                                  ),
                                // Profile button (hidden when left rail)
                                if (!isLeftRail)
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final currentProfileAsync = ref.watch(currentProfileProvider);
                                      return currentProfileAsync.when(
                                        loading: () => IconButton(
                                          icon: const Icon(Icons.person),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => const ProfileManagerPage(),
                                              ),
                                            );
                                          },
                                          tooltip: AppLocalizations.of(context)!.profileManager,
                                        ),
                                        error: (_, _) => IconButton(
                                          icon: const Icon(Icons.person),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => const ProfileManagerPage(),
                                              ),
                                            );
                                          },
                                          tooltip: AppLocalizations.of(context)!.profileManager,
                                        ),
                                        data: (currentProfile) {
                                          Widget profileIcon;
                                          if (currentProfile?.photoPath != null &&
                                              File(currentProfile!.photoPath!).existsSync()) {
                                            profileIcon = ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: Image.file(
                                                File(currentProfile.photoPath!),
                                                width: 32,
                                                height: 32,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(Icons.person);
                                                },
                                              ),
                                            );
                                          } else {
                                            profileIcon = const Icon(Icons.person);
                                          }
                                          return IconButton(
                                            icon: profileIcon,
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => const ProfileManagerPage(),
                                                ),
                                              );
                                            },
                                            tooltip: currentProfile?.name ?? AppLocalizations.of(context)!.profileManager,
                                          );
                                        },
                                      );
                                    },
                                  ),
                              ],
                      )
                    : null,
                bottomNavigationBar: MobileUtils.isMobile()
                    ? NavigationBar(
                        selectedIndex: _tabController.index,
                        onDestinationSelected: (i) {
                          _tabController.animateTo(i);
                          setState(() {});
                        },
                        destinations: [
                          for (final tab in _currentVisibleTabs)
                            switch (tab) {
                              AppTab.projects => NavigationDestination(
                                  icon: const Icon(Icons.library_music_outlined),
                                  selectedIcon: const Icon(Icons.library_music),
                                  label: AppLocalizations.of(context)!.projects,
                                ),
                              AppTab.releases => NavigationDestination(
                                  icon: const Icon(Icons.album_outlined),
                                  selectedIcon: const Icon(Icons.album),
                                  label: AppLocalizations.of(context)!.releasesTab,
                                ),
                              AppTab.playlists => NavigationDestination(
                                  icon: const Icon(Icons.playlist_play_outlined),
                                  selectedIcon: const Icon(Icons.playlist_play),
                                  label: AppLocalizations.of(context)!.playlists,
                                ),
                              AppTab.queue => NavigationDestination(
                                  icon: const Icon(Icons.checklist_outlined),
                                  selectedIcon: const Icon(Icons.checklist),
                                  label: AppLocalizations.of(context)!.queueTab,
                                ),
                              AppTab.statistics => NavigationDestination(
                                  icon: const Icon(Icons.bar_chart_outlined),
                                  selectedIcon: const Icon(Icons.bar_chart_rounded),
                                  label: AppLocalizations.of(context)!.statisticsTab,
                                ),
                              // player is desktop-only; filtered out of _currentVisibleTabs on mobile
                              AppTab.player => NavigationDestination(
                                  icon: const Icon(Icons.headphones_outlined),
                                  selectedIcon: const Icon(Icons.headphones),
                                  label: AppLocalizations.of(context)!.playerTitle,
                                ),
                            },
                        ],
                      )
                    : () {
                        final playerRequest = ref.watch(desktopPlayerProvider);
                        if (playerRequest == null) return null;
                        return _DesktopPlayerBar(
                          key: const Key('desktop_player_bar'),
                          request: playerRequest,
                        );
                      }(),
                body: Builder(builder: (context) {
                  final col = Column(
          children: [
            // Custom title bar – Windows/Linux only.
            // macOS uses the native title bar + MacOSMenuBar for Theme/Language/Support.
            DesktopTitleBar(
              title: AppLocalizations.of(context)!.appTitleWithVersion(appVersion),
              actions: [
                // Donate button
                Consumer(
                  builder: (context, ref, child) {
                    final l10n = AppLocalizations.of(context)!;
                    return Tooltip(
                      message: l10n.supportTheProject,
                      child: TextButton.icon(
                        icon: const Icon(Icons.card_giftcard, size: 18, color: Colors.white70),
                        label: Text(
                          l10n.support,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        onPressed: () async {
                          final uri = Uri.parse('https://www.paypal.com/donate/?hosted_button_id=QHVVZ3LAF39BL');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                const ThemeSwitcher(),
                const SizedBox(width: 8),
                const LanguageSwitcher(),
                const SizedBox(width: 8),
                Tooltip(
                  message: AppLocalizations.of(context)!.menuDocumentation,
                  child: IconButton(
                    icon: const Icon(Icons.menu_book_outlined, size: 18, color: Colors.white70),
                    onPressed: () => launchUrl(
                      Uri.parse('https://dpm.bandpassrecords.com/docs.html'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: AppLocalizations.of(context)!.keyboardShortcuts,
                  child: IconButton(
                    icon: const Icon(Icons.keyboard_outlined, size: 18, color: Colors.white70),
                    onPressed: () => showShortcutsHelpDialog(context),
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: AppLocalizations.of(context)!.customizeTabs,
                  child: IconButton(
                    icon: const Icon(Icons.tab_outlined, size: 18, color: Colors.white70),
                    onPressed: () => showTabCustomizationDialog(context),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
            
            // CONTEÚDO DA BARRA DE AÇÕES E PESQUISA
            Builder(
              builder: (context) {
                final isMobile = MobileUtils.isMobile();
                if (isMobile) return const SizedBox.shrink();
                return Padding(
                  padding: MobileUtils.getResponsivePadding(context),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search bar on top for mobile (hidden on Playlists tab)
                            if (_currentTab != AppTab.playlists) TextField(
                              focusNode: _searchFocusNode,
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: switch (_currentTab) {
                                  AppTab.projects  => AppLocalizations.of(context)!.searchProjects,
                                  AppTab.releases  => AppLocalizations.of(context)!.searchReleases,
                                  AppTab.queue     => AppLocalizations.of(context)!.queueSearchHint,
                                  _                => AppLocalizations.of(context)!.statsSearchProjects,
                                },
                                isDense: true,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: () {
                                  final cs = currentSearch;
                                  return cs.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: _clearCurrentTabSearch,
                                        )
                                      : null;
                                }(),
                              ),
                              onChanged: _updateCurrentTabSearch,
                            ),
                            if (_currentTab != AppTab.playlists)
                              const SizedBox(height: 12),
                            // Filters and info row (only show on Projects tab)
                            if (_currentTab == AppTab.projects) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: repoAsync.when(
                                      loading: () => const SizedBox.shrink(),
                                      error: (_, _) => const SizedBox.shrink(),
                                      data: (repo) {
                                        String projectText;
                                        final l10n = AppLocalizations.of(context)!;
                                        // On mobile, don't show roots count (Android doesn't use scan roots)
                                        if (hiddenMode == 2) {
                                          projectText = '${l10n.projectsCount(hiddenCount)} ${l10n.hiddenOnly}';
                                        } else {
                                          projectText = l10n.projectsCount(visibleCount);
                                          if (hiddenCount > 0 && hiddenMode == 0) {
                                            projectText += ' ${l10n.hiddenCount(hiddenCount)}';
                                          }
                                        }
                                        return Text(
                                          projectText,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: hiddenMode == 2 ? Colors.orange.shade300 : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Filter row
                              Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // Show Hidden Projects checkbox (Mobile) - only show if there are hidden projects
                                if (hiddenCount > 0)
                                  InkWell(
                                    onTap: () {
                                      final currentValue = hiddenMode == 1;
                                      if (!currentValue) {
                                        hiddenNotifier.setShowAll(true);
                                      } else {
                                        hiddenNotifier.setShowAll(false);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(
                                          value: hiddenMode == 1,
                                          onChanged: (value) {
                                            if (value == true) {
                                              hiddenNotifier.setShowAll(true);
                                            } else {
                                              hiddenNotifier.setShowAll(false);
                                            }
                                          },
                                        ),
                                        Text(
                                          AppLocalizations.of(context)!.showHidden,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Hide Finished Projects checkbox (Mobile)
                                InkWell(
                                  onTap: () {
                                    final currentValue = finishedMode == 1;
                                    if (!currentValue) {
                                      finishedNotifier.setHideFinished(true);
                                    } else {
                                      finishedNotifier.setHideFinished(false);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: finishedMode == 1,
                                        onChanged: (value) {
                                          if (value == true) {
                                            finishedNotifier.setHideFinished(true);
                                          } else {
                                            finishedNotifier.setHideFinished(false);
                                          }
                                        },
                                      ),
                                      Text(
                                        AppLocalizations.of(context)!.hideFinished,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                // Show Deadline checkbox (Mobile)
                                InkWell(
                                  onTap: () {
                                    final currentValue = ref.read(showOnlyWithDeadlineProvider);
                                    ref.read(showOnlyWithDeadlineProvider.notifier).setShowOnlyWithDeadline(!currentValue);
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: ref.watch(showOnlyWithDeadlineProvider),
                                        onChanged: (value) {
                                          ref.read(showOnlyWithDeadlineProvider.notifier).setShowOnlyWithDeadline(value == true);
                                        },
                                      ),
                                      Text(
                                        AppLocalizations.of(context)!.showOnlyDeadlines,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hiddenCount > 0)
                                  TextButton.icon(
                                    icon: Icon(
                                      hiddenMode == 2 ? Icons.visibility : Icons.visibility_off_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      hiddenMode == 2 ? AppLocalizations.of(context)!.showAll : AppLocalizations.of(context)!.showOnlyHidden,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: hiddenMode == 2 ? Colors.orange.shade700 : null,
                                      foregroundColor: hiddenMode == 2 ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                                    onPressed: () {
                                      if (hiddenMode == 2) {
                                        hiddenNotifier.setShowOnlyHidden(false);
                                      } else {
                                        hiddenNotifier.setShowOnlyHidden(true);
                                      }
                                    },
                                  ),
                                DropdownButton<String>(
                                  value: phaseFilter,
                                  hint: Text(
                                    AppLocalizations.of(context)!.filterByPhase,
                                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                                  ),
                                  underline: const SizedBox.shrink(),
                                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                                  icon: Icon(Icons.filter_list, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(AppLocalizations.of(context)!.allPhases),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'Idea',
                                      child: Text(AppLocalizations.of(context)!.projectPhaseIdea),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'Arranging',
                                      child: Text(AppLocalizations.of(context)!.projectPhaseArranging),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'Mixing',
                                      child: Text(AppLocalizations.of(context)!.projectPhaseMixing),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'Mastering',
                                      child: Text(AppLocalizations.of(context)!.projectPhaseMastering),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'Finished',
                                      child: Text(AppLocalizations.of(context)!.projectPhaseFinished),
                                    ),
                                  ],
                          onChanged: (String? value) {
                            ref.read(phaseFilterProvider.notifier).setPhase(value);
                          },
                        ),
                        // Deadline Filter dropdown (Desktop only)
                        if (!MobileUtils.isMobile())
                          DropdownButton<DeadlineFilter>(
                            value: deadlineFilter,
                            hint: Text(
                              AppLocalizations.of(context)!.filterByDeadline,
                              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                            ),
                            underline: const SizedBox.shrink(),
                            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                            icon: Icon(Icons.schedule, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                            items: [
                              DropdownMenuItem<DeadlineFilter>(
                                value: DeadlineFilter.all,
                                child: Text(AppLocalizations.of(context)!.allDeadlines),
                              ),
                              DropdownMenuItem<DeadlineFilter>(
                                value: DeadlineFilter.hasDeadline,
                                child: Text(AppLocalizations.of(context)!.hasDeadline),
                              ),
                              DropdownMenuItem<DeadlineFilter>(
                                value: DeadlineFilter.overdue,
                                child: Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.red, size: 16),
                                    const SizedBox(width: 4),
                                    Text(AppLocalizations.of(context)!.overdue),
                                  ],
                                ),
                              ),
                              DropdownMenuItem<DeadlineFilter>(
                                value: DeadlineFilter.dueSoon,
                                child: Row(
                                  children: [
                                    Icon(Icons.schedule, color: Colors.orange, size: 16),
                                    const SizedBox(width: 4),
                                    Text(AppLocalizations.of(context)!.dueSoon),
                                  ],
                                ),
                              ),
                              DropdownMenuItem<DeadlineFilter>(
                                value: DeadlineFilter.dueToday,
                                child: Row(
                                  children: [
                                    Icon(Icons.today, color: Colors.red, size: 16),
                                    const SizedBox(width: 4),
                                    Text(AppLocalizations.of(context)!.dueToday),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (DeadlineFilter? value) {
                              if (value != null) {
                                ref.read(deadlineFilterProvider.notifier).setFilter(value);
                              }
                            },
                          ),
                      ],
                    ),
                            ],
                          ],
                        )
                      : Row(
                          children: [
                  // Ações de Root e Scan
                  Row(
                      children: [
                        // Quick profile switch button (hidden when left rail)
                        if (!isLeftRail)
                          Consumer(
                            builder: (context, ref, child) {
                              final allProfiles = ref.watch(allProfilesProvider).value;
                              if (allProfiles == null || allProfiles.length < 2) return const SizedBox.shrink();
                              return IconButton(
                                icon: const Icon(Icons.swap_horiz),
                                tooltip: AppLocalizations.of(context)!.switchProfile,
                                onPressed: () => _quickSwitchProfile(context),
                              );
                            },
                          ),
                        // Profile button (hidden when left rail)
                        if (!isLeftRail)
                          Consumer(
                            builder: (context, ref, child) {
                              final currentProfileAsync = ref.watch(currentProfileProvider);
                              return currentProfileAsync.when(
                                loading: () => Tooltip(
                                  message: AppLocalizations.of(context)!.profileManager,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.person, size: 24),
                                    label: Text(AppLocalizations.of(context)!.profileManager),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const ProfileManagerPage(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                error: (_, _) => Tooltip(
                                  message: AppLocalizations.of(context)!.profileManager,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.person, size: 24),
                                    label: Text(AppLocalizations.of(context)!.profileManager),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const ProfileManagerPage(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                data: (currentProfile) {
                                  Widget profileIcon;
                                  if (currentProfile?.photoPath != null &&
                                      File(currentProfile!.photoPath!).existsSync()) {
                                    profileIcon = ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(currentProfile.photoPath!),
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.person, size: 24);
                                        },
                                      ),
                                    );
                                  } else {
                                    profileIcon = const Icon(Icons.person, size: 24);
                                  }

                                  final profileName = currentProfile?.name ?? AppLocalizations.of(context)!.profileManager;

                                  return Tooltip(
                                    message: profileName,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const ProfileManagerPage(),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          profileIcon,
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 150),
                                              child: Text(
                                                profileName,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        if (!isLeftRail) const SizedBox(width: 8),
                        if (!isLeftRail && !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) ...[
                          OutlinedButton.icon(
                            onPressed: isAnyOperation
                                ? null
                                : () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ProjectFoldersSettingsPage(),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.settings_outlined),
                            label: Text(AppLocalizations.of(context)!.settings),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (!isLeftRail) ElevatedButton.icon(
                          onPressed: isAnyOperation
                              ? null
                              : () async {
                                    await _scanAll();
                                  },
                          icon: isAnyOperation
                              ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                              : const Icon(Icons.refresh),
                          label: Text(isAnyOperation ? AppLocalizations.of(context)!.scanning : AppLocalizations.of(context)!.rescan),
                        ),
                        if (!isLeftRail) ...[
                          const SizedBox(width: 12),
                          Tooltip(
                            message: AppLocalizations.of(context)!.deepScanTooltip,
                            waitDuration: const Duration(milliseconds: 500),
                            child: ElevatedButton.icon(
                              onPressed: isAnyOperation
                                  ? null
                                  : () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: Theme.of(context).cardColor,
                                            title: Text(AppLocalizations.of(context)!.deepScan),
                                            content: Text(AppLocalizations.of(context)!.deepScanConfirm),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: Text(AppLocalizations.of(context)!.cancel),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                                ),
                                                child: Text(AppLocalizations.of(context)!.deepScan),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await _fullScanAll();
                                        }
                                      },
                              icon: isAnyOperation
                                  ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                  : const Icon(Icons.search),
                              label: Text(isAnyOperation ? AppLocalizations.of(context)!.scanning : AppLocalizations.of(context)!.deepScan),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(width: 8),
                  // Google Drive sync (hidden when left rail — shown there instead)
                  if (!MobileUtils.isMobile() && !isLeftRail)
                    Tooltip(
                      message: AppLocalizations.of(context)!.syncWithGoogleDrive,
                      child: IconButton(
                        icon: const Icon(Icons.cloud_outlined),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const GoogleDriveSyncPage()),
                        ),
                      ),
                    ),
                  const SizedBox(width: 16),
                  // Active DAW session chip
                  const _ActiveProjectChip(),
                  const SizedBox(width: 8),
                  // Search bar (desktop only — hidden on Playlists tab)
                  if (!MobileUtils.isMobile())
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ClipRect(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            width: (isLeftRail || _isSearchingDesktop) ? 400 : 0,
                            child: Focus(
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey == LogicalKeyboardKey.escape) {
                                  _collapseDesktopSearch();
                                  return KeyEventResult.handled;
                                }
                                return KeyEventResult.ignored;
                              },
                              child: TextField(
                              focusNode: _searchFocusNode,
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: switch (_currentTab) {
                                  AppTab.projects   => AppLocalizations.of(context)!.searchProjects,
                                  AppTab.releases   => AppLocalizations.of(context)!.searchReleases,
                                  AppTab.queue      => AppLocalizations.of(context)!.queueSearchHint,
                                  _                 => AppLocalizations.of(context)!.statsSearchProjects,
                                },
                                isDense: true,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: isLeftRail
                                    ? (ref.watch(sessionModeProvider) && _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.close, size: 18),
                                            tooltip: AppLocalizations.of(context)!.clear,
                                            onPressed: () {
                                              _searchController.clear();
                                              _updateCurrentTabSearch('');
                                            },
                                          )
                                        : null)
                                    : IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: _collapseDesktopSearch,
                                      ),
                              ),
                              onChanged: _updateCurrentTabSearch,
                            ),
                          ),
                        ),
                        ),
                        if (!isLeftRail)
                          Tooltip(
                            message: '${AppLocalizations.of(context)!.searchProjects} (${Platform.isMacOS ? 'Cmd+F' : 'Ctrl+F'})',
                            child: IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: _focusSearchAndSelectAll,
                            ),
                          ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ],
              ),
            );
            },
          ),

            // Project folders are managed in the dedicated desktop-only settings page.
            // Tab Bar (desktop only - mobile uses AppBar bottom)
            if (!MobileUtils.isMobile() && ref.watch(tabPositionProvider) == TabPosition.top)
              Builder(
                builder: (context) => TabBar(
                  controller: _tabController,
                  tabs: [
                    for (final tab in _currentVisibleTabs)
                      switch (tab) {
                        AppTab.projects   => Tab(icon: const Icon(Icons.library_music), text: AppLocalizations.of(context)!.projectsTab),
                        AppTab.releases   => Tab(icon: const Icon(Icons.album), text: AppLocalizations.of(context)!.releasesTab),
                        AppTab.playlists  => Tab(icon: const Icon(Icons.playlist_play), text: AppLocalizations.of(context)!.playlists),
                        AppTab.queue      => Tab(icon: const Icon(Icons.checklist), text: AppLocalizations.of(context)!.queueTab),
                        AppTab.statistics => Tab(icon: const Icon(Icons.bar_chart_rounded), text: AppLocalizations.of(context)!.statisticsTab),
                        AppTab.player     => const Tab(icon: Icon(Icons.headphones), text: 'Music Player'),
                      },
                  ],
                  labelColor: Theme.of(context).textTheme.titleMedium?.color,
                  unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            // Tab Bar View (with optional left NavigationRail)
            Expanded(
              child: Builder(builder: (context) {
                final tabView = TabBarView(
                  controller: _tabController,
                  children: [
                    for (final tab in _currentVisibleTabs)
                      switch (tab) {
                        AppTab.projects => MobileUtils.isMobile()
                          ? _MobileProjectsList(
                              projects: projects,
                              dateFormat: dateFormat,
                              onCreateRelease: (selectedProjects) {
                                _createReleaseFromSelectedProjects(context, ref, selectedProjects);
                              },
                              onHideProjects: (selectedProjectIds) async {
                                await _hideProjects(context, ref, selectedProjectIds);
                              },
                              onUnhideProjects: (selectedProjectIds) async {
                                await _unhideProjects(context, ref, selectedProjectIds);
                              },
                              showHidden: hiddenMode == 1 || hiddenMode == 2,
                            )
                          : _PlutoProjectsTableWithSelection(
                              key: _tableKey,
                              projects: projects,
                              dateFormat: dateFormat,
                              onCreateRelease: (selectedProjects) {
                                _createReleaseFromSelectedProjects(context, ref, selectedProjects);
                              },
                              onHideProjects: (selectedProjectIds) async {
                                await _hideProjects(context, ref, selectedProjectIds);
                              },
                              onUnhideProjects: (selectedProjectIds) async {
                                await _unhideProjects(context, ref, selectedProjectIds);
                              },
                              showHidden: hiddenMode == 1 || hiddenMode == 2,
                              onExtractingMetadataChanged: (extracting) {
                                setState(() => _extractingMetadata = extracting);
                              },
                              isAnyOperation: isAnyOperation,
                              visibleCount: visibleCount,
                              hiddenCount: hiddenCount,
                            ),
                      AppTab.releases   => const ReleasesTabPage(),
                      AppTab.playlists  => const PlaylistsPage(),
                      AppTab.queue      => const QueuePage(),
                      AppTab.statistics => const StatisticsPage(),
                      AppTab.player     => const MusicPlayerPage(),
                    },
                  ],
                );
                return tabView;
              }),
            ),
          ],
                );
                if (!isLeftRail) return col;
                return Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _tabController.index,
                      onDestinationSelected: (i) => _tabController.animateTo(i),
                      minWidth: _railCollapsed ? 64.0 : _railWidth,
                      labelType: _railCollapsed
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      leading: Column(
                        children: [
                          // Collapse/expand toggle
                          Tooltip(
                            message: _railCollapsed
                                ? AppLocalizations.of(context)!.expand
                                : AppLocalizations.of(context)!.collapse,
                            child: IconButton(
                              icon: Icon(_railCollapsed
                                  ? Icons.chevron_right
                                  : Icons.chevron_left),
                              onPressed: () => setState(() {
                                if (_railCollapsed) _railWidth = 130.0;
                                _railCollapsed = !_railCollapsed;
                              }),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Profile avatar + name
                          Consumer(builder: (ctx, ref, _) {
                            final profile = ref.watch(currentProfileProvider).value;
                            final hasPhoto = profile?.photoPath != null &&
                                File(profile!.photoPath!).existsSync();
                            const avatarSize = 44.0;
                            final Widget avatar = hasPhoto
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(avatarSize),
                                    child: Image.file(
                                      File(profile.photoPath!),
                                      width: avatarSize,
                                      height: avatarSize,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: avatarSize,
                                    height: avatarSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    ),
                                    child: const Icon(Icons.person, size: 26),
                                  );
                            return Tooltip(
                              message: profile?.name ??
                                  AppLocalizations.of(context)!.profileManager,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileManagerPage(),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 4),
                                  child: _railCollapsed
                                      ? avatar
                                      : Column(
                                          children: [
                                            avatar,
                                            if (profile?.name != null) ...[
                                              const SizedBox(height: 4),
                                              SizedBox(
                                                width: 80,
                                                child: Text(
                                                  profile!.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                ),
                              ),
                            );
                          }),
                          // Quick profile switch (multiple profiles only)
                          Consumer(builder: (ctx, ref, _) {
                            final allProfiles =
                                ref.watch(allProfilesProvider).value;
                            if (allProfiles == null || allProfiles.length < 2) {
                              return const SizedBox.shrink();
                            }
                            return Tooltip(
                              message: AppLocalizations.of(context)!
                                  .switchProfile,
                              child: IconButton(
                                icon: const Icon(Icons.swap_horiz, size: 18),
                                onPressed: () =>
                                    _quickSwitchProfile(context),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      ),
                      destinations: [
                        for (final tab in _currentVisibleTabs)
                          switch (tab) {
                            AppTab.projects   => NavigationRailDestination(icon: Tooltip(message: AppLocalizations.of(context)!.projectsTab, child: const Icon(Icons.library_music)), label: Text(AppLocalizations.of(context)!.projectsTab)),
                            AppTab.releases   => NavigationRailDestination(icon: Tooltip(message: AppLocalizations.of(context)!.releasesTab, child: const Icon(Icons.album)), label: Text(AppLocalizations.of(context)!.releasesTab)),
                            AppTab.playlists  => NavigationRailDestination(icon: Tooltip(message: AppLocalizations.of(context)!.playlists, child: const Icon(Icons.playlist_play)), label: Text(AppLocalizations.of(context)!.playlists)),
                            AppTab.queue      => NavigationRailDestination(icon: Tooltip(message: AppLocalizations.of(context)!.queueTab, child: const Icon(Icons.checklist)), label: Text(AppLocalizations.of(context)!.queueTab)),
                            AppTab.statistics => NavigationRailDestination(icon: Tooltip(message: AppLocalizations.of(context)!.statisticsTab, child: const Icon(Icons.bar_chart_rounded)), label: Text(AppLocalizations.of(context)!.statisticsTab)),
                            AppTab.player     => NavigationRailDestination(icon: const Tooltip(message: 'Music Player', child: Icon(Icons.headphones)), label: const Text('Music Player')),
                          },
                      ],
                      trailing: Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Google Drive sync
                                Tooltip(
                                  message: AppLocalizations.of(context)!.googleDriveSync,
                                  child: IconButton(
                                    icon: const Icon(Icons.cloud_outlined),
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const GoogleDriveSyncPage()),
                                    ),
                                  ),
                                ),
                                if (!_railCollapsed)
                                  Text(
                                    AppLocalizations.of(context)!.googleDriveSync,
                                    style: Theme.of(context).textTheme.labelSmall,
                                    textAlign: TextAlign.center,
                                  ),
                                const SizedBox(height: 8),
                                // Rescan
                                Tooltip(
                                  message: isAnyOperation
                                      ? AppLocalizations.of(context)!.scanning
                                      : AppLocalizations.of(context)!.rescan,
                                  child: IconButton(
                                    icon: isAnyOperation
                                        ? const SizedBox(
                                            width: 18, height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.refresh),
                                    onPressed: isAnyOperation ? null : () => _scanAll(),
                                  ),
                                ),
                                if (!_railCollapsed)
                                  Text(
                                    isAnyOperation
                                        ? AppLocalizations.of(context)!.scanning
                                        : AppLocalizations.of(context)!.rescan,
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                const SizedBox(height: 8),
                                // Deep scan
                                Tooltip(
                                  message: AppLocalizations.of(context)!.deepScanTooltip,
                                  waitDuration: const Duration(milliseconds: 500),
                                  child: IconButton(
                                    icon: isAnyOperation
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Icon(Icons.search),
                                    onPressed: isAnyOperation
                                        ? null
                                        : () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                backgroundColor: Theme.of(context).cardColor,
                                                title: Text(AppLocalizations.of(context)!.deepScan),
                                                content: Text(AppLocalizations.of(context)!.deepScanConfirm),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, false),
                                                    child: Text(AppLocalizations.of(context)!.cancel),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                                                    child: Text(AppLocalizations.of(context)!.deepScan),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) await _fullScanAll();
                                          },
                                  ),
                                ),
                                if (!_railCollapsed)
                                  Text(
                                    AppLocalizations.of(context)!.deepScan,
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                const SizedBox(height: 8),
                                // Settings
                                Tooltip(
                                  message: AppLocalizations.of(context)!.settings,
                                  child: IconButton(
                                    icon: const Icon(Icons.settings_outlined),
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ProjectFoldersSettingsPage(),
                                      ),
                                    ),
                                  ),
                                ),
                                if (!_railCollapsed)
                                  Text(
                                    AppLocalizations.of(context)!.settings,
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Drag handle to resize the rail
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeColumn,
                      child: GestureDetector(
                        onHorizontalDragUpdate: _railCollapsed
                            ? null
                            : (details) => setState(() {
                                  _railWidth = (_railWidth + details.delta.dx)
                                      .clamp(120.0, 400.0);
                                }),
                        child: Container(
                          width: 6,
                          color: Colors.transparent,
                          child: Center(
                            child: Container(
                              width: 1,
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: col),
                  ],
                );
                }),
              ),
              // Loading overlay
              if (isAnyOperation)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Card(
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              isProfileSwitching ? AppLocalizations.of(context)!.switchingProfiles : AppLocalizations.of(context)!.scanningProjects,
                              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }
} 

class _PlutoProjectsTableWithSelection extends ConsumerStatefulWidget {
  final List<MusicProject> projects;
  final DateFormat dateFormat;
  final Function(List<MusicProject>) onCreateRelease;
  final Function(List<String>) onHideProjects;
  final Function(List<String>) onUnhideProjects;
  final bool showHidden;
  final Function(bool) onExtractingMetadataChanged;
  final bool isAnyOperation;
  final int visibleCount;
  final int hiddenCount;

  const _PlutoProjectsTableWithSelection({
    super.key,
    required this.projects,
    required this.dateFormat,
    required this.onCreateRelease,
    required this.onHideProjects,
    required this.onUnhideProjects,
    required this.showHidden,
    required this.onExtractingMetadataChanged,
    required this.isAnyOperation,
    required this.visibleCount,
    required this.hiddenCount,
  });

  @override
  ConsumerState<_PlutoProjectsTableWithSelection> createState() => _PlutoProjectsTableWithSelectionState();
}

class _PlutoProjectsTableWithSelectionState extends ConsumerState<_PlutoProjectsTableWithSelection> {
  final _innerTableKey = GlobalKey<_PlutoProjectsTableState>();

  void focusTable() => _innerTableKey.currentState?.focusTable();

  Set<String> get _selectedProjectIds => ref.watch(selectedProjectsProvider);

  void _clearSelection() {
    ref.read(selectedProjectsProvider.notifier).clear();
  }

  void _toggleProjectSelection(String projectId) {
    ref.read(selectedProjectsProvider.notifier).toggle(projectId);
  }

  void _selectAll() {
    ref.read(selectedProjectsProvider.notifier).selectAll(widget.projects.map((p) => p.id).toList());
  }

  bool get _areAllSelected {
    if (widget.projects.isEmpty) return false;
    return _selectedProjectIds.length == widget.projects.length &&
        widget.projects.every((p) => _selectedProjectIds.contains(p.id));
  }

  Future<void> _showChangeStatusDialog(BuildContext context) async {
    String? selectedStatus;
    
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.changeStatus),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.selectNewStatus),
              const SizedBox(height: 16),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.projectPhaseIdea),
                value: 'Idea',
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.projectPhaseArranging),
                value: 'Arranging',
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.projectPhaseMixing),
                value: 'Mixing',
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.projectPhaseMastering),
                value: 'Mastering',
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.projectPhaseFinished),
                value: 'Finished',
                groupValue: selectedStatus,
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: selectedStatus == null
                  ? null
                  : () => Navigator.pop(ctx, selectedStatus),
              child: Text(AppLocalizations.of(context)!.changeStatus),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      await _changeProjectsStatus(context, result);
    }
  }

  Future<void> _changeProjectsStatus(BuildContext context, String newStatus) async {
    try {
      final repo = await ref.read(repositoryProvider.future);
      final allProjectsAsync = ref.read(allProjectsStreamProvider);
      final allProjects = allProjectsAsync.value ?? [];
      
      int successCount = 0;
      int failCount = 0;
      
      for (final projectId in _selectedProjectIds) {
        try {
          final project = allProjects.firstWhere((p) => p.id == projectId);
          // Track when status changes
          final statusChanged = project.status != newStatus;
          final updated = project.copyWith(
            status: newStatus,
            statusChangedAt: statusChanged ? DateTime.now() : null,
          );
          await repo.updateProject(updated);
          successCount++;
        } catch (e) {
          failCount++;
          if (kDebugMode) {
            print('Failed to update project $projectId: $e');
          }
        }
      }
      
      // Refresh the projects list
      ref.invalidate(allProjectsStreamProvider);
      
      if (mounted) {
        final statusText = _translateStatus(context, newStatus);
        if (failCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.statusChangedForProjects(
                successCount,
                successCount == 1 ? '' : 's',
                statusText,
              )),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.statusChangedForProjectsWithErrors(
                successCount,
                successCount == 1 ? '' : 's',
                failCount,
                failCount == 1 ? '' : 's',
                statusText,
              )),
            ),
          );
        }
      }
      
      _clearSelection();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToChangeStatus(e.toString()))),
        );
      }
    }
  }

  String _translateStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'Idea':
        return l10n.projectPhaseIdea;
      case 'Arranging':
        return l10n.projectPhaseArranging;
      case 'Mixing':
        return l10n.projectPhaseMixing;
      case 'Mastering':
        return l10n.projectPhaseMastering;
      case 'Finished':
        return l10n.projectPhaseFinished;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hiddenMode = ref.watch(showHiddenProjectsProvider);
    final hiddenNotifier = ref.read(showHiddenProjectsProvider.notifier);
    final finishedMode = ref.watch(showFinishedProjectsProvider);
    final finishedNotifier = ref.read(showFinishedProjectsProvider.notifier);
    final phaseFilter = ref.watch(phaseFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: Theme.of(context).cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
                // Project count — all three mode variants are stacked and
                // rendered simultaneously; only the active one is opaque.
                // The Stack always sizes to the widest variant so the bar
                // never shifts regardless of which mode is active.
                Stack(
                  children: [
                    // Mode 0: "X projects (N hidden)"
                    Opacity(
                      opacity: hiddenMode == 0 ? 1.0 : 0.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.projectsCount(widget.visibleCount),
                              style: const TextStyle(fontSize: 12)),
                          if (widget.hiddenCount > 0)
                            Text(' ${l10n.hiddenCount(widget.hiddenCount)}',
                                style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    // Mode 1: "X projects" (show-all — visible count only)
                    Opacity(
                      opacity: hiddenMode == 1 ? 1.0 : 0.0,
                      child: Text(l10n.projectsCount(widget.visibleCount),
                          style: const TextStyle(fontSize: 12)),
                    ),
                    // Mode 2: "N projects hidden only"
                    if (widget.hiddenCount > 0)
                      Opacity(
                        opacity: hiddenMode == 2 ? 1.0 : 0.0,
                        child: Text(
                          '${l10n.projectsCount(widget.hiddenCount)} ${l10n.hiddenOnly}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.orange.shade300),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                if (widget.hiddenCount > 0) ...[
                  InkWell(
                    onTap: () {
                      if (hiddenMode == 1) {
                        hiddenNotifier.setShowAll(false);
                      } else {
                        hiddenNotifier.setShowAll(true);
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: hiddenMode == 1,
                          onChanged: (value) {
                            if (value == true) {
                              hiddenNotifier.setShowAll(true);
                            } else {
                              hiddenNotifier.setShowAll(false);
                            }
                          },
                        ),
                        Text(l10n.showHidden, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Stack keeps the button at the width of whichever label
                  // is wider — the ghost (opposite label, opacity 0) pins the
                  // layout; the Stack always takes the max of both children.
                  Stack(
                    children: [
                      Opacity(
                        opacity: 0,
                        child: IgnorePointer(
                          child: TextButton.icon(
                            icon: Icon(
                              hiddenMode == 2 ? Icons.visibility_off_outlined : Icons.visibility,
                              size: 16,
                            ),
                            label: Text(
                              hiddenMode == 2 ? l10n.showOnlyHidden : l10n.showAll,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: hiddenMode != 2 ? Colors.orange.shade700 : null,
                              foregroundColor: hiddenMode != 2 ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(
                          hiddenMode == 2 ? Icons.visibility : Icons.visibility_off_outlined,
                          size: 16,
                        ),
                        label: Text(
                          hiddenMode == 2 ? l10n.showAll : l10n.showOnlyHidden,
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: hiddenMode == 2 ? Colors.orange.shade700 : null,
                          foregroundColor: hiddenMode == 2 ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        onPressed: () {
                          if (hiddenMode == 2) {
                            hiddenNotifier.setShowOnlyHidden(false);
                          } else {
                            hiddenNotifier.setShowOnlyHidden(true);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
                InkWell(
                  onTap: () {
                    if (finishedMode == 1) {
                      finishedNotifier.setHideFinished(false);
                    } else {
                      finishedNotifier.setHideFinished(true);
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: finishedMode == 1,
                        onChanged: (value) {
                          if (value == true) {
                            finishedNotifier.setHideFinished(true);
                          } else {
                            finishedNotifier.setHideFinished(false);
                          }
                        },
                      ),
                      Text(l10n.hideFinished, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    final currentValue = ref.read(showOnlyWithDeadlineProvider);
                    ref.read(showOnlyWithDeadlineProvider.notifier).setShowOnlyWithDeadline(!currentValue);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: ref.watch(showOnlyWithDeadlineProvider),
                        onChanged: (value) {
                          ref.read(showOnlyWithDeadlineProvider.notifier).setShowOnlyWithDeadline(value == true);
                        },
                      ),
                      Text(l10n.showOnlyDeadlines, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: phaseFilter,
                  hint: Text(
                    l10n.filterByPhase,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  underline: const SizedBox.shrink(),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                  icon: Icon(Icons.filter_list, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                  items: [
                    DropdownMenuItem<String>(value: null, child: Text(l10n.allPhases)),
                    DropdownMenuItem<String>(value: 'Idea', child: Text(l10n.projectPhaseIdea)),
                    DropdownMenuItem<String>(value: 'Arranging', child: Text(l10n.projectPhaseArranging)),
                    DropdownMenuItem<String>(value: 'Mixing', child: Text(l10n.projectPhaseMixing)),
                    DropdownMenuItem<String>(value: 'Mastering', child: Text(l10n.projectPhaseMastering)),
                    DropdownMenuItem<String>(value: 'Finished', child: Text(l10n.projectPhaseFinished)),
                  ],
                  onChanged: (String? value) {
                    ref.read(phaseFilterProvider.notifier).setPhase(value);
                  },
                ),
              ],
          ),
        ),
        Expanded(
          child: _PlutoProjectsTable(
            key: _innerTableKey,
            projects: widget.projects,
            dateFormat: widget.dateFormat,
            selectedIds: _selectedProjectIds,
            onToggleSelection: _toggleProjectSelection,
            onHideProjects: widget.onHideProjects,
            onUnhideProjects: widget.onUnhideProjects,
            areAllSelected: _areAllSelected,
            onToggleSelectAll: () {
              if (_areAllSelected) {
                _clearSelection();
              } else {
                _selectAll();
              }
            },
            onExtractingMetadataChanged: widget.onExtractingMetadataChanged,
          ),
        ),
        // Selection action bar
        if (_selectedProjectIds.isNotEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.projectsSelected(_selectedProjectIds.length, _selectedProjectIds.length == 1 ? '' : 's'),
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              if (_selectedProjectIds.isNotEmpty)
                Row(
                  children: [
                    TextButton(
                      onPressed: _clearSelection,
                      child: Text(AppLocalizations.of(context)!.clearSelection),
                    ),
                    const SizedBox(width: 8),
                    // Check if selected projects are hidden or visible
                    Consumer(
                      builder: (context, ref, child) {
                        // Get current selection from provider
                        final selectedIds = ref.watch(selectedProjectsProvider);
                        // Check the state of selected projects
                        final selectedProjects = widget.projects.where((p) => selectedIds.contains(p.id)).toList();
                        final allHidden = selectedProjects.isNotEmpty && selectedProjects.every((p) => p.hidden);
                        final allVisible = selectedProjects.isNotEmpty && selectedProjects.every((p) => !p.hidden);
                        
                        // Show Unhide button if all selected are hidden, Hide button if all are visible
                        // If mixed, show both or the appropriate one
                        if (allHidden) {
                          return ElevatedButton.icon(
                            icon: const Icon(Icons.visibility),
                            label: Text(AppLocalizations.of(context)!.unhide),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                            ),
                            onPressed: () {
                              widget.onUnhideProjects(selectedIds.toList());
                              _clearSelection();
                            },
                          );
                        } else if (allVisible) {
                          return ElevatedButton.icon(
                            icon: const Icon(Icons.visibility_off),
                            label: Text(AppLocalizations.of(context)!.hide),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                            ),
                            onPressed: () {
                              widget.onHideProjects(selectedIds.toList());
                              _clearSelection();
                            },
                          );
                        } else {
                          // Mixed selection - show both buttons
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.visibility),
                                label: Text(AppLocalizations.of(context)!.unhide),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                ),
                                onPressed: () {
                                  widget.onUnhideProjects(selectedIds.toList());
                                  _clearSelection();
                                },
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.visibility_off),
                                label: Text(AppLocalizations.of(context)!.hide),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade700,
                                ),
                                onPressed: () {
                                  widget.onHideProjects(selectedIds.toList());
                                  _clearSelection();
                                },
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Builder(builder: (context) {
                      final anyFileFound = widget.projects
                          .where((p) => _selectedProjectIds.contains(p.id))
                          .any((p) =>
                              File(p.filePath).existsSync() ||
                              Directory(p.filePath).existsSync());
                      return Tooltip(
                        message: anyFileFound
                            ? ''
                            : AppLocalizations.of(context)!.sourceFileNotFoundOnThisMachine,
                        child: ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: Text(AppLocalizations.of(context)!.extractMetadata),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: widget.isAnyOperation || !anyFileFound
                          ? null
                          : () async {
                                widget.onExtractingMetadataChanged(true);
                                final repo = await ref.read(repositoryProvider.future);
                                int successCount = 0;
                                int failCount = 0;
                                
                                for (final projectId in _selectedProjectIds) {
                                  try {
                                    await repo.extractFullMetadataForProject(projectId);
                                    successCount++;
                                  } catch (_) {
                                    failCount++;
                                  }
                                }
                                
                                // Refresh the projects list
                                ref.invalidate(allProjectsStreamProvider);
                                
                                if (mounted) {
                                  final plural = successCount == 1 ? '' : 's';
                                  final failures = failCount > 0 ? AppLocalizations.of(context)!.extractionFailures(failCount, failCount == 1 ? '' : 's') : '';
                                  final message = AppLocalizations.of(context)!.metadataExtractedForProjects(successCount, plural, failures);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                }
                                
                                widget.onExtractingMetadataChanged(false);
                                _clearSelection();
                              },
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: Text(AppLocalizations.of(context)!.changeStatus),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => _showChangeStatusDialog(context),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.album),
                      label: Text(AppLocalizations.of(context)!.createRelease),
                      onPressed: () {
                        final selectedProjects = widget.projects
                            .where((p) => _selectedProjectIds.contains(p.id))
                            .toList();
                        widget.onCreateRelease(selectedProjects);
                        _clearSelection();
                      },
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}

enum _FileNotFoundAction { selectNew, remove }

class _PlutoProjectsTable extends ConsumerStatefulWidget {
  final List<MusicProject> projects;
  final DateFormat dateFormat;
  final Set<String> selectedIds;
  final Function(String) onToggleSelection;
  final Function(List<String>) onHideProjects;
  final Function(List<String>) onUnhideProjects;
  final bool areAllSelected;
  final VoidCallback onToggleSelectAll;
  final Function(bool) onExtractingMetadataChanged;
  const _PlutoProjectsTable({
    super.key,
    required this.projects,
    required this.dateFormat,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onHideProjects,
    required this.onUnhideProjects,
    required this.areAllSelected,
    required this.onToggleSelectAll,
    required this.onExtractingMetadataChanged,
  });

  @override
  ConsumerState<_PlutoProjectsTable> createState() => _PlutoProjectsTableState();
}

class _PlutoProjectsTableState extends ConsumerState<_PlutoProjectsTable> {
  TrinaGridStateManager? stateManager;

  void focusTable() {
    final sm = stateManager;
    if (sm == null) return;
    sm.gridFocusNode.requestFocus();
    if (sm.currentRow == null && sm.rows.isNotEmpty) {
      sm.setCurrentCell(sm.rows.first.cells.values.first, 0);
    }
  }

  void _onStateManagerChanged() {
    if (mounted) setState(() {});
  }

  void _collapseAll() {
    final sm = stateManager;
    if (sm == null) return;
    for (final row in sm.rows) {
      if (row.type.isGroup && row.type.group.expanded) {
        sm.toggleExpandedRowGroup(rowGroup: row);
      }
    }
  }

  void _expandAll() {
    final sm = stateManager;
    if (sm == null) return;
    for (final row in sm.rows) {
      if (row.type.isGroup && !row.type.group.expanded) {
        sm.toggleExpandedRowGroup(rowGroup: row);
      }
    }
  }

  // Drag-and-drop preview assignment
  double? _dragOverRowTop; // top Y of the highlighted row in local coords

  static const double _gridHeaderHeight = 45.0;
  static const double _gridRowHeight = 48.0;

  static const Set<String> _audioExtensions = {
    '.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac', '.aif', '.aiff',
  };

  void _updateDragTarget(Offset localPos) {
    final sm = stateManager;
    if (sm == null) return;
    final scrollOffset = sm.scroll.bodyRowsVertical?.offset ?? 0;
    final rowIndex =
        ((localPos.dy - _gridHeaderHeight + scrollOffset) / _gridRowHeight)
            .floor();
    if (rowIndex >= 0 && rowIndex < sm.rows.length) {
      final rowTop =
          _gridHeaderHeight + rowIndex * _gridRowHeight - scrollOffset;
      setState(() {
        _dragOverRowTop = rowTop;
      });
    } else {
      setState(() {
        _dragOverRowTop = null;
      });
    }
  }

  Future<void> _setPreviewSong(MusicProject project, String filePath) async {
    final ext = filePath.split('.').last.toLowerCase();
    if (!_audioExtensions.contains('.$ext')) return;
    final repo = await ref.read(repositoryProvider.future);
    final updated = project.copyWith(
      previewSongPath: filePath,
      previewSongFileName: filePath.split('/').last,
    );
    await repo.updateProject(updated);
    ref.invalidate(allProjectsStreamProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${updated.previewSongFileName} set as preview for ${updated.displayName}',
          ),
        ),
      );
    }
  }
  
  Future<void> _playPreviewSong(MusicProject project) async {
    final customFolder = ref.read(customMixdownFolderProvider).value;
    var effectivePath = project.previewSongPath?.isNotEmpty == true
        ? project.previewSongPath!
        : (project.previewSongAutoPath ?? MixdownDetectorService.findLatestMixdown(project, customFolder: customFolder)?.path);

    if (effectivePath == null) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.audio_file_outlined, size: 20),
              const SizedBox(width: 8),
              Text(l10n.noPreviewSongTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.noPreviewSongMessage),
              if (!MobileUtils.isMobile()) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.drag_indicator, size: 16,
                        color: Theme.of(ctx).colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.noPreviewSongDragHint,
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.selectPreviewSong),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
        dialogTitle: l10n.selectPreviewSong,
      );
      if (!mounted || picked == null || picked.files.single.path == null) return;
      final newPath = picked.files.single.path!;
      final repo = await ref.read(repositoryProvider.future);
      await repo.updateProject(project.copyWith(
        previewSongPath: newPath,
        previewSongFileName: path.basename(newPath),
      ));
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (dialogContext) => _PreviewSongDialog(
          project: project.copyWith(
            previewSongPath: newPath,
            previewSongFileName: path.basename(newPath),
          ),
          onClose: () {},
        ),
      );
      return;
    }

    final file = File(effectivePath);
    if (!await file.exists()) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final action = await showDialog<_FileNotFoundAction>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.previewSongFileNotFound),
          content: Text(l10n.previewSongFileNotFoundMessage),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, _FileNotFoundAction.remove),
              child: Text(l10n.removePreviewSong),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, _FileNotFoundAction.selectNew),
              child: Text(l10n.selectNewFile),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (action == _FileNotFoundAction.remove) {
        final repo = await ref.read(repositoryProvider.future);
        final isAuto = project.previewSongPath?.isNotEmpty != true;
        final updated = isAuto
            ? project.copyWith(clearPreviewSongAutoPath: true)
            : project.copyWith(clearPreviewSongPath: true, clearPreviewSongFileName: true);
        await repo.updateProject(updated);
        return;
      } else if (action == _FileNotFoundAction.selectNew) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
          dialogTitle: l10n.selectPreviewSong,
        );
        if (!mounted) return;
        if (result != null && result.files.single.path != null) {
          final newPath = result.files.single.path!;
          final repo = await ref.read(repositoryProvider.future);
          final isAuto = project.previewSongPath?.isNotEmpty != true;
          final updated = isAuto
              ? project.copyWith(previewSongAutoPath: newPath)
              : project.copyWith(previewSongPath: newPath, previewSongFileName: path.basename(newPath));
          await repo.updateProject(updated);
          effectivePath = newPath;
        } else {
          return;
        }
      } else {
        return;
      }
    }

    // Check for a newer audio file in the same folder as the current preview,
    // regardless of whether the path was manually set or auto-detected.
    final newer = MixdownDetectorService.findNewerFileInSameFolder(effectivePath);
    if (newer != null && mounted) {
      final l10n = AppLocalizations.of(context)!;
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.newerExportFound),
          content: Text(l10n.newerExportFoundMessage(path.basename(newer.path))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.keepCurrent)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.replaceAndPlay)),
          ],
        ),
      );
      if (!mounted) return;
      if (replace == null) return;
      if (replace) {
        final repo = await ref.read(repositoryProvider.future);
        final isManual = project.previewSongPath?.isNotEmpty == true;
        final updated = isManual
            ? project.copyWith(
                previewSongPath: newer.path,
                previewSongFileName: path.basename(newer.path),
              )
            : project.copyWith(previewSongAutoPath: newer.path);
        await repo.updateProject(updated);
        effectivePath = newer.path;
      }
    }

    if (!mounted) return;
    // Always build playProject from effectivePath so the player shows the
    // correct filename whether we replaced or not.
    final playProject = project.copyWith(
      previewSongPath: effectivePath,
      previewSongFileName: path.basename(effectivePath),
    );

    if (MobileUtils.isMobile()) {
      await showDialog(
        context: context,
        builder: (dialogContext) => _PreviewSongDialog(
          project: playProject,
          onClose: () {},
        ),
      );
    } else {
      ref.read(desktopPlayerProvider.notifier).play(playProject, effectivePath);
    }
  }

  Future<void> _writeBpmToFile(MusicProject project, double? bpm) async {
    try {
      final projectDir = File(project.filePath).parent;
      final bpmFile = File(path.join(projectDir.path, 'bpm.txt'));
      
      if (bpm != null) {
        await bpmFile.writeAsString(bpm.toStringAsFixed(2));
      } else {
        // Delete file if BPM is cleared
        if (await bpmFile.exists()) {
          await bpmFile.delete();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToWriteBpmFile(e.toString()))),
        );
      }
    }
  }
  
  Future<void> _writeKeyToFile(MusicProject project, String? key) async {
    try {
      final projectDir = File(project.filePath).parent;
      final keyFile = File(path.join(projectDir.path, 'key.txt'));
      
      if (key != null && key.isNotEmpty) {
        await keyFile.writeAsString(key);
      } else {
        // Delete file if key is cleared
        if (await keyFile.exists()) {
          await keyFile.delete();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToWriteKeyFile(e.toString()))),
        );
      }
    }
  } 

  String _translateStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'Idea':
        return l10n.projectPhaseIdea;
      case 'Arranging':
        return l10n.projectPhaseArranging;
      case 'Mixing':
        return l10n.projectPhaseMixing;
      case 'Mastering':
        return l10n.projectPhaseMastering;
      case 'Finished':
        return l10n.projectPhaseFinished;
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Idea':
        return Colors.blue.shade300;
      case 'Arranging':
        return Colors.orange.shade300;
      case 'Mixing':
        return Colors.purple.shade300;
      case 'Mastering':
        return Colors.pink.shade300;
      case 'Finished':
        return Colors.green.shade300;
      default:
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    }
  }

  String? _getDawLogoPath(String? dawType) {
    if (dawType == null || dawType.isEmpty) return null;
    
    // Map DAW types to logo file names (case-insensitive matching)
    final dawLower = dawType.toLowerCase();
    final logoMap = {
      'ableton': 'ableton-live.png',
      'ableton live': 'ableton-live.png',
      'fl studio': 'fl-studio.png',
      'flstudio': 'fl-studio.png',
      'logic pro': 'logic-pro.png',
      'logic': 'logic-pro.png',
      'cubase': 'cubase.png',
      'studio one': 'studio-one.png',
      'studioone': 'studio-one.png',
      'reaper': 'reaper.png',
      'pro tools': 'pro-tools.png',
      'protools': 'pro-tools.png',
      'bitwig': 'bitwig-studio.png',
      'bitwig studio': 'bitwig-studio.png',
      'nuendo': 'nuendo.png',
      'maschine': 'maschine.png',
      'tracktion waveform': 'tracktion-waveform.png',
      'tracktion': 'tracktion-waveform.png',
      'waveform': 'tracktion-waveform.png',
      'cakewalk': 'cakewalk.png',
      'cakewalk sonar': 'cakewalk.png',
      'sonar': 'cakewalk.png',
    };
    
    // Try exact match first
    if (logoMap.containsKey(dawLower)) {
      return 'resources/daw/logos/${logoMap[dawLower]}';
    }
    
    // Try partial match
    for (final entry in logoMap.entries) {
      if (dawLower.contains(entry.key) || entry.key.contains(dawLower)) {
        return 'resources/daw/logos/${entry.value}';
      }
    }
    
    return null;
  }

  Future<void> _launchProject(MusicProject project) async {
    final exists = File(project.filePath).existsSync() || Directory(project.filePath).existsSync();
    if (!exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.fileMissing)));
      }
      return;
    }
    final success = await FileLauncher.launchProject(project.filePath);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.launchingProject(project.displayName))));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToLaunchProject(project.displayName))),
        );
      }
    }
  }

  Future<void> _viewProjectDetails(MusicProject project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
    );
  }

  Future<void> _openProjectFolder(MusicProject project) async {
    final String projectPath = project.filePath;
    final String folderPath = FileSystemEntity.isDirectorySync(projectPath)
        ? projectPath // Se for um diretório, usa o próprio caminho
        : path.dirname(projectPath); // Se for um arquivo, usa o diretório pai
    
    final exists = Directory(folderPath).existsSync();
    if (!exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.fileMissing)));
      }
      return;
    }
    
    final success = await FileLauncher.openFolder(folderPath);
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.openingFolder(project.displayName))));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenFolder('Unable to open folder'))));
      }
    }
  }

  Future<void> _toggleSession(MusicProject project) async {
    if (!mounted) return;
    final sessionMode = ref.read(sessionModeProvider);
    if (!sessionMode) return;
    final activeProject = ref.read(activeProjectProvider);
    if (activeProject?.id == project.id) {
      await _confirmEndSession(context, ref);
    } else {
      await _confirmStartSession(context, ref, project);
    }
  }

  Future<void> _showPhaseMenu(
    BuildContext context,
    MusicProject project,
    Offset position,
    TrinaColumnRendererContext rendererContext,
  ) async {
    const phases = ['Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'];
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: Theme.of(context).cardColor,
      items: phases.map((phase) {
        final isCurrent = project.status == phase;
        return PopupMenuItem<String>(
          value: phase,
          child: Row(
            children: [
              Icon(
                isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 16,
                color: _getStatusColor(phase),
              ),
              const SizedBox(width: 8),
              Text(
                _translateStatus(context, phase),
                style: TextStyle(
                  color: _getStatusColor(phase),
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    if (selected != null && selected != project.status && mounted) {
      final repo = await ref.read(repositoryProvider.future);
      final updated = project.copyWith(status: selected);
      await repo.updateProject(updated);
      // Update cells in-place so the row reflects the change immediately
      rendererContext.row.cells['status']?.value = selected;
      rendererContext.row.cells['data']?.value = updated;
      rendererContext.stateManager.notifyListeners();
    }
  }

  Future<void> _showContextMenu(BuildContext context, MusicProject project, Offset position) async {
    final l10n = AppLocalizations.of(context)!;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'launch',
          child: Row(
            children: [
              const Icon(Icons.open_in_new, size: 20),
              const SizedBox(width: 8),
              Text(l10n.tooltipLaunchInDaw),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'view',
          child: Row(
            children: [
              const Icon(Icons.assignment, size: 20),
              const SizedBox(width: 8),
              Text(l10n.tooltipViewDetails),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'openFolder',
          child: Row(
            children: [
              const Icon(Icons.folder_open, size: 20),
              const SizedBox(width: 8),
              Text(l10n.openFolder),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: project.hidden ? 'unhide' : 'hide',
          child: Row(
            children: [
              Icon(
                project.hidden ? Icons.visibility : Icons.visibility_off,
                size: 20,
                color: project.hidden ? Colors.green.shade300 : Colors.red.shade300,
              ),
              const SizedBox(width: 8),
              Text(project.hidden ? l10n.unhide : l10n.hide),
            ],
          ),
        ),
        if (File(project.filePath).existsSync() || Directory(project.filePath).existsSync())
          PopupMenuItem<String>(
            value: 'extractMetadata',
            child: Row(
              children: [
                const Icon(Icons.search, size: 20),
                const SizedBox(width: 8),
                Text(l10n.extractMetadata),
              ],
            ),
          ),
      ],
      color: Theme.of(context).cardColor,
    );

    if (result != null && mounted) {
      switch (result) {
        case 'launch':
          await _launchProject(project);
          break;
        case 'view':
          await _viewProjectDetails(project);
          break;
        case 'openFolder':
          await _openProjectFolder(project);
          break;
        case 'hide':
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text(l10n.hide),
              content: Text(l10n.hideProjectMessage(project.displayName)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade300,
                  ),
                  child: Text(l10n.hide),
                ),
              ],
            ),
          );
          if (confirm == true) {
            widget.onHideProjects([project.id]);
          }
          break;
        case 'unhide':
          widget.onUnhideProjects([project.id]);
          break;
        case 'extractMetadata':
          widget.onExtractingMetadataChanged(true);
          try {
            final repo = await ref.read(repositoryProvider.future);
            await repo.extractFullMetadataForProject(project.id);
            ref.invalidate(allProjectsStreamProvider);
            if (mounted) {
              final msg = l10n.metadataExtractedForProjects(1, '', '');
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
            }
          } catch (e) {
            if (mounted) {
              final msg = '${l10n.error}: $e';
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
            }
          } finally {
            widget.onExtractingMetadataChanged(false);
          }
          break;
      }
    }
  }

  TrinaRow _projectToRow(MusicProject p) {
    final dawDisplay = p.dawType != null
        ? (p.dawVersion != null && p.dawVersion!.isNotEmpty
            ? '${p.dawType} ${p.dawVersion}'
            : p.dawType!)
        : '';
    return TrinaRow(
      cells: {
        'checkbox': TrinaCell(value: ''),
        'name': TrinaCell(value: p.displayName),
        'status': TrinaCell(value: p.status),
        'dawType': TrinaCell(value: dawDisplay),
        'bpm': TrinaCell(value: p.bpm?.toString() ?? ''),
        'key': TrinaCell(value: p.musicalKey ?? ''),
        'lastModified': TrinaCell(value: widget.dateFormat.format(p.lastModifiedAt)),
        'deadline': TrinaCell(value: p.deadlineStatus ?? ''),
        'launch': TrinaCell(value: ''),
        'data': TrinaCell(value: p),
      },
    );
  }

  List<TrinaRow> _mapProjectsToRows(List<MusicProject> projects) {
    final roots = ref.read(scanRootsProvider);

    // Build normalized root path → ScanMode lookup.
    final rootModes = <String, ScanMode>{
      for (final r in roots) path.normalize(r.path): r.scanMode,
    };

    String? findRoot(String filePath) {
      final norm = path.normalize(filePath);
      for (final rootPath in rootModes.keys) {
        final prefix = rootPath.endsWith(path.separator) ? rootPath : rootPath + path.separator;
        if (norm.startsWith(prefix)) return rootPath;
      }
      return null;
    }

    final flatProjects = <MusicProject>[];
    final folderGroups = <String, List<MusicProject>>{};

    for (final proj in projects) {
      final rootPath = findRoot(proj.filePath);
      final mode = rootPath != null ? (rootModes[rootPath] ?? ScanMode.flat) : ScanMode.flat;

      if (mode == ScanMode.smartFolder && rootPath != null) {
        final rel = path.relative(path.normalize(proj.filePath), from: rootPath);
        final parts = path.split(rel);
        if (parts.length <= 1) {
          // Project sits directly in the root — no subfolder to group by.
          flatProjects.add(proj);
        } else {
          final topLevel = path.join(rootPath, parts[0]);
          folderGroups.putIfAbsent(topLevel, () => []).add(proj);
        }
      } else {
        flatProjects.add(proj);
      }
    }

    // Groups with exactly 1 project are demoted to flat.
    for (final entry in folderGroups.entries) {
      if (entry.value.length == 1) flatProjects.add(entry.value.first);
    }
    final realGroups = Map.fromEntries(
      folderGroups.entries.where((e) => e.value.length > 1),
    );

    // Build display items as (latestModified, row) so we can sort interleaved.
    final items = <(DateTime, TrinaRow)>[];

    for (final proj in flatProjects) {
      items.add((proj.lastModifiedAt, _projectToRow(proj)));
    }

    for (final entry in realGroups.entries) {
      final dir = entry.key;
      final group = List<MusicProject>.from(entry.value)
        ..sort((a, b) => a.lastModifiedAt.compareTo(b.lastModifiedAt));
      final latestModified = group.map((p) => p.lastModifiedAt).reduce((x, y) => x.isAfter(y) ? x : y);

      items.add((
        latestModified,
        TrinaRow(
          cells: {
            'checkbox': TrinaCell(value: ''),
            'name': TrinaCell(value: path.basename(dir)),
            'status': TrinaCell(value: ''),
            'dawType': TrinaCell(value: ''),
            'bpm': TrinaCell(value: ''),
            'key': TrinaCell(value: ''),
            'lastModified': TrinaCell(value: widget.dateFormat.format(latestModified)),
            'deadline': TrinaCell(value: ''),
            'launch': TrinaCell(value: ''),
            'data': TrinaCell(value: null),
          },
          type: TrinaRowType.group(
            children: FilteredList(initialList: group.map(_projectToRow).toList()),
          ),
        ),
      ));
    }

    // Sort all display items newest-first.
    items.sort((a, b) => b.$1.compareTo(a.$1));
    return items.map((e) => e.$2).toList();
  }

  @override
  void didUpdateWidget(_PlutoProjectsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.projects != widget.projects) {
      if (stateManager != null) {
        // Snapshot collapsed state of group rows before replacing, so Smart
        // Folder groups that the user collapsed stay collapsed after a data
        // refresh (e.g. metadata extraction).
        final wasCollapsed = <String, bool>{};
        for (final row in stateManager!.rows) {
          if (row.type.isGroup) {
            final name = row.cells['name']?.value as String? ?? '';
            wasCollapsed[name] = !row.type.group.expanded;
          }
        }

        final newRows = _mapProjectsToRows(widget.projects);
        stateManager!.removeRows(stateManager!.rows, notify: false);
        stateManager!.insertRows(0, newRows);

        // Restore collapsed state — new group rows default to expanded,
        // so only toggle the ones that were collapsed.
        for (final row in stateManager!.rows) {
          if (row.type.isGroup) {
            final name = row.cells['name']?.value as String? ?? '';
            if (wasCollapsed[name] == true) {
              stateManager!.toggleExpandedRowGroup(rowGroup: row);
            }
          }
        }

        stateManager!.notifyListeners();
      }
    } else if (oldWidget.selectedIds != widget.selectedIds) {
      // Selection changed only — update cell values to invalidate renderer cache
      // without destroying rows (which would reset folder expanded/collapsed state).
      if (stateManager != null) {
        for (final row in stateManager!.rows) {
          final project = row.cells['data']?.value as MusicProject?;
          if (project != null) {
            row.cells['checkbox']?.value =
                widget.selectedIds.contains(project.id) ? 'selected' : '';
          }
        }
        stateManager!.notifyListeners();
      }
    }
    
    // Also check if any project's lastModifiedAt changed (for color updates during scanning)
    if (oldWidget.projects.length == widget.projects.length) {
      bool hasModifiedDates = false;
      for (int i = 0; i < widget.projects.length; i++) {
        if (i < oldWidget.projects.length) {
          if (widget.projects[i].lastModifiedAt != oldWidget.projects[i].lastModifiedAt) {
            hasModifiedDates = true;
            break;
          }
        }
      }
      
      if (hasModifiedDates && stateManager != null) {
        // Update the lastModified cell values to trigger renderer refresh
        for (int i = 0; i < stateManager!.rows.length && i < widget.projects.length; i++) {
          final project = widget.projects[i];
          final row = stateManager!.rows[i];
          if (row.cells['lastModified'] != null) {
            row.cells['lastModified']!.value = widget.dateFormat.format(project.lastModifiedAt);
          }
        }
        stateManager!.notifyListeners();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // When the search query changes, ask TrinaGrid to repaint so the
    // "matched in description" icon in the name renderer reflects the new query.
    ref.listen(projectsSearchProvider, (prev, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        stateManager?.notifyListeners();
      });
    });
    // Repaint rows when the currently playing track changes (for highlight).
    ref.listen(desktopPlayerProvider, (prev, next) {
      if (prev?.project.id != next?.project.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) stateManager?.notifyListeners();
        });
      }
    });
    ref.listen(sessionModeProvider, (prev, next) {
      if (prev != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) stateManager?.notifyListeners();
        });
      }
    });
    ref.listen(activeProjectProvider, (prev, next) {
      if (prev?.id != next?.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) stateManager?.notifyListeners();
        });
      }
    });
    ref.listen(workTimerPausedProvider, (prev, next) {
      if (prev != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) stateManager?.notifyListeners();
        });
      }
    });
    final columns = [
      TrinaColumn(
        title: '',
        field: 'checkbox',
        type: TrinaColumnType.text(),
        width: 50,
        minWidth: 50,
        frozen: TrinaColumnFrozen.start,
        enableColumnDrag: false,
        enableContextMenu: false,
        enableFilterMenuItem: false,
        enableSorting: false,
        enableEditingMode: false,
        titleRenderer: (rendererContext) {
          final style = rendererContext.stateManager.configuration.style;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: rendererContext.column.backgroundColor,
              border: BorderDirectional(
                end: style.enableColumnBorderVertical
                    ? BorderSide(color: style.borderColor)
                    : BorderSide.none,
              ),
            ),
            child: Center(
              child: Transform.scale(
                scale: 0.78,
                child: Checkbox(
                  value: widget.areAllSelected,
                  tristate: widget.selectedIds.isNotEmpty && !widget.areAllSelected,
                  onChanged: (_) => widget.onToggleSelectAll(),
                ),
              ),
            ),
          );
        },
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          if (project == null) {
            return _ExpandArrowCell(
              row: rendererContext.row,
              stateManager: rendererContext.stateManager,
            );
          }
          final isSelected = widget.selectedIds.contains(project.id);
          return Transform.scale(
            scale: 0.78,
            child: Checkbox(
              value: isSelected,
              onChanged: (value) {
                widget.onToggleSelection(project.id);
              },
            ),
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.name,
        field: 'name',
        type: TrinaColumnType.text(),
        enableColumnDrag: true,
        enableContextMenu: false,
        enableEditingMode: false,
        width: 600,
        minWidth: 200,
        frozen: TrinaColumnFrozen.start,
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          if (project == null) {
            return _FolderNameCell(
              row: rendererContext.row,
              stateManager: rendererContext.stateManager,
              folderName: rendererContext.cell.value.toString(),
            );
          }

          final fileExists = File(project.filePath).existsSync() ||
              Directory(project.filePath).existsSync();

          final currentQuery = ref.read(projectsSearchProvider);
          final isNotesMatch = currentQuery.trim().isNotEmpty &&
              !fuzzyMatchAll(project.displayName, currentQuery) &&
              project.notes != null &&
              fuzzyMatchAll(project.notes!, currentQuery);

          // Tree connector for child rows inside a folder group
          final depth = rendererContext.row.depth;
          final parent = rendererContext.row.parent;
          final isLastChild = parent == null ||
              !parent.type.isGroup ||
              parent.type.group.children.isEmpty ||
              parent.type.group.children.last == rendererContext.row;

          return Row(
            children: [
              if (depth > 0)
                SizedBox(
                  width: 20,
                  height: double.infinity,
                  child: CustomPaint(
                    painter: _TreeConnectorPainter(
                      isLast: isLastChild,
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              Expanded(child: Text(rendererContext.cell.value.toString())),
              if (isNotesMatch)
                Tooltip(
                  message: AppLocalizations.of(context)!.matchedInDescription,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.notes, size: 14, color: Colors.amber.shade600),
                  ),
                ),
              if (!fileExists && !MobileUtils.isMobile())
                Tooltip(
                  message: AppLocalizations.of(context)!.sourceFileNotFoundOnThisMachine,
                  child: Icon(Icons.cloud_off, size: 14, color: Colors.orange.shade400),
                ),
            ],
          );
        },
      ),
      TrinaColumn(
        title: l10n.phase,
        field: 'status',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 140,
        minWidth: 120,
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          final status = rendererContext.cell.value as String? ?? '';
          final translatedStatus = _translateStatus(context, status);
          final textWidget = Row(
            children: [
              Text(
                translatedStatus,
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: 16, color: _getStatusColor(status).withValues(alpha: 0.7)),
            ],
          );

          if (project == null) return const SizedBox.shrink();

          return GestureDetector(
            onTapDown: (TapDownDetails details) {
              _showPhaseMenu(context, project, details.globalPosition, rendererContext);
            },
            child: textWidget,
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.daw,
        field: 'dawType',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 140,
        minWidth: 100,
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          if (project == null) return const SizedBox.shrink();
          final dawType = rendererContext.cell.value as String? ?? '';
          final logoPath = _getDawLogoPath(dawType);
          
          final content = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (logoPath != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Image.asset(
                    logoPath,
                    width: 16,
                    height: 16,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              Flexible(
                child: Text(
                  dawType,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
          
          return content;
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.bpm,
        field: 'bpm',
        type: TrinaColumnType.text(),
        width: 80,
        minWidth: 70,
        enableEditingMode: true,
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          final textWidget = Text(rendererContext.cell.value.toString());
          
          if (project == null) return textWidget;

          return textWidget;
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.key.split(' ').first, // Get just "Key" from "Key (e.g., C#m, F major)"
        field: 'key',
        type: TrinaColumnType.text(),
        width: 160,
        minWidth: 140,
        enableEditingMode: true,
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          if (project == null) {
            return Text(rendererContext.cell.value.toString());
          }
          
          final key = project.musicalKey;
          final camelot = project.camelotCode;
          
          if (key == null || key.isEmpty) {
            return const SizedBox.shrink();
          }
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  key,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (camelot != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Container(
                    width: 1,
                    height: 14,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    camelot,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.lastModifiedColumn,
        field: 'lastModified',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 200,
        minWidth: 160,
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          if (project == null) return const SizedBox.shrink();

          final colorEnabled = ref.watch(lastModifiedColorProvider);
          final defaultColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

          Color textColor;
          if (!colorEnabled) {
            textColor = defaultColor;
          } else {
            final status = project.status;
            if (status == 'Finished') {
              textColor = Colors.green;
            } else {
              final now = DateTime.now();
              final lastModified = project.lastModifiedAt;
              final daysSinceModified = now.difference(lastModified).inDays;

              if (daysSinceModified < 21) {
                textColor = defaultColor;
              } else if (daysSinceModified < 60) {
                final ratio = (daysSinceModified - 21) / 39.0;
                textColor = Color.lerp(Colors.yellow.shade300, Colors.orange.shade400, ratio)!;
              } else {
                final ratio = ((daysSinceModified - 60) / 60.0).clamp(0.0, 1.0);
                textColor = Color.lerp(Colors.orange.shade400, Colors.red.shade400, ratio)!;
              }
            }
          }

          return Text(
            rendererContext.cell.value.toString(),
            style: TextStyle(color: textColor),
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.deadline,
        field: 'deadline',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 120,
        minWidth: 100,
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          if (project == null || project.deadline == null || project.status == 'Finished') {
            return const SizedBox.shrink();
          }

          final daysUntil = project.daysUntilDeadline ?? 0;

          Color iconColor;
          IconData iconData;
          String text;

          if (daysUntil < 0) {
            iconColor = Colors.red;
            iconData = Icons.warning;
            text = AppLocalizations.of(context)!.daysLate(daysUntil.abs());
          } else if (daysUntil == 0) {
            iconColor = Colors.red;
            iconData = Icons.today;
            text = AppLocalizations.of(context)!.dueToday;
          } else if (daysUntil <= 7) {
            iconColor = Colors.orange;
            iconData = Icons.schedule;
            text = AppLocalizations.of(context)!.daysLeft(daysUntil);
          } else {
            iconColor = Colors.blue;
            iconData = Icons.calendar_today;
            text = '${daysUntil}d left';
          }

          final deadlineWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: iconColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  iconData,
                  size: 12,
                  color: iconColor,
                ),
                const SizedBox(width: 3),
                Text(
                  text,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );

          return deadlineWidget;
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.actions,
        field: 'launch',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 290, // Increased width to accommodate all action buttons
        minWidth: 250,
        renderer: (ctx) {
          final project = ctx.row.cells['data']?.value as MusicProject?;
          if (project == null) return const SizedBox.shrink();
          
          // Lógica para determinar o diretório pai
          final String projectPath = project.filePath;
          final bool sourceFileExists = File(projectPath).existsSync() || Directory(projectPath).existsSync();
          final String folderPath = FileSystemEntity.isDirectorySync(projectPath)
              ? projectPath // Se for um diretório, usa o próprio caminho
              : path.dirname(projectPath); // Se for um arquivo, usa o diretório pai
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play Preview Song button (always show, but disabled if no preview)
              IconButton(
                icon: Icon(
                  project.previewSongPath?.isNotEmpty == true || project.previewSongAutoPath != null
                      ? Icons.play_circle
                      : Icons.play_circle_outline,
                ),
                iconSize: 24,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: project.previewSongAutoPath != null && project.previewSongPath?.isNotEmpty != true
                    ? '${AppLocalizations.of(context)!.playPreview} (P)\n⚡ ${AppLocalizations.of(context)!.autoDetected}: ${path.basename(project.previewSongAutoPath!)}'
                    : '${AppLocalizations.of(context)!.playPreview} (P)',
                onPressed: () => _playPreviewSong(project),
                color: project.previewSongPath?.isNotEmpty == true
                    ? Colors.green
                    : project.previewSongAutoPath != null
                        ? Colors.amber
                        : Colors.grey,
              ),
              // Separator (always show)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: Text(
                  '|',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 16),
                ),
              ),
              // Launch / Start Session button — Consumer makes it self-reactive to
              // sessionModeProvider and activeProjectProvider without relying on
              // TrinaGrid to rebuild its cached column objects.
              Consumer(
                builder: (context, ref, _) {
                  final mode = ref.watch(sessionModeProvider);
                  final subProject = ref.watch(activeProjectProvider);
                  if (!mode) {
                    return IconButton(
                      icon: const Icon(Icons.open_in_new),
                      iconSize: 24,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: '${AppLocalizations.of(context)!.openInDaw} (O)',
                      onPressed: () => _launchProject(project),
                    );
                  }
                  final isSubscribed = subProject?.id == project.id;
                  return IconButton(
                    icon: Icon(isSubscribed ? Icons.bookmark : Icons.bookmark_add_outlined),
                    iconSize: 24,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: isSubscribed
                        ? '${AppLocalizations.of(context)!.endSession} (S)'
                        : '${AppLocalizations.of(context)!.startSession} (S)',
                    color: isSubscribed ? Colors.green.shade400 : null,
                    onPressed: () {
                      if (isSubscribed) {
                        _confirmEndSession(context, ref);
                      } else {
                        _confirmStartSession(context, ref, project);
                      }
                    },
                  );
                },
              ),
              // Separator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: Text(
                  '|',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 16),
                ),
              ),
              // View button
              IconButton(
                icon: const Icon(Icons.assignment),
                iconSize: 24,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: '${AppLocalizations.of(context)!.tooltipViewDetails} (D)',
                onPressed: () => _viewProjectDetails(project),
              ),
              // Open Folder button (desktop only — no file manager on mobile)
              if (!MobileUtils.isMobile())
                Tooltip(
                  message: sourceFileExists ? '' : AppLocalizations.of(context)!.sourceFileNotFoundOnThisMachine,
                  child: IconButton(
                    icon: const Icon(Icons.folder_open),
                    iconSize: 24,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    tooltip: sourceFileExists ? '${AppLocalizations.of(context)!.openFolder} (F)' : null,
                    onPressed: sourceFileExists ? () => _openProjectFolder(project) : null,
                  ),
                ),
              // Separator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: Text(
                  '|',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 16),
                ),
              ),
              // Hidden button
              IconButton(
                icon: Icon(project.hidden ? Icons.visibility : Icons.visibility_off),
                iconSize: 24,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                color: project.hidden ? Colors.green.shade300 : Colors.red.shade300,
                tooltip: project.hidden
                    ? AppLocalizations.of(context)!.unhide
                    : AppLocalizations.of(context)!.hide,
                onPressed: () async {
                  if (project.hidden) {
                    // Unhide - no confirmation needed
                    widget.onUnhideProjects([project.id]);
                  } else {
                    // Hide - show confirmation dialog
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Theme.of(context).cardColor,
                        title: Text(AppLocalizations.of(context)!.hide),
                        content: Text(AppLocalizations.of(context)!.hideProjectMessage(project.displayName)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade300,
                            ),
                            child: Text(AppLocalizations.of(context)!.hide),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      widget.onHideProjects([project.id]);
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
      // Hidden backing column for passing the model instance
      TrinaColumn(
        title: 'data',
        field: 'data',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 0,
        hide: true,
      ),
    ]; // <-- Semicolon final do array de colunas

    final initialRows = _mapProjectsToRows(widget.projects);

    if (widget.projects.isEmpty) {
      final allProjectsAsync = ref.watch(allProjectsStreamProvider);
      final hasProjects = (allProjectsAsync.value?.isNotEmpty) ?? false;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasProjects ? Icons.search_off : Icons.library_music_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              hasProjects
                  ? l10n.noResultsForFilter
                  : l10n.noProjectsFound,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              hasProjects
                  ? l10n.noResultsForFilterHint
                  : l10n.noProjectsFoundHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Read from Riverpod so isNeon and all theme colors come from the same build tick,
    // preventing a one-frame inversion when the user switches themes.
    final activeTheme = ref.watch(themeDataProvider);
    final isNeon = ref.watch(themeTypeProvider) == AppThemeType.neonDark;
    final isDark = activeTheme.brightness == Brightness.dark;

    final playingHighlightColor = activeTheme.colorScheme.primary.withValues(alpha: 0.32);
    final rowSelectColor = activeTheme.colorScheme.primary.withValues(alpha: 0.18);

    // Neon Dark: use scaffold background (very dark navy) for odd rows so alternating rows are clearly visible.
    // Classic Dark: use card colour for odd rows (current behaviour).
    final oddColor = isNeon
        ? activeTheme.scaffoldBackgroundColor
        : activeTheme.cardColor;
    final evenColor = isNeon
        ? activeTheme.cardColor
        : isDark
            ? Color.alphaBlend(Colors.white.withValues(alpha: 0.05), activeTheme.cardColor)
            : Color.alphaBlend(Colors.black.withValues(alpha: 0.04), activeTheme.cardColor);

    final grid = TrinaGrid(
          key: ValueKey('trina_grid_${l10n.localeName}_${isNeon ? "neon" : "classic"}'),
          columnMenuDelegate: _FitAllColumnsMenuDelegate(),
          columns: columns,
          rows: initialRows,
          rowColorCallback: (TrinaRowColorContext ctx) {
            final project = ctx.row.cells['data']?.value as MusicProject?;
            if (project != null) {
              final playing = ref.read(desktopPlayerProvider);
              if (playing?.project.id == project.id) return playingHighlightColor;
              final isSession = ref.read(activeProjectProvider)?.id == project.id;
              final isActivated = stateManager?.currentRow == ctx.row;
              if (isSession) {
                // Read current paused state directly so notifyListeners refreshes pick it up.
                final isPaused = ref.read(workTimerPausedProvider);
                return isPaused
                    ? const Color(0x70FBBF24) // amber when paused
                    : const Color(0x7022C55E); // green when active
              }
              if (isActivated) return rowSelectColor;
            }
            return ctx.rowIdx.isOdd ? oddColor : evenColor;
          },
          onLoaded: (TrinaGridOnLoadedEvent event) {
            stateManager = event.stateManager;
            stateManager!.setRowGroup(
              TrinaRowGroupTreeDelegate(
                // Returning null for all columns disables TrinaGrid's auto
                // expand icon; we render our own in the checkbox column.
                resolveColumnDepth: (column) => null,
                showText: (cell) => true,
                showFirstExpandableIcon: false,
                showCount: false,
              ),
            );
            stateManager!.addListener(_onStateManagerChanged);
          },
      onRowSecondaryTap: (TrinaGridOnRowSecondaryTapEvent event) {
        final project = event.row.cells['data']?.value as MusicProject?;
        if (project != null && mounted) {
          _showContextMenu(context, project, event.offset);
        }
      },
      onChanged: (TrinaGridOnChangedEvent event) async {
        final project = event.row.cells['data']?.value as MusicProject?;
        if (project == null) return;
        
        final field = event.column.field;
        final newValue = event.value?.toString().trim() ?? '';
        
        if (field == 'bpm') {
          final bpm = newValue.isEmpty ? null : double.tryParse(newValue);
          
          // Write to bpm.txt file
          await _writeBpmToFile(project, bpm);
          
          // Update project in repository
          final repo = await ref.read(repositoryProvider.future);
          final updated = project.copyWith(bpm: bpm);
          await repo.updateProject(updated);
        } else if (field == 'key') {
          final key = newValue.isEmpty ? null : newValue;

          // Write to key.txt file
          await _writeKeyToFile(project, key);

          // Update project in repository
          final repo = await ref.read(repositoryProvider.future);
          final updated = project.copyWith(musicalKey: key);
          await repo.updateProject(updated);
        }
      },
      configuration: TrinaGridConfiguration(
        style: TrinaGridStyleConfig(
          // Neon Dark: card colour for header area, scaffold bg used only for odd rows via rowColorCallback
          gridBackgroundColor: activeTheme.cardColor,
          gridBorderColor: isNeon
              ? activeTheme.colorScheme.primary.withValues(alpha: 0.25)
              : activeTheme.dividerColor.withValues(alpha: 0.4),
          borderColor: isNeon
              ? activeTheme.colorScheme.primary.withValues(alpha: 0.15)
              : activeTheme.dividerColor.withValues(alpha: 0.25),
          gridBorderRadius: BorderRadius.zero,
          rowColor: oddColor,
          cellColorInEditState: Colors.transparent,
          cellColorInReadOnlyState: Colors.transparent,
          columnTextStyle: TextStyle(
            color: isNeon
                ? activeTheme.colorScheme.primary
                : activeTheme.textTheme.titleMedium?.color,
            fontWeight: FontWeight.w600,
          ),
          cellTextStyle: TextStyle(
            color: activeTheme.textTheme.bodyMedium?.color,
          ),
          columnHeight: 44,
          rowHeight: 48,
          activatedBorderColor: activeTheme.colorScheme.primary,
          // Transparent so rowColorCallback controls all row backgrounds
          // (session green/yellow, playing, and click-selection).
          activatedColor: Colors.transparent,
          iconColor: isNeon
              ? activeTheme.colorScheme.primary.withValues(alpha: 0.7)
              : activeTheme.textTheme.bodyMedium?.color ?? Colors.grey,
          menuBackgroundColor: activeTheme.cardColor,
          oddRowColor: oddColor,
          evenRowColor: evenColor,
        ),
        scrollbar: const TrinaGridScrollbarConfig(
          showHorizontal: false,
        ),
        columnSize: const TrinaGridColumnSizeConfig(
          autoSizeMode: TrinaAutoSizeMode.scale,
          resizeMode: TrinaResizeMode.pushAndPull,
        ),
        shortcut: TrinaGridShortcut(
          actions: {
            ...TrinaGridShortcut.defaultActions,
            LogicalKeySet(LogicalKeyboardKey.enter): _TrinaProjectAction(_viewProjectDetails),
            LogicalKeySet(LogicalKeyboardKey.numpadEnter): _TrinaProjectAction(_viewProjectDetails),
            LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.enter): _TrinaProjectAction(_viewProjectDetails),
            LogicalKeySet(LogicalKeyboardKey.keyP): _TrinaProjectAction(_playPreviewSong),
            LogicalKeySet(LogicalKeyboardKey.keyO): _TrinaProjectAction(_launchProject),
            LogicalKeySet(LogicalKeyboardKey.keyD): _TrinaProjectAction(_viewProjectDetails),
            LogicalKeySet(LogicalKeyboardKey.keyF): _TrinaProjectAction(_openProjectFolder),
            LogicalKeySet(LogicalKeyboardKey.keyS): _TrinaProjectAction(_toggleSession),
          },
        ),
      ),
      onRowChecked: null,
      onSelected: null,
      onRowDoubleTap: (TrinaGridOnRowDoubleTapEvent event) async {
        final project = event.row.cells['data']?.value as MusicProject?;
        if (project == null) return;
        
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
        );
      },
      createFooter: (stateManager) => const SizedBox.shrink(),
    );

    final dropTarget = DropTarget(
      onDragUpdated: (detail) => _updateDragTarget(detail.localPosition),
      onDragExited: (_) => setState(() {
        _dragOverRowTop = null;
      }),
      onDragDone: (detail) {
        final sm = stateManager;
        MusicProject? targetProject;
        if (sm != null) {
          final scrollOffset = sm.scroll.bodyRowsVertical?.offset ?? 0;
          final rowIndex = ((detail.localPosition.dy - _gridHeaderHeight + scrollOffset) / _gridRowHeight).floor();
          if (rowIndex >= 0 && rowIndex < sm.rows.length) {
            targetProject = sm.rows[rowIndex].cells['data']?.value as MusicProject?;
          }
        }
        setState(() {
          _dragOverRowTop = null;
        });
        if (targetProject == null) return;
        for (final xFile in detail.files) {
          final path = xFile.path;
          final ext = '.${path.split('.').last.toLowerCase()}';
          if (_audioExtensions.contains(ext)) {
            _setPreviewSong(targetProject, path);
            return;
          }
        }
      },
      child: Stack(
        children: [
          grid,
          if (_dragOverRowTop != null)
            Positioned(
              top: _dragOverRowTop!,
              left: 0,
              right: 0,
              height: _gridRowHeight,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.35),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.audio_file,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Drop to set as preview',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final sm = stateManager;
    final hasGroups = sm != null && sm.rows.any((r) => r.type.isGroup);
    if (!hasGroups) return dropTarget;

    final anyExpanded = sm.rows.any((r) => r.type.isGroup && r.type.group.expanded);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: Icon(
                  anyExpanded ? Icons.unfold_less : Icons.unfold_more,
                  size: 16,
                ),
                label: Text(
                  anyExpanded ? '${l10n.collapse} All' : '${l10n.expand} All',
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: anyExpanded ? _collapseAll : _expandAll,
              ),
            ],
          ),
        ),
        Expanded(child: dropTarget),
      ],
    );
  }

  @override
  void dispose() {
    stateManager?.removeListener(_onStateManagerChanged);
    super.dispose();
  }
}

/// Custom TrinaGrid shortcut action that operates on the focused project row.
class _TrinaProjectAction extends TrinaGridShortcutAction {
  final Future<void> Function(MusicProject project) onProject;

  const _TrinaProjectAction(this.onProject);

  @override
  void execute({
    required TrinaKeyManagerEvent keyEvent,
    required TrinaGridStateManager stateManager,
  }) {
    if (stateManager.isEditing) return;
    final project = stateManager.currentRow?.cells['data']?.value;
    if (project is MusicProject) unawaited(onProject(project));
  }
}

class _ReleaseTitleDialog extends StatefulWidget {
  @override
  State<_ReleaseTitleDialog> createState() => _ReleaseTitleDialogState();
}

class _ReleaseTitleDialogState extends State<_ReleaseTitleDialog> {
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(AppLocalizations.of(context)!.enterReleaseTitle),
      content: TextField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.releaseTitle,
          hintText: AppLocalizations.of(context)!.enterReleaseTitleHint,
        ),
        autofocus: true,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            Navigator.pop(context, value.trim());
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _titleController.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _titleController.text.trim()),
          child: Text(AppLocalizations.of(context)!.create),
        ),
      ],
    );
  }
}

class _TogglePlayPauseIntent extends Intent {
  const _TogglePlayPauseIntent();
}

class _SeekIntent extends Intent {
  final int seconds;
  const _SeekIntent(this.seconds);
}


class _PreviewSongDialog extends ConsumerStatefulWidget {
  final MusicProject project;
  final VoidCallback onClose;

  const _PreviewSongDialog({
    required this.project,
    required this.onClose,
  });

  @override
  ConsumerState<_PreviewSongDialog> createState() => _PreviewSongDialogState();
}

class _PreviewSongDialogState extends ConsumerState<_PreviewSongDialog> {
  AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer? _warmPlayer;
  int _playerGen = 0;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;
  bool _isMono = false;
  bool _isGeneratingMono = false;
  String? _monoFilePath;
  AudioFileInfo? _fileInfo;
  String? _autoDetectedPath;

  String? get _effectivePreviewPath =>
      widget.project.previewSongPath?.isNotEmpty == true
          ? widget.project.previewSongPath
          : (_autoDetectedPath ?? widget.project.previewSongAutoPath);

  void _attachListeners(AudioPlayer player, int gen) {
    player.onPlayerStateChanged.listen((state) {
      if (gen != _playerGen || !mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    player.onDurationChanged.listen((d) {
      if (gen != _playerGen || !mounted) return;
      setState(() => _duration = d);
    });
    player.onPositionChanged.listen((p) {
      if (gen != _playerGen || !mounted) return;
      setState(() => _position = p);
    });
    player.onPlayerComplete.listen((_) {
      if (gen != _playerGen || !mounted) return;
      setState(() { _isPlaying = false; _position = Duration.zero; });
    });
  }

  @override
  void initState() {
    super.initState();
    _attachListeners(_audioPlayer, _playerGen);
    if (widget.project.previewSongPath?.isNotEmpty == true) {
      _startPlayback();
      _startBackgroundPrep();
    } else if (widget.project.previewSongAutoPath != null) {
      _autoDetectedPath = widget.project.previewSongAutoPath;
      _startPlayback();
      _startBackgroundPrep();
    } else {
      Future.microtask(() async {
        final customFolder = ref.read(customMixdownFolderProvider).value;
        final file = MixdownDetectorService.findLatestMixdown(widget.project, customFolder: customFolder);
        if (mounted && file != null) {
          setState(() => _autoDetectedPath = file.path);
          final repo = await ref.read(repositoryProvider.future);
          await repo.updateProject(widget.project.copyWith(previewSongAutoPath: file.path));
          _startPlayback();
          _startBackgroundPrep();
        }
      });
    }
  }

  bool _hasAudioFile() {
    final p2 = _effectivePreviewPath;
    return p2 != null && p2.isNotEmpty;
  }

  bool _supportsMonoMix() {
    final p2 = _effectivePreviewPath;
    if (p2 == null || p2.isEmpty) return false;
    final ext = p2.toLowerCase().split('.').last;
    if (ext == 'wav') return true;
    if (Platform.isMacOS || Platform.isIOS) {
      return const {'mp3', 'flac', 'aif', 'aiff', 'aac', 'm4a'}.contains(ext);
    }
    return const {'mp3', 'flac', 'aif', 'aiff', 'ogg', 'aac', 'm4a'}.contains(ext);
  }

  Source _currentSource() {
    if (_isMono && _monoFilePath != null) return DeviceFileSource(_monoFilePath!);
    return DeviceFileSource(_effectivePreviewPath!);
  }

  void _startBackgroundPrep() {
    if (!_hasAudioFile()) return;
    final filePath = _effectivePreviewPath!;
    AudioAnalysisService.getFileInfo(filePath).then((info) {
      if (mounted && info != null) setState(() => _fileInfo = info);
    });
    if (_supportsMonoMix()) _prepareMonoFile(filePath);
  }

  Future<void> _prepareMonoFile(String filePath) async {
    final tmpDir = await getTemporaryDirectory();
    final outPath = '${tmpDir.path}/mono_${widget.project.id}.wav';
    final ok = await AudioAnalysisService.writeMonoWavFile(filePath, outPath);
    if (!mounted) return;
    if (ok) {
      setState(() => _monoFilePath = outPath);
      _preWarmAlt(DeviceFileSource(outPath));
    } else {
      final channels = await AudioAnalysisService.getChannelCount(filePath);
      if (mounted && channels == 1) {
        setState(() => _monoFilePath = filePath);
        _preWarmAlt(DeviceFileSource(filePath));
      }
    }
  }

  void _preWarmAlt(Source source) {
    _warmPlayer?.dispose();
    _warmPlayer = AudioPlayer();
    _warmPlayer!.setVolume(_volume);
    _warmPlayer!.setSource(source);
  }

  void _fadeIn(AudioPlayer player) {
    const steps = 12;
    const stepMs = 10;
    int step = 0;
    Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
      step++;
      if (!mounted || player != _audioPlayer) {
        timer.cancel();
        return;
      }
      player.setVolume((_volume * step / steps).clamp(0.0, _volume));
      if (step >= steps) {
        timer.cancel();
        player.setVolume(_volume);
      }
    });
  }

  Future<void> _toggleMono() async {
    if (!_supportsMonoMix()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mono mixing is not supported for this format')),
      );
      return;
    }
    final newMono = !_isMono;
    if (newMono && _monoFilePath == null) {
      setState(() => _isGeneratingMono = true);
      final tmpDir = await getTemporaryDirectory();
      final outPath = '${tmpDir.path}/mono_${widget.project.id}.wav';
      final ok = await AudioAnalysisService.writeMonoWavFile(_effectivePreviewPath!, outPath);
      if (!mounted) return;
      if (!ok) {
        final channels = await AudioAnalysisService.getChannelCount(_effectivePreviewPath!);
        if (!mounted) return;
        if (channels == 1) {
          setState(() { _monoFilePath = _effectivePreviewPath!; _isGeneratingMono = false; });
        } else {
          setState(() => _isGeneratingMono = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not create mono mix — unsupported format')),
          );
          return;
        }
      } else {
        setState(() { _monoFilePath = outPath; _isGeneratingMono = false; });
      }
    }

    final wasPlaying = _isPlaying;
    final savedPosition = _position;
    setState(() => _isMono = newMono);

    final newActive = _warmPlayer ?? AudioPlayer();
    _warmPlayer = null;
    final gen = ++_playerGen;
    final oldActive = _audioPlayer;
    _audioPlayer = newActive;
    _attachListeners(newActive, gen);

    try {
      if (wasPlaying) {
        await newActive.setVolume(0);
        await newActive.play(_currentSource(), position: savedPosition);
        _fadeIn(newActive);
      } else {
        await newActive.setVolume(_volume);
        await newActive.setSource(_currentSource());
        if (savedPosition > Duration.zero) await newActive.seek(savedPosition);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mono switch failed: $e')),
        );
      }
    }

    await oldActive.stop();
    final altSource = _isMono
        ? DeviceFileSource(_effectivePreviewPath!)
        : (_monoFilePath != null ? DeviceFileSource(_monoFilePath!) : null);
    if (altSource != null) {
      _warmPlayer = oldActive;
      _warmPlayer!.setVolume(_volume);
      _warmPlayer!.setSource(altSource);
    } else {
      oldActive.dispose();
    }
  }

  Future<void> _startPlayback() async {
    if (!_hasAudioFile()) return;

    final file = File(_effectivePreviewPath!);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.previewSongFileNotFound)),
        );
        Navigator.pop(context);
      }
      return;
    }

    try {
      await _audioPlayer.play(_currentSource());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToPlayPreview(e.toString()))),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _warmPlayer?.dispose();
    widget.onClose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position == Duration.zero || _position >= _duration) {
          await _audioPlayer.play(DeviceFileSource(_effectivePreviewPath!));
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToPlayPreview(e.toString()))),
        );
      }
    }
  }

  Future<void> _seek(int seconds) async {
    final target = _position + Duration(seconds: seconds);
    final clamped = target.isNegative ? Duration.zero : (_duration > Duration.zero && target > _duration ? _duration : target);
    await _audioPlayer.seek(clamped);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours > 0 ? '${twoDigits(hours)}:$minutes:$seconds' : '$minutes:$seconds';
  }

  static final _uuidPreviewRe = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}_preview\.',
    caseSensitive: false,
  );

  String? _displayFileName() {
    // Prefer the stored display name, unless it's itself a UUID backup name
    final storedName = widget.project.previewSongFileName;
    if (storedName != null && storedName.isNotEmpty && !_uuidPreviewRe.hasMatch(storedName)) {
      return storedName;
    }
    // Fall back to the path basename, suppressing UUID-named backup downloads
    final fallback = path.basename(_effectivePreviewPath ?? '');
    if (fallback.isEmpty || _uuidPreviewRe.hasMatch(fallback)) return null;
    return fallback;
  }


  Widget _buildAndroidPlayerLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File name
        if (_autoDetectedPath != null &&
            widget.project.previewSongPath?.isNotEmpty != true)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.folder_open, size: 12, color: Colors.amber),
                const SizedBox(width: 4),
                const Text(
                  'Auto-detected from mixdown folder',
                  style: TextStyle(fontSize: 11, color: Colors.amber),
                ),
              ],
            ),
          ),
        if (_displayFileName() != null)
          Text(
            _displayFileName()!,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        if (_displayFileName() != null) const SizedBox(height: 8),
        const SizedBox(height: 8),
        // Transport controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_5),
              onPressed: () => _seek(-5),
              iconSize: 32,
            ),
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlayPause,
              iconSize: 48,
              color: _autoDetectedPath != null &&
                      widget.project.previewSongPath?.isNotEmpty != true
                  ? Colors.amber
                  : Theme.of(context).colorScheme.primary,
            ),
            IconButton(
              icon: const Icon(Icons.forward_5),
              onPressed: () => _seek(5),
              iconSize: 32,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Seek bar
        Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Theme.of(context).colorScheme.primary,
                thumbColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
                overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                trackHeight: 4.0,
              ),
              child: Slider(
                value: _duration.inMilliseconds > 0
                    ? _position.inMilliseconds.toDouble()
                    : 0.0,
                max: _duration.inMilliseconds > 0
                    ? _duration.inMilliseconds.toDouble()
                    : 100.0,
                onChanged: (value) async {
                  final position = Duration(milliseconds: value.toInt());
                  await _audioPlayer.seek(position);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Volume + mono on a single row
        Row(
          children: [
            Icon(
              _volume == 0 ? Icons.volume_off : (_volume < 0.5 ? Icons.volume_down : Icons.volume_up),
              size: 24,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            Expanded(
              child: Slider(
                value: _volume,
                min: 0.0,
                max: 1.0,
                onChanged: (value) async {
                  setState(() { _volume = value; });
                  await _audioPlayer.setVolume(value);
                },
              ),
            ),
            const SizedBox(width: 8),
            _isGeneratingMono
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : FilterChip(
                    avatar: Icon(
                      _isMono ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 16,
                      color: _isMono ? Colors.red : null,
                    ),
                    label: Text('Mono', style: TextStyle(color: _isMono ? Colors.red : null, fontWeight: _isMono ? FontWeight.bold : null)),
                    tooltip: 'Toggle mono playback',
                    selected: _isMono,
                    showCheckmark: false,
                    selectedColor: Colors.red.withValues(alpha: 0.15),
                    onSelected: (_) => _toggleMono(),
                    visualDensity: VisualDensity.compact,
                  ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopPlayerLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_displayFileName() != null) ...[
          Text(
            _displayFileName()!,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
        ],
        // Audio player controls
        Row(
          children: [
            Tooltip(
              message: '← −5s',
              child: IconButton(
                icon: const Icon(Icons.replay_5),
                onPressed: () => _seek(-5),
              ),
            ),
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlayPause,
              iconSize: 32,
              color: _autoDetectedPath != null &&
                      widget.project.previewSongPath?.isNotEmpty != true
                  ? Colors.amber
                  : null,
            ),
            Tooltip(
              message: '→ +5s',
              child: IconButton(
                icon: const Icon(Icons.forward_5),
                onPressed: () => _seek(5),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      thumbColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
                      overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      trackHeight: 3.0,
                    ),
                    child: Slider(
                      value: _duration.inMilliseconds > 0
                          ? _position.inMilliseconds.toDouble()
                          : 0.0,
                      max: _duration.inMilliseconds > 0
                          ? _duration.inMilliseconds.toDouble()
                          : 100.0,
                      onChanged: (value) async {
                        final position = Duration(milliseconds: value.toInt());
                        await _audioPlayer.seek(position);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Volume control
            const SizedBox(width: 8),
            Icon(
              _volume == 0 ? Icons.volume_off : (_volume < 0.5 ? Icons.volume_down : Icons.volume_up),
              size: 20,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            SizedBox(
              width: 120,
              child: Slider(
                value: _volume,
                min: 0.0,
                max: 1.0,
                onChanged: (value) async {
                  setState(() {
                    _volume = value;
                  });
                  await _audioPlayer.setVolume(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _isGeneratingMono
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : FilterChip(
                    avatar: Icon(
                      _isMono ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 16,
                      color: _isMono ? Colors.red : null,
                    ),
                    label: Text('Mono', style: TextStyle(color: _isMono ? Colors.red : null, fontWeight: _isMono ? FontWeight.bold : null)),
                    tooltip: 'Toggle mono playback',
                    selected: _isMono,
                    showCheckmark: false,
                    selectedColor: Colors.red.withValues(alpha: 0.15),
                    onSelected: (_) => _toggleMono(),
                    visualDensity: VisualDensity.compact,
                  ),
            const SizedBox(width: 12),
            Builder(builder: (ctx) {
              final dim = Theme.of(ctx).textTheme.bodySmall?.color;
              final ext = (widget.project.previewSongPath ?? '').toLowerCase().split('.').last;
              final formatLabel = switch (ext) {
                'wav'  => 'WAV',
                'mp3'  => 'MP3',
                'flac' => 'FLAC',
                'aif' || 'aiff' => 'AIFF',
                'ogg'  => 'OGG',
                'aac'  => 'AAC',
                'm4a'  => 'M4A',
                _      => ext.toUpperCase(),
              };
              final parts = <String>[];
              if (_fileInfo != null) {
                final sr = _fileInfo!.sampleRate;
                parts.add(sr % 1000 == 0 ? '${sr ~/ 1000} kHz' : '${(sr / 1000).toStringAsFixed(1)} kHz');
                if (_fileInfo!.bitDepth != null) {
                  parts.add('${_fileInfo!.bitDepth}-bit');
                } else if (_fileInfo!.bitrateKbps != null) {
                  parts.add('${_fileInfo!.bitrateKbps} kbps');
                }
                parts.add(_fileInfo!.channels == 1 ? 'Mono' : _fileInfo!.channels == 2 ? 'Stereo' : '${_fileInfo!.channels}ch');
              }
              parts.add(formatLabel);
              return Text(parts.join(' · '), style: TextStyle(fontSize: 11, color: dim));
            }),
          ],
        ),
      ],
    );
  }

  Future<void> _sharePreviewSong() async {
    if (widget.project.previewSongPath == null || widget.project.previewSongPath!.isEmpty) {
      if (kDebugMode) {
        debugPrint('[preview_share] No previewSongPath set for project=${widget.project.id}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.previewSongFileNotFound)),
        );
      }
      return;
    }

    // Skip if it's a Drive file reference (not downloaded)
    if (widget.project.previewSongPath!.startsWith('drive://')) {
      if (kDebugMode) {
        debugPrint('[preview_share] Path is Drive reference (not downloaded): ${widget.project.previewSongPath}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.previewSongNotAvailableDownloadFirst)),
        );
      }
      return;
    }

    try {
      final sourceFile = File(widget.project.previewSongPath!);
      if (kDebugMode) {
        debugPrint('[preview_share] sourceFile=${sourceFile.path}');
      }
      if (!await sourceFile.exists()) {
        if (kDebugMode) {
          debugPrint('[preview_share] sourceFile does not exist');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.previewSongFileNotFound)),
          );
        }
        return;
      }

      // WhatsApp enforces a ~64MB limit for audio messages, but typically allows larger files as "documents".
      // Keep default share here (audio). A separate "Share as ZIP" action is also available.
      final fileSizeBytes = await sourceFile.length();
      if (kDebugMode) {
        debugPrint('[preview_share] sizeBytes=$fileSizeBytes');
      }

      // Get the original filename or use a default
      String originalFileName = widget.project.previewSongFileName ?? 
          path.basename(widget.project.previewSongPath!);
      
      // Ensure the filename has an extension
      if (!originalFileName.contains('.')) {
        final ext = path.extension(widget.project.previewSongPath!);
        originalFileName = '$originalFileName$ext';
      }

      // On mobile, copy to cache directory with original name for sharing
      if (MobileUtils.isMobile()) {
        final cacheDir = await getTemporaryDirectory();
        final shareFile = File(path.join(cacheDir.path, originalFileName));
        if (kDebugMode) {
          debugPrint('[preview_share] cacheDir=${cacheDir.path} shareFile=${shareFile.path}');
        }
        
        // Copy file to cache with original name
        await sourceFile.copy(shareFile.path);
        if (kDebugMode) {
          debugPrint('[preview_share] copied to cache OK, invoking share sheet...');
        }

        // Share the file (default behavior)
        final result = await Share.shareXFiles(
          [XFile(shareFile.path, name: originalFileName)],
          text: 'Preview song: ${widget.project.displayName}',
        );
        if (kDebugMode) {
          debugPrint('[preview_share] Share.shareXFiles returned (user completed/dismissed share sheet)');
          debugPrint('[preview_share] ShareResult: status=${result.status} raw=${result.raw}');
        }
      } else {
        // On other platforms, share the file directly
        if (kDebugMode) {
          debugPrint('[preview_share] non-Android direct share, invoking share sheet...');
        }
        final result = await Share.shareXFiles(
          [XFile(sourceFile.path)],
          text: 'Preview song: ${widget.project.displayName}',
        );
        if (kDebugMode) {
          debugPrint('[preview_share] ShareResult: status=${result.status} raw=${result.raw}');
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[preview_share] ERROR: $e');
        debugPrint('$st');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSharePreviewSong(e.toString()))),
        );
      }
    }
  }

  Future<void> _sharePreviewSongAsZip() async {
    if (!MobileUtils.isMobile()) return;

    if (widget.project.previewSongPath == null || widget.project.previewSongPath!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.previewSongFileNotFound)),
        );
      }
      return;
    }

    // Skip if it's a Drive file reference (not downloaded)
    if (widget.project.previewSongPath!.startsWith('drive://')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.previewSongNotAvailableDownloadFirst)),
        );
      }
      return;
    }

    try {
      final sourceFile = File(widget.project.previewSongPath!);
      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.previewSongFileNotFound)),
          );
        }
        return;
      }

      // Get the original filename or use a default
      String originalFileName = widget.project.previewSongFileName ??
          path.basename(widget.project.previewSongPath!);
      if (!originalFileName.contains('.')) {
        final ext = path.extension(widget.project.previewSongPath!);
        originalFileName = '$originalFileName$ext';
      }

      // Copy to cache and zip it
      final cacheDir = await getTemporaryDirectory();
      final shareFile = File(path.join(cacheDir.path, originalFileName));
      await sourceFile.copy(shareFile.path);

      final zipBase = path.basenameWithoutExtension(originalFileName);
      var zipPath = path.join(cacheDir.path, '$zipBase.zip');
      var zipFile = File(zipPath);
      if (await zipFile.exists()) {
        zipPath = path.join(cacheDir.path, '${zipBase}_${DateTime.now().millisecondsSinceEpoch}.zip');
        zipFile = File(zipPath);
      }

      if (kDebugMode) {
        debugPrint('[preview_share_zip] sourceFile=${sourceFile.path}');
        debugPrint('[preview_share_zip] copiedTo=${shareFile.path}');
        debugPrint('[preview_share_zip] creating zip: ${zipFile.path}');
      }

      final encoder = ZipFileEncoder();
      encoder.create(zipFile.path);
      await encoder.addFile(shareFile);
      encoder.close();

      final zipSizeBytes = await zipFile.length();
      if (kDebugMode) {
        debugPrint('[preview_share_zip] zipSizeBytes=$zipSizeBytes');
        debugPrint('[preview_share_zip] invoking share sheet...');
      }

      final result = await Share.shareXFiles(
        [XFile(zipFile.path, name: path.basename(zipFile.path), mimeType: 'application/zip')],
        text: 'Preview song (ZIP): ${widget.project.displayName}',
      );
      if (kDebugMode) {
        debugPrint('[preview_share_zip] Share.shareXFiles returned (user completed/dismissed share sheet)');
        debugPrint('[preview_share_zip] ShareResult: status=${result.status} raw=${result.raw}');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[preview_share_zip] ERROR: $e');
        debugPrint('$st');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSharePreviewSongAsZip(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
        if (_isTextInputFocused()) return KeyEventResult.ignored;
        final isModified = HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed;
        if (event.logicalKey == LogicalKeyboardKey.space) {
          _togglePlayPause();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _seek(isModified ? -30 : -5);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _seek(isModified ? 30 : 5);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            constraints: BoxConstraints(
              minWidth: MobileUtils.isMobile() ? 320 : 780,
              maxWidth: MobileUtils.isMobile() ? double.infinity : 840,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.project.displayName,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (MobileUtils.isMobile() &&
                    widget.project.previewSongPath != null &&
                    widget.project.previewSongPath!.isNotEmpty &&
                    !widget.project.previewSongPath!.startsWith('drive://')) ...[
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: AppLocalizations.of(context)!.sharePreviewSong,
                    onPressed: _sharePreviewSong,
                  ),
                  IconButton(
                    icon: const Icon(Icons.archive),
                    tooltip: AppLocalizations.of(context)!.shareAsZip,
                    onPressed: _sharePreviewSongAsZip,
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            content: SizedBox(
              width: MobileUtils.isMobile() ? double.infinity : 600,
              child: MobileUtils.isMobile()
                  ? _buildAndroidPlayerLayout(context)
                  : _buildDesktopPlayerLayout(context),
            ),
          ),
    );
  }
}

// ─── Desktop embedded bottom player ──────────────────────────────────────────

class _DesktopPlayerBar extends ConsumerStatefulWidget {
  final DesktopPlayerRequest request;
  const _DesktopPlayerBar({super.key, required this.request});

  @override
  ConsumerState<_DesktopPlayerBar> createState() => _DesktopPlayerBarState();
}

class _DesktopPlayerBarState extends ConsumerState<_DesktopPlayerBar> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _preMuteVolume = 1.0;
  bool _isMono = false;
  bool _isGeneratingMono = false;
  String? _monoFilePath;
  AudioFileInfo? _fileInfo;
  WaveformPeaks? _peaks;
  double _barHeight = 200.0;
  final FocusNode _focusNode = FocusNode();

  static const _kBarHeightKey = 'player_bar_height';

  String get _activePath =>
      _isMono && _monoFilePath != null ? _monoFilePath! : widget.request.resolvedPath;

  bool _supportsMonoMix() {
    final ext = widget.request.resolvedPath.toLowerCase().split('.').last;
    if (ext == 'wav') return true;
    if (Platform.isMacOS || Platform.isIOS) {
      return const {'mp3', 'flac', 'aif', 'aiff', 'aac', 'm4a'}.contains(ext);
    }
    return const {'mp3', 'flac', 'aif', 'aiff', 'ogg', 'aac', 'm4a'}.contains(ext);
  }

  Future<void> _loadBarHeight() async {
    final box = await Hive.openBox<String>('app_settings');
    final saved = box.get(_kBarHeightKey);
    if (saved != null && mounted) {
      setState(() => _barHeight = double.tryParse(saved) ?? 200.0);
    }
  }

  Future<void> _saveBarHeight() async {
    final box = await Hive.openBox<String>('app_settings');
    await box.put(_kBarHeightKey, _barHeight.toString());
  }

  bool _handleKeyboard(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    // Never steal keys from text inputs.
    if (_isTextInputFocused()) return false;

    final modified = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (event.logicalKey == LogicalKeyboardKey.space) {
      _togglePlayPause();
      return true;
    }
    // Arrow keys only when the player bar has focus — avoids conflicting with
    // table row navigation when the user has clicked into the projects table.
    if (!_focusNode.hasFocus) return false;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _seek(modified ? -30 : -5);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _seek(modified ? 30 : 5);
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadBarHeight();
    HardwareKeyboard.instance.addHandler(_handleKeyboard);
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _isPlaying = s == PlayerState.playing);
    });
    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() { _isPlaying = false; _position = Duration.zero; });
      if (widget.request.isQueuedPlayback) {
        ref.read(desktopPlayerCompletedProvider.notifier).increment();
      }
    });
    _player.play(DeviceFileSource(widget.request.resolvedPath));
    _loadBackgroundData();
  }

  @override
  void didUpdateWidget(_DesktopPlayerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.resolvedPath != widget.request.resolvedPath ||
        oldWidget.request.generation != widget.request.generation) {
      _player.stop();
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
        _duration = Duration.zero;
        _isMono = false;
        _isGeneratingMono = false;
        _monoFilePath = null;
        _fileInfo = null;
        _peaks = null;
      });
      _player.play(DeviceFileSource(widget.request.resolvedPath));
      _loadBackgroundData();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyboard);
    _focusNode.dispose();
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  void _loadBackgroundData() {
    final filePath = widget.request.resolvedPath;

    // Waveform peaks — memory → disk → extraction
    ref.read(waveformCacheProvider.notifier).getOrExtract(filePath).then((peaks) {
      if (!mounted || peaks == null) return;
      setState(() => _peaks = peaks);
    });

    // File info
    AudioAnalysisService.getFileInfo(filePath).then((info) {
      if (mounted && info != null) setState(() => _fileInfo = info);
    });

    // Pre-generate mono in background
    if (_supportsMonoMix()) _prepareMonoFile(filePath);
  }

  Future<void> _prepareMonoFile(String filePath) async {
    final tmpDir = await getTemporaryDirectory();
    final outPath = '${tmpDir.path}/mono_bar_${widget.request.project.id}.wav';
    final ok = await AudioAnalysisService.writeMonoWavFile(filePath, outPath);
    if (!mounted) return;
    if (ok) {
      setState(() => _monoFilePath = outPath);
    } else {
      final channels = await AudioAnalysisService.getChannelCount(filePath);
      if (mounted && channels == 1) setState(() => _monoFilePath = filePath);
    }
  }

  Future<void> _toggleMono() async {
    if (!_supportsMonoMix()) return;
    final newMono = !_isMono;
    if (newMono && _monoFilePath == null) {
      setState(() => _isGeneratingMono = true);
      final tmpDir = await getTemporaryDirectory();
      final outPath = '${tmpDir.path}/mono_bar_${widget.request.project.id}.wav';
      final ok = await AudioAnalysisService.writeMonoWavFile(widget.request.resolvedPath, outPath);
      if (!mounted) return;
      if (!ok) {
        final ch = await AudioAnalysisService.getChannelCount(widget.request.resolvedPath);
        if (!mounted) return;
        if (ch == 1) {
          setState(() { _monoFilePath = widget.request.resolvedPath; _isGeneratingMono = false; });
        } else {
          setState(() => _isGeneratingMono = false);
          return;
        }
      } else {
        setState(() { _monoFilePath = outPath; _isGeneratingMono = false; });
      }
    }
    final wasPlaying = _isPlaying;
    final savedPos = _position;
    setState(() => _isMono = newMono);
    try {
      if (wasPlaying) {
        await _player.play(DeviceFileSource(_activePath), position: savedPos);
      } else {
        await _player.setSource(DeviceFileSource(_activePath));
        if (savedPos > Duration.zero) await _player.seek(savedPos);
      }
    } catch (_) {}
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_duration > Duration.zero && _position >= _duration) {
        await _player.play(DeviceFileSource(_activePath));
      } else {
        await _player.resume();
      }
    }
  }

  Future<void> _seek(int seconds) async {
    final target = _position + Duration(seconds: seconds);
    final clamped = target.isNegative
        ? Duration.zero
        : (_duration > Duration.zero && target > _duration ? _duration : target);
    await _player.seek(clamped);
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return h > 0 ? '${two(h)}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(desktopPlayerProvider, (prev, next) {
      if (next == null) _player.stop();
    });
    final queueNav = ref.watch(queueNavigationProvider);
    final isQueued = widget.request.isQueuedPlayback;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final project = widget.request.project;
    final isAutoDetected = (project.previewSongPath?.isEmpty ?? true) &&
        project.previewSongAutoPath == widget.request.resolvedPath;

    final ext = widget.request.resolvedPath.toLowerCase().split('.').last;
    final formatLabel = switch (ext) {
      'wav' => 'WAV', 'mp3' => 'MP3', 'flac' => 'FLAC',
      'aif' || 'aiff' => 'AIFF', 'ogg' => 'OGG',
      'aac' => 'AAC', 'm4a' => 'M4A',
      _ => ext.toUpperCase(),
    };
    final infoParts = <String>[];
    if (_fileInfo != null) {
      final sr = _fileInfo!.sampleRate;
      infoParts.add(sr % 1000 == 0 ? '${sr ~/ 1000}kHz' : '${(sr / 1000).toStringAsFixed(1)}kHz');
      if (_fileInfo!.bitDepth != null) {
        infoParts.add('${_fileInfo!.bitDepth}-bit');
      } else if (_fileInfo!.bitrateKbps != null) {
        infoParts.add('${_fileInfo!.bitrateKbps}kbps');
      }
      infoParts.add(_fileInfo!.channels == 1 ? 'Mono' : _fileInfo!.channels == 2 ? 'Stereo' : '${_fileInfo!.channels}ch');
    }
    infoParts.add(formatLabel);

    const iconConstraints = BoxConstraints(minWidth: 32, minHeight: 32);
    const iconPad = EdgeInsets.zero;

    final modKey = Platform.isMacOS ? '⌘' : 'Ctrl';

    return Focus(
      focusNode: _focusNode,
      child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _focusNode.requestFocus(),
      child: Material(
      elevation: 8,
      color: theme.cardColor,
      child: SizedBox(
        height: _barHeight,
        child: Column(
          children: [
            // Resize grip — drag upward to make the player taller (max 300px)
            MouseRegion(
              cursor: SystemMouseCursors.resizeUpDown,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _barHeight = (_barHeight - details.delta.dy).clamp(100.0, 300.0);
                  });
                },
                onVerticalDragEnd: (_) => _saveBarHeight(),
                child: SizedBox(
                  height: 8,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 3,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: cs.outline.withValues(alpha: 0.18)),
            // ── Row 1: transport · volume · [centered name] · time · mono · info · close ─
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
              child: Row(
                children: [
                  // Transport controls
                  if (isQueued)
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      iconSize: 20, padding: iconPad, constraints: iconConstraints,
                      tooltip: l10n.playerPreviousTrack,
                      onPressed: queueNav.playPrev,
                    ),
                  Tooltip(
                    message: '−5s  (←)  •  $modKey+← −30s',
                    child: IconButton(icon: const Icon(Icons.replay_5), iconSize: 20, padding: iconPad, constraints: iconConstraints, onPressed: () => _seek(-5)),
                  ),
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                    iconSize: 34, color: cs.primary, padding: iconPad,
                    constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                    tooltip: 'Play / Pause  (Space)',
                    onPressed: _togglePlayPause,
                  ),
                  Tooltip(
                    message: '+5s  (→)  •  $modKey+→ +30s',
                    child: IconButton(icon: const Icon(Icons.forward_5), iconSize: 20, padding: iconPad, constraints: iconConstraints, onPressed: () => _seek(5)),
                  ),
                  if (isQueued)
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      iconSize: 20, padding: iconPad, constraints: iconConstraints,
                      tooltip: l10n.playerNextTrack,
                      onPressed: queueNav.playNext,
                    ),
                  // Volume (immediately after transport)
                  IconButton(
                    icon: Icon(_volume == 0 ? Icons.volume_off : (_volume < 0.5 ? Icons.volume_down : Icons.volume_up)),
                    iconSize: 18,
                    color: cs.onSurface.withValues(alpha: 0.6),
                    padding: iconPad,
                    constraints: iconConstraints,
                    tooltip: _volume == 0 ? 'Unmute' : 'Mute',
                    onPressed: () {
                      if (_volume > 0) {
                        _preMuteVolume = _volume;
                        setState(() => _volume = 0);
                      } else {
                        setState(() => _volume = _preMuteVolume > 0 ? _preMuteVolume : 1.0);
                      }
                      _player.setVolume(_volume);
                    },
                  ),
                  SizedBox(
                    width: 135,
                    child: Slider(
                      value: _volume, min: 0, max: 1,
                      onChanged: (v) {
                        setState(() => _volume = v);
                        if (v > 0) _preMuteVolume = v;
                        _player.setVolume(v);
                      },
                    ),
                  ),
                  // Centered track name + filename
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isAutoDetected) ...[
                                const Icon(Icons.folder_open, size: 11, color: Colors.amber),
                                const SizedBox(width: 3),
                              ],
                              Flexible(
                                child: Text(
                                  project.displayName,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis, maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            path.basename(widget.request.resolvedPath),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                            overflow: TextOverflow.ellipsis, maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Time display (fixed-width to prevent jitter)
                  SizedBox(
                    width: 92,
                    child: Text(
                      '${_fmt(_position)} / ${_fmt(_duration)}',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Mono toggle
                  if (_supportsMonoMix())
                    _isGeneratingMono
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : FilterChip(
                            avatar: Icon(
                              _isMono ? Icons.check_box : Icons.check_box_outline_blank,
                              size: 16,
                              color: _isMono ? Colors.red : null,
                            ),
                            label: Text('Mono', style: TextStyle(fontSize: 11, color: _isMono ? Colors.red : null, fontWeight: _isMono ? FontWeight.bold : null)),
                            selected: _isMono, showCheckmark: false,
                            selectedColor: Colors.red.withValues(alpha: 0.15),
                            onSelected: (_) => _toggleMono(),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                  const SizedBox(width: 8),
                  // File info
                  Text(
                    infoParts.join(' · '),
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(width: 10),
                  // Session bookmark (only when session mode is on)
                  Consumer(
                    builder: (context, ref, _) {
                      final sessionMode = ref.watch(sessionModeProvider);
                      if (!sessionMode) return const SizedBox.shrink();
                      final activeProject = ref.watch(activeProjectProvider);
                      final isSubscribed = activeProject?.id == project.id;
                      return IconButton(
                        icon: Icon(isSubscribed ? Icons.bookmark : Icons.bookmark_add_outlined),
                        iconSize: 18, padding: iconPad, constraints: iconConstraints,
                        tooltip: isSubscribed ? l10n.endSession : l10n.startSession,
                        color: isSubscribed ? Colors.green.shade400 : null,
                        onPressed: () {
                          if (isSubscribed) {
                            _confirmEndSession(context, ref);
                          } else {
                            _confirmStartSession(context, ref, project);
                          }
                        },
                      );
                    },
                  ),
                  // View Details
                  IconButton(
                    icon: const Icon(Icons.assignment),
                    iconSize: 18, padding: iconPad, constraints: iconConstraints,
                    tooltip: l10n.projectDetails,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
                    ),
                  ),
                  // Open Folder
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    iconSize: 18, padding: iconPad, constraints: iconConstraints,
                    tooltip: l10n.openFolder,
                    onPressed: () async {
                      final projectPath = project.filePath;
                      final folderPath = FileSystemEntity.isDirectorySync(projectPath)
                          ? projectPath
                          : path.dirname(projectPath);
                      if (Directory(folderPath).existsSync()) {
                        await FileLauncher.openFolder(folderPath);
                      }
                    },
                  ),
                  // Close
                  IconButton(
                    icon: const Icon(Icons.close),
                    iconSize: 18, padding: iconPad, constraints: iconConstraints,
                    tooltip: l10n.close,
                    onPressed: () => ref.read(desktopPlayerProvider.notifier).close(),
                  ),
                ],
              ),
            ),
            // ── Row 2: waveform (full width) ──────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
                child: WaveformWidget(
                  peaks: _peaks,
                  progress: progress,
                  height: null,
                  onSeek: (p) {
                    _focusNode.requestFocus();
                    if (_duration > Duration.zero) {
                      _player.seek(Duration(
                        milliseconds: (p * _duration.inMilliseconds).round(),
                      ));
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      )));
  }
}

// Mobile-friendly projects list widget for Android
class _MobileProjectsList extends ConsumerStatefulWidget {
  final List<MusicProject> projects;
  final DateFormat dateFormat;
  final Function(List<MusicProject>) onCreateRelease;
  final Function(List<String>) onHideProjects;
  final Function(List<String>) onUnhideProjects;
  final bool showHidden;

  const _MobileProjectsList({
    required this.projects,
    required this.dateFormat,
    required this.onCreateRelease,
    required this.onHideProjects,
    required this.onUnhideProjects,
    required this.showHidden,
  });

  @override
  ConsumerState<_MobileProjectsList> createState() => _MobileProjectsListState();
}

enum _MobileSortField { lastModified, name, phase, createdAt, bpm }

class _MobileProjectsListState extends ConsumerState<_MobileProjectsList> {
  final Set<String> _selectedProjectIds = {};
  bool _isSelectionMode = false;
  _MobileSortField _sortField = _MobileSortField.lastModified;

  List<MusicProject> _sorted(List<MusicProject> projects) {
    // DEBUG: log date fields for all projects
    for (final p in projects) {
      debugPrint(
        '[DEBUG DATE] "${p.displayName}" | '
        'lastModifiedAt=${p.lastModifiedAt.toIso8601String()} | '
        'fileCreatedAt=${p.fileCreatedAt?.toIso8601String() ?? "null"} | '
        'createdAt=${p.createdAt.toIso8601String()} | '
        'same=${p.fileCreatedAt == p.lastModifiedAt}',
      );
    }
    final list = List<MusicProject>.from(projects);
    switch (_sortField) {
      case _MobileSortField.lastModified:
        list.sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));
      case _MobileSortField.name:
        list.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
      case _MobileSortField.phase:
        list.sort((a, b) => a.status.compareTo(b.status));
      case _MobileSortField.createdAt:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _MobileSortField.bpm:
        list.sort((a, b) => (b.bpm ?? 0).compareTo(a.bpm ?? 0));
    }
    return list;
  }

  void _toggleProjectSelection(String projectId) {
    setState(() {
      if (_selectedProjectIds.contains(projectId)) {
        _selectedProjectIds.remove(projectId);
        // Exit selection mode if no items are selected
        if (_selectedProjectIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedProjectIds.add(projectId);
        // Enter selection mode when first item is selected
        if (!_isSelectionMode) {
          _isSelectionMode = true;
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedProjectIds.clear();
      _isSelectionMode = false;
    });
  }

  void _enterSelectionMode(String projectId) {
    setState(() {
      _isSelectionMode = true;
      _selectedProjectIds.add(projectId);
    });
  }

  Future<void> _playPreviewSong(MusicProject project) async {
    final customFolder = ref.read(customMixdownFolderProvider).value;
    var effectivePath = project.previewSongPath?.isNotEmpty == true
        ? project.previewSongPath!
        : (project.previewSongAutoPath ?? MixdownDetectorService.findLatestMixdown(project, customFolder: customFolder)?.path);

    if (effectivePath == null) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.audio_file_outlined, size: 20),
              const SizedBox(width: 8),
              Text(l10n.noPreviewSongTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.noPreviewSongMessage),
              if (!MobileUtils.isMobile()) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.drag_indicator, size: 16,
                        color: Theme.of(ctx).colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.noPreviewSongDragHint,
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.selectPreviewSong),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
        dialogTitle: l10n.selectPreviewSong,
      );
      if (!mounted || picked == null || picked.files.single.path == null) return;
      final newPath = picked.files.single.path!;
      final repo = await ref.read(repositoryProvider.future);
      await repo.updateProject(project.copyWith(
        previewSongPath: newPath,
        previewSongFileName: path.basename(newPath),
      ));
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (dialogContext) => _PreviewSongDialog(
          project: project.copyWith(
            previewSongPath: newPath,
            previewSongFileName: path.basename(newPath),
          ),
          onClose: () {},
        ),
      );
      return;
    }

    final file = File(effectivePath);
    if (!await file.exists()) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final action = await showDialog<_FileNotFoundAction>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.previewSongFileNotFound),
          content: Text(l10n.previewSongFileNotFoundMessage),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, _FileNotFoundAction.remove),
              child: Text(l10n.removePreviewSong),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, _FileNotFoundAction.selectNew),
              child: Text(l10n.selectNewFile),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (action == _FileNotFoundAction.remove) {
        final repo = await ref.read(repositoryProvider.future);
        final isAuto = project.previewSongPath?.isNotEmpty != true;
        final updated = isAuto
            ? project.copyWith(clearPreviewSongAutoPath: true)
            : project.copyWith(clearPreviewSongPath: true, clearPreviewSongFileName: true);
        await repo.updateProject(updated);
        return;
      } else if (action == _FileNotFoundAction.selectNew) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
          dialogTitle: l10n.selectPreviewSong,
        );
        if (!mounted) return;
        if (result != null && result.files.single.path != null) {
          final newPath = result.files.single.path!;
          final repo = await ref.read(repositoryProvider.future);
          final isAuto = project.previewSongPath?.isNotEmpty != true;
          final updated = isAuto
              ? project.copyWith(previewSongAutoPath: newPath)
              : project.copyWith(previewSongPath: newPath, previewSongFileName: path.basename(newPath));
          await repo.updateProject(updated);
          effectivePath = newPath;
        } else {
          return;
        }
      } else {
        return;
      }
    }

    // Check for a newer audio file in the same folder as the current preview,
    // regardless of whether the path was manually set or auto-detected.
    final newer = MixdownDetectorService.findNewerFileInSameFolder(effectivePath);
    if (newer != null && mounted) {
      final l10n = AppLocalizations.of(context)!;
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.newerExportFound),
          content: Text(l10n.newerExportFoundMessage(path.basename(newer.path))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.keepCurrent)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.replaceAndPlay)),
          ],
        ),
      );
      if (!mounted) return;
      if (replace == null) return;
      if (replace) {
        final repo = await ref.read(repositoryProvider.future);
        final isManual = project.previewSongPath?.isNotEmpty == true;
        final updated = isManual
            ? project.copyWith(
                previewSongPath: newer.path,
                previewSongFileName: path.basename(newer.path),
              )
            : project.copyWith(previewSongAutoPath: newer.path);
        await repo.updateProject(updated);
        effectivePath = newer.path;
      }
    }

    if (!mounted) return;
    final playProject = project.copyWith(
      previewSongPath: effectivePath,
      previewSongFileName: path.basename(effectivePath),
    );

    if (MobileUtils.isMobile()) {
      await showDialog(
        context: context,
        builder: (dialogContext) => _PreviewSongDialog(
          project: playProject,
          onClose: () {},
        ),
      );
    } else {
      ref.read(desktopPlayerProvider.notifier).play(playProject, effectivePath);
    }
  }

  String _getStatusDisplayName(String status, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'Idea':
        return l10n.projectPhaseIdea;
      case 'Arranging':
        return l10n.projectPhaseArranging;
      case 'Mixing':
        return l10n.projectPhaseMixing;
      case 'Mastering':
        return l10n.projectPhaseMastering;
      case 'Finished':
        return l10n.projectPhaseFinished;
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Idea':
        return Colors.blue.shade300;
      case 'Arranging':
        return Colors.orange.shade300;
      case 'Mixing':
        return Colors.purple.shade300;
      case 'Mastering':
        return Colors.pink.shade300;
      case 'Finished':
        return Colors.green.shade300;
      default:
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (widget.projects.isEmpty) {
      final allProjectsAsync = ref.watch(allProjectsStreamProvider);
      final totalProjects = allProjectsAsync.value?.length ?? 0;
      final hasProjectsButFiltered = totalProjects > 0;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: hasProjectsButFiltered
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noResultsForFilter,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noResultsForFilterHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_sync,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.firstTimeSyncTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.firstTimeSyncMessage,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const GoogleDriveSyncPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.cloud_upload),
                      label: Text(l10n.syncWithGoogleDrive),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    final sortedProjects = _sorted(widget.projects);

    return Column(
      children: [
        // Sort bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.sort, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              DropdownButton<_MobileSortField>(
                value: _sortField,
                underline: const SizedBox.shrink(),
                isDense: true,
                style: Theme.of(context).textTheme.bodySmall,
                items: [
                  DropdownMenuItem(value: _MobileSortField.lastModified, child: Text(l10n.sortByLastModified)),
                  DropdownMenuItem(value: _MobileSortField.name, child: Text(l10n.sortByName)),
                  DropdownMenuItem(value: _MobileSortField.phase, child: Text(l10n.sortByPhase)),
                  DropdownMenuItem(value: _MobileSortField.createdAt, child: Text(l10n.sortByCreatedAt)),
                  DropdownMenuItem(value: _MobileSortField.bpm, child: Text(l10n.sortByBpm)),
                ],
                onChanged: (v) { if (v != null) setState(() => _sortField = v); },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sortedProjects.length,
            itemBuilder: (context, index) {
              final project = sortedProjects[index];
              final isSelected = _selectedProjectIds.contains(project.id);
              final searchQuery = ref.read(projectsSearchProvider);
              final isNotesMatch = searchQuery.trim().isNotEmpty &&
                  !fuzzyMatchAll(project.displayName, searchQuery) &&
                  project.notes != null &&
                  fuzzyMatchAll(project.notes!, searchQuery);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: _isSelectionMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleProjectSelection(project.id),
                        )
                      : null,
                  title: Row(
                    children: [
                      Expanded(child: Text(
                        project.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )),
                      if (isNotesMatch)
                        Tooltip(
                          message: AppLocalizations.of(context)!.matchedInDescription,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.notes, size: 14, color: Colors.amber.shade600),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // Phase and DAW on the same line
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${l10n.phase}: ${_getStatusDisplayName(project.status, context)}',
                              style: TextStyle(
                                color: _getStatusColor(project.status),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (project.dawType != null) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(AppLocalizations.of(context)!.dawInfoLabel('${project.dawType}${project.dawVersion != null ? ' ${project.dawVersion}' : ''}')),
                            ),
                          ],
                        ],
                      ),
                      // BPM and Key on the same line
                      if (project.bpm != null || project.musicalKey != null)
                        Row(
                          children: [
                            if (project.bpm != null)
                              Expanded(
                                child: Text(AppLocalizations.of(context)!.bpmInfoLabel('${project.bpm}')),
                              ),
                            if (project.bpm != null && project.musicalKey != null)
                              const SizedBox(width: 16),
                            if (project.musicalKey != null)
                              Expanded(
                                child: Text(AppLocalizations.of(context)!.keyInfoLabel(project.musicalKey!)),
                              ),
                          ],
                        ),
                      // Deadline display on mobile
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Modified: ${widget.dateFormat.format(project.lastModifiedAt)}',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          if (project.deadline != null && project.status != 'Finished')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: project.daysUntilDeadline! < 0
                                    ? Colors.red.withOpacity(0.1)
                                    : project.daysUntilDeadline! == 0
                                        ? Colors.red.withOpacity(0.1)
                                        : project.daysUntilDeadline! <= 7
                                            ? Colors.orange.withOpacity(0.1)
                                            : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: project.daysUntilDeadline! < 0
                                      ? Colors.red.withOpacity(0.3)
                                      : project.daysUntilDeadline! == 0
                                          ? Colors.red.withOpacity(0.3)
                                          : project.daysUntilDeadline! <= 7
                                              ? Colors.orange.withOpacity(0.3)
                                              : Colors.blue.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    project.daysUntilDeadline! < 0
                                        ? Icons.warning
                                        : project.daysUntilDeadline! == 0
                                            ? Icons.today
                                            : Icons.schedule,
                                    size: 12,
                                    color: project.daysUntilDeadline! < 0
                                        ? Colors.red
                                        : project.daysUntilDeadline! == 0
                                            ? Colors.red
                                            : project.daysUntilDeadline! <= 7
                                                ? Colors.orange
                                                : Colors.blue,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    project.daysUntilDeadline! < 0
                                        ? AppLocalizations.of(context)!.daysLate(project.daysUntilDeadline!.abs())
                                        : project.daysUntilDeadline! == 0
                                            ? AppLocalizations.of(context)!.today
                                            : AppLocalizations.of(context)!.daysLeft(project.daysUntilDeadline!),
                                    style: TextStyle(
                                      color: project.daysUntilDeadline! < 0
                                          ? Colors.red
                                          : project.daysUntilDeadline! == 0
                                              ? Colors.red
                                              : project.daysUntilDeadline! <= 7
                                                  ? Colors.orange
                                                  : Colors.blue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: _isSelectionMode
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.play_arrow),
                          tooltip: project.previewSongAutoPath != null && project.previewSongPath?.isNotEmpty != true
                              ? '${AppLocalizations.of(context)!.playPreview}\n⚡ ${AppLocalizations.of(context)!.autoDetected}: ${path.basename(project.previewSongAutoPath!)}'
                              : AppLocalizations.of(context)!.playPreview,
                          onPressed: () => _playPreviewSong(project),
                          color: project.previewSongPath?.isNotEmpty == true
                              ? Colors.green
                              : project.previewSongAutoPath != null
                                  ? Colors.amber
                                  : Colors.grey,
                        ),
                  onTap: () {
                    if (_isSelectionMode) {
                      // In selection mode, tap toggles selection
                      _toggleProjectSelection(project.id);
                    } else {
                      // Normal mode, navigate to project detail
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailPage(projectId: project.id),
                        ),
                      );
                    }
                  },
                  onLongPress: () {
                    // Long press enters selection mode and selects the item
                    if (!_isSelectionMode) {
                      _enterSelectionMode(project.id);
                    } else {
                      _toggleProjectSelection(project.id);
                    }
                  },
                ),
              );
            },
          ),
        ),
        // Selection action bar
        if (_selectedProjectIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(l10n.projectsSelected(_selectedProjectIds.length, _selectedProjectIds.length == 1 ? '' : 's')),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.album),
                    label: Text(l10n.createRelease),
                    onPressed: () {
                      final selectedProjects = widget.projects
                          .where((p) => _selectedProjectIds.contains(p.id))
                          .toList();
                      widget.onCreateRelease(selectedProjects);
                      _clearSelection();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Check if selected projects are hidden or visible
                Builder(
                  key: ValueKey('${_selectedProjectIds.length}_${widget.projects.where((p) => _selectedProjectIds.contains(p.id)).map((p) => '${p.id}_${p.hidden}').join(',')}'),
                  builder: (context) {
                    // Check the state of selected projects
                    final selectedProjects = widget.projects.where((p) => _selectedProjectIds.contains(p.id)).toList();
                    final allHidden = selectedProjects.isNotEmpty && selectedProjects.every((p) => p.hidden);
                    final allVisible = selectedProjects.isNotEmpty && selectedProjects.every((p) => !p.hidden);
                    
                    // Show Unhide button if all selected are hidden, Hide button if all are visible
                    // If mixed, show both
                    if (allHidden) {
                      return IconButton(
                        icon: const Icon(Icons.visibility),
                        tooltip: l10n.unhide,
                        onPressed: () {
                          widget.onUnhideProjects(_selectedProjectIds.toList());
                          _clearSelection();
                        },
                      );
                    } else if (allVisible) {
                      return IconButton(
                        icon: const Icon(Icons.visibility_off),
                        tooltip: l10n.hide,
                        onPressed: () {
                          widget.onHideProjects(_selectedProjectIds.toList());
                          _clearSelection();
                        },
                      );
                    } else {
                      // Mixed selection - show both buttons
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: l10n.unhide,
                            onPressed: () {
                              widget.onUnhideProjects(_selectedProjectIds.toList());
                              _clearSelection();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.visibility_off),
                            tooltip: l10n.hide,
                            onPressed: () {
                              widget.onHideProjects(_selectedProjectIds.toList());
                              _clearSelection();
                            },
                          ),
                        ],
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.clearSelection,
                  onPressed: _clearSelection,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Column menu delegate that extends the default TrinaGrid header context menu with
/// an "Auto fit all columns" option that calls autoFitColumn on every column at once.
class _FitAllColumnsMenuDelegate
    implements TrinaColumnMenuDelegate<dynamic> {
  static const String _menuFitAll = 'fitAll';

  @override
  List<PopupMenuEntry<dynamic>> buildMenuItems({
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
  }) {
    final defaults =
        const TrinaColumnMenuDelegateDefault().buildMenuItems(
      stateManager: stateManager,
      column: column,
    );
    return [
      ...defaults,
      const PopupMenuDivider(),
      const PopupMenuItem<String>(
        value: _menuFitAll,
        child: Row(
          children: [
            Icon(Icons.fit_screen, size: 16),
            SizedBox(width: 8),
            Text('Auto fit all columns'),
          ],
        ),
      ),
    ];
  }

  @override
  void onSelected({
    required BuildContext context,
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
    required bool mounted,
    required dynamic selected,
  }) {
    if (selected == _menuFitAll) {
      if (!mounted) return;
      for (final col in stateManager.columns) {
        stateManager.autoFitColumn(context, col);
      }
      stateManager.notifyResizingListeners();
      return;
    }
    const TrinaColumnMenuDelegateDefault().onSelected(
      context: context,
      stateManager: stateManager,
      column: column,
      mounted: mounted,
      selected: selected,
    );
  }
}

/// Shows a confirmation dialog before ending the active session.
/// Displays the project name and elapsed session time so the user can review
/// before committing.
Future<void> _confirmEndSession(BuildContext context, WidgetRef ref) async {
  final project = ref.read(activeProjectProvider);
  if (project == null) return;

  final elapsed = ref.read(workTimerProvider);
  final l10n = AppLocalizations.of(context)!;

  String fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '< 1m';
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.endSession),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.displayName,
            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (elapsed > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 16,
                    color: Theme.of(ctx).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  '${l10n.sessionDuration}: ${fmt(elapsed)}',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          child: Text(l10n.endSession),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    ref.read(activeProjectProvider.notifier).clear();
  }
}

/// Shows a confirmation dialog before starting a session on a project.
/// If another session is already active, offers to switch instead.
Future<void> _confirmStartSession(
    BuildContext context, WidgetRef ref, MusicProject project) async {
  final l10n = AppLocalizations.of(context)!;
  final current = ref.read(activeProjectProvider);

  if (current != null) {
    // ── Switch dialog ──────────────────────────────────────────────────────
    final elapsed = ref.read(workTimerProvider);

    String fmt(int s) {
      final h = s ~/ 3600;
      final m = (s % 3600) ~/ 60;
      if (h > 0) return '${h}h ${m}m';
      if (m > 0) return '${m}m';
      return '< 1m';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: Text(l10n.switchSession),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.switchSessionBody,
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 14),
              // Current project row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bookmark, size: 14, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.switchSessionCurrent(current.displayName),
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (elapsed > 0)
                      Text(
                        fmt(elapsed),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Center(child: Icon(Icons.arrow_downward, size: 16)),
              ),
              // New project row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bookmark_add_outlined,
                        size: 14, color: Colors.green.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.switchSessionNew(project.displayName),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.switchSession),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      ref.read(activeProjectProvider.notifier).set(project);
    }
    return;
  }

  // ── Simple start dialog ────────────────────────────────────────────────
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.startSession),
      content: Text(
        project.displayName,
        style: Theme.of(ctx)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.startSession),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    ref.read(activeProjectProvider.notifier).set(project);
  }
}

/// Compact chip displayed in the toolbar when a project session is active.
/// Shows a pulsing dot, project name, session timer, and quick-action buttons.
class _ActiveProjectChip extends ConsumerStatefulWidget {
  const _ActiveProjectChip();

  @override
  ConsumerState<_ActiveProjectChip> createState() => _ActiveProjectChipState();
}

class _ActiveProjectChipState extends ConsumerState<_ActiveProjectChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  static const _dot = Padding(
    padding: EdgeInsets.symmetric(horizontal: 4),
    child: Text('·', style: TextStyle(color: Color(0x4DFFFFFF), fontSize: 11)),
  );

  String _formatWorkTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final sessionElapsed = ref.watch(workTimerProvider);
    final isPaused = ref.watch(workTimerPausedProvider);

    if (project == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final dawLabel = project.dawType ?? project.fileExtension.replaceFirst('.', '').toUpperCase();
    const green = Color(0xFF22C55E);
    const yellow = Color(0xFFFBBF24);
    final chipColor = isPaused ? yellow : green;

    // Always pulse — color (green vs yellow) does the state communication.
    if (!_pulse.isAnimating) _pulse.repeat(reverse: true);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: chipColor.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pulsing dot — green when active, yellow when paused; always animates.
          AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final v = _anim.value;
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.35 + 0.65 * v),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: chipColor.withValues(alpha: 0.7 * v),
                      blurRadius: 5 + 5 * v,
                      spreadRadius: 0.5 + 2 * v,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          // Two-line content block
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Line 1 — project name (tooltip shows full name when truncated)
              Tooltip(
                message: project.displayName,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Text(
                    project.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Line 2 — DAW version, BPM, key, Camelot, total work, session timer
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // DAW name + version
                  Text(
                    project.dawVersion != null
                        ? '$dawLabel ${project.dawVersion}'
                        : dawLabel,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                  ),
                  // BPM
                  if (project.bpm != null) ...[
                    _dot,
                    Icon(Icons.speed, size: 11, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 2),
                    Text(
                      '${project.bpm! % 1 == 0 ? project.bpm!.toInt() : project.bpm!.toStringAsFixed(1)} BPM',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                    ),
                  ],
                  // Musical key
                  if (project.musicalKey != null && project.musicalKey!.isNotEmpty) ...[
                    _dot,
                    Icon(Icons.music_note, size: 11, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 2),
                    Text(
                      project.musicalKey!,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                    ),
                  ],
                  // Camelot code badge
                  if (project.camelotCode != null) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        project.camelotCode!,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  // Total accumulated work time
                  if (project.totalWorkSeconds > 0) ...[
                    _dot,
                    Icon(Icons.history, size: 11, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 2),
                    SizedBox(
                      width: 56,
                      child: Text(
                        _formatWorkTime(project.totalWorkSeconds),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  // Session elapsed timer
                  const SizedBox(width: 6),
                  Icon(Icons.timer_outlined, size: 11, color: chipColor.withValues(alpha: 0.85)),
                  const SizedBox(width: 2),
                  SizedBox(
                    width: 52,
                    child: Text(
                      _formatWorkTime(sessionElapsed),
                      style: TextStyle(
                        color: chipColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Action buttons — icon-only with tooltips
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: l10n.launch,
                child: IconButton(
                  icon: const Icon(Icons.launch),
                  iconSize: 20,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  color: Colors.white70,
                  onPressed: () async {
                    final exists = File(project.filePath).existsSync() ||
                        Directory(project.filePath).existsSync();
                    if (!exists) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.fileMissing)),
                        );
                      }
                      return;
                    }
                    await FileLauncher.launchProject(project.filePath);
                  },
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: l10n.projectDetails,
                child: IconButton(
                  icon: const Icon(Icons.assignment),
                  iconSize: 20,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  color: Colors.white70,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _PauseSessionButton(
                isPaused: isPaused,
                onPressed: () {
                  if (isPaused) {
                    ref.read(workTimerProvider.notifier).resume();
                  } else {
                    ref.read(workTimerProvider.notifier).pause();
                  }
                },
              ),
              const SizedBox(width: 4),
              _StopSessionButton(
                onPressed: () => _confirmEndSession(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paints the ├── / └── tree connector for child rows in the folder tree view.
class _TreeConnectorPainter extends CustomPainter {
  final bool isLast;
  final Color color;

  const _TreeConnectorPainter({required this.isLast, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const x = 8.0; // horizontal position of the vertical trunk line
    final midY = size.height / 2;

    // Vertical segment: top → midY for last child (└), top → bottom for others (├)
    canvas.drawLine(Offset(x, 0), Offset(x, isLast ? midY : size.height), paint);

    // Horizontal branch: trunk → right edge at mid-height
    canvas.drawLine(Offset(x, midY), Offset(size.width, midY), paint);
  }

  @override
  bool shouldRepaint(_TreeConnectorPainter old) =>
      old.isLast != isLast || old.color != color;
}

class _PauseSessionButton extends StatefulWidget {
  final bool isPaused;
  final VoidCallback onPressed;
  const _PauseSessionButton({required this.isPaused, required this.onPressed});

  @override
  State<_PauseSessionButton> createState() => _PauseSessionButtonState();
}

class _PauseSessionButtonState extends State<_PauseSessionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const yellow = Color(0xFFFBBF24);
    const green = Color(0xFF22C55E);

    final baseColor = widget.isPaused ? yellow : Colors.white54;
    final hoverColor = widget.isPaused ? green : yellow;
    final color = _hovered ? hoverColor : baseColor;
    final glowColor = _hovered ? hoverColor : yellow;
    final icon = widget.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded;

    return Tooltip(
      message: widget.isPaused ? l10n.resume : l10n.pause,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
              color: color.withValues(alpha: _hovered ? 0.10 : (widget.isPaused ? 0.08 : 0.0)),
              boxShadow: (_hovered || widget.isPaused)
                  ? [BoxShadow(color: glowColor.withValues(alpha: _hovered ? 0.35 : 0.2), blurRadius: _hovered ? 8 : 5)]
                  : const [],
            ),
            child: Center(child: Icon(icon, size: 16, color: color)),
          ),
        ),
      ),
    );
  }
}

class _StopSessionButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _StopSessionButton({required this.onPressed});

  @override
  State<_StopSessionButton> createState() => _StopSessionButtonState();
}

class _StopSessionButtonState extends State<_StopSessionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const red = Color(0xFFEF5350);
    final color = _hovered ? red : Colors.white54;

    return Tooltip(
      message: l10n.stop,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
              color: color.withValues(alpha: _hovered ? 0.10 : 0.0),
              boxShadow: _hovered
                  ? [BoxShadow(color: red.withValues(alpha: 0.35), blurRadius: 8)]
                  : const [],
            ),
            child: Center(child: Icon(Icons.stop_rounded, size: 16, color: color)),
          ),
        ),
      ),
    );
  }
}

// Subscribes to stateManager to react to row group expand/collapse changes.
class _ExpandArrowCell extends StatefulWidget {
  final TrinaRow row;
  final TrinaGridStateManager stateManager;
  const _ExpandArrowCell({required this.row, required this.stateManager});

  @override
  State<_ExpandArrowCell> createState() => _ExpandArrowCellState();
}

class _ExpandArrowCellState extends State<_ExpandArrowCell> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.row.type.isGroup && widget.row.type.group.expanded;
    widget.stateManager.addListener(_sync);
  }

  void _sync() {
    if (!mounted) return;
    final now = widget.row.type.isGroup && widget.row.type.group.expanded;
    if (now != _expanded) setState(() => _expanded = now);
  }

  @override
  void dispose() {
    widget.stateManager.removeListener(_sync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          widget.stateManager.toggleExpandedRowGroup(rowGroup: widget.row),
      child: Center(
        child: Icon(
          _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _FolderNameCell extends StatefulWidget {
  final TrinaRow row;
  final TrinaGridStateManager stateManager;
  final String folderName;
  const _FolderNameCell({
    required this.row,
    required this.stateManager,
    required this.folderName,
  });

  @override
  State<_FolderNameCell> createState() => _FolderNameCellState();
}

class _FolderNameCellState extends State<_FolderNameCell> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.row.type.isGroup && widget.row.type.group.expanded;
    widget.stateManager.addListener(_sync);
  }

  void _sync() {
    if (!mounted) return;
    final now = widget.row.type.isGroup && widget.row.type.group.expanded;
    if (now != _expanded) setState(() => _expanded = now);
  }

  @override
  void dispose() {
    widget.stateManager.removeListener(_sync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          widget.stateManager.toggleExpandedRowGroup(rowGroup: widget.row),
      child: Row(
        children: [
          Icon(
            _expanded ? Icons.folder_open : Icons.folder,
            size: 15,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.folderName,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
