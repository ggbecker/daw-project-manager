import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// NOVO IMPORT
import 'package:path/path.dart' as p; // NOVO IMPORT
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

import 'package:uuid/uuid.dart';

import '../models/music_project.dart';
import '../models/project_event.dart';
import '../providers/providers.dart';
import '../repository/project_repository.dart';
import '../utils/mobile_utils.dart';
import '../utils/file_launcher.dart';
import '../generated/l10n/app_localizations.dart';
import 'widgets/desktop_title_bar.dart';
import 'widgets/todo_list_widget.dart';

class ProjectDetailPage extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage> {
  final _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _bpmCtrl;
  late TextEditingController _keyCtrl;
  late TextEditingController _notesCtrl; // NOVO CONTROLLER
  late FocusNode _nameFocusNode;
  late FocusNode _bpmFocusNode;
  late FocusNode _keyFocusNode;
  late FocusNode _notesFocusNode;
  String? _lastSavedName;
  String? _lastSavedBpm;
  String? _lastSavedKey;
  String? _lastSavedNotes;
  String? _selectedPhase;
  bool _hasInitializedPhase = false; // Track if we've initialized the phase
  bool _extractingMetadata = false; // Track metadata extraction state

  /// Records status-change and/or metadata-edit events after saving a project.
  Future<void> _recordSaveEvents(
    ProjectRepository repo,
    MusicProject oldProject,
    MusicProject newProject,
    String newStatus,
    bool statusChanged,
  ) async {
    final now = DateTime.now();
    if (statusChanged) {
      await repo.addEvent(ProjectEvent(
        id: _uuid.v4(),
        projectId: newProject.id,
        eventType: ProjectEvent.statusChange,
        occurredAt: now,
        payload: jsonEncode({'from': oldProject.status, 'to': newStatus}),
      ));
    }
    final changedFields = <String>[];
    if (oldProject.customDisplayName != newProject.customDisplayName) {
      changedFields.add('name');
    }
    if (oldProject.bpm != newProject.bpm) changedFields.add('bpm');
    if (oldProject.musicalKey != newProject.musicalKey) changedFields.add('key');
    if (oldProject.notes != newProject.notes) changedFields.add('notes');
    if (oldProject.deadline != newProject.deadline) changedFields.add('deadline');
    if (changedFields.isNotEmpty) {
      await repo.addEvent(ProjectEvent(
        id: _uuid.v4(),
        projectId: newProject.id,
        eventType: ProjectEvent.metadataEdit,
        occurredAt: now,
        payload: jsonEncode({'fields': changedFields}),
      ));
    }
  }

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

