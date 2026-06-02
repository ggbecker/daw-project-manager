import 'dart:async';
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
import '../services/audio_analysis_service.dart';
import '../services/mixdown_detector_service.dart';
import 'widgets/desktop_title_bar.dart';
import 'widgets/todo_list_widget.dart';
import 'widgets/waveform_widget.dart';
import 'project_statistics_page.dart';

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
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bpmCtrl.dispose();
    _keyCtrl.dispose();
    _notesCtrl.dispose();
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

  Future<void> _doSave(
    ProjectRepository repo,
    MusicProject project,
    MusicProject updatedProject,
  ) async {
    final nameText = _nameCtrl.text.trim();
    final newCustomDisplayName =
        (nameText.isEmpty || nameText == updatedProject.fileName) ? null : nameText;
    final notesText = _notesCtrl.text.trim();
    final newNotes = notesText.isEmpty ? null : notesText;
    final newStatus =
        _selectedPhase != null ? _translateStatusToEnglish(_selectedPhase!) : 'Idea';
    final statusChanged = project.status != newStatus;
    final updated = project.copyWith(
      customDisplayName: newCustomDisplayName,
      bpm: _bpmCtrl.text.trim().isEmpty ? null : double.tryParse(_bpmCtrl.text.trim()),
      musicalKey: _keyCtrl.text.trim().isEmpty ? null : _keyCtrl.text.trim(),
      notes: newNotes,
      clearNotes: newNotes == null,
      status: newStatus,
      statusChangedAt: statusChanged ? DateTime.now() : null,
    );
    await repo.updateProject(updated);
    await _recordSaveEvents(repo, project, updated, newStatus, statusChanged);
    _lastSavedName = newCustomDisplayName ?? updatedProject.fileName;
    _lastSavedBpm = _bpmCtrl.text.trim();
    _lastSavedKey = _keyCtrl.text.trim();
    _lastSavedNotes = newNotes ?? '';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.saved)),
      );
    }
  }

  Future<void> _renameProjectFile(MusicProject project) async {
    final ext = p.extension(project.filePath);
    final currentBaseName = p.basenameWithoutExtension(project.filePath);
    final projectDir = p.dirname(project.filePath);
    final folderName = p.basename(projectDir);
    final folderMatchesProject = folderName == currentBaseName;

    final result = await showDialog<({String newName, bool renameFolder})>(
      context: context,
      builder: (ctx) => _RenameProjectDialog(
        currentName: currentBaseName,
        canRenameFolder: folderMatchesProject,
      ),
    );
    if (result == null || result.newName.trim() == currentBaseName) return;

    final newBaseName = result.newName.trim();
    final newFilePath = p.join(projectDir, '$newBaseName$ext');

    if (File(newFilePath).existsSync() || Directory(newFilePath).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.renameAlreadyExists('$newBaseName$ext'))),
        );
      }
      return;
    }

    try {
      // Rename the project file or bundle directory
      if (Directory(project.filePath).existsSync()) {
        await Directory(project.filePath).rename(newFilePath);
      } else {
        await File(project.filePath).rename(newFilePath);
      }

      String finalFilePath = newFilePath;
      String? newPreviewSongPath = project.previewSongPath;
      String? newAutoPath = project.previewSongAutoPath;

      // Rename containing folder if requested
      if (result.renameFolder && folderMatchesProject) {
        final newFolderPath = p.join(p.dirname(projectDir), newBaseName);
        if (!Directory(newFolderPath).existsSync()) {
          await Directory(projectDir).rename(newFolderPath);
          finalFilePath = p.join(newFolderPath, '$newBaseName$ext');
          // Fix any stored paths that were inside the old folder
          if (newPreviewSongPath != null && newPreviewSongPath.startsWith(projectDir)) {
            newPreviewSongPath = newFolderPath + newPreviewSongPath.substring(projectDir.length);
          }
          if (newAutoPath != null && newAutoPath.startsWith(projectDir)) {
            newAutoPath = newFolderPath + newAutoPath.substring(projectDir.length);
          }
        }
      }

      final repo = await ref.read(repositoryProvider.future);
      await repo.updateProject(project.copyWith(
        filePath: finalFilePath,
        fileName: '$newBaseName$ext',
        previewSongPath: newPreviewSongPath,
        previewSongAutoPath: newAutoPath,
      ));
      ref.invalidate(allProjectsStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.renameSuccess('$newBaseName$ext'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.renameFailed(e.toString()))),
        );
      }
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
        final dateFormat = ref.watch(dateFormatProvider);
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProjectDetailHeader(
                  project: updatedProject,
                  isMobile: isMobile,
                  dateFormat: dateFormat,
                  formatDuration: _formatDuration,
                  formatCompletionDuration: _formatCompletionDuration,
                  isSessionActive: ref.watch(activeProjectProvider)?.id == widget.projectId,
                  liveSessionSeconds: ref.watch(workTimerProvider),
                ),
                _ProjectDetailActionBar(
                  project: updatedProject,
                  isMobile: isMobile,
                  sourceFileExists: sourceFileExists,
                  onSave: () => _doSave(repo, project, updatedProject),
                  onOpenFolder: () => _openProjectFolder(updatedProject.filePath),
                  onRename: () => _renameProjectFile(updatedProject),
                  onOpenInDaw: () async {
                    final success = await FileLauncher.launchProject(updatedProject.filePath);
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.failedToLaunchProject(updatedProject.displayName))),
                      );
                    }
                  },
                  onStats: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProjectStatisticsPage(projectId: updatedProject.id)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: MobileUtils.getResponsivePadding(context),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                    if (!sourceFileExists && !MobileUtils.isMobile())
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
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.sourceFileNotFoundMetadataOnly,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                        const SizedBox(height: 16),

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
                                      Tooltip(
                                        message: sourceFileExists
                                            ? ''
                                            : AppLocalizations.of(context)!.sourceFileNotFoundOnThisMachine,
                                        child: ElevatedButton.icon(
                                        onPressed: _extractingMetadata || !sourceFileExists
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
                            _SessionHistorySection(sessions: updatedProject.sessions),
                            const SizedBox(height: 24),
                            _ProjectStatsButton(projectId: updatedProject.id),
                            const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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

// ─── Project Detail Header ────────────────────────────────────────────────────

class _ProjectDetailHeader extends StatelessWidget {
  final MusicProject project;
  final bool isMobile;
  final DateFormat dateFormat;
  final String Function(Duration) formatDuration;
  final String? Function(Duration?) formatCompletionDuration;
  final bool isSessionActive;
  final int liveSessionSeconds;

  const _ProjectDetailHeader({
    required this.project,
    required this.isMobile,
    required this.dateFormat,
    required this.formatDuration,
    required this.formatCompletionDuration,
    required this.isSessionActive,
    required this.liveSessionSeconds,
  });

  String _formatTotalWork(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${seconds}s';
  }

  String _formatLiveSession(int seconds) {
    final h = seconds ~/ 3600;
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String _relativeDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return l10n.dateToday;
    if (diff.inDays == 1) return l10n.dateYesterday;
    if (diff.inDays < 7) return l10n.dateDaysAgo(diff.inDays);
    if (diff.inDays < 30) return l10n.dateWeeksAgo(diff.inDays ~/ 7);
    if (diff.inDays < 365) return l10n.dateMonthsAgo(diff.inDays ~/ 30);
    return l10n.dateYearsAgo(diff.inDays ~/ 365, '');
  }

  Color _phaseColor(String status) {
    switch (status) {
      case 'Finished': return Colors.green;
      case 'Mastering': return Colors.purple;
      case 'Mixing': return Colors.blue;
      case 'Arranging': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final phaseColor = _phaseColor(project.status);
    final surfaceColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  project.displayName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: phaseColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  project.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: phaseColor,
                  ),
                ),
              ),
            ],
          ),
          if (!isMobile) ...[
            const SizedBox(height: 4),
            Text(
              project.filePath,
              style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoChip(
                icon: Icons.access_time,
                label: formatDuration(project.projectAge),
              ),
              _InfoChip(
                icon: Icons.edit_calendar_outlined,
                label: l10n.lastModified(dateFormat.format(project.lastModifiedAt)),
              ),
              if (project.bpm != null)
                _InfoChip(
                  icon: Icons.speed,
                  label: '${project.bpm!.toStringAsFixed(project.bpm! % 1 == 0 ? 0 : 1)} BPM',
                ),
              if (project.musicalKey != null)
                _InfoChip(icon: Icons.music_note, label: project.musicalKey!),
              if (project.timeToCompletion != null)
                _InfoChip(
                  icon: Icons.emoji_events,
                  label: l10n.completedIn(formatCompletionDuration(project.timeToCompletion)!),
                  color: Colors.amber,
                ),
              if (project.fileCreatedAt != null)
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: l10n.createdDate(_relativeDate(context, project.fileCreatedAt!)),
                ),
              if (project.totalWorkSeconds > 0)
                _InfoChip(
                  icon: Icons.work_history,
                  label: l10n.totalWorkTime(_formatTotalWork(project.totalWorkSeconds)),
                ),
              if (isSessionActive)
                _InfoChip(
                  icon: Icons.timelapse,
                  label: l10n.sessionTime(_formatLiveSession(liveSessionSeconds)),
                  color: Colors.green.shade400,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.textTheme.bodySmall?.color ?? Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: c)),
      ],
    );
  }
}

