import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:trina_grid/trina_grid.dart';

import '../models/release.dart';
import '../models/music_project.dart';
import '../providers/providers.dart';
import '../utils/mobile_utils.dart';
import '../utils/search_utils.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import 'release_detail_page.dart';

class ReleasesTabPage extends ConsumerStatefulWidget {
  const ReleasesTabPage({super.key});

  @override
  ConsumerState<ReleasesTabPage> createState() => _ReleasesTabPageState();
}

class _ReleasesTabPageState extends ConsumerState<ReleasesTabPage> {

  Future<void> _createNewRelease() async {
    final projects = ref.read(projectsProvider);
    
    if (projects.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noProjectsAvailable)),
        );
      }
      return;
    }

    // Show dialog to select tracks
    final selectedProjectIds = await showDialog<List<String>>(
      context: context,
      builder: (context) => _TrackSelectionDialog(projects: projects),
    );

    if (selectedProjectIds == null || selectedProjectIds.isEmpty) {
      return;
    }

    // Get selected projects to determine release title
    final allProjectsAsync = ref.read(allProjectsStreamProvider);
    final allProjects = allProjectsAsync.value ?? [];
    final selectedProjects = allProjects.where((p) => selectedProjectIds.contains(p.id)).toList();

    String releaseTitle;
    bool shouldNavigateToRelease = false;

    // If single project, use project name; otherwise create with empty title
    if (selectedProjects.length == 1) {
      releaseTitle = selectedProjects.first.displayName;
    } else {
      releaseTitle = ''; // Empty title, user will fill it in the release page
      shouldNavigateToRelease = true;
    }

    final repo = await ref.read(repositoryProvider.future);
    final newRelease = Release(
      id: const Uuid().v4(),
      title: releaseTitle,
      trackIds: selectedProjectIds,
      releaseDate: DateTime.now(),
    );
    await repo.addRelease(newRelease);

    if (mounted) {
      if (shouldNavigateToRelease) {
        // Navigate to release page so user can fill in the title
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReleaseDetailPage(releaseId: newRelease.id),
          ),
        );
        // Refresh releases data when returning
        if (mounted) {
          ref.invalidate(releasesProvider);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.releaseCreated(releaseTitle))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider).toString();
    final dateFormat = DateFormat.yMMMd(locale);
    final releasesAsync = ref.watch(releasesProvider);
    final allProjectsAsync = ref.watch(allProjectsStreamProvider);
    // Use allProjects to include preserved projects, not just filtered projectsProvider
    final projects = allProjectsAsync.value ?? [];
    
    // Use releases search provider instead of widget.searchText
    final releasesSearch = ref.watch(releasesSearchProvider);
    final releasesSort = ref.watch(releasesSortProvider);

    return releasesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.errorLoadingReleases(error.toString())),
          ],
        ),
      ),
      data: (releases) {
        // Filter releases by search text if provided
        var filteredReleases = releases;
        if (releasesSearch.trim().isNotEmpty) {
          filteredReleases = releases.where((release) {
            return fuzzyMatchAll(release.title, releasesSearch) ||
                fuzzyMatchAll(release.description ?? '', releasesSearch);
          }).toList();
        }

        // Sort releases
        filteredReleases = List.from(filteredReleases)..sort((a, b) {
          switch (releasesSort) {
            case ReleasesSort.dateAsc:
              return (a.releaseDate ?? DateTime(0)).compareTo(b.releaseDate ?? DateTime(0));
            case ReleasesSort.titleAsc:
              return a.title.toLowerCase().compareTo(b.title.toLowerCase());
            case ReleasesSort.titleDesc:
              return b.title.toLowerCase().compareTo(a.title.toLowerCase());
            case ReleasesSort.dateDesc:
              return (b.releaseDate ?? DateTime(0)).compareTo(a.releaseDate ?? DateTime(0));
          }
        });

        if (filteredReleases.isEmpty) {
          // Show different message if search filtered everything out
          if (releasesSearch.trim().isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noReleasesFound,
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Original empty state
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.album_outlined,
                  size: 64,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noReleasesYet,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.createFirstRelease,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _createNewRelease,
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context)!.createNewRelease),
                ),
              ],
            ),
          );
        }

        final isMobile = MobileUtils.isMobile();
        final l10n = AppLocalizations.of(context)!;
        return Column(
          children: [
            // Filter bar
            if (isMobile)
              Padding(
                padding: MobileUtils.getResponsivePadding(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.releasesCount(filteredReleases.length),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ElevatedButton.icon(
                      onPressed: _createNewRelease,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.createNewRelease),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: Theme.of(context).cardColor,
                child: Row(
                  children: [
                    Text(
                      l10n.releasesCount(filteredReleases.length),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<ReleasesSort>(
                      value: releasesSort,
                      underline: const SizedBox.shrink(),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                      icon: Icon(Icons.sort, size: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                      items: [
                        DropdownMenuItem(value: ReleasesSort.dateDesc, child: Text(l10n.sortNewestFirst)),
                        DropdownMenuItem(value: ReleasesSort.dateAsc, child: Text(l10n.sortOldestFirst)),
                        DropdownMenuItem(value: ReleasesSort.titleAsc, child: Text(l10n.sortTitleAZ)),
                        DropdownMenuItem(value: ReleasesSort.titleDesc, child: Text(l10n.sortTitleZA)),
                      ],
                      onChanged: (v) {
                        if (v != null) ref.read(releasesSortProvider.notifier).setSort(v);
                      },
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _createNewRelease,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.createNewRelease),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            // Releases table/list
            Expanded(
              child: isMobile
                  ? _MobileReleasesList(
                      releases: filteredReleases,
                      projects: projects,
                      dateFormat: dateFormat,
                    )
                  : _ReleasesTable(
                      releases: filteredReleases,
                      projects: projects,
                      dateFormat: dateFormat,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ReleasesTable extends ConsumerStatefulWidget {
  final List<Release> releases;
  final List<MusicProject> projects;
  final DateFormat dateFormat;

  const _ReleasesTable({
    required this.releases,
    required this.projects,
    required this.dateFormat,
  });

  @override
  ConsumerState<_ReleasesTable> createState() => _ReleasesTableState();
}

class _ReleasesTableState extends ConsumerState<_ReleasesTable> {
  TrinaGridStateManager? stateManager;

  @override
  void didUpdateWidget(_ReleasesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the grid rows when releases change
    if (widget.releases != oldWidget.releases && stateManager != null) {
      final newRows = _mapReleasesToRows(widget.releases);
      stateManager!.removeAllRows();
      stateManager!.appendRows(newRows);
    }
  }

  @override
  void dispose() {
    stateManager?.removeListener(_onStateManagerChanged);
    super.dispose();
  }

  void _onStateManagerChanged() {
    if (mounted) setState(() {});
  }

  List<TrinaRow> _mapReleasesToRows(List<Release> releases) {
    return releases.map((release) {
      final releaseProjects = widget.projects
          .where((p) => release.trackIds.contains(p.id))
          .toList();
      
      return TrinaRow(cells: {
        'artwork': TrinaCell(value: release.artworkImagePath),
        'title': TrinaCell(value: release.title),
        'tracks': TrinaCell(value: releaseProjects.length),
        'releaseDate': TrinaCell(
          value: release.releaseDate != null
              ? widget.dateFormat.format(release.releaseDate!)
              : '',
        ),
        'description': TrinaCell(value: release.description ?? ''),
        'actions': TrinaCell(value: ''),
        'data': TrinaCell(value: release),
      });
    }).toList();
  }

  Future<void> _viewRelease(Release release) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReleaseDetailPage(releaseId: release.id),
      ),
    );
    // Refresh releases data when returning from detail page
    if (mounted) {
      ref.invalidate(releasesProvider);
    }
  }

  Future<void> _deleteRelease(Release release) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.deleteRelease),
        content: Text(AppLocalizations.of(context)!.deleteReleaseMessage(release.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final repo = await ref.read(repositoryProvider.future);
      await repo.deleteRelease(release.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.releaseDeleted(release.title))),
        );
      }
    }
  }

  Future<void> _showReleaseContextMenu(BuildContext context, Release release, Offset position) async {
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
          value: 'view',
          child: Row(
            children: [
              const Icon(Icons.assignment, size: 20),
              const SizedBox(width: 8),
              Text(l10n.view),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red.shade300),
              const SizedBox(width: 8),
              Text(l10n.delete, style: TextStyle(color: Colors.red.shade300)),
            ],
          ),
        ),
      ],
      color: Theme.of(context).cardColor,
    );

    if (result != null && mounted) {
      switch (result) {
        case 'view':
          await _viewRelease(release);
          break;
        case 'delete':
          await _deleteRelease(release);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = [
      TrinaColumn(
        title: AppLocalizations.of(context)!.artwork,
        field: 'artwork',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 100,
        minWidth: 80,
        frozen: TrinaColumnFrozen.start,
        renderer: (ctx) {
          final release = ctx.row.cells['data']?.value as Release?;
          final imagePath = ctx.cell.value as String?;
          
          Widget content;
          if (imagePath != null && File(imagePath).existsSync()) {
            content = Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                width: 60,
                height: 60,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.broken_image,
                    size: 40,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  );
                },
              ),
            );
          } else {
            content = Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.album,
                size: 40,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            );
          }
          
          if (release == null) return content;
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showReleaseContextMenu(context, release, details.globalPosition);
            },
            child: content,
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.title,
        field: 'title',
        type: TrinaColumnType.text(),
        enableColumnDrag: true,
        enableContextMenu: false,
        enableEditingMode: false,
        width: 300,
        minWidth: 200,
        frozen: TrinaColumnFrozen.start,
        renderer: (rendererContext) {
          final release = rendererContext.row.cells['data']?.value as Release?;
          if (release == null) {
            return Text(rendererContext.cell.value.toString());
          }
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showReleaseContextMenu(context, release, details.globalPosition);
            },
            child: Text(rendererContext.cell.value.toString()),
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.tracks,
        field: 'tracks',
        type: TrinaColumnType.number(),
        enableEditingMode: false,
        width: 100,
        minWidth: 80,
        renderer: (rendererContext) {
          final release = rendererContext.row.cells['data']?.value as Release?;
          final textWidget = Text(rendererContext.cell.value.toString());
          
          if (release == null) return textWidget;
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showReleaseContextMenu(context, release, details.globalPosition);
            },
            child: textWidget,
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.releaseDate,
        field: 'releaseDate',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 180,
        minWidth: 150,
        renderer: (rendererContext) {
          final release = rendererContext.row.cells['data']?.value as Release?;
          if (release == null) {
            return Text(rendererContext.cell.value.toString());
          }
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showReleaseContextMenu(context, release, details.globalPosition);
            },
            child: Text(rendererContext.cell.value.toString()),
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.description,
        field: 'description',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        width: 300,
        minWidth: 200,
        renderer: (rendererContext) {
          final release = rendererContext.row.cells['data']?.value as Release?;
          final textWidget = Text(rendererContext.cell.value.toString());
          
          if (release == null) return textWidget;
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showReleaseContextMenu(context, release, details.globalPosition);
            },
            child: textWidget,
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.actions,
        field: 'actions',
        type: TrinaColumnType.text(),
        enableColumnDrag: false,
        width: 200,
        minWidth: 180,
        renderer: (ctx) {
          final release = ctx.row.cells['data']!.value as Release;
          
          return GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showReleaseContextMenu(context, release, details.globalPosition);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.assignment),
                  tooltip: AppLocalizations.of(context)!.view,
                  onPressed: () => _viewRelease(release),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red.shade300,
                  tooltip: AppLocalizations.of(context)!.delete,
                  onPressed: () => _deleteRelease(release),
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
        width: 0,
        hide: true,
      ),
    ];

    final initialRows = _mapReleasesToRows(widget.releases);

    final isNeon = ref.watch(themeTypeProvider) == AppThemeType.neonDark;
    // Classic Dark's primary is a muted gray-blue, so tinting with it reads
    // as barely-there against the dark card background — lean on white
    // instead for a highlight that actually contrasts. Neon Dark's bright
    // primary already pops, so keep that one colored.
    final rowSelectColor = isNeon
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.14);
    final oddColor = Theme.of(context).cardColor;
    final evenColor = Theme.of(context).brightness == Brightness.dark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: 0.05),
            Theme.of(context).cardColor,
          )
        : Color.alphaBlend(
            Colors.black.withValues(alpha: 0.04),
            Theme.of(context).cardColor,
          );

    return TrinaGrid(
      columns: columns,
      rows: initialRows,
      rowColorCallback: (TrinaRowColorContext ctx) {
        final isActivated = stateManager?.currentRow == ctx.row;
        if (isActivated) return rowSelectColor;
        return ctx.rowIdx.isOdd ? oddColor : evenColor;
      },
      onLoaded: (TrinaGridOnLoadedEvent event) {
        stateManager = event.stateManager;
        stateManager!.addListener(_onStateManagerChanged);
      },
      configuration: TrinaGridConfiguration(
        style: TrinaGridStyleConfig(
          gridBackgroundColor: Theme.of(context).cardColor,
          gridBorderColor: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          borderColor: ref.watch(themeTypeProvider) == AppThemeType.neonDark
                ? Theme.of(context).dividerColor
                : Theme.of(context).dividerColor.withValues(alpha: 0.25),
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
          rowHeight: 70, // Taller rows to accommodate thumbnails
          // Transparent so rowColorCallback controls all row backgrounds
          // (odd/even and click-selection) with no per-cell border/fill on click.
          activatedBorderColor: Colors.transparent,
          activatedColor: Colors.transparent,
          iconColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
          menuBackgroundColor: Theme.of(context).cardColor,
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
            LogicalKeySet(LogicalKeyboardKey.enter): _TrinaReleaseAction(_viewRelease),
            LogicalKeySet(LogicalKeyboardKey.keyD): _TrinaReleaseAction(_viewRelease),
          },
        ),
      ),
      onRowChecked: null,
      onSelected: null,
      onRowDoubleTap: (TrinaGridOnRowDoubleTapEvent event) async {
        final release = event.row.cells['data']?.value as Release?;
        if (release == null) return;
        
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReleaseDetailPage(releaseId: release.id),
          ),
        );
        // Refresh releases data when returning from detail page
        if (mounted) {
          ref.invalidate(releasesProvider);
        }
      },
      createFooter: (stateManager) => const SizedBox.shrink(),
    );
  }
}

