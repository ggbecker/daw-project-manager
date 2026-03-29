import 'dart:async';
import 'dart:io';

import 'package:trina_grid/trina_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/services.dart'; 
import 'package:path/path.dart' as path; // 🚨 NOVO IMPORT
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

import '../services/scanner_service.dart';
import '../services/audio_analysis_service.dart';
import '../utils/mobile_utils.dart';
import '../utils/file_launcher.dart';
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

import '../models/music_project.dart';
import '../models/release.dart';
import '../providers/providers.dart';
import 'package:uuid/uuid.dart';

/// App version embedded at build-time (CI passes `--dart-define=APP_VERSION=x.y.z`).
/// For PR/local builds, we fall back to a dummy version.
const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.0.0');

// Intent classes for keyboard shortcuts
class _SearchIntent extends Intent {
  const _SearchIntent();
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

class _DashboardPageState extends ConsumerState<DashboardPage> with SingleTickerProviderStateMixin {
  bool _scanning = false;
  bool _extractingMetadata = false;
  bool _isSearchingMobile = false;
  bool _isSearchingDesktop = false;
  late TabController _tabController;
  
  // 1. FocusNode para a barra de pesquisa
  final FocusNode _searchFocusNode = FocusNode();
  
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
    // Mobile has 5 tabs (Projects, Releases, Playlists, Tasks, Statistics), desktop has 4
    final tabCount = MobileUtils.isMobile() ? 5 : 4;
    _tabController = TabController(length: tabCount, vsync: this);
    _searchController = TextEditingController();
    
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

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      // Sync search controller with the appropriate tab's search state
      final currentTabIndex = _tabController.index;
      final queueTabIndex = MobileUtils.isMobile() ? 3 : 2;
      final statsTabIndex = MobileUtils.isMobile() ? 4 : 3;
      if (currentTabIndex == 0) {
        // Projects tab
        final projectsSearch = ref.read(projectsSearchProvider);
        if (_searchController.text != projectsSearch) {
          _searchController.text = projectsSearch;
        }
      } else if (currentTabIndex == 1) {
        // Releases tab
        final releasesSearch = ref.read(releasesSearchProvider);
        if (_searchController.text != releasesSearch) {
          _searchController.text = releasesSearch;
        }
      } else if (currentTabIndex == queueTabIndex) {
        // Tasks tab
        final queueSearch = ref.read(queueSearchProvider);
        if (_searchController.text != queueSearch) {
          _searchController.text = queueSearch;
        }
      } else if (currentTabIndex == statsTabIndex) {
        // Statistics tab
        final statsSearch = ref.read(statisticsSearchProvider);
        if (_searchController.text != statsSearch) {
          _searchController.text = statsSearch;
        }
      } else {
        // Playlists tab — clear search bar
        _searchController.clear();
      }
      if (MobileUtils.isMobile() && _isSearchingMobile) {
        _isSearchingMobile = false;
      }
      setState(() {}); // Rebuild to update search placeholder when tab animation completes
    }
  }

  void _clearCurrentTabSearch() {
    _searchController.clear();
    final queueTabIndex = MobileUtils.isMobile() ? 3 : 2;
    if (_tabController.index == 0) {
      ref.read(projectsSearchProvider.notifier).clear();
    } else if (_tabController.index == 1) {
      ref.read(releasesSearchProvider.notifier).clear();
    } else if (_tabController.index == queueTabIndex) {
      ref.read(queueSearchProvider.notifier).clear();
    } else {
      ref.read(statisticsSearchProvider.notifier).set('');
    }
  }

  void _updateCurrentTabSearch(String text) {
    final queueTabIndex = MobileUtils.isMobile() ? 3 : 2;
    if (_tabController.index == 0) {
      ref.read(projectsSearchProvider.notifier).setSearchText(text);
    } else if (_tabController.index == 1) {
      ref.read(releasesSearchProvider.notifier).setSearchText(text);
    } else if (_tabController.index == queueTabIndex) {
      ref.read(queueSearchProvider.notifier).set(text);
    } else {
      ref.read(statisticsSearchProvider.notifier).set(text);
    }
  }

  @override
  void dispose() {
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
  }


  void _collapseDesktopSearch() {
    _clearCurrentTabSearch();
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
        await for (final entity in scanner.scanDirectory(root.path, ignoredPaths: ignoredPaths)) {
          await repo.upsertFromFileSystemEntity(entity, fullMetadata: fullMetadata);
          foundCount++;
        }
        // Update lastScanAt timestamp for this root
        await repo.updateRootLastScanAt(root.id, scanTime);
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
    // Get current search text based on active tab
    final queueTabIndex = MobileUtils.isMobile() ? 3 : 2;
    final statsTabIndex = MobileUtils.isMobile() ? 4 : 3;
    final currentSearch = _tabController.index == 0
        ? ref.watch(projectsSearchProvider)
        : _tabController.index == 1
            ? ref.watch(releasesSearchProvider)
            : _tabController.index == queueTabIndex
                ? ref.watch(queueSearchProvider)
                : _tabController.index == statsTabIndex
                    ? ref.watch(statisticsSearchProvider)
                    : '';
    final projects = ref.watch(projectsProvider);
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
            // Keep Shortcuts as backup (though RawKeyboardListener handles it directly)
            LogicalKeySet(
              Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
              LogicalKeyboardKey.keyF,
            ): const _SearchIntent(),
            LogicalKeySet(
              Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
              LogicalKeyboardKey.keyR,
            ): const _RescanIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _SearchIntent: _SearchAction(() {
                _focusSearchAndSelectAll();
              }),
              _RescanIntent: _RescanAction(() {
                _scanAll();
              }),
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
                                  hintText: _tabController.index == 0
                                      ? AppLocalizations.of(context)!.searchProjects
                                      : _tabController.index == 1
                                          ? AppLocalizations.of(context)!.searchReleases
                                          : _tabController.index == 3
                                              ? AppLocalizations.of(context)!.queueSearchHint
                                              : AppLocalizations.of(context)!.statsSearchProjects,
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
                                // Search icon (only on searchable tabs — not Playlists tab index 2)
                                if (_tabController.index != 2)  // 2 = Playlists on mobile
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
                                // Profile button
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
                          NavigationDestination(
                            icon: const Icon(Icons.library_music_outlined),
                            selectedIcon: const Icon(Icons.library_music),
                            label: AppLocalizations.of(context)!.projects,
                          ),
                          NavigationDestination(
                            icon: const Icon(Icons.album_outlined),
                            selectedIcon: const Icon(Icons.album),
                            label: AppLocalizations.of(context)!.releasesTab,
                          ),
                          NavigationDestination(
                            icon: const Icon(Icons.playlist_play),
                            selectedIcon: const Icon(Icons.playlist_play),
                            label: AppLocalizations.of(context)!.playlists,
                          ),
                          NavigationDestination(
                            icon: const Icon(Icons.checklist_outlined),
                            selectedIcon: const Icon(Icons.checklist),
                            label: AppLocalizations.of(context)!.queueTab,
                          ),
                          NavigationDestination(
                            icon: const Icon(Icons.bar_chart_outlined),
                            selectedIcon: const Icon(Icons.bar_chart_rounded),
                            label: AppLocalizations.of(context)!.statisticsTab,
                          ),
                        ],
                      )
                    : null,
                body: Column(
          children: [
            // Custom title bar – Windows/Linux only.
            // macOS uses the native title bar + MacOSMenuBar for Theme/Language/Support.
            DesktopTitleBar(
              title: 'DAW Project Manager v$appVersion',
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
                            if (_tabController.index != 2) TextField(
                              focusNode: _searchFocusNode,
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: _tabController.index == 0
                                    ? AppLocalizations.of(context)!.searchProjects
                                    : _tabController.index == 1
                                        ? AppLocalizations.of(context)!.searchReleases
                                        : AppLocalizations.of(context)!.statsSearchProjects,
                                isDense: true,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: () {
                                  final cs = _tabController.index == 0
                                      ? ref.read(projectsSearchProvider)
                                      : _tabController.index == 1
                                          ? ref.read(releasesSearchProvider)
                                          : ref.read(statisticsSearchProvider);
                                  return cs.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            _searchController.clear();
                                            if (_tabController.index == 0) {
                                              ref.read(projectsSearchProvider.notifier).clear();
                                            } else if (_tabController.index == 1) {
                                              ref.read(releasesSearchProvider.notifier).clear();
                                            } else {
                                              ref.read(statisticsSearchProvider.notifier).set('');
                                            }
                                          },
                                        )
                                      : null;
                                }(),
                              ),
                              onChanged: (text) {
                                if (_tabController.index == 0) {
                                  ref.read(projectsSearchProvider.notifier).setSearchText(text);
                                } else if (_tabController.index == 1) {
                                  ref.read(releasesSearchProvider.notifier).setSearchText(text);
                                } else {
                                  ref.read(statisticsSearchProvider.notifier).set(text);
                                }
                              },
                            ),
                            if (_tabController.index != 2)
                              const SizedBox(height: 12),
                            // Filters and info row (only show on Projects tab)
                            if (_tabController.index == 0) ...[
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
                        // Profile button - always visible
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
                        const SizedBox(width: 8),
                        if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) ...[
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
                            icon: const Icon(Icons.tune),
                            label: Text(AppLocalizations.of(context)!.roots),
                          ),
                          const SizedBox(width: 12),
                        ],
                        ElevatedButton.icon(
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
                    ),
                  const SizedBox(width: 16),
                  // Search bar (desktop only — hidden on Playlists tab)
                  if (!MobileUtils.isMobile() && (_tabController.index != 2 || !MobileUtils.isMobile()))
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ClipRect(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            width: _isSearchingDesktop ? 400 : 0,
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
                                hintText: _tabController.index == 0
                                    ? AppLocalizations.of(context)!.searchProjects
                                    : _tabController.index == 1
                                        ? AppLocalizations.of(context)!.searchReleases
                                        : _tabController.index == 2  // Queue on desktop
                                            ? AppLocalizations.of(context)!.queueSearchHint
                                            : AppLocalizations.of(context)!.statsSearchProjects,
                                isDense: true,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: _collapseDesktopSearch,
                                ),
                              ),
                              onChanged: (text) {
                                if (_tabController.index == 0) {
                                  ref.read(projectsSearchProvider.notifier).setSearchText(text);
                                } else if (_tabController.index == 1) {
                                  ref.read(releasesSearchProvider.notifier).setSearchText(text);
                                } else if (_tabController.index == 2) {  // Queue on desktop
                                  ref.read(queueSearchProvider.notifier).set(text);
                                } else {
                                  ref.read(statisticsSearchProvider.notifier).set(text);
                                }
                              },
                            ),
                          ),
                        ),
                        ),
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
            if (!MobileUtils.isMobile())
              Builder(
                builder: (context) => TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(icon: Icon(Icons.library_music), text: AppLocalizations.of(context)!.projectsTab),
                    Tab(icon: Icon(Icons.album), text: AppLocalizations.of(context)!.releasesTab),
                    if (MobileUtils.isMobile())
                      Tab(icon: Icon(Icons.playlist_play), text: AppLocalizations.of(context)!.playlists),
                    Tab(icon: Icon(Icons.checklist), text: AppLocalizations.of(context)!.queueTab),
                    Tab(icon: Icon(Icons.bar_chart_rounded), text: AppLocalizations.of(context)!.statisticsTab),
                  ],
                  labelColor: Theme.of(context).textTheme.titleMedium?.color,
                  unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Use mobile-friendly list view on mobile, table on desktop
                  MobileUtils.isMobile()
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
                  const ReleasesTabPage(),
                  if (MobileUtils.isMobile()) const PlaylistsPage(),
                  const QueuePage(),
                  const StatisticsPage(),
                ],
              ),
            ),
          ],
                ),
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
                // Project count
                Text(
                  () {
                    if (hiddenMode == 2) {
                      return '${l10n.projectsCount(widget.hiddenCount)} ${l10n.hiddenOnly}';
                    } else {
                      var text = l10n.projectsCount(widget.visibleCount);
                      if (widget.hiddenCount > 0 && hiddenMode == 0) {
                        text += ' ${l10n.hiddenCount(widget.hiddenCount)}';
                      }
                      return text;
                    }
                  }(),
                  style: TextStyle(
                    fontSize: 12,
                    color: hiddenMode == 2 ? Colors.orange.shade300 : null,
                  ),
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

class _PlutoProjectsTable extends ConsumerStatefulWidget {
  final List<MusicProject> projects;
  final DateFormat dateFormat;
  final Set<String> selectedIds;
  final Function(String) onToggleSelection;
  final Function(List<String>) onHideProjects;
  final Function(List<String>) onUnhideProjects;
  final bool areAllSelected;
  final VoidCallback onToggleSelectAll;
  const _PlutoProjectsTable({
    required this.projects,
    required this.dateFormat,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onHideProjects,
    required this.onUnhideProjects,
    required this.areAllSelected,
    required this.onToggleSelectAll,
  });

  @override
  ConsumerState<_PlutoProjectsTable> createState() => _PlutoProjectsTableState();
}

class _PlutoProjectsTableState extends ConsumerState<_PlutoProjectsTable> {
  TrinaGridStateManager? stateManager;
  
  Future<void> _playPreviewSong(MusicProject project) async {
    if (project.previewSongPath == null || project.previewSongPath!.isEmpty) {
      return;
    }
    
    final file = File(project.previewSongPath!);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.previewSongFileNotFound)),
        );
      }
      return;
    }
    
    // Show popup dialog with audio player
    if (mounted) {
      await showDialog(
        context: context,
        builder: (dialogContext) => _PreviewSongDialog(
          project: project,
          onClose: () {
            // Callback when dialog closes - can be used for cleanup if needed
          },
        ),
      );
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
    if (dawType == null) return null;
    
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
      
      // On desktop, automatically open project details for context
      // This helps users return to the app with the project context loaded
      // if (mounted && !MobileUtils.isMobile()) {
      //   await _viewProjectDetails(project);
      // }
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
      }
    }
  }

  List<TrinaRow> _mapProjectsToRows(List<MusicProject> projects) {
    return projects.map((p) {
      // Combine DAW type and version into a single string
      final dawDisplay = p.dawType != null
          ? (p.dawVersion != null && p.dawVersion!.isNotEmpty
              ? '${p.dawType} ${p.dawVersion}'
              : p.dawType!)
          : '';
      
      return TrinaRow(
        cells: {
          'checkbox': TrinaCell(value: ''), // Placeholder for checkbox column
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
    }).toList();
  }

  @override
  void didUpdateWidget(_PlutoProjectsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.projects != widget.projects || oldWidget.selectedIds != widget.selectedIds) {
      if (stateManager != null) {
        final newRows = _mapProjectsToRows(widget.projects);
        stateManager!.removeRows(stateManager!.rows, notify: false);
        stateManager!.insertRows(0, newRows);
        // Force rebuild to update checkbox states and color coding
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
              child: Checkbox(
                value: widget.areAllSelected,
                tristate: widget.selectedIds.isNotEmpty && !widget.areAllSelected,
                onChanged: (_) => widget.onToggleSelectAll(),
              ),
            ),
          );
        },
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          if (project == null) return const SizedBox.shrink();
          
          final isSelected = widget.selectedIds.contains(project.id);
          return Checkbox(
            value: isSelected,
            onChanged: (value) {
              widget.onToggleSelection(project.id);
            },
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
            return Text(rendererContext.cell.value.toString());
          }

          final fileExists = File(project.filePath).existsSync() ||
              Directory(project.filePath).existsSync();

          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
            },
            child: Row(
              children: [
                Expanded(child: Text(rendererContext.cell.value.toString())),
                if (!fileExists && !MobileUtils.isMobile())
                  Tooltip(
                    message: AppLocalizations.of(context)!.sourceFileNotFoundOnThisMachine,
                    child: Icon(Icons.cloud_off, size: 14,
                        color: Colors.orange.shade400),
                  ),
              ],
            ),
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

          if (project == null) return textWidget;

          return GestureDetector(
            onTapDown: (TapDownDetails details) {
              _showPhaseMenu(context, project, details.globalPosition, rendererContext);
            },
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
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
          
          if (project == null) return content;
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
            },
            child: content,
          );
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
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
            },
            child: textWidget,
          );
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
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Musical key on the left
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
                // Visual separator and Camelot code on the right
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
            ),
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
          if (project == null) {
            return Text(rendererContext.cell.value.toString());
          }

          final status = project.status;
          
          // If status is "Finished", show green
          Color textColor;
          if (status == 'Finished') {
            textColor = Colors.green;
          } else {
            final now = DateTime.now();
            final lastModified = project.lastModifiedAt;
            
            // Calculate color based on age of lastModifiedAt
            final daysSinceModified = now.difference(lastModified).inDays;
            
            if (daysSinceModified < 21) {
              // Recent (0-21 days): default white
              textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
            } else if (daysSinceModified < 60) {
              // Medium (21-60 days): yellow/orange gradient
              final ratio = (daysSinceModified - 21) / 39.0; // 0 to 1 from 21 to 60 days
              textColor = Color.lerp(
                Colors.yellow.shade300,
                Colors.orange.shade400,
                ratio,
              )!;
            } else {
              // Old (60+ days): orange to red gradient
              final ratio = ((daysSinceModified - 60) / 60.0).clamp(0.0, 1.0); // 0 to 1 from 60 to 120 days
              textColor = Color.lerp(
                Colors.orange.shade400,
                Colors.red.shade400,
                ratio,
              )!;
            }
          }
          
          final textWidget = Text(
            rendererContext.cell.value.toString(),
            style: TextStyle(color: textColor),
          );
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
            },
            child: textWidget,
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

          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
            },
            child: deadlineWidget,
          );
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
          final project = ctx.row.cells['data']!.value as MusicProject;
          
          // Lógica para determinar o diretório pai
          final String projectPath = project.filePath;
          final bool sourceFileExists = File(projectPath).existsSync() || Directory(projectPath).existsSync();
          final String folderPath = FileSystemEntity.isDirectorySync(projectPath)
              ? projectPath // Se for um diretório, usa o próprio caminho
              : path.dirname(projectPath); // Se for um arquivo, usa o diretório pai
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
            },
            child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play Preview Song button (always show, but disabled if no preview)
              IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 24,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: project.previewSongPath != null && project.previewSongPath!.isNotEmpty
                    ? '${AppLocalizations.of(context)!.playPreview} (P)'
                    : AppLocalizations.of(context)!.noPreviewSong,
                onPressed: project.previewSongPath != null && project.previewSongPath!.isNotEmpty
                    ? () => _playPreviewSong(project)
                    : null,
                color: project.previewSongPath != null && project.previewSongPath!.isNotEmpty
                    ? Colors.green
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
              // Launch button
              Tooltip(
                message: sourceFileExists || MobileUtils.isMobile() ? '' : AppLocalizations.of(context)!.sourceFileNotFoundOnThisMachine,
                child: IconButton(
                  icon: const Icon(Icons.open_in_new),
                  iconSize: 24,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  tooltip: sourceFileExists ? '${AppLocalizations.of(context)!.tooltipLaunchInDaw} (O)' : null,
                  onPressed: sourceFileExists ? () => _launchProject(project) : null,
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
              // View button
              IconButton(
                icon: const Icon(Icons.assignment),
                iconSize: 24,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: '${AppLocalizations.of(context)!.tooltipViewDetails} (D)',
                onPressed: () => _viewProjectDetails(project),
              ),
              // Open Folder button
              Tooltip(
                message: sourceFileExists || MobileUtils.isMobile() ? '' : AppLocalizations.of(context)!.sourceFileNotFoundOnThisMachine,
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
          ),
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

    return TrinaGrid(
          key: ValueKey('trina_grid_${l10n.localeName}'), // Force rebuild when locale changes
          columns: columns,
          rows: initialRows,
          onLoaded: (TrinaGridOnLoadedEvent event) {
            stateManager = event.stateManager;
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
          gridBackgroundColor: Theme.of(context).cardColor,
          gridBorderColor: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          gridBorderRadius: BorderRadius.zero,
          rowColor: Theme.of(context).cardColor,
          cellColorInEditState: Theme.of(context).cardColor,
          cellColorInReadOnlyState: Theme.of(context).cardColor,
          columnTextStyle: TextStyle(
            color: Theme.of(context).textTheme.titleMedium?.color,
            fontWeight: FontWeight.w600,
          ),
          cellTextStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          columnHeight: 44,
          rowHeight: 48,
          activatedBorderColor: Theme.of(context).colorScheme.primary,
          activatedColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          iconColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
          menuBackgroundColor: Theme.of(context).cardColor,
          oddRowColor: Theme.of(context).cardColor,
          evenRowColor: Theme.of(context).brightness == Brightness.dark
              ? Color.alphaBlend(Colors.white.withValues(alpha: 0.05), Theme.of(context).cardColor)
              : Color.alphaBlend(Colors.black.withValues(alpha: 0.04), Theme.of(context).cardColor),
        ),
        columnSize: const TrinaGridColumnSizeConfig(
          autoSizeMode: TrinaAutoSizeMode.scale,
          resizeMode: TrinaResizeMode.normal,
        ),
        shortcut: TrinaGridShortcut(
          actions: {
            ...TrinaGridShortcut.defaultActions,
            LogicalKeySet(LogicalKeyboardKey.keyP): _TrinaProjectAction(_playPreviewSong),
            LogicalKeySet(LogicalKeyboardKey.keyO): _TrinaProjectAction(_launchProject),
            LogicalKeySet(LogicalKeyboardKey.keyD): _TrinaProjectAction(_viewProjectDetails),
            LogicalKeySet(LogicalKeyboardKey.keyF): _TrinaProjectAction(_openProjectFolder),
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


class _PreviewSongDialog extends StatefulWidget {
  final MusicProject project;
  final VoidCallback onClose;

  const _PreviewSongDialog({
    required this.project,
    required this.onClose,
  });

  @override
  State<_PreviewSongDialog> createState() => _PreviewSongDialogState();
}

class _PreviewSongDialogState extends State<_PreviewSongDialog> {
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
    // Auto-start playback when dialog opens
    _startPlayback();
    _startBackgroundPrep();
  }

  bool _hasAudioFile() {
    final p2 = widget.project.previewSongPath;
    return p2 != null && p2.isNotEmpty;
  }

  bool _supportsMonoMix() {
    final p2 = widget.project.previewSongPath;
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
    return DeviceFileSource(widget.project.previewSongPath!);
  }

  void _startBackgroundPrep() {
    if (!_hasAudioFile()) return;
    final filePath = widget.project.previewSongPath!;
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
      final ok = await AudioAnalysisService.writeMonoWavFile(widget.project.previewSongPath!, outPath);
      if (!mounted) return;
      if (!ok) {
        final channels = await AudioAnalysisService.getChannelCount(widget.project.previewSongPath!);
        if (!mounted) return;
        if (channels == 1) {
          setState(() { _monoFilePath = widget.project.previewSongPath!; _isGeneratingMono = false; });
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
        ? DeviceFileSource(widget.project.previewSongPath!)
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
    if (widget.project.previewSongPath == null || widget.project.previewSongPath!.isEmpty) {
      return;
    }

    final file = File(widget.project.previewSongPath!);
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
          await _audioPlayer.play(DeviceFileSource(widget.project.previewSongPath!));
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

  Future<void> _stop() async {
    await _audioPlayer.stop();
    setState(() {
      _position = Duration.zero;
    });
  }

  Future<void> _seek(int seconds) async {
    final target = _position + Duration(seconds: seconds);
    final clamped = target.isNegative ? Duration.zero : (_duration > Duration.zero && target > _duration ? _duration : target);
    await _audioPlayer.seek(clamped);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }


  Widget _buildAndroidPlayerLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File name
        Text(
          widget.project.previewSongFileName ?? 
          (widget.project.previewSongPath != null 
            ? path.basename(widget.project.previewSongPath!)
            : ''),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        // Playback controls (top row)
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
              color: Theme.of(context).colorScheme.primary,
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _isPlaying || _position > Duration.zero ? _stop : null,
              iconSize: 32,
            ),
            IconButton(
              icon: const Icon(Icons.forward_5),
              onPressed: () => _seek(5),
              iconSize: 32,
            ),
            const SizedBox(width: 16),
            // Volume control
            Icon(
              _volume == 0 ? Icons.volume_off : (_volume < 0.5 ? Icons.volume_down : Icons.volume_up),
              size: 24,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            SizedBox(
              width: 100,
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
        const SizedBox(height: 16),
        // Large seek bar (bottom, separated from controls)
        Column(
          children: [
            Slider(
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
              // Make the slider larger and more touch-friendly
              thumbColor: Theme.of(context).colorScheme.primary,
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor: Theme.of(context).colorScheme.surface,
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
      ],
    );
  }

  Widget _buildDesktopPlayerLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.project.previewSongFileName ?? 
          (widget.project.previewSongPath != null 
            ? path.basename(widget.project.previewSongPath!)
            : ''),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
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
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _isPlaying || _position > Duration.zero ? _stop : null,
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
                  Slider(
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
              width: 80,
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
              width: MobileUtils.isMobile() ? double.infinity : 400,
              child: MobileUtils.isMobile()
                  ? _buildAndroidPlayerLayout(context)
                  : _buildDesktopPlayerLayout(context),
            ),
          ),
    );
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
    if (project.previewSongPath == null || project.previewSongPath!.isEmpty) {
      return;
    }
    
    final file = File(project.previewSongPath!);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.previewSongFileNotFound)),
        );
      }
      return;
    }
    
    // Show popup dialog with audio player
    if (mounted) {
      await showDialog(
        context: context,
        builder: (dialogContext) => _PreviewSongDialog(
          project: project,
          onClose: () {
            // Callback when dialog closes - can be used for cleanup if needed
          },
        ),
      );
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
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: _isSelectionMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleProjectSelection(project.id),
                        )
                      : null,
                  title: Text(
                    project.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                              child: Text('DAW: ${project.dawType}${project.dawVersion != null ? ' ${project.dawVersion}' : ''}'),
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
                                child: Text('BPM: ${project.bpm}'),
                              ),
                            if (project.bpm != null && project.musicalKey != null)
                              const SizedBox(width: 16),
                            if (project.musicalKey != null)
                              Expanded(
                                child: Text('Key: ${project.musicalKey}'),
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
                      : project.previewSongPath != null && project.previewSongPath!.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.play_arrow),
                              tooltip: AppLocalizations.of(context)!.playPreview,
                              onPressed: () => _playPreviewSong(project),
                              color: Colors.green,
                            )
                          : null,
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
