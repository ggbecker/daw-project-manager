import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;
import '../models/playlist.dart';
import '../models/music_project.dart';
import '../providers/providers.dart';
import '../utils/mobile_utils.dart';
import '../generated/l10n/app_localizations.dart';

/// Playlists page - Android only
/// Allows creating playlists with preview songs and playing them in sequence
class PlaylistsPage extends ConsumerStatefulWidget {
  const PlaylistsPage({super.key});

  @override
  ConsumerState<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends ConsumerState<PlaylistsPage> {
  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      // Desktop: show message that playlists are Android-only
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.playlists),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)!.playlistsDesktopOnly),
        ),
      );
    }

    final playlistsAsync = ref.watch(playlistsProvider);
    final projectsAsync = ref.watch(allProjectsStreamProvider);

    return Scaffold(
      body: playlistsAsync.when(
        data: (playlists) => projectsAsync.when(
          data: (allProjects) => _buildPlaylistsList(context, playlists, allProjects),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text(AppLocalizations.of(context)!.errorLoadingProjects),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(AppLocalizations.of(context)!.errorLoadingPlaylists),
        ),
      ),
      floatingActionButton: Platform.isAndroid
          ? FloatingActionButton(
              onPressed: () => _showCreatePlaylistDialog(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildPlaylistsList(
    BuildContext context,
    List<Playlist> playlists,
    List<MusicProject> allProjects,
  ) {
    // Apply search filter
    final searchQuery = ref.watch(playlistsSearchProvider);
    if (searchQuery.trim().isNotEmpty) {
      final needle = searchQuery.toLowerCase();
      playlists = playlists.where((p) => p.name.toLowerCase().contains(needle)).toList();
    }

    if (playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.trim().isNotEmpty ? Icons.search_off : Icons.playlist_add,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.trim().isNotEmpty
                  ? AppLocalizations.of(context)!.noPlaylistsFound
                  : AppLocalizations.of(context)!.noPlaylistsYet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.trim().isNotEmpty
                  ? AppLocalizations.of(context)!.tryDifferentSearch
                  : AppLocalizations.of(context)!.createFirstPlaylist,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        // Get projects that have preview songs
        final playlistProjects = playlist.projectIds
            .map((id) {
              try {
                return allProjects.firstWhere((p) => p.id == id);
              } catch (_) {
                return null;
              }
            })
            .where((project) =>
                project != null &&
                project!.previewSongPath != null &&
                project.previewSongPath!.isNotEmpty &&
                !project.previewSongPath!.startsWith('drive://'))
            .cast<MusicProject>()
            .toList();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.playlist_play),
            title: Text(playlist.name),
            subtitle: Text(
              AppLocalizations.of(context)!.playlistSongCount(playlistProjects.length),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditPlaylistDialog(context, ref, playlist, allProjects);
                } else if (value == 'delete') {
                  _showDeletePlaylistDialog(context, ref, playlist);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.edit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.delete,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              // Open playlist player
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaylistPlayerPage(playlist: playlist),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showCreatePlaylistDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final projectsAsync = ref.read(allProjectsStreamProvider);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.createPlaylist),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.playlistName,
                hintText: AppLocalizations.of(context)!.playlistNameHint,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.playlistNameRequired),
                  ),
                );
                return;
              }

              final repo = await ref.read(repositoryProvider.future);
              await repo.createPlaylist(name);
              
              // Invalidate provider to refresh the UI
              ref.invalidate(playlistsProvider);
              
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                // Open edit dialog to add songs
                projectsAsync.whenData((allProjects) {
                  final playlist = repo.getPlaylistById(
                    repo.getAllPlaylists().firstWhere((p) => p.name == name).id,
                  );
                  if (playlist != null) {
                    _showEditPlaylistDialog(context, ref, playlist, allProjects);
                  }
                });
              }
            },
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditPlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
    List<MusicProject> allProjects,
  ) async {
    final nameController = TextEditingController(text: playlist.name);
    // List of project IDs in order
    final orderedProjectIds = List<String>.from(playlist.projectIds);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.editPlaylist,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.playlistName,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.playlistItems,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          // Show dialog to add items
                          await _showAddItemsDialog(
                            context,
                            ref,
                            allProjects,
                            orderedProjectIds,
                            setDialogState,
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: Text(AppLocalizations.of(context)!.addSongs),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    itemCount: orderedProjectIds.length,
                    onReorder: (oldIndex, newIndex) {
                      setDialogState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final projectId = orderedProjectIds.removeAt(oldIndex);
                        orderedProjectIds.insert(newIndex, projectId);
                      });
                    },
                    itemBuilder: (context, index) {
                      final projectId = orderedProjectIds[index];
                      final project = allProjects.firstWhere(
                        (p) => p.id == projectId,
                        orElse: () => allProjects.first,
                      );
                      
                      return ListTile(
                        key: ValueKey(projectId),
                        leading: const Icon(Icons.library_music),
                        title: Text(project.displayName),
                        subtitle: project.previewSongFileName != null
                            ? Text(project.previewSongFileName!)
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setDialogState(() {
                              orderedProjectIds.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.playlistNameRequired),
                              ),
                            );
                            return;
                          }

                          final repo = await ref.read(repositoryProvider.future);
                          final updated = playlist.copyWith(
                            name: name,
                            projectIds: orderedProjectIds,
                            audioFilePaths: const [], // No external files
                          );
                          await repo.updatePlaylist(updated);
                          
                          // Invalidate provider to refresh the UI
                          ref.invalidate(playlistsProvider);
                          
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                        child: Text(AppLocalizations.of(context)!.save),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddItemsDialog(
    BuildContext context,
    WidgetRef ref,
    List<MusicProject> allProjects,
    List<String> orderedProjectIds,
    StateSetter setDialogState,
  ) async {
    final selectedProjectIds = <String>{};
    final searchController = TextEditingController();
    String searchQuery = '';
    
    // Get already added project IDs
    final existingProjectIds = orderedProjectIds.toSet();

    // Filter available projects (those with preview songs and not already in playlist)
    List<MusicProject> getFilteredProjects() {
      return allProjects
          .where((project) =>
              project.previewSongPath != null &&
              project.previewSongPath!.isNotEmpty &&
              !project.previewSongPath!.startsWith('drive://') &&
              !existingProjectIds.contains(project.id) &&
              (searchQuery.isEmpty ||
                  project.displayName.toLowerCase().contains(searchQuery.toLowerCase())))
          .toList();
    }

    // Check if there are any available projects before showing dialog
    final availableProjectsCheck = getFilteredProjects();
    if (availableProjectsCheck.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noProjectsAvailableForPlaylist),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    await showDialog(
      context: context,
      builder: (addDialogContext) => StatefulBuilder(
        builder: (context, setAddDialogState) {
          final availableProjects = getFilteredProjects();
          
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.addSongs),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search field
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.search,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setAddDialogState(() {
                                    searchController.clear();
                                    searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setAddDialogState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.selectFromProjects,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableProjects.length,
                        itemBuilder: (context, index) {
                          final project = availableProjects[index];
                          final isSelected = selectedProjectIds.contains(project.id);
                          return CheckboxListTile(
                            title: Text(project.displayName),
                            subtitle: project.previewSongFileName != null
                                ? Text(project.previewSongFileName!)
                                : null,
                            value: isSelected,
                            onChanged: (value) {
                              setAddDialogState(() {
                                if (value == true) {
                                  selectedProjectIds.add(project.id);
                                } else {
                                  selectedProjectIds.remove(project.id);
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(addDialogContext),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              FilledButton(
                onPressed: () {
                  setDialogState(() {
                    // Add selected projects to the end of the list
                    orderedProjectIds.addAll(selectedProjectIds);
                  });
                  Navigator.pop(addDialogContext);
                },
                child: Text(AppLocalizations.of(context)!.add),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeletePlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deletePlaylist),
        content: Text(
          AppLocalizations.of(context)!.deletePlaylistConfirm(playlist.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = await ref.read(repositoryProvider.future);
      await repo.deletePlaylist(playlist.id);
      
      // Invalidate provider to refresh the UI
      ref.invalidate(playlistsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.playlistDeleted),
          ),
        );
      }
    }
  }
}

/// Playlist player page - plays songs in sequence
class PlaylistPlayerPage extends ConsumerStatefulWidget {
  final Playlist playlist;

  const PlaylistPlayerPage({
    super.key,
    required this.playlist,
  });

  @override
  ConsumerState<PlaylistPlayerPage> createState() => _PlaylistPlayerPageState();
}

// Playlist item - represents a project with preview song
class _PlaylistItem {
  final String projectId;
  final String displayName;
  final String? fileName;
  final String? previewSongPath;

  _PlaylistItem(MusicProject project)
      : projectId = project.id,
        displayName = project.displayName,
        fileName = project.previewSongFileName,
        previewSongPath = project.previewSongPath;
}

class _PlaylistPlayerPageState extends ConsumerState<PlaylistPlayerPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  int _currentIndex = 0;
  List<_PlaylistItem> _playlistItems = [];
  bool _isLoading = true;
  late Playlist _currentPlaylist;

  @override
  void initState() {
    super.initState();
    _currentPlaylist = widget.playlist;
    _initAudioPlayer();
    _loadPlaylistItems();
  }

  void _initAudioPlayer() {
    // Listen to player state
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Listen to completion
    _audioPlayer.onPlayerComplete.listen((_) {
      _playNext();
    });
  }

  Future<void> _reloadPlaylist() async {
    try {
      final repo = await ref.read(repositoryProvider.future);
      final playlistsAsync = ref.read(playlistsProvider);
      await playlistsAsync.whenData((playlists) {
        final updatedPlaylist = playlists.firstWhere(
          (p) => p.id == widget.playlist.id,
          orElse: () => widget.playlist,
        );
        if (mounted) {
          setState(() {
            _currentPlaylist = updatedPlaylist;
          });
        }
      });
    } catch (e) {
      // If reload fails, keep current playlist
    }
  }

  Future<void> _loadPlaylistItems() async {
    final projectsAsync = ref.read(allProjectsStreamProvider);
    projectsAsync.whenData((allProjects) {
      final items = <_PlaylistItem>[];

      // Add projects in order using current playlist state
      for (final projectId in _currentPlaylist.projectIds) {
        try {
          final project = allProjects.firstWhere((p) => p.id == projectId);
          if (project.previewSongPath != null &&
              project.previewSongPath!.isNotEmpty &&
              !project.previewSongPath!.startsWith('drive://')) {
            items.add(_PlaylistItem(project));
          }
        } catch (_) {
          // Project not found, skip
        }
      }

      if (mounted) {
        setState(() {
          _playlistItems = items;
          _isLoading = false;
        });
        // Do NOT autoplay - user must click a song
      }
    });
  }

  Future<void> _playCurrentSong() async {
    if (_playlistItems.isEmpty || _currentIndex < 0 || _currentIndex >= _playlistItems.length) {
      return;
    }

    final item = _playlistItems[_currentIndex];
    if (item.previewSongPath == null || item.previewSongPath!.isEmpty) {
      return;
    }

    final file = File(item.previewSongPath!);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio file not found')),
        );
      }
      return;
    }

    try {
      await _audioPlayer.play(DeviceFileSource(item.previewSongPath!));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  Future<void> _playNext() async {
    if (_currentIndex < _playlistItems.length - 1) {
      setState(() {
        _currentIndex++;
      });
      await _playCurrentSong();
    }
  }

  Future<void> _playPrevious() async {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      await _playCurrentSong();
    }
  }

  Future<void> _savePlaylistOrder() async {
    // Save the new order to the playlist
    final repo = await ref.read(repositoryProvider.future);
    final projectIds = _playlistItems.map((item) => item.projectId).toList();
    final updated = _currentPlaylist.copyWith(
      projectIds: projectIds,
      audioFilePaths: const [], // No external files
    );
    await repo.updatePlaylist(updated);
    // Update current playlist state
    _currentPlaylist = updated;
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_position == Duration.zero && _playlistItems.isNotEmpty) {
        // Start playing from current index
        await _playCurrentSong();
      } else {
        // Resume playback
        await _audioPlayer.resume();
      }
    }
  }

  Future<void> _stop() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _position = Duration.zero;
      _currentIndex = 0;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_currentPlaylist.name),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_playlistItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_currentPlaylist.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: AppLocalizations.of(context)!.edit,
              onPressed: () async {
                final projectsAsync = ref.read(allProjectsStreamProvider);
                final allProjectsValue = projectsAsync.value;
                
                // Check if projects failed to load
                if (allProjectsValue == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.errorLoadingProjects),
                      ),
                    );
                  }
                  return;
                }
                
                // Check if there are no projects in database at all
                if (allProjectsValue.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.noProjectsInDatabase),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                  return;
                }

                // Check if there are any projects with preview songs available
                final projectsWithPreview = allProjectsValue.where((project) =>
                  project.previewSongPath != null &&
                  project.previewSongPath!.isNotEmpty &&
                  !project.previewSongPath!.startsWith('drive://')
                ).toList();
                
                if (projectsWithPreview.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.noProjectsAvailableForPlaylist),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                  return;
                }

                if (mounted) {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _EditPlaylistRoute(
                        playlist: _currentPlaylist,
                        allProjects: allProjectsValue,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    // Reload playlist from database first, then reload items
                    await _reloadPlaylist();
                    _loadPlaylistItems();
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: AppLocalizations.of(context)!.delete,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: Theme.of(context).cardColor,
                    title: Text(AppLocalizations.of(context)!.deletePlaylist),
                    content: Text(AppLocalizations.of(context)!.deletePlaylistConfirm(_currentPlaylist.name)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: Text(AppLocalizations.of(context)!.delete),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    final repo = await ref.read(repositoryProvider.future);
                    await repo.deletePlaylist(widget.playlist.id);
                    
                    // Invalidate provider to refresh the UI
                    ref.invalidate(playlistsProvider);
                    
                    if (mounted) {
                      Navigator.of(context).pop(); // Close player page
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.playlistDeleted),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.errorDeletingPlaylist),
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_off,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.noPreviewSongsInPlaylist,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.tapEditToAddSongs,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final currentItem = _playlistItems[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentPlaylist.name),
            Text(
              AppLocalizations.of(context)!.playlistProgress(
                _currentIndex + 1,
                _playlistItems.length,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: AppLocalizations.of(context)!.edit,
            onPressed: () async {
              final projectsAsync = ref.read(allProjectsStreamProvider);
              final allProjectsValue = projectsAsync.value;
              
              // Check if projects failed to load
              if (allProjectsValue == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.errorLoadingProjects),
                  ),
                );
                return;
              }
              
              // Check if there are no projects in database at all
              if (allProjectsValue.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.noProjectsInDatabase),
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }
              
              if (mounted) {
                // Stop playback before editing
                if (_isPlaying) {
                  await _audioPlayer.pause();
                }
                
                // Navigate to main playlist page's edit dialog
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _EditPlaylistRoute(
                      playlist: _currentPlaylist,
                      allProjects: allProjectsValue,
                    ),
                  ),
                );
                
                // Reload playlist from database first, then reload items if edited
                if (result == true) {
                  await _reloadPlaylist();
                  _loadPlaylistItems();
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: AppLocalizations.of(context)!.delete,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.deletePlaylist),
                  content: Text(
                    AppLocalizations.of(context)!.deletePlaylistConfirm(_currentPlaylist.name),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final repo = await ref.read(repositoryProvider.future);
                await repo.deletePlaylist(widget.playlist.id);
                
                // Invalidate provider to refresh the UI
                ref.invalidate(playlistsProvider);
                
                if (mounted) {
                  Navigator.of(context).pop(); // Go back to playlists page
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.playlistDeleted),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Current song info
          Card(
            margin: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.library_music),
              title: Text(currentItem.displayName),
              subtitle: Text(currentItem.fileName ?? ''),
            ),
          ),
          // Playback controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Progress bar
                Slider(
                  value: _duration.inMilliseconds > 0
                      ? _position.inMilliseconds / _duration.inMilliseconds
                      : 0.0,
                  onChanged: (value) async {
                    final newPosition = Duration(
                      milliseconds: (value * _duration.inMilliseconds).round(),
                    );
                    await _audioPlayer.seek(newPosition);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(_position)),
                    Text(_formatDuration(_duration)),
                  ],
                ),
                const SizedBox(height: 16),
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: _currentIndex > 0 ? _playPrevious : null,
                      iconSize: 32,
                    ),
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: _togglePlayPause,
                      iconSize: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed:
                          _currentIndex < _playlistItems.length - 1
                              ? _playNext
                              : null,
                      iconSize: 32,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: _isPlaying || _position > Duration.zero
                          ? _stop
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Playlist queue - reorderable
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _playlistItems.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _playlistItems.removeAt(oldIndex);
                  _playlistItems.insert(newIndex, item);
                  
                  // Update current index if needed
                  if (_currentIndex == oldIndex) {
                    _currentIndex = newIndex;
                  } else if (_currentIndex > oldIndex && _currentIndex <= newIndex) {
                    _currentIndex -= 1;
                  } else if (_currentIndex < oldIndex && _currentIndex >= newIndex) {
                    _currentIndex += 1;
                  }
                  
                  // Save the new order to the playlist
                  _savePlaylistOrder();
                });
              },
              itemBuilder: (context, index) {
                final item = _playlistItems[index];
                final isCurrent = index == _currentIndex;
                return ListTile(
                  key: ValueKey(item.projectId),
                  leading: isCurrent
                      ? const Icon(Icons.play_arrow, color: Colors.blue)
                      : Text('${index + 1}'),
                  title: Text(item.displayName),
                  subtitle: item.fileName != null ? Text(item.fileName!) : null,
                  trailing: const Icon(Icons.library_music),
                  selected: isCurrent,
                  onTap: () async {
                    // If something is playing, ask for confirmation
                    if (_isPlaying && index != _currentIndex) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(AppLocalizations.of(context)!.changeSong),
                          content: Text(AppLocalizations.of(context)!.changeSongConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext, false),
                              child: Text(AppLocalizations.of(context)!.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(dialogContext, true),
                              child: Text(AppLocalizations.of(context)!.changeSongButton),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmed != true) return;
                    }
                    
                    // Play the selected song
                    setState(() {
                      _currentIndex = index;
                      _position = Duration.zero;
                    });
                    _playCurrentSong();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper route to edit playlist from player page
class _EditPlaylistRoute extends ConsumerWidget {
  final Playlist playlist;
  final List<MusicProject> allProjects;

  const _EditPlaylistRoute({
    required this.playlist,
    required this.allProjects,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editPlaylist),
      ),
      body: _EditPlaylistForm(
        playlist: playlist,
        allProjects: allProjects,
      ),
    );
  }
}