class _TrinaReleaseAction extends TrinaGridShortcutAction {
  final Future<void> Function(Release release) onRelease;
  const _TrinaReleaseAction(this.onRelease);

  @override
  void execute({
    required TrinaKeyManagerEvent keyEvent,
    required TrinaGridStateManager stateManager,
  }) {
    if (stateManager.isEditing) return;
    final release = stateManager.currentRow?.cells['data']?.value;
    if (release is Release) unawaited(onRelease(release));
  }
}

class _TrackSelectionDialog extends StatefulWidget {
  final List<MusicProject> projects;

  const _TrackSelectionDialog({required this.projects});

  @override
  State<_TrackSelectionDialog> createState() => _TrackSelectionDialogState();
}

class _TrackSelectionDialogState extends State<_TrackSelectionDialog> {
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MusicProject> get _filteredProjects {
    if (_searchQuery.isEmpty) {
      return widget.projects;
    }
    return widget.projects.where((project) {
      final name = project.displayName.toLowerCase();
      final dawType = (project.dawType ?? '').toLowerCase();
      return name.contains(_searchQuery) || dawType.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _filteredProjects;
    
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.selectTracks),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.selectTracksToInclude(_selectedIds.length, _selectedIds.length == 1 ? '' : 's'),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 16),
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.searchTracks,
                hintText: AppLocalizations.of(context)!.searchTracksHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredProjects.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.noTracksFound,
                        style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredProjects.length,
                      itemBuilder: (context, index) {
                        final project = filteredProjects[index];
                        final isSelected = _selectedIds.contains(project.id);
                        return CheckboxListTile(
                          title: Text(project.displayName),
                          subtitle: Text(
                            '${project.dawType ?? AppLocalizations.of(context)!.unknown} • ${project.bpm?.toStringAsFixed(0) ?? '?'} ${AppLocalizations.of(context)!.bpm}',
                            style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                          ),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedIds.add(project.id);
                              } else {
                                _selectedIds.remove(project.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _selectedIds.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedIds.toList()),
          child: Text(AppLocalizations.of(context)!.continueButton),
        ),
      ],
    );
  }
}

