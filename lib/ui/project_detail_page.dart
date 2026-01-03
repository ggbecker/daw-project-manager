import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart'; // NOVO IMPORT
import 'package:path/path.dart' as p; // NOVO IMPORT
import 'package:window_manager/window_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:desktop_drop/desktop_drop.dart';

import '../models/music_project.dart';
import '../models/todo_item.dart';
import '../providers/providers.dart';
import '../repository/project_repository.dart';
import '../generated/l10n/app_localizations.dart';
import 'dashboard_page.dart';
import 'widgets/todo_list_widget.dart';

class ProjectDetailPage extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _bpmCtrl;
  late TextEditingController _keyCtrl;
  late TextEditingController _notesCtrl; // NOVO CONTROLLER
  String? _selectedPhase;
  bool _hasInitializedPhase = false; // Track if we've initialized the phase
  bool _extractingMetadata = false; // Track metadata extraction state

  List<String> _getProjectPhases(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.projectPhaseIdea,
      l10n.projectPhaseArranging,
      l10n.projectPhaseMixing,
      l10n.projectPhaseMastering,
      l10n.projectPhaseFinished,
    ];
  }

  String _translateStatusToEnglish(String localizedStatus) {
    // Map localized status back to English for storage
    final l10n = AppLocalizations.of(context)!;
    if (localizedStatus == l10n.projectPhaseIdea) return 'Idea';
    if (localizedStatus == l10n.projectPhaseArranging) return 'Arranging';
    if (localizedStatus == l10n.projectPhaseMixing) return 'Mixing';
    if (localizedStatus == l10n.projectPhaseMastering) return 'Mastering';
    if (localizedStatus == l10n.projectPhaseFinished) return 'Finished';
    return localizedStatus; // Fallback
  }

  String _translateStatusFromEnglish(String englishStatus) {
    // Map English status to localized for display
    final l10n = AppLocalizations.of(context)!;
    switch (englishStatus) {
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
        return englishStatus;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bpmCtrl = TextEditingController();
    _keyCtrl = TextEditingController();
    _notesCtrl = TextEditingController(); // INICIALIZA
    // Initialize with default phase - will be set in build method
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bpmCtrl.dispose();
    _keyCtrl.dispose();
    _notesCtrl.dispose(); // DISPOSE
    super.dispose();
  }

  // NOVO: Função para abrir o diretório pai
  Future<void> _openProjectFolder(String filePath) async {
    // Determina o caminho da pasta: Se for um arquivo, pega o diretório pai. Se for um diretório, pega ele mesmo.
    final folderPath =
        (FileSystemEntity.typeSync(filePath) == FileSystemEntityType.file)
        ? p.dirname(filePath)
        : filePath;

    final Uri uri = Uri.directory(folderPath);

    try {
      if (await launchUrl(uri)) {
        return;
      }
    } catch (_) {
      // Tenta métodos nativos como fallback se o launchUrl falhar
    }

    try {
      if (Platform.isWindows) {
        await Process.run('explorer', [folderPath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [folderPath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [folderPath]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.couldNotOpenFolder(e.toString()),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(repositoryProvider);
    final allProjectsAsync = ref.watch(allProjectsStreamProvider);

    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          // Window title bar
          if (!kDebugMode)
            GestureDetector(
              onPanStart: (_) => windowManager.startDragging(),
              onDoubleTap: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.restore();
                } else {
                  windowManager.maximize();
                }
              },
              child: Container(
                color: Theme.of(context).cardColor,
                height: 40,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                      tooltip: AppLocalizations.of(context)!.back,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        AppLocalizations.of(context)!.projectDetails,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.titleMedium?.color,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const WindowButtons(),
                  ],
                ),
              ),
            ),
          Expanded(
            child: repoAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(AppLocalizations.of(context)!.failedToLoad),
              ),
              data: (repo) {
                // Use projects from stream to get latest data, fallback to repo if stream not ready
                // The stream should automatically update when Hive emits changes
                // Use whenData to properly observe the stream
                return allProjectsAsync.when(
                  data: (allProjects) {
                    final project = allProjects.firstWhere(
                      (p) => p.id == widget.projectId,
                    );
                    return _buildProjectContent(repo, project, allProjectsAsync);
                  },
                  loading: () {
                    // Fallback to repo if stream is loading
                    final allProjects = repo.getAllProjects();
                    final project = allProjects.firstWhere(
                      (p) => p.id == widget.projectId,
                    );
                    return _buildProjectContent(repo, project, allProjectsAsync);
                  },
                  error: (_, __) {
                    // Fallback to repo if stream has error
                    final allProjects = repo.getAllProjects();
                    final project = allProjects.firstWhere(
                      (p) => p.id == widget.projectId,
                    );
                    return _buildProjectContent(repo, project, allProjectsAsync);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectContent(
    ProjectRepository repo,
    MusicProject project,
    AsyncValue<List<MusicProject>> allProjectsAsync,
  ) {
    // Watch the stream to ensure we get updates when the project changes
    return Consumer(
      builder: (context, ref, child) {
        // Re-read the project from the stream to get the latest value
        final currentProjectsAsync = ref.watch(allProjectsStreamProvider);
        final currentProjects = currentProjectsAsync.value ?? [project];
        final currentProject = currentProjects.firstWhere(
          (p) => p.id == widget.projectId,
          orElse: () => project,
        );
        
        // Use the current project instead of the passed one
        final updatedProject = currentProject;
        
        // Debug: Log when project preview song changes
        if (kDebugMode && updatedProject.previewSongPath != project.previewSongPath) {
          print('Project preview song changed in stream:');
          print('  Old: ${project.previewSongPath}');
          print('  New: ${updatedProject.previewSongPath}');
        }

        // Sincroniza controllers com os dados do projeto
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentName =
              updatedProject.customDisplayName ?? updatedProject.fileName;
                  if (_nameCtrl.text != currentName) {
                    _nameCtrl.text = currentName;
                  }
          if (_bpmCtrl.text != (updatedProject.bpm?.toString() ?? '')) {
            _bpmCtrl.text = updatedProject.bpm?.toString() ?? '';
          }
          if (_keyCtrl.text != (updatedProject.musicalKey ?? '')) {
            _keyCtrl.text = updatedProject.musicalKey ?? '';
          }
          // NOVO: Sincroniza Notas
          if (_notesCtrl.text != (updatedProject.notes ?? '')) {
            _notesCtrl.text = updatedProject.notes ?? '';
          }
          // Sincroniza fase do projeto (only on first load)
          if (!_hasInitializedPhase) {
            final projectStatus = updatedProject.status;
                    // Translate English status to localized for display
                    final localizedStatus = _translateStatusFromEnglish(
                      projectStatus,
                    );
                    if (mounted) {
                      setState(() {
                        _selectedPhase = localizedStatus;
                        _hasInitializedPhase = true;
                      });
                    }
                  }
                });

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text(
                      updatedProject.displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    const SizedBox(height: 8),
                    Text(
                      updatedProject.filePath,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                            ),
                            const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.lastModified(
                        updatedProject.lastModifiedAt.toString(),
                      ),
                    ),
                            const SizedBox(height: 24),

                            // Campo para editar o nome de exibição customizado
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(
                                  context,
                                )!.projectName,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _bpmCtrl,
                                    decoration: InputDecoration(
                                      labelText: AppLocalizations.of(
                                        context,
                                      )!.bpm,
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _keyCtrl,
                                    decoration: InputDecoration(
                                      labelText: AppLocalizations.of(
                                        context,
                                      )!.key,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _extractingMetadata
                                      ? null
                                      : () async {
                                          setState(
                                            () => _extractingMetadata = true,
                                          );
                                          try {
                                            await repo
                                                .extractFullMetadataForProject(
                                                  updatedProject.id,
                                                );
                                            // Refresh the project data
                                            ref.invalidate(
                                              allProjectsStreamProvider,
                                            );
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.metadataExtractedSuccessfully,
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.failedToExtractMetadata(
                                                      e.toString(),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(
                                                () =>
                                                    _extractingMetadata = false,
                                              );
                                            }
                                          }
                                        },
                                  icon: _extractingMetadata
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.search, size: 18),
                                  label: Text(
                                    _extractingMetadata
                                        ? AppLocalizations.of(
                                            context,
                                          )!.extracting
                                        : AppLocalizations.of(context)!.extract,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Project Phase Dropdown
                            DropdownButtonFormField<String>(
                              value:
                                  _selectedPhase ??
                                  _getProjectPhases(context).first,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(
                                  context,
                                )!.projectPhase,
                              ),
                              items: _getProjectPhases(context).map((phase) {
                                return DropdownMenuItem<String>(
                                  value: phase,
                                  child: Text(phase),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPhase = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            // NOVO: CAMPO DE NOTAS
                            TextFormField(
                              controller: _notesCtrl,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.notes,
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                            ),

                            const SizedBox(height: 24),

                            // Preview Song Section
                            _PreviewSongPlayer(
                              key: ValueKey('${updatedProject.id}_${updatedProject.previewSongPath}'),
                              project: updatedProject,
                              onSongRemoved: () async {
                                try {
                                  if (kDebugMode) {
                                    print('Removing preview song from project: ${updatedProject.id}');
                                    print('Current previewSongPath: ${updatedProject.previewSongPath}');
                                  }
                                  
                                  // Create updated project with previewSongPath set to null
                                  // Use clearPreviewSongPath flag to explicitly set it to null
                                  final updated = updatedProject.copyWith(
                                    clearPreviewSongPath: true,
                                    updatedAt: DateTime.now(),
                                  );
                                  
                                  if (kDebugMode) {
                                    print('Updated project previewSongPath: ${updated.previewSongPath}');
                                    print('Updated project updatedAt: ${updated.updatedAt}');
                                  }
                                  
                                  // Update directly in the box to ensure Hive emits the event
                                  await repo.updateProject(updated);
                                  
                                  if (kDebugMode) {
                                    // Verify immediately after update
                                    final verifyProjects = repo.getAllProjects();
                                    final verifyProject = verifyProjects.firstWhere(
                                      (p) => p.id == updatedProject.id,
                                      orElse: () => updatedProject,
                                    );
                                    print('Immediately after update - previewSongPath: ${verifyProject.previewSongPath}');
                                  }
                                  
                                  if (kDebugMode) {
                                    // Verify the update was saved
                                    final verifyProject = repo.getAllProjects().firstWhere(
                                      (p) => p.id == updatedProject.id,
                                      orElse: () => updatedProject,
                                    );
                                    print('After update - previewSongPath in repo: ${verifyProject.previewSongPath}');
                                  }
                                  
                                  if (mounted) {
                                    // The Hive watch should automatically trigger the stream to emit
                                    // The Consumer in _buildProjectContent watches allProjectsStreamProvider
                                    // and will automatically rebuild when the stream emits a new value
                                    // We don't need to invalidate - the stream will update via Hive watch
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.previewSongRemoved,
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (kDebugMode) {
                                    print('Error removing preview song: $e');
                                  }
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error: ${e.toString()}',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              onSongChanged: (filePath) async {
                                final updated = project.copyWith(
                                  previewSongPath: filePath,
                                );
                                await repo.updateProject(updated);
                                if (mounted) {
                                  // Invalidate to refresh the stream
                                  ref.invalidate(allProjectsStreamProvider);
                                  // Wait a bit for the stream to update
                                  await Future.delayed(const Duration(milliseconds: 100));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.previewSongAdded,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),

                            const SizedBox(height: 24),
                            // TODO List
                            TodoListWidget(
                              todos: updatedProject.todos,
                              onTodosChanged: (updatedTodos) async {
                                final updated = updatedProject.copyWith(
                                  todos: updatedTodos,
                                );
                                await repo.updateProject(updated);
                                // Invalidate the projects stream to refresh the UI
                                if (mounted) {
                                  ref.invalidate(allProjectsStreamProvider);
                                }
                              },
                            ),

                            const SizedBox(height: 24),
                            Row(
                              children: [
                                // BOTÃO: SAVE (LÓGICA ATUALIZADA)
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    // O campo name atualiza customDisplayName. Se o texto for vazio ou igual ao nome do arquivo original, ele deve ser null.
                                    final nameText = _nameCtrl.text.trim();
                                    final newCustomDisplayName =
                                        (nameText.isEmpty ||
                                            nameText == updatedProject.fileName)
                                        ? null
                                        : nameText;

                                    final notesText = _notesCtrl.text.trim();
                                    final newNotes = notesText.isEmpty
                                        ? null
                                        : notesText;

                                    final updated = project.copyWith(
                                      customDisplayName: newCustomDisplayName,
                                      bpm: _bpmCtrl.text.trim().isEmpty
                                          ? null
                                          : double.tryParse(
                                              _bpmCtrl.text.trim(),
                                            ),
                                      musicalKey: _keyCtrl.text.trim().isEmpty
                                          ? null
                                          : _keyCtrl.text.trim(),
                                      notes: newNotes, // NOVO: Salva Notas
                                      status: _selectedPhase != null
                                          ? _translateStatusToEnglish(
                                              _selectedPhase!,
                                            )
                                          : 'Idea', // Save project phase
                                    );

                                    await repo.updateProject(updated);
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(context)!.saved,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.save),
                                  label: Text(
                                    AppLocalizations.of(context)!.save,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // NOVO: BOTÃO OPEN FOLDER
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _openProjectFolder(updatedProject.filePath),
                                  icon: const Icon(Icons.folder_open),
                                  label: Text(
                                    AppLocalizations.of(context)!.openFolder,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // BOTÃO OPEN IN DAW (Existente)
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      if (Platform.isMacOS) {
                                        await Process.start('open', [
                                          updatedProject.filePath,
                                        ]);
                                      } else if (Platform.isWindows) {
                                        await Process.start('cmd', [
                                          '/c',
                                          'start',
                                          '',
                                          updatedProject.filePath,
                                        ]);
                                      } else {
                                        await Process.start(
                                          updatedProject.filePath,
                                          [],
                                        );
                                      }
                                    } catch (_) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.failedToLaunchDaw,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.open_in_new),
                                  label: Text(
                                    AppLocalizations.of(context)!.openInDaw,
                                  ),
                                ),
                              ],
                            ),
                  ],
                ),
              ),
            ),
            // Loading overlay
            if (_extractingMetadata)
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
                            'Extracting metadata...',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
    },
    );
  }
}

class _PreviewSongPlayer extends StatefulWidget {
  final MusicProject project;
  final Future<void> Function() onSongRemoved;
  final Future<void> Function(String) onSongChanged;

  const _PreviewSongPlayer({
    super.key,
    required this.project,
    required this.onSongRemoved,
    required this.onSongChanged,
  });

  @override
  State<_PreviewSongPlayer> createState() => _PreviewSongPlayerState();
}

class _TogglePlayPauseIntent extends Intent {
  const _TogglePlayPauseIntent();
}

class _PreviewSongPlayerState extends State<_PreviewSongPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FocusNode _focusNode = FocusNode();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isDraggingOver = false;

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
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_PreviewSongPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If preview song was removed, stop playing and reset state
    if (oldWidget.project.previewSongPath != null &&
        widget.project.previewSongPath == null) {
      _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    }
    // If preview song changed, reset position
    else if (oldWidget.project.previewSongPath != widget.project.previewSongPath) {
      _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (widget.project.previewSongPath == null ||
        widget.project.previewSongPath!.isEmpty) {
      return;
    }

    final file = File(widget.project.previewSongPath!);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.previewSongFileNotFound,
            ),
          ),
        );
      }
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position == Duration.zero || _position >= _duration) {
          await _audioPlayer.play(
            DeviceFileSource(widget.project.previewSongPath!),
          );
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToPlayPreview(e.toString()),
            ),
          ),
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

  bool _isValidAudioFile(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac'].contains(ext);
  }

  Future<void> _handleDroppedFiles(List<String> filePaths) async {
    if (filePaths.isEmpty) {
      if (kDebugMode) {
        print('No file paths provided');
      }
      return;
    }

    if (kDebugMode) {
      print('Dropped files: $filePaths');
    }

    // Use the first valid audio file
    for (final filePath in filePaths) {
      if (kDebugMode) {
        print('Checking file: $filePath');
        print('Is valid audio: ${_isValidAudioFile(filePath)}');
      }

      if (_isValidAudioFile(filePath)) {
        final file = File(filePath);
        final exists = await file.exists();
        if (kDebugMode) {
          print('File exists: $exists');
        }

        if (exists) {
          if (kDebugMode) {
            print('Calling onSongChanged with: $filePath');
          }
          await widget.onSongChanged(filePath);
          return;
        }
      }
    }

    // If no valid audio file was found, show a message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.previewSongFileNotFound),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        setState(() {
          _isDraggingOver = false;
        });
        try {
          if (detail.files.isNotEmpty) {
            if (kDebugMode) {
              print('Files dropped: ${detail.files.length}');
              for (final file in detail.files) {
                print('File: ${file.name}, path: ${file.path}');
              }
            }

            // Extract file paths from dropped files
            final filePaths = <String>[];
            for (final file in detail.files) {
              if (file.path != null && file.path!.isNotEmpty) {
                filePaths.add(file.path!);
              }
            }

            if (filePaths.isNotEmpty) {
              await _handleDroppedFiles(filePaths);
            } else if (kDebugMode) {
              print('No valid file paths found');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error handling dropped files: $e');
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error handling dropped files: ${e.toString()}'),
              ),
            );
          }
        }
      },
      onDragEntered: (detail) {
        setState(() {
          _isDraggingOver = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _isDraggingOver = false;
        });
      },
      child: Card(
        color: _isDraggingOver
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : null,
        child: Container(
          decoration: _isDraggingOver
              ? BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.previewSong,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.project.previewSongPath != null &&
                    widget.project.previewSongPath!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.basename(widget.project.previewSongPath!),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red.shade300,
                            onPressed: () async {
                              // Stop audio if playing
                              await _audioPlayer.stop();
                              setState(() {
                                _isPlaying = false;
                                _position = Duration.zero;
                                _duration = Duration.zero;
                              });
                              await widget.onSongRemoved();
                            },
                            tooltip: AppLocalizations.of(
                              context,
                            )!.removePreviewSong,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Audio player controls with keyboard shortcuts
                      Shortcuts(
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
                            focusNode: _focusNode,
                              child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                  ),
                                  onPressed: () {
                                    _focusNode.requestFocus();
                                    _togglePlayPause();
                                  },
                                  iconSize: 32,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.stop),
                                  onPressed: _isPlaying || _position > Duration.zero
                                      ? _stop
                                      : null,
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
                                          final position = Duration(
                                            milliseconds: value.toInt(),
                                          );
                                          await _audioPlayer.seek(position);
                                        },
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDuration(_position),
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.color,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            _formatDuration(_duration),
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.color,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.noPreviewSongSelected,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (_isDraggingOver)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            AppLocalizations.of(context)!.dropAudioFileHere,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Get the project's directory to start the file picker there
                    final projectDir = p.dirname(widget.project.filePath);

                    // Open file picker - attempt to start in project directory
                    // Note: file_picker package doesn't support initialDirectory parameter directly
                    // On Windows, the file picker may open in the project directory if it's accessible
                    // The user can navigate to the project folder if needed
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: [
                        'mp3',
                        'wav',
                        'm4a',
                        'aac',
                        'ogg',
                        'flac',
                      ],
                      dialogTitle: AppLocalizations.of(
                        context,
                      )!.selectPreviewSong,
                    );
                    if (result != null && result.files.single.path != null) {
                      widget.onSongChanged(result.files.single.path!);
                    }
                  },
                  icon: const Icon(Icons.audio_file),
                  label: Text(
                    widget.project.previewSongPath != null &&
                            widget.project.previewSongPath!.isNotEmpty
                        ? AppLocalizations.of(context)!.changePreviewSong
                        : AppLocalizations.of(context)!.selectPreviewSong,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