/// Edit playlist form widget
class _EditPlaylistForm extends ConsumerStatefulWidget {
  final Playlist playlist;
  final List<MusicProject> allProjects;

  const _EditPlaylistForm({
    required this.playlist,
    required this.allProjects,
  });

  @override
  ConsumerState<_EditPlaylistForm> createState() => _EditPlaylistFormState();
}

class _EditPlaylistFormState extends ConsumerState<_EditPlaylistForm> {
  late TextEditingController _nameController;
  late List<String> _orderedProjectIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist.name);
    _orderedProjectIds = List<String>.from(widget.playlist.projectIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showAddItemsDialog() async {
    final selectedProjectIds = <String>{};
    final searchController = TextEditingController();
    String searchQuery = '';
    
    // Get already added project IDs
    final existingProjectIds = _orderedProjectIds.toSet();

    // Filter available projects
    List<MusicProject> getFilteredProjects() {
      return widget.allProjects
          .where((project) =>
              project.previewSongPath != null &&
              project.previewSongPath!.isNotEmpty &&
              !project.previewSongPath!.startsWith('drive://') &&
              !existingProjectIds.contains(project.id) &&
              (searchQuery.isEmpty ||
                  project.displayName.toLowerCase().contains(searchQuery.toLowerCase())))
          .toList();
    }

    // Check if there are any available projects before showing dialog
    final availableProjectsCheck = getFilteredProjects();
    if (availableProjectsCheck.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noProjectsAvailableForPlaylist),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    await showDialog(
      context: context,
      builder: (addDialogContext) => StatefulBuilder(
        builder: (context, setAddDialogState) {
          final availableProjects = getFilteredProjects();
          
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.addSongs),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search field
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.search,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setAddDialogState(() {
                                    searchController.clear();
                                    searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setAddDialogState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.selectFromProjects,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableProjects.length,
                        itemBuilder: (context, index) {
                          final project = availableProjects[index];
                          final isSelected = selectedProjectIds.contains(project.id);
                          return CheckboxListTile(
                            title: Text(project.displayName),
                            subtitle: project.previewSongFileName != null
                                ? Text(project.previewSongFileName!)
                                : null,
                            value: isSelected,
                            onChanged: (value) {
                              setAddDialogState(() {
                                if (value == true) {
                                  selectedProjectIds.add(project.id);
                                } else {
                                  selectedProjectIds.remove(project.id);
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(addDialogContext),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _orderedProjectIds.addAll(selectedProjectIds);
                  });
                  Navigator.pop(addDialogContext);
                },
                child: Text(AppLocalizations.of(context)!.add),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.playlistName,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.playlistItems,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: _showAddItemsDialog,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.addSongs),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: _orderedProjectIds.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final projectId = _orderedProjectIds.removeAt(oldIndex);
                _orderedProjectIds.insert(newIndex, projectId);
              });
            },
            itemBuilder: (context, index) {
              final projectId = _orderedProjectIds[index];
              final project = widget.allProjects.firstWhere(
                (p) => p.id == projectId,
                orElse: () => widget.allProjects.first,
              );
              
              return ListTile(
                key: ValueKey(projectId),
                leading: const Icon(Icons.library_music),
                title: Text(project.displayName),
                subtitle: project.previewSongFileName != null
                    ? Text(project.previewSongFileName!)
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _orderedProjectIds.removeAt(index);
                    });
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.playlistNameRequired),
                      ),
                    );
                    return;
                  }

                  final repo = await ref.read(repositoryProvider.future);
                  final updated = widget.playlist.copyWith(
                    name: name,
                    projectIds: _orderedProjectIds,
                    audioFilePaths: const [],
                  );
                  await repo.updatePlaylist(updated);
                  
                  // Invalidate provider to refresh the UI
                  ref.invalidate(playlistsProvider);
                  
                  if (mounted) {
                    Navigator.pop(context, true); // Return true to signal success
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.playlistUpdated),
                      ),
                    );
                  }
                },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