class _MobileReleasesList extends ConsumerWidget {
  final List<Release> releases;
  final List<MusicProject> projects;
  final DateFormat dateFormat;

  const _MobileReleasesList({
    required this.releases,
    required this.projects,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (releases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.album_outlined,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noReleasesYet,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: MobileUtils.getResponsivePadding(context),
      itemCount: releases.length,
      itemBuilder: (context, index) {
        final release = releases[index];
        final releaseProjects = projects.where((p) => release.trackIds.contains(p.id)).toList();
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReleaseDetailPage(releaseId: release.id),
                ),
              );
              if (context.mounted) {
                ref.invalidate(releasesProvider);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Artwork thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: release.artworkImagePath != null && File(release.artworkImagePath!).existsSync()
                        ? Image.file(
                            File(release.artworkImagePath!),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Theme.of(context).cardColor,
                                child: Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Theme.of(context).cardColor,
                            child: Icon(
                              Icons.album,
                              size: 40,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Release info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          release.title.isNotEmpty ? release.title : 'Untitled Release',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.tracksCount(releaseProjects.length),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        if (release.releaseDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(release.releaseDate!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                        if (release.description != null && release.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            release.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Actions
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      if (value == 'view') {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReleaseDetailPage(releaseId: release.id),
                          ),
                        );
                        if (context.mounted) {
                          ref.invalidate(releasesProvider);
                        }
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Theme.of(context).cardColor,
                            title: Text(AppLocalizations.of(context)!.deleteRelease),
                            content: Text(AppLocalizations.of(context)!.deleteReleaseMessage(release.title)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(AppLocalizations.of(context)!.cancel),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: Text(AppLocalizations.of(context)!.delete),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          final repo = await ref.read(repositoryProvider.future);
                          await repo.deleteRelease(release.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context)!.releaseDeleted(release.title))),
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'view',
                        child: Row(
                          children: [
                            const Icon(Icons.assignment, size: 20),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.view),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red.shade300),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.delete,
                              style: TextStyle(color: Colors.red.shade300),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CreateReleaseDialog extends StatefulWidget {
  @override
  State<_CreateReleaseDialog> createState() => _CreateReleaseDialogState();
}

class _CreateReleaseDialogState extends State<_CreateReleaseDialog> {
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
      title: Text(AppLocalizations.of(context)!.createRelease),
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