  String _formatDate(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return l10n.dateToday;
    } else if (diff.inDays == 1) {
      return l10n.dateYesterday;
    } else if (diff.inDays < 7) {
      return l10n.dateDaysAgo(diff.inDays);
    } else if (diff.inDays < 30) {
      final weeks = diff.inDays ~/ 7;
      return l10n.dateWeeksAgo(weeks);
    } else if (diff.inDays < 365) {
      final months = diff.inDays ~/ 7;
      return l10n.dateMonthsAgo(months);
    } else {
      final years = diff.inDays ~/ 365;
      return l10n.dateYearsAgo(years, '');
    }
  }

  String _formatDuration(Duration duration) {
    final l10n = AppLocalizations.of(context)!;
    final years = duration.inDays ~/ 365;
    final months = (duration.inDays % 365) ~/ 30;
    final days = duration.inDays % 30;
    
    if (years > 0) {
      if (months > 0) {
        return l10n.ageYearsMonths(years, years > 1 ? 's' : '', months, months > 1 ? 's' : '');
      }
      return l10n.ageYears(years, years > 1 ? 's' : '');
    } else if (months > 0) {
      if (days > 0) {
        return l10n.ageMonthsDays(months, months > 1 ? 's' : '', days, days > 1 ? 's' : '');
      }
      return l10n.ageMonths(months, months > 1 ? 's' : '');
    } else if (days > 0) {
      return l10n.ageDays(days, days > 1 ? 's' : '');
    } else if (duration.inHours > 0) {
      return l10n.ageHours(duration.inHours, duration.inHours > 1 ? 's' : '');
    } else {
      return l10n.ageJustNow;
    }
  }

  String? _formatCompletionDuration(Duration? duration) {
    if (duration == null) return null;
    final l10n = AppLocalizations.of(context)!;
    final years = duration.inDays ~/ 365;
    final months = (duration.inDays % 365) ~/ 30;
    final days = duration.inDays % 30;
    
    if (years > 0) {
      if (months > 0) {
        return l10n.ageYearsMonths(years, years > 1 ? 's' : '', months, months > 1 ? 's' : '');
      }
      return l10n.ageYears(years, years > 1 ? 's' : '');
    } else if (months > 0) {
      if (days > 0) {
        return l10n.ageMonthsDays(months, months > 1 ? 's' : '', days, days > 1 ? 's' : '');
      }
      return l10n.ageMonths(months, months > 1 ? 's' : '');
    } else if (days > 0) {
      return l10n.ageDays(days, days > 1 ? 's' : '');
    } else if (duration.inHours > 0) {
      return l10n.ageHours(duration.inHours, duration.inHours > 1 ? 's' : '');
    } else {
      return l10n.ageLessThanHour;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bpmCtrl = TextEditingController();
    _keyCtrl = TextEditingController();
    _notesCtrl = TextEditingController(); // INICIALIZA
    _nameFocusNode = FocusNode();
    _bpmFocusNode = FocusNode();
    _keyFocusNode = FocusNode();
    _notesFocusNode = FocusNode();
    // Initialize with default phase - will be set in build method
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bpmCtrl.dispose();
    _keyCtrl.dispose();
    _notesCtrl.dispose(); // DISPOSE
    _nameFocusNode.dispose();
    _bpmFocusNode.dispose();
    _keyFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  // NOVO: Função para abrir o diretório pai
  Future<void> _openProjectFolder(String filePath) async {
    // Determina o caminho da pasta: Se for um arquivo, pega o diretório pai. Se for um diretório, pega ele mesmo.
    final folderPath =
        (FileSystemEntity.typeSync(filePath) == FileSystemEntityType.file)
        ? p.dirname(filePath)
        : filePath;

    final success = await FileLauncher.openFolder(folderPath);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.couldNotOpenFolder('Unable to open folder'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(repositoryProvider);
    final allProjectsAsync = ref.watch(allProjectsStreamProvider);
    final isMobile = MobileUtils.isMobile();

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(AppLocalizations.of(context)!.projectDetails),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: Column(
        children: [
          DesktopTitleBar(
            title: AppLocalizations.of(context)!.projectDetails,
            showBack: true,
          ),
          Expanded(
            child: repoAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Text(AppLocalizations.of(context)!.failedToLoad),
              ),
              data: (repo) {
                // Use projects from stream to get latest data, fallback to repo if stream not ready
                // The stream should automatically update when Hive emits changes
                return allProjectsAsync.when(
                  data: (allProjects) {
                    final project = allProjects.firstWhere(
                      (p) => p.id == widget.projectId,
                      orElse: () {
                        // Fallback to repo if not found in stream
                        final allProjectsFromRepo = repo.getAllProjects();
                        return allProjectsFromRepo.firstWhere(
                          (p) => p.id == widget.projectId,
                        );
                      },
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
                  error: (_, _) {
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
        

        // Sincroniza controllers com os dados do projeto
        // Só atualiza se o campo não estiver com foco E se o texto não foi modificado pelo usuário
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentName =
              updatedProject.customDisplayName ?? updatedProject.fileName;
          final currentBpm = updatedProject.bpm?.toString() ?? '';
          final currentKey = updatedProject.musicalKey ?? '';
          final currentNotes = updatedProject.notes ?? '';
          
          // Só atualiza se o campo não estiver com foco E se o texto atual for igual ao último valor salvo
          // Isso preserva o texto digitado pelo usuário mesmo quando o foco muda
          if (!_nameFocusNode.hasFocus) {
            if (_lastSavedName == null || _nameCtrl.text == _lastSavedName) {
              if (_nameCtrl.text != currentName) {
                _nameCtrl.text = currentName;
                _lastSavedName = currentName;
              }
            } else {
              // Se o texto foi modificado pelo usuário, atualiza o valor salvo apenas se ainda não foi inicializado
              _lastSavedName ??= currentName;
            }
          }
          
          if (!_bpmFocusNode.hasFocus) {
            if (_lastSavedBpm == null || _bpmCtrl.text == _lastSavedBpm) {
              if (_bpmCtrl.text != currentBpm) {
                _bpmCtrl.text = currentBpm;
                _lastSavedBpm = currentBpm;
              }
            } else {
              _lastSavedBpm ??= currentBpm;
            }
          }
          
          if (!_keyFocusNode.hasFocus) {
            if (_lastSavedKey == null || _keyCtrl.text == _lastSavedKey) {
              if (_keyCtrl.text != currentKey) {
                _keyCtrl.text = currentKey;
                _lastSavedKey = currentKey;
              }
            } else {
              _lastSavedKey ??= currentKey;
            }
          }
          
          // NOVO: Sincroniza Notas - só atualiza se não estiver com foco E se o texto não foi modificado
          if (!_notesFocusNode.hasFocus) {
            if (_lastSavedNotes == null || _notesCtrl.text == _lastSavedNotes) {
              if (_notesCtrl.text != currentNotes) {
                _notesCtrl.text = currentNotes;
                _lastSavedNotes = currentNotes;
              }
            } else {
              _lastSavedNotes ??= currentNotes;
            }
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

        final isMobile = MobileUtils.isMobile();
        final sourceFileExists = File(updatedProject.filePath).existsSync() ||
            Directory(updatedProject.filePath).existsSync();
        return Stack(
          children: [
            Padding(
              padding: MobileUtils.getResponsivePadding(context),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (!sourceFileExists)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade400),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Source file not found on this machine — metadata-only mode. '
                                'You can still edit and export metadata.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      updatedProject.displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    const SizedBox(height: 8),
                    // Only show full path on desktop, not on mobile
                    if (!isMobile)
                      Text(
                        updatedProject.filePath,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                ),
                              ),
                    if (!isMobile) const SizedBox(height: 16),
                    if (isMobile) const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.lastModified(
updatedProject.lastModifiedAt.toString(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Project age display
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.projectAge(_formatDuration(updatedProject.projectAge)),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        if (updatedProject.fileCreatedAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${AppLocalizations.of(context)!.createdDate(_formatDate(updatedProject.fileCreatedAt!))})',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Time to completion (only show for finished projects)
                    if (updatedProject.timeToCompletion != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.completedIn(_formatCompletionDuration(updatedProject.timeToCompletion)!),
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          if (updatedProject.statusChangedAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(${AppLocalizations.of(context)!.finishedDate(_formatDate(updatedProject.statusChangedAt!))})',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                            const SizedBox(height: 24),

                            // Campo para editar o nome de exibição customizado
                            TextFormField(
                              controller: _nameCtrl,
                              focusNode: _nameFocusNode,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(
                                  context,
                                )!.projectName,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Use Column on mobile, Row on desktop
                            isMobile
                                ? Column(
                                    children: [
                                      TextFormField(
                                        controller: _bpmCtrl,
                                        focusNode: _bpmFocusNode,
                                        decoration: InputDecoration(
                                          labelText: AppLocalizations.of(
                                            context,
                                          )!.bpm,
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _keyCtrl,
                                        focusNode: _keyFocusNode,
                                        decoration: InputDecoration(
                                          labelText: AppLocalizations.of(
                                            context,
                                          )!.key,
                                        ),
                                        onChanged: (value) {
                                          // Force rebuild to update Camelot code display
                                          setState(() {});
                                        },
                                      ),
                                      // Camelot code field (only shown when key is set)
                                      if (updatedProject.camelotCode != null) ...[
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          key: ValueKey(updatedProject.camelotCode),
                                          enabled: false,
                                          initialValue: updatedProject.camelotCode,
                                          decoration: InputDecoration(
                                            labelText: AppLocalizations.of(context)!.camelotCode,
                                            filled: true,
                                            fillColor: Colors.blue.withOpacity(0.05),
                                            border: const OutlineInputBorder(),
                                            disabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.blue.withOpacity(0.3),
                                              ),
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.music_note,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _bpmCtrl,
                                          focusNode: _bpmFocusNode,
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
                                          focusNode: _keyFocusNode,
                                          decoration: InputDecoration(
                                            labelText: AppLocalizations.of(
                                              context,
                                            )!.key,
                                          ),
                                          onChanged: (value) {
                                            // Force rebuild to update Camelot code display
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      // Camelot code field on desktop (next to key field)
                                      if (updatedProject.camelotCode != null) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            enabled: false,
                                            initialValue: updatedProject.camelotCode,
                                            decoration: InputDecoration(
                                              labelText: AppLocalizations.of(context)!.camelotCode,
                                              filled: true,
                                              fillColor: Colors.blue.withOpacity(0.05),
                                              border: const OutlineInputBorder(),
                                              disabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.blue.withOpacity(0.3),
                                                ),
                                              ),
                                              prefixIcon: const Icon(
                                                Icons.music_note,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
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
                              initialValue:
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
                              focusNode: _notesFocusNode,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.notes,
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                            ),

                            const SizedBox(height: 12),

                            // Deadline field
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: updatedProject.deadline ?? DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                                );
                                if (picked != null) {
                                  final updated = updatedProject.copyWith(deadline: picked);
                                  await repo.updateProject(updated);
                                  if (mounted) {
                                    ref.invalidate(allProjectsStreamProvider);
                                  }
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.projectDeadline,
                                  border: const OutlineInputBorder(),
                                  suffixIcon: updatedProject.deadline != null
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () async {
                                            final updated = updatedProject.copyWith(clearDeadline: true);
                                            await repo.updateProject(updated);
                                            if (mounted) {
                                              ref.invalidate(allProjectsStreamProvider);
                                            }
                                          },
                                        )
                                      : const Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  updatedProject.deadline != null
                                      ? DateFormat('MMM dd, yyyy').format(updatedProject.deadline!)
                                      : AppLocalizations.of(context)!.noDeadlineSet,
                                  style: TextStyle(
                                    color: updatedProject.deadline != null
                                        ? (updatedProject.daysUntilDeadline! < 0
                                            ? Colors.red
                                            : updatedProject.daysUntilDeadline! == 0
                                                ? Colors.red
                                                : updatedProject.daysUntilDeadline! <= 7
                                                    ? Colors.orange
                                                    : Theme.of(context).textTheme.bodyLarge?.color)
                                        : Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ),
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
                                          '${AppLocalizations.of(context)!.error}: ${e.toString()}',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              onSongChanged: (filePath) async {
                                // When changing the preview song, we should NOT update the uploadedPreviewSongHash here.
                                // The uploadedPreviewSongHash should only be updated after a successful upload to Drive.
                                // By keeping the old hash intact, the upload process will calculate
                                // the new file's hash and compare it with the old uploadedPreviewSongHash in the database.
                                // If they differ, it will upload the new file and update the uploadedPreviewSongHash.
                                // The uploadedPreviewSongHash will be updated in uploadDatabase() after successful upload.
                                
                                final updated = project.copyWith(
                                  previewSongPath: filePath,
                                  // Keep old uploadedPreviewSongHash - don't update it here
                                  // It will be updated after successful upload to Drive
                                  previewSongFileName: p.basename(filePath),
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
                            // Use key to force widget rebuild when todos change
                            TodoListWidget(
                              key: ValueKey('${updatedProject.id}_${updatedProject.todos.length}_${updatedProject.todos.map((t) => t.id).join(",")}'),
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
                              onTodoCompleted: (completedTodo) async {
                                await repo.addEvent(ProjectEvent(
                                  id: _uuid.v4(),
                                  projectId: updatedProject.id,
                                  eventType: ProjectEvent.todoCompleted,
                                  occurredAt: DateTime.now(),
                                  payload: jsonEncode({
                                    'todoId': completedTodo.id,
                                    'todoText': completedTodo.text,
                                  }),
                                ));
                              },
                            ),

                            const SizedBox(height: 24),
                            // Use Wrap on mobile, Row on desktop
                            isMobile
                                ? Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
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

                                            // Determine new status and check if it changed
                                            final newStatus = _selectedPhase != null
                                                ? _translateStatusToEnglish(_selectedPhase!)
                                                : 'Idea';
                                            final statusChanged = project.status != newStatus;

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
                                              notes: newNotes,
                                              clearNotes: newNotes == null,
                                              status: newStatus,
                                              statusChangedAt: statusChanged ? DateTime.now() : null,
                                            );

                                            await repo.updateProject(updated);
                                            await _recordSaveEvents(repo, project, updated, newStatus, statusChanged);
                                            // Atualiza os valores salvos para preservar o texto na próxima reconstrução
                                            _lastSavedName = newCustomDisplayName ?? updatedProject.fileName;
                                            _lastSavedBpm = _bpmCtrl.text.trim();
                                            _lastSavedKey = _keyCtrl.text.trim();
                                            _lastSavedNotes = newNotes ?? '';
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
                                      ),
                                    ],
                                  )
                                : Row(
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

                                          // Determine new status and check if it changed
                                          final newStatus = _selectedPhase != null
                                              ? _translateStatusToEnglish(_selectedPhase!)
                                              : 'Idea';
                                          final statusChanged = project.status != newStatus;

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
                                            notes: newNotes,
                                            clearNotes: newNotes == null,
                                            status: newStatus,
                                            statusChangedAt: statusChanged ? DateTime.now() : null,
                                          );

                                          await repo.updateProject(updated);
                                          await _recordSaveEvents(repo, project, updated, newStatus, statusChanged);
                                          // Atualiza os valores salvos para preservar o texto na próxima reconstrução
                                          _lastSavedName = newCustomDisplayName ?? updatedProject.fileName;
                                          _lastSavedBpm = _bpmCtrl.text.trim();
                                          _lastSavedKey = _keyCtrl.text.trim();
                                          _lastSavedNotes = newNotes ?? '';
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
                                      Tooltip(
                                        message: sourceFileExists ? '' : AppLocalizations.of(context)!.sourceFileNotFoundOnThisMachine,
                                        child: ElevatedButton.icon(
                                          onPressed: sourceFileExists
                                              ? () => _openProjectFolder(updatedProject.filePath)
                                              : null,
                                          icon: const Icon(Icons.folder_open),
                                          label: Text(
                                            AppLocalizations.of(context)!.openFolder,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // BOTÃO OPEN IN DAW (Existente)
                                      Tooltip(
                                        message: sourceFileExists ? '' : AppLocalizations.of(context)!.sourceFileNotFoundOnThisMachine,
                                        child: ElevatedButton.icon(
                                          onPressed: sourceFileExists
                                              ? () async {
                                                  final success = await FileLauncher.launchProject(updatedProject.filePath);
                                                  if (!success && mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text(AppLocalizations.of(context)!.failedToLaunchProject(updatedProject.displayName))),
                                                    );
                                                  }
                                                  if (success) {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text(AppLocalizations.of(context)!.failedToLaunchDaw)),
                                                      );
                                                    }
                                                  }
                                                }
                                              : null,
                                          icon: const Icon(Icons.open_in_new),
                                          label: Text(
                                            AppLocalizations.of(context)!.openInDaw,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                    // ── Project History Timeline ──────────────────────────
                    const SizedBox(height: 16),
                    _ProjectHistoryTimeline(projectId: updatedProject.id),
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

class _PreviewSongPlayer extends ConsumerStatefulWidget {
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
  ConsumerState<_PreviewSongPlayer> createState() => _PreviewSongPlayerState();
}

class _TogglePlayPauseIntent extends Intent {
  const _TogglePlayPauseIntent();
}

class _PreviewSongPlayerState extends ConsumerState<_PreviewSongPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FocusNode _focusNode = FocusNode();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isDraggingOver = false;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        if (kDebugMode) {
          print('Audio player state changed: $state');
        }
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        if (kDebugMode) {
          print('Audio duration changed: $duration');
        }
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
    // Listen for player logs (if available)
    try {
      _audioPlayer.onLog.listen((message) {
        if (kDebugMode) {
          print('Audio player log: $message');
        }
      });
    } catch (e) {
      // onLog might not be available in all versions
      if (kDebugMode) {
        print('onLog not available: $e');
      }
    }
    // Listen for completion
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        if (kDebugMode) {
          print('Audio playback completed');
        }
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
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

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        // Check if it's a Drive file reference (format: "drive://fileId")
        // Preview songs should already be downloaded during backup merge
        // If it's still a Drive reference, it means download failed or file doesn't exist
        if (widget.project.previewSongPath!.startsWith('drive://')) {
          // If we still have a Drive reference, the file wasn't downloaded
          // This shouldn't happen if backup was downloaded correctly, but handle gracefully
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Preview song not available. Please download backup again.',
                ),
              ),
            );
          }
          return;
        } else {
          // Local file - check if it exists
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
          
          // Use device file source for local files
          if (_position == Duration.zero || _position >= _duration) {
            await _audioPlayer.play(DeviceFileSource(widget.project.previewSongPath!));
          } else {
            await _audioPlayer.resume();
          }
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
      // Keep default share here (audio). A separate "Share ZIP" button is also available.
      final fileSizeBytes = await sourceFile.length();
      if (kDebugMode) {
        debugPrint('[preview_share] sizeBytes=$fileSizeBytes');
      }

      // Get the original filename or use a default
      String originalFileName = widget.project.previewSongFileName ?? 
          p.basename(widget.project.previewSongPath!);
      
      // Ensure the filename has an extension
      if (!originalFileName.contains('.')) {
        final ext = p.extension(widget.project.previewSongPath!);
        originalFileName = '$originalFileName$ext';
      }

      // On Android, copy to cache directory with original name for sharing
      if (Platform.isAndroid) {
        final cacheDir = await getTemporaryDirectory();
        final shareFile = File(p.join(cacheDir.path, originalFileName));
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
    if (!Platform.isAndroid) return;

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
          p.basename(widget.project.previewSongPath!);
      if (!originalFileName.contains('.')) {
        final ext = p.extension(widget.project.previewSongPath!);
        originalFileName = '$originalFileName$ext';
      }

      // Copy to cache and zip it
      final cacheDir = await getTemporaryDirectory();
      final shareFile = File(p.join(cacheDir.path, originalFileName));
      await sourceFile.copy(shareFile.path);

      final zipBase = p.basenameWithoutExtension(originalFileName);
      var zipPath = p.join(cacheDir.path, '$zipBase.zip');
      var zipFile = File(zipPath);
      if (await zipFile.exists()) {
        zipPath = p.join(cacheDir.path, '${zipBase}_${DateTime.now().millisecondsSinceEpoch}.zip');
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
        [XFile(zipFile.path, name: p.basename(zipFile.path), mimeType: 'application/zip')],
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

  /// Picks a local audio file on Android/iOS and stores it in the app's preview_songs folder.
  /// This does NOT upload anything to Drive.
  Future<void> _pickPreviewSongMobile() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final l10n = AppLocalizations.of(context)!;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
        dialogTitle: l10n.selectPreviewSong,
      );

      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        return;
      }

      final source = File(result.files.single.path!);
      if (!await source.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.previewSongFileNotFound)),
          );
        }
        return;
      }

      // Copy into app's persistent documents directory for reliable access
      final appDir = await getApplicationDocumentsDirectory();
      final destDir = Directory(p.join(appDir.path, 'preview_songs', widget.project.id));
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      final originalName =
          result.files.single.name.isNotEmpty ? result.files.single.name : p.basename(source.path);
      final destPath = p.join(destDir.path, originalName);
      await source.copy(destPath);

      final repo = await ref.read(repositoryProvider.future);
      final updated = widget.project.copyWith(
        previewSongPath: destPath,
        previewSongFileName: originalName,
        clearUploadedPreviewSongHash: true,
        updatedAt: DateTime.now(),
      );
      await repo.updateProject(updated);

      // Refresh UI
      ref.invalidate(allProjectsStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.previewSongAdded)),
        );
      }
    } on PlatformException catch (e) {
      // Common error in Android emulators: file picker can't access storage
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to select file: ${e.message ?? "Unknown error"}\n\n'
              'Note: This often happens in Android emulators. '
              'Try using a real device or adding audio files to the emulator storage.',
            ),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: ${e.toString()}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
              if (file.path.isNotEmpty) {
                filePaths.add(file.path);
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
                              // Use previewSongFileName if available (original filename), otherwise use basename
                              widget.project.previewSongFileName ?? 
                              (widget.project.previewSongPath != null 
                                ? p.basename(widget.project.previewSongPath!)
                                : ''),
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
                              // Show confirmation dialog
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(
                                    AppLocalizations.of(context)!.removePreviewSong,
                                  ),
                                  content: Text(
                                    AppLocalizations.of(context)!.removePreviewSongConfirm,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(false),
                                      child: Text(AppLocalizations.of(context)!.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: Text(AppLocalizations.of(context)!.remove),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                // Stop audio if playing
                                await _audioPlayer.stop();
                                setState(() {
                                  _isPlaying = false;
                                  _position = Duration.zero;
                                  _duration = Duration.zero;
                                });
                                await widget.onSongRemoved();
                              }
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
                // On mobile, show Share button instead of Change Preview Song
                // On desktop, show Change Preview Song button
                Platform.isAndroid || Platform.isIOS
                    ? Builder(
                        builder: (context) {
                          final buttons = <Widget>[];

                          // Mobile: allow selecting/changing preview song locally
                          buttons.add(
                            ElevatedButton.icon(
                              onPressed: _pickPreviewSongMobile,
                              icon: const Icon(Icons.audio_file),
                              label: Text(
                                widget.project.previewSongPath != null &&
                                        widget.project.previewSongPath!.isNotEmpty
                                    ? AppLocalizations.of(context)!.changePreviewSong
                                    : AppLocalizations.of(context)!.selectPreviewSong,
                              ),
                            ),
                          );

                          // Share (if a local preview song exists)
                          if (widget.project.previewSongPath != null &&
                              widget.project.previewSongPath!.isNotEmpty &&
                              !widget.project.previewSongPath!.startsWith('drive://')) {
                            buttons.add(
                              ElevatedButton.icon(
                                onPressed: _sharePreviewSong,
                                icon: const Icon(Icons.share),
                                label: Text(AppLocalizations.of(context)!.share),
                              ),
                            );

                            if (Platform.isAndroid) {
                              buttons.add(
                                ElevatedButton.icon(
                                  onPressed: _sharePreviewSongAsZip,
                                  icon: const Icon(Icons.archive),
                                  label: Text(AppLocalizations.of(context)!.shareZip),
                                ),
                              );
                            }
                          }

                          if (buttons.isEmpty) return const SizedBox.shrink();
                          return Wrap(spacing: 8, runSpacing: 8, children: buttons);
                        },
                      )
                    : ElevatedButton.icon(
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

// ---------------------------------------------------------------------------
// Project History Timeline — embedded in the detail page
// ---------------------------------------------------------------------------

class _ProjectHistoryTimeline extends ConsumerWidget {
  final String projectId;
  const _ProjectHistoryTimeline({required this.projectId});

  static const double _dotSize = 10;
  static const double _lineWidth = 2;
  static const double _dateColWidth = 54;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final events = ref.watch(eventsForProjectProvider(projectId));

    // Chronological order: oldest at top, newest at bottom
    final chronological = [...events]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      leading: const Icon(Icons.timeline, size: 20),
      title: Text(
        l10n.statsProjectActivity,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: events.isEmpty
          ? Text(l10n.statsNoEvents,
              style: Theme.of(context).textTheme.bodySmall)
          : Text(l10n.statsEventCount(events.length),
              style: Theme.of(context).textTheme.bodySmall),
      children: [
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
            child: Text(l10n.statsNoEvents,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).hintColor)),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Column(
              children: [
                for (int i = 0; i < chronological.length; i++)
                  _buildTimelineRow(
                    context,
                    chronological[i],
                    isFirst: i == 0,
                    isLast: i == chronological.length - 1,
                    l10n: l10n,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimelineRow(
    BuildContext context,
    ProjectEvent event, {
    required bool isFirst,
    required bool isLast,
    required AppLocalizations l10n,
  }) {
    final hintColor = Theme.of(context).hintColor;
    final bodySmall = Theme.of(context).textTheme.bodySmall;
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    String label;
    Color dotColor;

    try {
      final payload = event.payload != null
          ? jsonDecode(event.payload!) as Map<String, dynamic>
          : <String, dynamic>{};

      switch (event.eventType) {
        case ProjectEvent.statusChange:
          icon = Icons.swap_horiz;
          final toPhase = payload['to'] as String? ?? '';
          dotColor = _phaseColor(toPhase);
          label = l10n.statsEventPhaseChanged(
              payload['from'] as String? ?? '', toPhase);
          break;
        case ProjectEvent.metadataEdit:
          icon = Icons.edit_outlined;
          dotColor = colorScheme.secondary;
          final fields =
              (payload['fields'] as List?)?.cast<String>().join(', ') ?? '';
          label = l10n.statsEventMetadataUpdated(fields);
          break;
        case ProjectEvent.todoCompleted:
          icon = Icons.check_circle_outline;
          dotColor = Colors.green;
          label = l10n
              .statsEventTodoCompleted(payload['todoText'] as String? ?? '');
          break;
        case ProjectEvent.fileChanged:
          icon = Icons.folder_outlined;
          dotColor = Colors.orange;
          label = l10n.statsEventFileModified;
          break;
        default:
          icon = Icons.circle_outlined;
          dotColor = hintColor;
          label = event.eventType;
      }
    } catch (_) {
      icon = Icons.circle_outlined;
      dotColor = hintColor;
      label = event.eventType;
    }

    final dt = event.occurredAt;
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final isToday = DateTime.now().difference(dt).inDays == 0;
    final dateLabel = isToday
        ? timeStr
        : '${dt.day}/${dt.month}/${dt.year.toString().substring(2)}\n$timeStr';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date label
          SizedBox(
            width: _dateColWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                dateLabel,
                textAlign: TextAlign.right,
                style: bodySmall?.copyWith(
                  fontSize: 9,
                  color: hintColor,
                  height: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Line + dot
          SizedBox(
            width: _dotSize + 8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: isFirst
                        ? const SizedBox.shrink()
                        : Container(
                            width: _lineWidth,
                            color: hintColor.withValues(alpha: 0.25)),
                  ),
                ),
                Container(
                  width: _dotSize,
                  height: _dotSize,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.35),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: isLast
                        ? const SizedBox.shrink()
                        : Container(
                            width: _lineWidth,
                            color: hintColor.withValues(alpha: 0.25)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Icon + description
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: dotColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(label,
                        style: bodySmall?.copyWith(height: 1.3),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _phaseColor(String phase) {
    switch (phase) {
      case 'Idea':
        return Colors.purple;
      case 'Composing':
        return Colors.blue;
      case 'Arranging':
        return Colors.teal;
      case 'Mixing':
        return Colors.orange;
      case 'Mastering':
        return Colors.deepOrange;
      case 'Finished':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
