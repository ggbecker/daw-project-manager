import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart';
import '../models/todo_item.dart';
import '../providers/providers.dart';
import 'project_detail_page.dart';

class MusicPlayerPage extends ConsumerStatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  ConsumerState<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends ConsumerState<MusicPlayerPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _currentIndex = -1;
  List<MusicProject> _tracks = [];
  String _searchQuery = '';
  late TextEditingController _searchController;
  double _sidebarWidth = 320.0;

  final List<MusicProject> _playlist = [];
  int _playlistIndex = -1;
  bool _playingFromPlaylist = false;

  int _selectedIndex = -1;
  final TextEditingController _addTodoController = TextEditingController();

  // Manual double-click detection — avoids DoubleTapGestureRecognizer in the arena.
  DateTime? _lastTapTime;
  int _lastTapKey = -1; // library: originalIndex, queue: ~i (bitwise not)

  MusicProject? get _current =>
      _currentIndex >= 0 && _currentIndex < _tracks.length
          ? _tracks[_currentIndex]
          : null;

  List<(int, MusicProject)> get _displayTracks {
    if (_searchQuery.isEmpty) {
      return List.generate(_tracks.length, (i) => (i, _tracks[i]));
    }
    final q = _searchQuery.toLowerCase();
    return [
      for (int i = 0; i < _tracks.length; i++)
        if (_tracks[i].displayName.toLowerCase().contains(q) ||
            p.basename(_resolvedPath(_tracks[i]) ?? '').toLowerCase().contains(q))
          (i, _tracks[i]),
    ];
  }

  String? _resolvedPath(MusicProject project) =>
      project.previewSongPath?.isNotEmpty == true
          ? project.previewSongPath
          : project.previewSongAutoPath;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Seed the track list from whatever the stream already holds on first mount.
      final value = ref.read(allProjectsStreamProvider).value;
      if (value != null) _buildTrackList(value);
      // Register queue navigation callbacks for the bottom player bar.
      ref.read(queueNavigationProvider.notifier).register(
        playNext: _playNext,
        playPrev: _playPrev,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addTodoController.dispose();
    ref.read(queueNavigationProvider.notifier).unregister();
    super.dispose();
  }

  Future<void> _addTodo(MusicProject project, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _addTodoController.clear();
    final newTodo = TodoItem(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      createdAt: DateTime.now(),
    );
    final repo = await ref.read(repositoryProvider.future);
    await repo.updateProject(project.copyWith(
      todos: [...project.todos, newTodo],
    ));
    ref.invalidate(allProjectsStreamProvider);
  }

  void _buildTrackList(List<MusicProject> projects) {
    final tracks = projects
        .where((p) => _resolvedPath(p) != null)
        .toList()
      ..sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));

    // Skip rebuild when nothing the UI cares about has changed.
    if (tracks.length == _tracks.length) {
      bool same = true;
      for (int i = 0; i < tracks.length && same; i++) {
        final a = tracks[i], b = _tracks[i];
        if (a.id != b.id ||
            a.displayName != b.displayName ||
            a.status != b.status ||
            a.todos.length != b.todos.length ||
            a.todos.where((t) => t.completed).length !=
                b.todos.where((t) => t.completed).length) {
          same = false;
        }
      }
      if (same) return;
    }

    setState(() {
      final prevCurrentId = _current?.id;
      final prevSelectedId = _selectedIndex >= 0 && _selectedIndex < _tracks.length
          ? _tracks[_selectedIndex].id
          : null;
      _tracks = tracks;
      if (prevCurrentId != null) {
        final idx = _tracks.indexWhere((t) => t.id == prevCurrentId);
        _currentIndex = idx >= 0 ? idx : _currentIndex.clamp(-1, _tracks.length - 1);
      }
      if (prevSelectedId != null) {
        final idx = _tracks.indexWhere((t) => t.id == prevSelectedId);
        if (idx >= 0) _selectedIndex = idx;
      }
    });
  }

  void _selectTrack(int index, {bool keepPlaylistState = false}) {
    if (index < 0 || index >= _tracks.length) return;
    final track = _tracks[index];
    final filePath = _resolvedPath(track)!;
    setState(() {
      _currentIndex = index;
      _selectedIndex = index;
      if (!keepPlaylistState) _playingFromPlaylist = false;
    });
    ref.read(desktopPlayerProvider.notifier).play(track, filePath, isQueuedPlayback: true);
  }

  void _selectFromPlaylist(int pi) {
    if (pi < 0 || pi >= _playlist.length) return;
    final project = _playlist[pi];
    final idx = _tracks.indexWhere((t) => t.id == project.id);
    if (idx < 0) return;
    setState(() {
      _playlistIndex = pi;
      _playingFromPlaylist = true;
    });
    _selectTrack(idx, keepPlaylistState: true);
  }

  void _playNext() {
    if (_playingFromPlaylist && _playlist.isNotEmpty) {
      _selectFromPlaylist((_playlistIndex + 1) % _playlist.length);
    } else {
      if (_tracks.isEmpty) return;
      _selectTrack((_currentIndex + 1) % _tracks.length);
    }
  }

  void _playPrev() {
    if (_playingFromPlaylist && _playlist.isNotEmpty) {
      _selectFromPlaylist((_playlistIndex - 1 + _playlist.length) % _playlist.length);
    } else {
      if (_tracks.isEmpty) return;
      _selectTrack((_currentIndex - 1 + _tracks.length) % _tracks.length);
    }
  }

  void _showTrackContextMenu(BuildContext context, Offset globalPos, MusicProject track, int originalIndex) {
    final l10n = AppLocalizations.of(context)!;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final navigator = Navigator.of(context);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        globalPos & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'detail',
          child: Row(children: [
            const Icon(Icons.open_in_new, size: 16),
            const SizedBox(width: 10),
            Text(l10n.playerGoToProject),
          ]),
        ),
        if (!_playlist.any((t) => t.id == track.id))
          PopupMenuItem(
            value: 'queue',
            child: Row(children: [
              const Icon(Icons.queue_music, size: 16),
              const SizedBox(width: 10),
              Text(l10n.playerAddToQueue),
            ]),
          ),
      ],
    ).then((value) {
      if (!mounted) return;
      if (value == 'detail') {
        navigator.push(
          MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: track.id)),
        );
      } else if (value == 'queue') {
        setState(() => _playlist.add(track));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    ref.listen(allProjectsStreamProvider, (_, next) {
      _buildTrackList(next.value ?? []);
    });
    ref.listen(desktopPlayerCompletedProvider, (prev, next) {
      if (_currentIndex >= 0 || _playingFromPlaylist) _playNext();
    });

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        // ── Left: track library ───────────────────────────────────────────
        SizedBox(
          width: _sidebarWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Icon(Icons.headphones, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(l10n.playerTitle,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      _searchQuery.isEmpty
                          ? l10n.playerTrackCount(_tracks.length)
                          : l10n.playerTrackCountFiltered(_displayTracks.length, _tracks.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.playerSearchHint,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _tracks.isEmpty
                    ? Center(
                        child: Text(
                          l10n.playerNoPreviewSongs,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : _displayTracks.isEmpty
                        ? Center(
                            child: Text(
                              l10n.playerNoTracksMatch(_searchQuery),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _displayTracks.length,
                            itemBuilder: (context, i) {
                              final (originalIndex, track) = _displayTracks[i];
                              final isPlaying = originalIndex == _currentIndex;
                              final isPreviewing = originalIndex == _selectedIndex;
                              final resolvedPath = _resolvedPath(track)!;
                              return Draggable<MusicProject>(
                                data: track,
                                feedback: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: _sidebarWidth - 32,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: cs.surface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.music_note, size: 16,
                                            color: cs.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            track.displayName,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.4,
                                  child: ListTile(
                                    dense: true,
                                    selected: isPlaying || isPreviewing,
                                    selectedTileColor:
                                        cs.primary.withValues(alpha: 0.1),
                                    leading: Icon(Icons.music_note, size: 18,
                                        color: isPlaying ? cs.primary : null),
                                    title: Text(track.displayName,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                                child: GestureDetector(
                                  onTapDown: (_) {
                                    final now = DateTime.now();
                                    final isDouble = _lastTapKey == originalIndex &&
                                        _lastTapTime != null &&
                                        now.difference(_lastTapTime!) <
                                            const Duration(milliseconds: 350);
                                    _lastTapTime = isDouble ? null : now;
                                    _lastTapKey = originalIndex;
                                    if (isDouble) {
                                      setState(() {
                                        _playlist.clear();
                                        _playlist.add(track);
                                        _playlistIndex = 0;
                                        _playingFromPlaylist = true;
                                      });
                                      _selectTrack(originalIndex,
                                          keepPlaylistState: true);
                                    } else {
                                      setState(() {
                                        _selectedIndex = originalIndex;
                                        _addTodoController.clear();
                                      });
                                    }
                                  },
                                  onSecondaryTapUp: (details) =>
                                      _showTrackContextMenu(
                                          context,
                                          details.globalPosition,
                                          track,
                                          originalIndex),
                                  child: ListTile(
                                    dense: true,
                                    selected: isPlaying || isPreviewing,
                                    selectedTileColor: isPlaying
                                        ? cs.primary.withValues(alpha: 0.12)
                                        : cs.secondary.withValues(alpha: 0.08),
                                    leading: Icon(
                                      isPlaying
                                          ? Icons.volume_up
                                          : Icons.music_note,
                                      size: 18,
                                      color: isPlaying
                                          ? cs.primary
                                          : (isPreviewing ? cs.secondary : null),
                                    ),
                                    title: Text(
                                      track.displayName,
                                      style: TextStyle(
                                        fontWeight:
                                            isPlaying ? FontWeight.w600 : null,
                                        color: isPlaying ? cs.primary : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      p.basename(resolvedPath),
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: cs.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        // ── Sidebar resize handle ─────────────────────────────────────────
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) {
              setState(() {
                _sidebarWidth = (_sidebarWidth + d.delta.dx).clamp(180.0, 520.0);
              });
            },
            child: Container(
              width: 5,
              color: Colors.transparent,
              child: const VerticalDivider(width: 1),
            ),
          ),
        ),
        // ── Middle: project detail or hint ──────────────────────────────
        if (_selectedIndex >= 0 && _selectedIndex < _tracks.length)
          Expanded(child: _buildProjectDetail(context, _tracks[_selectedIndex]))
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.queue_music, size: 48,
                      color: cs.onSurface.withValues(alpha: 0.15)),
                  const SizedBox(height: 12),
                  Text(l10n.playerDoubleClickToPlay,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.35),
                      )),
                  const SizedBox(height: 6),
                  Text(l10n.playerSingleClickToPreview,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.25),
                      )),
                ],
              ),
            ),
          ),
        // ── Right: queue (always visible) ───────────────────────────────
        Container(width: 1, color: theme.dividerColor),
        SizedBox(width: 280, child: _buildPlaylistPanel(context)),
      ],
    );
  }

  Color _phaseColor(String status) => switch (status) {
        'Idea'       => Colors.blue.shade300,
        'Arranging'  => Colors.orange.shade300,
        'Mixing'     => Colors.purple.shade300,
        'Mastering'  => Colors.pink.shade300,
        'Finished'   => Colors.green.shade300,
        _            => Colors.grey,
      };

  Widget _buildProjectDetail(BuildContext context, MusicProject project) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final phaseColor = _phaseColor(project.status);
    final pending = project.todos.where((t) => !t.completed).toList();
    final done    = project.todos.where((t) =>  t.completed).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 9, height: 9,
                  decoration: BoxDecoration(
                    color: phaseColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    project.displayName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                _Chip(label: project.status, color: phaseColor),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  tooltip: l10n.playerGoToProject,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ProjectDetailPage(projectId: project.id),
                  )),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  tooltip: l10n.playerDismissDetail,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _selectedIndex = -1),
                ),
              ],
            ),
          ),
          // ── Meta row (BPM · Key · Deadline) ─────────────────────────────
          if (project.bpm != null || project.musicalKey != null || project.deadline != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (project.bpm != null)
                    _Chip(
                      label: '${project.bpm!.toStringAsFixed(project.bpm! == project.bpm!.roundToDouble() ? 0 : 1)} BPM',
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  if (project.musicalKey != null)
                    _Chip(
                      label: project.musicalKey!,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  if (project.deadline != null)
                    _Chip(
                      label: project.deadlineStatus ?? '',
                      color: (project.daysUntilDeadline != null && project.daysUntilDeadline! < 0)
                          ? Colors.red.shade300
                          : cs.onSurface.withValues(alpha: 0.5),
                    ),
                ],
              ),
            ),
          const Divider(height: 1),
          // ── Scrollable body ──────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                // Notes
                if (project.notes != null && project.notes!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                    child: Text(l10n.playerNotes,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          letterSpacing: 0.8,
                        )),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Text(
                      project.notes!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const Divider(height: 1),
                ],
                // Tasks header
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: Row(children: [
                    Text(l10n.playerTasks,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          letterSpacing: 0.8,
                        )),
                    const SizedBox(width: 6),
                    if (pending.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${pending.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            )),
                      ),
                  ]),
                ),
                if (project.todos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Text(l10n.playerNoTasks,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.4),
                        )),
                  )
                else ...[
                  ...pending.map((todo) => _DetailTodoItem(
                        project: project,
                        todo: todo,
                        onToggled: () => setState(() {}),
                      )),
                  if (done.isNotEmpty)
                    ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                      title: Text(
                        l10n.playerCompletedTasks(done.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                      children: done.map((todo) => _DetailTodoItem(
                            project: project,
                            todo: todo,
                            onToggled: () => setState(() {}),
                          )).toList(),
                    ),
                ],
                // Add task input
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addTodoController,
                          style: theme.textTheme.bodySmall,
                          decoration: InputDecoration(
                            hintText: l10n.playerAddTaskHint,
                            hintStyle: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.35),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: cs.onSurface.withValues(alpha: 0.2)),
                            ),
                          ),
                          onSubmitted: (v) => _addTodo(project, v),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        visualDensity: VisualDensity.compact,
                        tooltip: l10n.playerAddTaskHint,
                        onPressed: () => _addTodo(project, _addTodoController.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DragTarget<MusicProject>(
      onAcceptWithDetails: (details) {
        final track = details.data;
        if (!_playlist.any((t) => t.id == track.id)) {
          setState(() => _playlist.add(track));
        }
      },
      builder: (context, candidateData, _) {
        final isDraggingOver = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isDraggingOver ? cs.primary : theme.dividerColor,
              ),
            ),
            color: isDraggingOver ? cs.primary.withValues(alpha: 0.05) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
                child: Row(
                  children: [
                    Icon(Icons.queue_music, size: 16, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(l10n.playerQueueTitle,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Text(
                      '${_playlist.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const Spacer(),
                    if (_playlist.isNotEmpty) ...[
                      IconButton(
                        icon: const Icon(Icons.skip_previous, size: 18),
                        tooltip: l10n.playerPrev,
                        visualDensity: VisualDensity.compact,
                        onPressed: _playPrev,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, size: 18),
                        tooltip: l10n.playerNext,
                        visualDensity: VisualDensity.compact,
                        onPressed: _playNext,
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear_all, size: 18),
                        tooltip: l10n.playerClearQueue,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() {
                          _playlist.clear();
                          _playlistIndex = -1;
                          _playingFromPlaylist = false;
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _playlist.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.queue_music, size: 40,
                                  color: cs.onSurface.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              Text(
                                l10n.playerQueueEmptyHint,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ReorderableListView.builder(
                        itemCount: _playlist.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = _playlist.removeAt(oldIndex);
                            _playlist.insert(newIndex, item);
                            if (_playlistIndex == oldIndex) {
                              _playlistIndex = newIndex;
                            } else if (oldIndex < _playlistIndex &&
                                newIndex >= _playlistIndex) {
                              _playlistIndex--;
                            } else if (oldIndex > _playlistIndex &&
                                newIndex <= _playlistIndex) {
                              _playlistIndex++;
                            }
                          });
                        },
                        itemBuilder: (context, i) {
                          final track = _playlist[i];
                          final isActive =
                              _playingFromPlaylist && i == _playlistIndex;
                          final resolvedPath = _resolvedPath(track);
                          return GestureDetector(
                            key: ValueKey(track.id),
                            onTapDown: (_) {
                              final key = ~i; // negative namespace for queue items
                              final now = DateTime.now();
                              final isDouble = _lastTapKey == key &&
                                  _lastTapTime != null &&
                                  now.difference(_lastTapTime!) <
                                      const Duration(milliseconds: 350);
                              _lastTapTime = isDouble ? null : now;
                              _lastTapKey = key;
                              if (isDouble) {
                                if (resolvedPath != null) _selectFromPlaylist(i);
                              } else {
                                final idx = _tracks.indexWhere((t) => t.id == track.id);
                                if (idx >= 0) {
                                  setState(() {
                                    _selectedIndex = idx;
                                    _addTodoController.clear();
                                  });
                                }
                              }
                            },
                            onSecondaryTapUp: (details) {
                              final RenderBox overlay = Overlay.of(context)
                                  .context
                                  .findRenderObject()! as RenderBox;
                              final navigator = Navigator.of(context);
                              showMenu<String>(
                                context: context,
                                position: RelativeRect.fromRect(
                                  details.globalPosition & const Size(1, 1),
                                  Offset.zero & overlay.size,
                                ),
                                items: [
                                  PopupMenuItem(
                                    value: 'detail',
                                    child: Row(children: [
                                      const Icon(Icons.open_in_new, size: 16),
                                      const SizedBox(width: 10),
                                      Text(l10n.playerGoToProject),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'remove',
                                    child: Row(children: [
                                      const Icon(Icons.remove_circle_outline,
                                          size: 16),
                                      const SizedBox(width: 10),
                                      Text(l10n.playerRemoveFromQueue),
                                    ]),
                                  ),
                                ],
                              ).then((value) {
                                if (!mounted) return;
                                if (value == 'detail') {
                                  navigator.push(MaterialPageRoute(
                                    builder: (_) =>
                                        ProjectDetailPage(projectId: track.id),
                                  ));
                                } else if (value == 'remove') {
                                  setState(() {
                                    _playlist.removeAt(i);
                                    if (_playlistIndex >= _playlist.length) {
                                      _playlistIndex = _playlist.length - 1;
                                    }
                                  });
                                }
                              });
                            },
                            child: ListTile(
                              dense: true,
                              selected: isActive,
                              selectedTileColor:
                                  cs.primary.withValues(alpha: 0.1),
                              leading: Icon(
                                isActive ? Icons.volume_up : Icons.music_note,
                                size: 16,
                                color: isActive
                                    ? cs.primary
                                    : cs.onSurface.withValues(alpha: 0.4),
                              ),
                              title: Text(
                                track.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isActive ? FontWeight.w600 : null,
                                  color: isActive ? cs.primary : null,
                                ),
                              ),
                              subtitle: Text(
                                p.basename(resolvedPath ?? ''),
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 14),
                                visualDensity: VisualDensity.compact,
                                onPressed: () => setState(() {
                                  _playlist.removeAt(i);
                                  if (_playlistIndex >= _playlist.length) {
                                    _playlistIndex = _playlist.length - 1;
                                  }
                                }),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DetailTodoItem extends ConsumerWidget {
  const _DetailTodoItem({
    required this.project,
    required this.todo,
    required this.onToggled,
  });
  final MusicProject project;
  final TodoItem todo;
  final VoidCallback onToggled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      controlAffinity: ListTileControlAffinity.leading,
      value: todo.completed,
      title: Text(
        todo.text,
        style: TextStyle(
          fontSize: 13,
          decoration: todo.completed ? TextDecoration.lineThrough : null,
          color: todo.completed
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
              : null,
        ),
      ),
      onChanged: (_) async {
        final repo = await ref.read(repositoryProvider.future);
        final updated = project.copyWith(
          todos: project.todos.map((t) {
            if (t.id == todo.id) {
              return t.copyWith(completed: !t.completed);
            }
            return t;
          }).toList(),
        );
        await repo.updateProject(updated);
        ref.invalidate(allProjectsStreamProvider);
        onToggled();
      },
    );
  }
}