// ─── Action Toolbar ───────────────────────────────────────────────────────────

class _ProjectDetailActionBar extends StatelessWidget {
  final MusicProject project;
  final bool isMobile;
  final bool sourceFileExists;
  final VoidCallback onSave;
  final VoidCallback onOpenFolder;
  final VoidCallback onRename;
  final VoidCallback onOpenInDaw;
  final VoidCallback onStats;

  const _ProjectDetailActionBar({
    required this.project,
    required this.isMobile,
    required this.sourceFileExists,
    required this.onSave,
    required this.onOpenFolder,
    required this.onRename,
    required this.onOpenInDaw,
    required this.onStats,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notFoundMsg = l10n.sourceFileNotFoundOnThisMachine;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save, size: 16),
            label: Text(l10n.save),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: sourceFileExists ? '' : notFoundMsg,
              child: OutlinedButton.icon(
                onPressed: sourceFileExists ? onOpenInDaw : null,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(l10n.openInDaw),
              ),
            ),
          ],
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: sourceFileExists ? '' : notFoundMsg,
              child: OutlinedButton.icon(
                onPressed: sourceFileExists ? onOpenFolder : null,
                icon: const Icon(Icons.folder_open, size: 16),
                label: Text(l10n.openFolder),
              ),
            ),
          ],
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: sourceFileExists ? '' : notFoundMsg,
              child: OutlinedButton.icon(
                onPressed: sourceFileExists ? onRename : null,
                icon: const Icon(Icons.drive_file_rename_outline, size: 16),
                label: Text(l10n.renameFileButtonLabel),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onStats,
              icon: const Icon(Icons.bar_chart, size: 16),
              label: Text(l10n.statsProjectActivity),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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

enum _FileNotFoundAction { selectNew, remove }

class _PreviewSongPlayerState extends ConsumerState<_PreviewSongPlayer> {
  AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer? _warmPlayer; // pre-loaded with the alternate source (mono↔stereo)
  int _playerGen = 0;       // incremented on each swap; stale listeners self-cancel
  final FocusNode _focusNode = FocusNode();
  bool _isPlaying = false;
  bool _playbackEnded = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isDraggingOver = false;
  double _volume = 1.0;
  double _preMuteVolume = 1.0;

  // Mono
  bool _isMono = false;
  bool _isGeneratingMono = false;
  String? _monoFilePath;

  // File metadata (populated for any format)
  AudioFileInfo? _fileInfo;

  // Waveform peaks for display
  WaveformPeaks? _peaks;

  // Auto-detected mixdown path (used when no preview song is set manually)
  String? _autoDetectedPath;

  // Set when the user accepts a "Replace & Play" suggestion; overrides everything
  // until the widget rebuilds with updated project data from the stream.
  String? _replacedPreviewPath;

  String? get _effectivePreviewPath =>
      _replacedPreviewPath ??
      (widget.project.previewSongPath?.isNotEmpty == true
          ? widget.project.previewSongPath
          : (_autoDetectedPath ?? widget.project.previewSongAutoPath));

  @override
  void initState() {
    super.initState();
    _attachListeners(_audioPlayer, _playerGen);
    _detectMixdown();
    _startBackgroundPrep();
  }

  void _detectMixdown() {
    if (widget.project.previewSongPath?.isNotEmpty == true) return;
    if (widget.project.previewSongAutoPath != null) {
      _autoDetectedPath = widget.project.previewSongAutoPath;
      return;
    }
    Future.microtask(() async {
      final customFolder = ref.read(customMixdownFolderProvider).value;
      final file = MixdownDetectorService.findLatestMixdown(widget.project, customFolder: customFolder);
      if (mounted && file != null) {
        setState(() => _autoDetectedPath = file.path);
        final repo = await ref.read(repositoryProvider.future);
        await repo.updateProject(widget.project.copyWith(previewSongAutoPath: file.path));
        _startBackgroundPrep();
      }
    });
  }

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
      setState(() { _isPlaying = false; _position = Duration.zero; _playbackEnded = true; });
    });
  }

  @override
  void dispose() {
    _warmPlayer?.dispose();
    _audioPlayer.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_PreviewSongPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.previewSongPath != widget.project.previewSongPath ||
        oldWidget.project.id != widget.project.id) {
      // If the stream delivered the path we replaced to, clear the local override.
      if (_replacedPreviewPath != null &&
          (widget.project.previewSongPath == _replacedPreviewPath ||
           widget.project.previewSongAutoPath == _replacedPreviewPath)) {
        _replacedPreviewPath = null;
      }
      _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _playbackEnded = false;
        _position = Duration.zero;
        _duration = Duration.zero;
        _isMono = false;
        _isGeneratingMono = false;
        _monoFilePath = null;
        _fileInfo = null;
        _peaks = null;
        _autoDetectedPath = null;
      });
      _detectMixdown();
      _startBackgroundPrep();
    }
  }

  // ── Background preparation ──────────────────────────────────────────────────

  void _startBackgroundPrep() {
    if (!_hasAudioFile()) return;
    final path = _effectivePreviewPath!;

    // File metadata — works for any format
    AudioAnalysisService.getFileInfo(path).then((info) {
      if (mounted && info != null) setState(() => _fileInfo = info);
    });

    // Waveform peaks — memory → disk → extraction
    ref.read(waveformCacheProvider.notifier).getOrExtract(path).then((peaks) {
      if (!mounted || peaks == null) return;
      setState(() => _peaks = peaks);
    });

    // Pre-generate mono file for any supported format
    if (_supportsMonoMix()) _prepareMonoFile(path);
  }

  Future<void> _prepareMonoFile(String path) async {
    final tmpDir = await getTemporaryDirectory();
    final outPath = '${tmpDir.path}/mono_${widget.project.id}.wav';
    final ok = await AudioAnalysisService.writeMonoWavFile(path, outPath);
    if (!mounted) return;
    if (ok) {
      setState(() => _monoFilePath = outPath);
      _preWarmAlt(DeviceFileSource(outPath));
    } else {
      // File may already be mono — level data may not be ready yet, so we
      // resolve the channel count here directly from the service.
      final channels = await AudioAnalysisService.getChannelCount(path);
      if (mounted && channels == 1) {
        setState(() => _monoFilePath = path);
        _preWarmAlt(DeviceFileSource(path));
      }
    }
  }

  /// Pre-loads [source] into [_warmPlayer] so the next toggle is source-load-free.
  void _preWarmAlt(Source source) {
    _warmPlayer?.dispose();
    _warmPlayer = AudioPlayer();
    _warmPlayer!.setVolume(_volume);
    _warmPlayer!.setSource(source); // fire-and-forget; loads into native buffer
  }

  /// Fades [player] from 0 → [_volume] over ~120 ms.
  /// Cancels automatically if the player is swapped out before the fade ends.
  void _fadeIn(AudioPlayer player) {
    const steps = 12;
    const stepMs = 10; // 12 × 10 ms = 120 ms total
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
        player.setVolume(_volume); // land on exact target
      }
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool _hasAudioFile() {
    final path = _effectivePreviewPath;
    return path != null && path.isNotEmpty;
  }

  bool _supportsMonoMix() {
    final path = _effectivePreviewPath;
    if (path == null || path.isEmpty) return false;
    final ext = path.toLowerCase().split('.').last;
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

  Future<void> _toggleMono() async {
    debugPrint('[Mono] _toggleMono called. supportsMonoMix=${_supportsMonoMix()} isMono=$_isMono monoFilePath=$_monoFilePath');
    if (!_supportsMonoMix()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.monoRequiresWav)),
      );
      return;
    }
    final newMono = !_isMono;

    // If we're toggling ON and the mono file isn't ready yet, generate it now.
    if (newMono && _monoFilePath == null) {
      setState(() => _isGeneratingMono = true);
      final tmpDir = await getTemporaryDirectory();
      final outPath = '${tmpDir.path}/mono_${widget.project.id}.wav';
      debugPrint('[Mono] Generating mono file → $outPath');
      final ok = await AudioAnalysisService.writeMonoWavFile(
          _effectivePreviewPath!, outPath);
      debugPrint('[Mono] writeMonoWavFile result: $ok channels=${_fileInfo?.channels}');
      if (!mounted) return;
      if (!ok) {
        // If the file is already mono, use the original as the mono source.
        final alreadyMono = _fileInfo?.channels == 1;
        if (alreadyMono) {
          debugPrint('[Mono] File is already mono — using original path.');
          setState(() { _monoFilePath = _effectivePreviewPath!; _isGeneratingMono = false; });
        } else {
          setState(() => _isGeneratingMono = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.monoUnsupportedFormat)),
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

    // Grab (or create) the new active player.
    final newActive = _warmPlayer ?? AudioPlayer();
    _warmPlayer = null;

    // Advance generation: listeners on the old player will now self-cancel.
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
      debugPrint('[Mono] switch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.monoSwitchFailed(e.toString()))),
        );
      }
    }

    // Recycle the old player as the warm player for the next toggle.
    await oldActive.stop();
    final altSource = _isMono
        ? DeviceFileSource(_effectivePreviewPath!)
        : (_monoFilePath != null ? DeviceFileSource(_monoFilePath!) : null);
    if (altSource != null) {
      _warmPlayer = oldActive;
      _warmPlayer!.setVolume(_volume);
      _warmPlayer!.setSource(altSource); // fire-and-forget
    } else {
      oldActive.dispose();
    }
  }

  Future<void> _togglePlayPause() async {
    if (!_hasAudioFile()) return;

    if (!_isPlaying) ref.read(desktopPlayerProvider.notifier).close();

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_effectivePreviewPath!.startsWith('drive://')) {
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
          final file = File(_effectivePreviewPath!);
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
              await widget.onSongRemoved();
            } else if (action == _FileNotFoundAction.selectNew) {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
                dialogTitle: l10n.selectPreviewSong,
              );
              if (!mounted) return;
              if (result != null && result.files.single.path != null) {
                final newPath = result.files.single.path!;
                setState(() => _replacedPreviewPath = newPath);
                await widget.onSongChanged(newPath);
                await _audioPlayer.play(DeviceFileSource(newPath));
              }
            }
            return;
          }
          
          // Check for a newer audio file in the same folder as the current preview,
          // regardless of whether the path was manually set or auto-detected.
          // Skip the prompt if the user previously rejected this specific file.
          final newer = MixdownDetectorService.findNewerFileInSameFolder(
            _effectivePreviewPath!,
            ignoredPath: widget.project.ignoredNewerSongPath,
          );
          if (newer != null && mounted) {
            final l10n = AppLocalizations.of(context)!;
            final replace = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.newerExportFound),
                content: Text(l10n.newerExportFoundMessage(p.basename(newer.path))),
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
              // Override _effectivePreviewPath immediately so the filename display
              // updates before the stream rebuild arrives (covers both manual and auto).
              setState(() => _replacedPreviewPath = newer.path);
              // Persist; triggers stream rebuild which will make _replacedPreviewPath redundant.
              widget.onSongChanged(newer.path);
              await _audioPlayer.play(DeviceFileSource(newer.path));
              return;
            } else {
              // "Keep Current" — remember the user rejected this specific file so
              // we don't ask again unless an even newer file appears.
              final repo = await ref.read(repositoryProvider.future);
              await repo.updateProject(
                widget.project.copyWith(ignoredNewerSongPath: newer.path),
              );
            }
          }

          // Play from current source (stereo or pre-mixed mono).
          // After natural completion the native player is in "completed" state;
          // stop() resets it so play() works again. If the user seeked to a
          // non-zero position after completion, play from that position.
          if (_playbackEnded) {
            setState(() => _playbackEnded = false);
            await _audioPlayer.stop();
            await _audioPlayer.play(_currentSource(),
                position: _position > Duration.zero ? _position : null);
          } else if (_position == Duration.zero || _position >= _duration) {
            await _audioPlayer.play(_currentSource());
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

  Future<void> _seek(int seconds) async {
    final target = _position + Duration(seconds: seconds);
    final clamped = target.isNegative
        ? Duration.zero
        : (_duration > Duration.zero && target > _duration ? _duration : target);
    await _audioPlayer.seek(clamped);
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

      // On mobile, copy to cache directory with original name for sharing
      if (MobileUtils.isMobile()) {
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

  /// Desktop (macOS/Windows): opens a save dialog and copies the preview song to the chosen location.
  Future<void> _exportPreviewSongDesktop() async {
    final l10n = AppLocalizations.of(context)!;
    final songPath = widget.project.previewSongPath;

    if (songPath == null || songPath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.previewSongFileNotFound)),
        );
      }
      return;
    }

    if (songPath.startsWith('drive://')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.previewSongNotAvailableDownloadFirst)),
        );
      }
      return;
    }

    try {
      final sourceFile = File(songPath);
      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.previewSongFileNotFound)),
          );
        }
        return;
      }

      final originalName = widget.project.previewSongFileName ?? p.basename(songPath);
      final ext = p.extension(songPath).replaceFirst('.', '');

      final destPath = await FilePicker.platform.saveFile(
        dialogTitle: l10n.saveCopy,
        fileName: originalName,
        type: FileType.custom,
        allowedExtensions: [ext.isNotEmpty ? ext : 'mp3'],
      );

      if (destPath == null) return; // user cancelled

      await sourceFile.copy(destPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.savedCopyTo(destPath))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToSharePreviewSong(e.toString()))),
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
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours > 0 ? '${twoDigits(hours)}:$minutes:$seconds' : '$minutes:$seconds';
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
    ref.listen(desktopPlayerProvider, (prev, next) {
      if (next != null && _isPlaying) _audioPlayer.pause();
    });
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
                if (_hasAudioFile())
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.project.previewSongFileName ??
                              p.basename(_effectivePreviewPath!),
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
                      if (_autoDetectedPath != null &&
                          widget.project.previewSongPath?.isNotEmpty != true)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.folder_open,
                                  size: 12, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                'Auto-detected from mixdown folder',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.amber),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 2),
                      _FileInfoRow(
                        path: _effectivePreviewPath!,
                        fileInfo: _fileInfo,
                      ),
                      const SizedBox(height: 10),
                      // Audio player controls with keyboard shortcuts
                      Focus(
                        focusNode: _focusNode,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Transport + volume row
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.replay_5),
                                  tooltip: Platform.isMacOS ? '← −5s  •  ⌘+← −30s' : '← −5s  •  Ctrl+← −30s',
                                  onPressed: () => _seek(-5),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isPlaying ? Icons.pause_circle : Icons.play_circle,
                                  ),
                                  onPressed: () {
                                    _focusNode.requestFocus();
                                    _togglePlayPause();
                                  },
                                  iconSize: 34,
                                  color: _autoDetectedPath != null &&
                                          widget.project.previewSongPath
                                                  ?.isNotEmpty !=
                                              true
                                      ? Colors.amber
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.forward_5),
                                  tooltip: Platform.isMacOS ? '→ +5s  •  ⌘+→ +30s' : '→ +5s  •  Ctrl+→ +30s',
                                  onPressed: () => _seek(5),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _volume == 0 ? Icons.volume_off : (_volume < 0.5 ? Icons.volume_down : Icons.volume_up),
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    if (_volume > 0) {
                                      setState(() { _preMuteVolume = _volume; _volume = 0; });
                                      await _audioPlayer.setVolume(0);
                                    } else {
                                      final restore = _preMuteVolume > 0 ? _preMuteVolume : 1.0;
                                      setState(() { _volume = restore; });
                                      await _audioPlayer.setVolume(restore);
                                    }
                                  },
                                  tooltip: _volume == 0 ? AppLocalizations.of(context)!.volumeUnmute : AppLocalizations.of(context)!.volumeMute,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                                SizedBox(
                                  width: 120,
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
                                Text(
                                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            // Waveform
                            WaveformWidget(
                              peaks: _peaks,
                              progress: _duration.inMilliseconds > 0
                                  ? _position.inMilliseconds / _duration.inMilliseconds
                                  : 0.0,
                              height: 80,
                              onSeek: (p) {
                                final target = Duration(milliseconds: (p * _duration.inMilliseconds).round());
                                setState(() => _position = target);
                                _audioPlayer.seek(target);
                              },
                            ),
                          ],
                        ),
                      ),
                      // Mono toggle + Analyze (any audio file)
                      if (_hasAudioFile()) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Tooltip(
                              message: AppLocalizations.of(context)!.monoToggleTooltip,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 18, height: 18,
                                    child: _isGeneratingMono
                                        ? const CircularProgressIndicator(strokeWidth: 2)
                                        : Checkbox(
                                            value: _isMono,
                                            onChanged: (_) => _toggleMono(),
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            visualDensity: VisualDensity.compact,
                                            activeColor: Colors.red,
                                          ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: _isGeneratingMono ? null : _toggleMono,
                                    child: Text(
                                      AppLocalizations.of(context)!.monoLabel,
                                      style: TextStyle(color: _isMono ? Colors.red : null),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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

                            if (MobileUtils.isMobile()) {
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
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: const [
                                  'mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac',
                                ],
                                dialogTitle: AppLocalizations.of(context)!.selectPreviewSong,
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
                          if (widget.project.previewSongPath != null &&
                              widget.project.previewSongPath!.isNotEmpty &&
                              !widget.project.previewSongPath!.startsWith('drive://'))
                            ElevatedButton.icon(
                              onPressed: _exportPreviewSongDesktop,
                              icon: const Icon(Icons.save_alt),
                              label: Text(AppLocalizations.of(context)!.saveCopy),
                            ),
                        ],
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
// Project Stats Button — navigates to the dedicated statistics page
// ---------------------------------------------------------------------------

// ─── File info row ────────────────────────────────────────────────────────────

class _FileInfoRow extends StatelessWidget {
  final String path;
  final AudioFileInfo? fileInfo;

  const _FileInfoRow({required this.path, required this.fileInfo});

  String get _formatLabel {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'wav': return 'WAV';
      case 'mp3': return 'MP3';
      case 'flac': return 'FLAC';
      case 'aif': case 'aiff': return 'AIFF';
      case 'aac': return 'AAC';
      case 'm4a': return 'M4A';
      case 'ogg': return 'OGG';
      default: return ext.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = Theme.of(context).textTheme.bodySmall?.color;

    final parts = <String>[];
    if (fileInfo != null) {
      final sr = fileInfo!.sampleRate;
      parts.add(sr % 1000 == 0 ? '${sr ~/ 1000} kHz' : '${(sr / 1000).toStringAsFixed(1)} kHz');
      if (fileInfo!.bitDepth != null) {
        parts.add('${fileInfo!.bitDepth}-bit');
      } else if (fileInfo!.bitrateKbps != null) {
        parts.add('${fileInfo!.bitrateKbps} kbps');
      }
      final ch = fileInfo!.channels;
      parts.add(ch == 1 ? 'Mono' : ch == 2 ? 'Stereo' : '${ch}ch');
    }
    parts.add(_formatLabel);

    return Text(
      parts.join(' · '),
      style: TextStyle(fontSize: 11, color: dim),
    );
  }
}

class _ProjectStatsButton extends ConsumerWidget {
  final String projectId;
  const _ProjectStatsButton({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final events = ref.watch(eventsForProjectProvider(projectId));

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.bar_chart_rounded, size: 20),
      title: Text(
        l10n.statsProjectActivity,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(
        events.isEmpty
            ? l10n.statsNoEvents
            : l10n.statsEventCount(events.length),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectStatisticsPage(projectId: projectId),
        ),
      ),
    );
  }
}

class _RenameProjectDialog extends StatefulWidget {
  final String currentName;
  final bool canRenameFolder;

  const _RenameProjectDialog({
    required this.currentName,
    required this.canRenameFolder,
  });

  @override
  State<_RenameProjectDialog> createState() => _RenameProjectDialogState();
}

class _RenameProjectDialogState extends State<_RenameProjectDialog> {
  late final TextEditingController _ctrl;
  bool _renameFolder = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentName);
    _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: widget.currentName.length);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.renameProjectFileTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.newFileNameLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final l10n = AppLocalizations.of(context)!;
                if (v == null || v.trim().isEmpty) return l10n.nameCannotBeEmpty;
                if (v.contains('/') || v.contains('\\') || v.contains(':')) {
                  return l10n.nameInvalidCharacters;
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            if (widget.canRenameFolder) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _renameFolder,
                onChanged: (v) => setState(() => _renameFolder = v ?? true),
                title: Text(AppLocalizations.of(context)!.alsoRenameContainingFolder),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(AppLocalizations.of(context)!.renameButton),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (
      newName: _ctrl.text.trim(),
      renameFolder: widget.canRenameFolder && _renameFolder,
    ));
  }
}

