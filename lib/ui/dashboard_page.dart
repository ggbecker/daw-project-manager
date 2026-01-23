import 'dart:io';
import 'dart:ui' show Canvas, Paint, PaintingStyle, Rect;

import 'package:pluto_grid/pluto_grid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/services.dart'; 
import 'package:window_manager/window_manager.dart' if (dart.library.html) 'package:window_manager/window_manager_stub.dart'; 
import 'package:path/path.dart' as path; // 🚨 NOVO IMPORT
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

import '../services/scanner_service.dart';
import '../utils/mobile_utils.dart';
import 'project_detail_page.dart';
import 'releases_tab_page.dart';
import 'release_detail_page.dart';
import 'profile_manager_page.dart';
import 'project_folders_settings_page.dart';
import 'playlists_page.dart';
import 'widgets/language_switcher.dart';
import 'widgets/theme_switcher.dart';
import '../generated/l10n/app_localizations.dart';

import '../models/music_project.dart';
import '../models/release.dart';
import '../providers/providers.dart';
import '../repository/project_repository.dart';
import 'package:uuid/uuid.dart';

/// App version embedded at build-time (CI passes `--dart-define=APP_VERSION=x.y.z`).
/// For PR/local builds, we fall back to a dummy version.
const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.0.0');

// WIDGET CORRIGIDO: Botões de controle da janela usando window_manager (desktop only)
class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  // Função auxiliar assíncrona para alternar entre maximizar e restaurar
  void _toggleMaximize() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      if (await windowManager.isMaximized()) {
        windowManager.restore();
      } else {
        windowManager.maximize();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show on desktop platforms
    if (kIsWeb || (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux)) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        // Minimize
        IconButton(
          icon: Icon(Icons.minimize, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
          onPressed: () => windowManager.minimize(),
        ),
        // Maximize/Restore
        IconButton(
          icon: Icon(Icons.crop_square_sharp, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
          onPressed: _toggleMaximize, 
        ),
        // Close
        IconButton(
          icon: Icon(Icons.close, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
          onPressed: () => windowManager.close(), 
          splashColor: Colors.transparent, 
          highlightColor: const Color(0xFFC42B1C), 
        ),
      ],
    );
  }
}

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
    // Android has 3 tabs (Projects, Releases, Playlists), desktop has 2
    final tabCount = Platform.isAndroid ? 3 : 2;
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
      if (currentTabIndex == 0) {
        // Projects tab
        final projectsSearch = ref.read(projectsSearchProvider);
        if (_searchController.text != projectsSearch) {
          _searchController.text = projectsSearch;
        }
      } else {
        // Releases tab
        final releasesSearch = ref.read(releasesSearchProvider);
        if (_searchController.text != releasesSearch) {
          _searchController.text = releasesSearch;
        }
      }
      setState(() {}); // Rebuild to update search placeholder when tab animation completes
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


  // Método para focar na busca e selecionar texto
  void _focusSearchAndSelectAll() {
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
    final currentSearch = _tabController.index == 0
        ? ref.watch(projectsSearchProvider)
        : ref.watch(releasesSearchProvider);
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
    // On Android, we're only syncing metadata, so show ALL projects (both in releases and not)
    // On desktop, filter preserved projects that aren't in active scan roots
    final List<MusicProject> filteredProjects;
    if (Platform.isAndroid) {
      // Android: show all projects (metadata-only mode, no file system checks)
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
                        title: const Text('DAW Project Manager'),
                        actions: [
                          // Search icon
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              _focusSearchAndSelectAll();
                            },
                            tooltip: AppLocalizations.of(context)!.searchProjects,
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
                                error: (_, __) => IconButton(
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
                        bottom: TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(text: AppLocalizations.of(context)!.projects),
                            Tab(text: AppLocalizations.of(context)!.releasesTab),
                            if (Platform.isAndroid)
                              Tab(text: AppLocalizations.of(context)!.playlists),
                          ],
                        ),
                      )
                    : null,
                body: Column(
          children: [
            // ----------------------------------------------------
            // LÓGICA DE WINDOW BAR: APENHAS MOSTRA A BARRA PERSONALIZADA SE NÃO ESTIVER EM DEBUG E FOR DESKTOP
            if (!kDebugMode && !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux))
              GestureDetector(
                onPanStart: (_) => windowManager.startDragging(),
                // LÓGICA para alternar maximizar/restaurar no double tap
                onDoubleTap: () async {
                  if (await windowManager.isMaximized()) {
                    windowManager.restore();
                  } else {
                    windowManager.maximize();
                  }
                }, 
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  height: 40, // Altura padrão para a barra
                  child: Row(
                    children: [
                      // Título da Aplicação com versão (como antes)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          'DAW Project Manager v$appVersion',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.titleMedium?.color,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(), // Espaçador para empurrar os botões para a direita
                      const SizedBox(width: 4),
                      // Donate button
                      Tooltip(
                        message: 'Support the project',
                        child: TextButton.icon(
                          icon: const Icon(Icons.card_giftcard, size: 18, color: Colors.white70),
                          label: const Text(
                            'Support',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          onPressed: () async {
                            final uri = Uri.parse('https://www.paypal.com/donate/?hosted_button_id=QHVVZ3LAF39BL');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } 
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const ThemeSwitcher(),
                      const SizedBox(width: 8),
                      const LanguageSwitcher(),
                      const SizedBox(width: 8),
                      // Botões de minimizar, maximizar e fechar
                      const WindowButtons(),
                    ],
                  ),
                ),
              ),
            // ----------------------------------------------------
            
            // CONTEÚDO DA BARRA DE AÇÕES E PESQUISA
            Builder(
              builder: (context) {
                final isMobile = MobileUtils.isMobile();
                return Padding(
                  padding: MobileUtils.getResponsivePadding(context),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search bar on top for mobile
                            TextField(
                              focusNode: _searchFocusNode,
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: _tabController.index == 0
                                    ? AppLocalizations.of(context)!.searchProjects
                                    : AppLocalizations.of(context)!.searchReleases,
                                isDense: true,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: () {
                                  final currentSearch = _tabController.index == 0
                                      ? ref.read(projectsSearchProvider)
                                      : ref.read(releasesSearchProvider);
                                  return currentSearch.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            _searchController.clear();
                                            if (_tabController.index == 0) {
                                              ref.read(projectsSearchProvider.notifier).clear();
                                            } else {
                                              ref.read(releasesSearchProvider.notifier).clear();
                                            }
                                          },
                                        )
                                      : null;
                                }(),
                              ),
                              onChanged: (text) {
                                if (_tabController.index == 0) {
                                  ref.read(projectsSearchProvider.notifier).setSearchText(text);
                                } else {
                                  ref.read(releasesSearchProvider.notifier).setSearchText(text);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            // Filters and info row (only show on Projects tab)
                            if (_tabController.index == 0) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: repoAsync.when(
                                      loading: () => const SizedBox.shrink(),
                                      error: (_, __) => const SizedBox.shrink(),
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
                                Row(
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
                                // Hide Finished Projects checkbox (Mobile)
                                Row(
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
                                // Show Only With Deadline checkbox (Mobile)
                                Row(
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
                        if (!Platform.isAndroid)
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                  // Ações de Root e Scan
                  Flexible(
                    flex: 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                              error: (_, __) => Tooltip(
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
                          Flexible(
                            child: OutlinedButton.icon(
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
                          ),
                          const SizedBox(width: 12),
                        ],
                        Flexible(
                          child: ElevatedButton.icon(
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
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Tooltip(
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
                          ),
                      ],
                    ),
                  ),
                  // Área de Pesquisa e Filtro (desktop only)
                  Flexible(
                    flex: 3,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 400,
                          child: TextField(
                              // Associar o FocusNode ao TextField
                              focusNode: _searchFocusNode, 
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: _tabController.index == 0
                                    ? '${AppLocalizations.of(context)!.searchProjects} (${Platform.isMacOS ? 'Cmd+F' : 'Ctrl+F'})'
                                    : '${AppLocalizations.of(context)!.searchReleases} (${Platform.isMacOS ? 'Cmd+F' : 'Ctrl+F'})',
                                isDense: true,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: () {
                                  // Get current search text based on active tab
                                  final currentSearch = _tabController.index == 0
                                      ? ref.read(projectsSearchProvider)
                                      : ref.read(releasesSearchProvider);
                                  return currentSearch.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            _searchController.clear();
                                            if (_tabController.index == 0) {
                                              ref.read(projectsSearchProvider.notifier).clear();
                                            } else {
                                              ref.read(releasesSearchProvider.notifier).clear();
                                            }
                                          },
                                        )
                                      : null;
                                }(),
                              ),
                              onChanged: (text) {
                                // Update the appropriate search provider based on current tab
                                if (_tabController.index == 0) {
                                  // Projects tab
                                  ref.read(projectsSearchProvider.notifier).setSearchText(text);
                                } else {
                                  // Releases tab
                                  ref.read(releasesSearchProvider.notifier).setSearchText(text);
                                }
                              },
                            ),
                        ),
                        const SizedBox(width: 8),
                        const Spacer(),
                        // Filters (only show on Projects tab)
                        if (_tabController.index == 0) ...[
                          // Exibe o contador de projetos
                          Flexible(
                            child: repoAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (repo) {
                                String projectText;
                                final l10n = AppLocalizations.of(context)!;
                                if (hiddenMode == 2) {
                                  // Showing only hidden
                                  projectText = '${l10n.projectsCount(hiddenCount)} ${l10n.hiddenOnly}';
                                } else {
                                  // Showing visible or all
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
                          const SizedBox(width: 8),
                          // Show Hidden Projects checkbox
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: hiddenMode == 1, // Show all mode
                              onChanged: (value) {
                                if (value == true) {
                                  hiddenNotifier.setShowAll(true);
                                } else {
                                  // If unchecking, go back to show only visible (mode 0)
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
                        const SizedBox(width: 8),
                        // Show Only Hidden button
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
                                // Currently showing only hidden, switch back to visible (mode 0)
                                hiddenNotifier.setShowOnlyHidden(false);
                              } else {
                                // Switch to show only hidden (mode 2)
                                // Also uncheck the "Show Hidden" checkbox
                                hiddenNotifier.setShowOnlyHidden(true);
                              }
                            },
                          ),
                        const SizedBox(width: 8),
                        // Hide Finished Projects checkbox
                        Row(
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
                        const SizedBox(width: 8),
                        // Show Only With Deadline checkbox (Desktop)
                        Row(
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
                        const SizedBox(width: 8),
                        // Phase Filter dropdown
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
                          const SizedBox(width: 8),
                          const SizedBox.shrink(),
                        ],
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
                    if (Platform.isAndroid)
                      Tab(icon: Icon(Icons.playlist_play), text: AppLocalizations.of(context)!.playlists),
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
                  // Use mobile-friendly list view on Android, table on desktop
                  Platform.isAndroid
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
                        ),
                  const ReleasesTabPage(),
                  if (Platform.isAndroid) const PlaylistsPage(),
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

  const _PlutoProjectsTableWithSelection({
    required this.projects,
    required this.dateFormat,
    required this.onCreateRelease,
    required this.onHideProjects,
    required this.onUnhideProjects,
    required this.showHidden,
    required this.onExtractingMetadataChanged,
    required this.isAnyOperation,
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
    return Column(
      children: [
        Expanded(
          child: _PlutoProjectsTable(
            projects: widget.projects,
            dateFormat: widget.dateFormat,
            selectedIds: _selectedProjectIds,
            onToggleSelection: _toggleProjectSelection,
            onHideProjects: widget.onHideProjects,
            onUnhideProjects: widget.onUnhideProjects,
          ),
        ),
        // Selection action bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _areAllSelected,
                    onChanged: (value) {
                      if (value == true) {
                        _selectAll();
                      } else {
                        _clearSelection();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedProjectIds.isEmpty
                        ? AppLocalizations.of(context)!.selectAllProjects
                        : AppLocalizations.of(context)!.projectsSelected(_selectedProjectIds.length, _selectedProjectIds.length == 1 ? '' : 's'),
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ],
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
                    ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: Text(AppLocalizations.of(context)!.extractMetadata),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: widget.isAnyOperation
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
  const _PlutoProjectsTable({
    required this.projects,
    required this.dateFormat,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onHideProjects,
    required this.onUnhideProjects,
  });

  @override
  ConsumerState<_PlutoProjectsTable> createState() => _PlutoProjectsTableState();
}

class _PlutoProjectsTableState extends ConsumerState<_PlutoProjectsTable> {
  PlutoGridStateManager? stateManager;
  
  Future<void> _playPreviewSong(MusicProject project) async {
    if (project.previewSongPath == null || project.previewSongPath!.isEmpty) {
      return;
    }
    
    final file = File(project.previewSongPath!);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preview song file not found')),
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
    try {
      // Lançamento específico para Windows e macOS
      if (Platform.isMacOS) {
        await Process.start('open', [project.filePath]);
      } else if (Platform.isWindows) {
        await Process.start('cmd', ['/c', 'start', '', project.filePath]);
      } else {
        // Fallback para outros sistemas operacionais (e.g. Linux)
        await Process.start(project.filePath, []);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.launchingProject(project.displayName))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.failedToLaunch(e.toString()))));
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
    
    try {
      // Lógica para abrir o diretório no explorador de arquivos nativo
      if (Platform.isMacOS) {
        await Process.start('open', [folderPath]);
      } else if (Platform.isWindows) {
        // Usar 'explorer' para Windows
        await Process.start('explorer', [folderPath]);
      } else if (Platform.isLinux) {
        // Usar 'xdg-open' para a maioria dos ambientes Linux
        await Process.start('xdg-open', [folderPath]);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.osNotSupportedForOpeningFolder)));
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.openingFolder(project.displayName))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.failedToOpenFolder(e.toString()))));
      }
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

  List<PlutoRow> _mapProjectsToRows(List<MusicProject> projects) {
    return projects.map((p) {
      // Combine DAW type and version into a single string
      final dawDisplay = p.dawType != null
          ? (p.dawVersion != null && p.dawVersion!.isNotEmpty
              ? '${p.dawType} ${p.dawVersion}'
              : p.dawType!)
          : '';
      
      return PlutoRow(
        cells: {
          'checkbox': PlutoCell(value: ''), // Placeholder for checkbox column
          'name': PlutoCell(value: p.displayName),
          'status': PlutoCell(value: p.status),
          'dawType': PlutoCell(value: dawDisplay),
          'bpm': PlutoCell(value: p.bpm?.toString() ?? ''),
          'key': PlutoCell(value: p.musicalKey ?? ''),
          'lastModified': PlutoCell(value: widget.dateFormat.format(p.lastModifiedAt)),
          'deadline': PlutoCell(value: p.deadlineStatus ?? ''),
          'launch': PlutoCell(value: ''),
          'data': PlutoCell(value: p),
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
      PlutoColumn(
        title: '',
        field: 'checkbox',
        type: PlutoColumnType.text(),
        width: 50,
        minWidth: 50,
        frozen: PlutoColumnFrozen.start,
        enableColumnDrag: false,
        enableContextMenu: false,
        enableFilterMenuItem: false,
        enableSorting: false,
        enableEditingMode: false,
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
      PlutoColumn(
        title: AppLocalizations.of(context)!.name,
        field: 'name',
        type: PlutoColumnType.text(),
        enableColumnDrag: true,
        enableContextMenu: false,
        enableEditingMode: false,
        width: 600,
        minWidth: 200,
        frozen: PlutoColumnFrozen.start,
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          if (project == null) {
            return Text(rendererContext.cell.value.toString());
          }
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
            },
            child: Text(rendererContext.cell.value.toString()),
          );
        },
      ),
      PlutoColumn(
        title: l10n.phase,
        field: 'status',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 140,
        minWidth: 120,
        renderer: (rendererContext) {
          final project = rendererContext.row.cells['data']?.value as MusicProject?;
          final status = rendererContext.cell.value as String? ?? '';
          final translatedStatus = _translateStatus(context, status);
          final textWidget = Text(
            translatedStatus,
            style: TextStyle(
              color: _getStatusColor(status),
              fontWeight: FontWeight.w500,
            ),
          );
          
          if (project == null) return textWidget;
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, project, details.globalPosition);
            },
            child: textWidget,
          );
        },
      ),
      PlutoColumn(
        title: AppLocalizations.of(context)!.daw,
        field: 'dawType',
        type: PlutoColumnType.text(),
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
      PlutoColumn(
        title: AppLocalizations.of(context)!.bpm,
        field: 'bpm',
        type: PlutoColumnType.text(),
        width: 100,
        minWidth: 80,
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
      PlutoColumn(
        title: AppLocalizations.of(context)!.key.split(' ').first, // Get just "Key" from "Key (e.g., C#m, F major)"
        field: 'key',
        type: PlutoColumnType.text(),
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
      PlutoColumn(
        title: AppLocalizations.of(context)!.lastModifiedColumn,
        field: 'lastModified',
        type: PlutoColumnType.text(),
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
      PlutoColumn(
        title: AppLocalizations.of(context)!.deadline,
        field: 'deadline',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 140,
        minWidth: 120,
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
      PlutoColumn(
        title: AppLocalizations.of(context)!.actions,
        field: 'launch',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 250, // Increased width to accommodate hidden button
        minWidth: 220,
        renderer: (ctx) {
          final project = ctx.row.cells['data']!.value as MusicProject;
          
          // Lógica para determinar o diretório pai
          final String projectPath = project.filePath;
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
                tooltip: project.previewSongPath != null && project.previewSongPath!.isNotEmpty
                    ? AppLocalizations.of(context)!.playPreview
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
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '|',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 18),
                ),
              ),
              // Launch button
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: AppLocalizations.of(context)!.tooltipLaunchInDaw,
                onPressed: () => _launchProject(project),
              ),
              // Separator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '|',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 18),
                ),
              ),
              // View button
              IconButton(
                icon: const Icon(Icons.assignment),
                tooltip: AppLocalizations.of(context)!.tooltipViewDetails,
                onPressed: () => _viewProjectDetails(project),
              ),
              // Open Folder button
              IconButton(
                icon: const Icon(Icons.folder_open),
                tooltip: AppLocalizations.of(context)!.openFolder,
                onPressed: () => _openProjectFolder(project),
              ),
              // Separator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '|',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 18),
                ),
              ),
              // Hidden button
              IconButton(
                icon: Icon(project.hidden ? Icons.visibility : Icons.visibility_off),
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
      PlutoColumn(
        title: 'data',
        field: 'data',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 0,
        hide: true,
      ),
    ]; // <-- Semicolon final do array de colunas

    final initialRows = _mapProjectsToRows(widget.projects);

    return PlutoGrid(
          columns: columns,
          rows: initialRows,
          onLoaded: (PlutoGridOnLoadedEvent event) {
            stateManager = event.stateManager;
          },
      onChanged: (PlutoGridOnChangedEvent event) async {
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
      configuration: PlutoGridConfiguration(
        style: PlutoGridStyleConfig(
          gridBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
          gridBorderColor: Theme.of(context).dividerColor,
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
          activatedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          iconColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
          menuBackgroundColor: Theme.of(context).cardColor,
          evenRowColor: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).cardColor.withOpacity(0.5)
              : Theme.of(context).cardColor.withOpacity(0.7),
        ),
        columnSize: const PlutoGridColumnSizeConfig(
          autoSizeMode: PlutoAutoSizeMode.scale,
          resizeMode: PlutoResizeMode.normal,
        ),
      ),
      onRowChecked: null,
      onSelected: null,
      onRowDoubleTap: (PlutoGridOnRowDoubleTapEvent event) async {
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
    
    // Auto-start playback when dialog opens
    _startPlayback();
  }

  Future<void> _startPlayback() async {
    if (widget.project.previewSongPath == null || widget.project.previewSongPath!.isEmpty) {
      return;
    }

    final file = File(widget.project.previewSongPath!);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preview song file not found')),
        );
        Navigator.pop(context);
      }
      return;
    }

    try {
      await _audioPlayer.play(DeviceFileSource(widget.project.previewSongPath!));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play preview: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
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
          SnackBar(content: Text('Failed to play preview: ${e.toString()}')),
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
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _togglePlayPause,
              iconSize: 32,
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _isPlaying || _position > Duration.zero ? _stop : null,
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
          const SnackBar(content: Text('Preview song file not found')),
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
          const SnackBar(content: Text('Preview song not available. Please download backup first.')),
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
            const SnackBar(content: Text('Preview song file not found')),
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

      // On Android, copy to cache directory with original name for sharing
      if (Platform.isAndroid) {
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
          SnackBar(content: Text('Failed to share preview song: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _sharePreviewSongAsZip() async {
    if (!Platform.isAndroid) return;

    if (widget.project.previewSongPath == null || widget.project.previewSongPath!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preview song file not found')),
        );
      }
      return;
    }

    // Skip if it's a Drive file reference (not downloaded)
    if (widget.project.previewSongPath!.startsWith('drive://')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preview song not available. Please download backup first.')),
        );
      }
      return;
    }

    try {
      final sourceFile = File(widget.project.previewSongPath!);
      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preview song file not found')),
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
          SnackBar(content: Text('Failed to share preview song as ZIP: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        SingleActivator(LogicalKeyboardKey.space): const _TogglePlayPauseIntent(),
      },
      child: Actions(
        actions: {
          _TogglePlayPauseIntent: CallbackAction<_TogglePlayPauseIntent>(
            onInvoke: (_) {
              _togglePlayPause();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
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
                if (Platform.isAndroid &&
                    widget.project.previewSongPath != null &&
                    widget.project.previewSongPath!.isNotEmpty &&
                    !widget.project.previewSongPath!.startsWith('drive://')) ...[
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Share preview song',
                    onPressed: _sharePreviewSong,
                  ),
                  IconButton(
                    icon: const Icon(Icons.archive),
                    tooltip: 'Share as ZIP',
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
              width: Platform.isAndroid ? double.infinity : 400,
              child: Platform.isAndroid
                  ? _buildAndroidPlayerLayout(context)
                  : _buildDesktopPlayerLayout(context),
            ),
          ),
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

class _MobileProjectsListState extends ConsumerState<_MobileProjectsList> {
  final Set<String> _selectedProjectIds = {};
  bool _isSelectionMode = false;

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
          SnackBar(content: Text('Preview song file not found')),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.noProjectsAvailable,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.selectProjectsFolder,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: widget.projects.length,
            itemBuilder: (context, index) {
              final project = widget.projects[index];
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
                              'Modified: ${DateFormat('MMM dd, yyyy').format(project.lastModifiedAt)}',
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
