import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart'; // NOVO IMPORT
import 'package:path/path.dart' as p; // NOVO IMPORT
import 'package:window_manager/window_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';

import '../models/music_project.dart';
import '../models/todo_item.dart';
import '../providers/providers.dart';
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
    final folderPath = (FileSystemEntity.typeSync(filePath) == FileSystemEntityType.file) 
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
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenFolder(e.toString()))));
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
                      icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
                      onPressed: () => Navigator.pop(context),
                      tooltip: AppLocalizations.of(context)!.back,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        AppLocalizations.of(context)!.projectDetails,
                        style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color, fontSize: 16),
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
              error: (_, __) => Center(child: Text(AppLocalizations.of(context)!.failedToLoad)),
              data: (repo) {
          // Use projects from stream to get latest data, fallback to repo if stream not ready
          final allProjects = allProjectsAsync.value ?? repo.getAllProjects();
          final project = allProjects.firstWhere((p) => p.id == widget.projectId);

          // Sincroniza controllers com os dados do projeto
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final currentName = project.customDisplayName ?? project.fileName;
            if (_nameCtrl.text != currentName) {
               _nameCtrl.text = currentName;
            }
            if (_bpmCtrl.text != (project.bpm?.toString() ?? '')) {
              _bpmCtrl.text = project.bpm?.toString() ?? '';
            }
            if (_keyCtrl.text != (project.musicalKey ?? '')) {
              _keyCtrl.text = project.musicalKey ?? '';
            }
            // NOVO: Sincroniza Notas
            if (_notesCtrl.text != (project.notes ?? '')) {
              _notesCtrl.text = project.notes ?? '';
            }
            // Sincroniza fase do projeto (only on first load)
            if (!_hasInitializedPhase) {
              final projectStatus = project.status;
              // Translate English status to localized for display
              final localizedStatus = _translateStatusFromEnglish(projectStatus);
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
                      Text(project.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(project.filePath, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.lastModified(project.lastModifiedAt.toString())),
                      const SizedBox(height: 24),
                      
                      // Campo para editar o nome de exibição customizado
                      TextFormField(
                    controller: _nameCtrl,
                        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.projectName),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bpmCtrl,
                          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.bpm),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _keyCtrl,
                          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.key),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _extractingMetadata
                            ? null
                            : () async {
                                  setState(() => _extractingMetadata = true);
                                  try {
                                    await repo.extractFullMetadataForProject(project.id);
                                    // Refresh the project data
                                    ref.invalidate(allProjectsStreamProvider);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(AppLocalizations.of(context)!.metadataExtractedSuccessfully)),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(AppLocalizations.of(context)!.failedToExtractMetadata(e.toString()))),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _extractingMetadata = false);
                                    }
                                  }
                                },
                        icon: _extractingMetadata
                            ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                            : const Icon(Icons.search, size: 18),
                        label: Text(_extractingMetadata ? AppLocalizations.of(context)!.extracting : AppLocalizations.of(context)!.extract),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Project Phase Dropdown
                    DropdownButtonFormField<String>(
                    value: _selectedPhase ?? _getProjectPhases(context).first,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.projectPhase,
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
                      project: project,
                      onSongRemoved: () async {
                        final updated = project.copyWith(previewSongPath: null);
                        await repo.updateProject(updated);
                        if (mounted) {
                          ref.invalidate(allProjectsStreamProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Preview song removed')),
                          );
                        }
                      },
                      onSongChanged: (filePath) async {
                        final updated = project.copyWith(previewSongPath: filePath);
                        await repo.updateProject(updated);
                        if (mounted) {
                          ref.invalidate(allProjectsStreamProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Preview song added')),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 24),
                    // TODO List
                    TodoListWidget(
                    todos: project.todos,
                    onTodosChanged: (updatedTodos) async {
                      final updated = project.copyWith(todos: updatedTodos);
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
                          final newCustomDisplayName = (nameText.isEmpty || nameText == project.fileName) 
                              ? null 
                              : nameText;
                          
                          final notesText = _notesCtrl.text.trim();
                          final newNotes = notesText.isEmpty ? null : notesText;

                          final updated = project.copyWith(
                            customDisplayName: newCustomDisplayName,
                            bpm: _bpmCtrl.text.trim().isEmpty ? null : double.tryParse(_bpmCtrl.text.trim()),
                            musicalKey: _keyCtrl.text.trim().isEmpty ? null : _keyCtrl.text.trim(),
                            notes: newNotes, // NOVO: Salva Notas
                            status: _selectedPhase != null ? _translateStatusToEnglish(_selectedPhase!) : 'Idea', // Save project phase
                          );

                          await repo.updateProject(updated);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.saved)));
                          }
                        },
                        icon: const Icon(Icons.save),
                          label: Text(AppLocalizations.of(context)!.save),
                        ),
                        const SizedBox(width: 12),
                        
                        // NOVO: BOTÃO OPEN FOLDER
                        ElevatedButton.icon(
                        onPressed: () => _openProjectFolder(project.filePath),
                        icon: const Icon(Icons.folder_open),
                          label: Text(AppLocalizations.of(context)!.openFolder),
                        ),
                        const SizedBox(width: 12),

                        // BOTÃO OPEN IN DAW (Existente)
                        ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            if (Platform.isMacOS) {
                              await Process.start('open', [project.filePath]);
                            } else if (Platform.isWindows) {
                              await Process.start('cmd', ['/c', 'start', '', project.filePath]);
                            } else {
                              await Process.start(project.filePath, []);
                            }
                          } catch (_) {
                             if (mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.failedToLaunchDaw)));
                             }
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: Text(AppLocalizations.of(context)!.openInDaw),
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
                              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
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
      ),
            ),
        ],
      ),
    );
  }
}

class _PreviewSongPlayer extends StatefulWidget {
  final MusicProject project;
  final VoidCallback onSongRemoved;
  final Function(String) onSongChanged;

  const _PreviewSongPlayer({
    required this.project,
    required this.onSongRemoved,
    required this.onSongChanged,
  });

  @override
  State<_PreviewSongPlayer> createState() => _PreviewSongPlayerState();
}

class _PreviewSongPlayerState extends State<_PreviewSongPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

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
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (widget.project.previewSongPath == null || widget.project.previewSongPath!.isEmpty) {
      return;
    }

    final file = File(widget.project.previewSongPath!);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preview song file not found')),
        );
      }
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview Song',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.project.previewSongPath != null && widget.project.previewSongPath!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.basename(widget.project.previewSongPath!),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.red.shade300,
                        onPressed: widget.onSongRemoved,
                        tooltip: 'Remove preview song',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                    ],
                  ),
                ],
              )
            else
              Text(
                'No preview song selected',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
                );
                if (result != null && result.files.single.path != null) {
                  widget.onSongChanged(result.files.single.path!);
                }
              },
              icon: const Icon(Icons.audio_file),
              label: Text(widget.project.previewSongPath != null && widget.project.previewSongPath!.isNotEmpty
                  ? 'Change Preview Song'
                  : 'Select Preview Song'),
            ),
          ],
        ),
      ),
    );
  }
}