// ─── Session History Section ──────────────────────────────────────────────────

class _SessionHistorySection extends StatelessWidget {
  final List<SessionRecord> sessions;
  const _SessionHistorySection({required this.sessions});

  static String _fmtDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Newest first
    final sorted = [...sessions]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final totalSeconds = sessions.fold<int>(0, (a, b) => a + b.durationSeconds);
    final dateFmt = DateFormat('MMM d, yyyy');
    final timeFmt = DateFormat('HH:mm');
    final bodySmall = theme.textTheme.bodySmall;
    final divider = theme.dividerColor.withValues(alpha: 0.4);

    Widget cell(String text, {bool bold = false, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Text(
            text,
            style: bodySmall?.copyWith(
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              color: color,
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.work_history_outlined,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              l10n.sessionHistory,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (sessions.isEmpty)
          Text(
            l10n.noSessionsYet,
            style: bodySmall?.copyWith(color: theme.disabledColor),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              border: TableBorder(
                horizontalInside: BorderSide(color: divider, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  ),
                  children: [
                    cell('Date', bold: true),
                    cell('Time', bold: true),
                    cell('Duration', bold: true),
                  ],
                ),
                // One row per individual session
                for (final s in sorted)
                  TableRow(
                    children: [
                      cell(dateFmt.format(s.startedAt)),
                      cell('${timeFmt.format(s.startedAt)}–${timeFmt.format(s.endedAt)}'),
                      cell(_fmtDuration(s.durationSeconds)),
                    ],
                  ),
                // Total row
                TableRow(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  ),
                  children: [
                    cell('Total', bold: true, color: theme.colorScheme.primary),
                    cell('${sessions.length} session${sessions.length == 1 ? '' : 's'}',
                        color: theme.colorScheme.primary),
                    cell(_fmtDuration(totalSeconds), bold: true,
                        color: theme.colorScheme.primary),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
