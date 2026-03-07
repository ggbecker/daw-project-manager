import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:archive/archive.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/release.dart';
import 'widgets/desktop_title_bar.dart';
import '../models/release_file.dart';
import '../models/music_project.dart';
import '../providers/providers.dart';
import '../repository/project_repository.dart';
import '../utils/app_paths.dart';
import '../utils/mobile_utils.dart';
import '../utils/file_launcher.dart';
import '../generated/l10n/app_localizations.dart';
import 'project_detail_page.dart';
import 'widgets/todo_list_widget.dart';
import '../models/todo_item.dart';

class ReleaseDetailPage extends ConsumerStatefulWidget {
  final String releaseId;
  const ReleaseDetailPage({super.key, required this.releaseId});

  @override
  ConsumerState<ReleaseDetailPage> createState() => _ReleaseDetailPageState();
}

class _ReleaseDetailPageState extends ConsumerState<ReleaseDetailPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _artworkImagePath;
  DateTime? _releaseDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final releases = ref.read(releasesProvider);
      final release = releases.asData?.value.firstWhere(
        (r) => r.id == widget.releaseId,
        orElse: () => throw StateError('Release not found'),
      );
    if (release != null) {
      _titleController.text = release.title;
      _descriptionController.text = release.description ?? '';
        setState(() {
      _artworkImagePath = release.artworkImagePath;
          _releaseDate = release.releaseDate;
        });
    }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveReleaseDate(Release release, DateTime? date) async {
    try {
      final repo = await ref.read(repositoryProvider.future);
      final updatedRelease = release.copyWith(
        releaseDate: date,
        clearReleaseDate: date == null,
      );
      await repo.updateRelease(updatedRelease);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(date != null ? AppLocalizations.of(context)!.releaseDateSaved : AppLocalizations.of(context)!.releaseDateCleared)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToSaveReleaseDate(e.toString()))),
        );
      }
    }
  }

  String _getFileType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    if (['.wav', '.mp3', '.flac', '.aac', '.ogg', '.m4a'].contains(ext)) {
      return 'audio';
    } else if (['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(ext)) {
      return 'video';
    } else if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(ext)) {
      return 'image';
    } else if (['.pdf', '.doc', '.docx', '.txt', '.rtf'].contains(ext)) {
      return 'document';
    }
    return 'other';
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

  Future<void> _addFiles(BuildContext context, Release release) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;

    try {
      final releasesDirPath = await getReleaseFilesPath(release.id);
      final releasesDir = Directory(releasesDirPath);
      
      if (!await releasesDir.exists()) {
        await releasesDir.create(recursive: true);
      }

      final repo = await ref.read(repositoryProvider.future);
      final newFiles = <ReleaseFile>[];

      for (final pickedFile in result.files) {
        if (pickedFile.path == null) continue;
        
        final sourceFile = File(pickedFile.path!);
        if (!await sourceFile.exists()) continue;

        final fileExtension = path.extension(pickedFile.path!);
        final fileName = '${const Uuid().v4()}$fileExtension';
        final destPath = path.join(releasesDir.path, fileName);
        
        final destFile = await sourceFile.copy(destPath);
        final fileSize = await destFile.length();
        
        final releaseFile = ReleaseFile(
          id: const Uuid().v4(),
          fileName: pickedFile.name,
          filePath: destFile.path,
          fileType: _getFileType(pickedFile.name),
          fileSizeBytes: fileSize,
          addedAt: DateTime.now(),
        );
        
        newFiles.add(releaseFile);
      }

      if (newFiles.isNotEmpty) {
        final updatedFiles = [...release.files, ...newFiles];
        final updatedRelease = release.copyWith(files: updatedFiles);
        await repo.updateRelease(updatedRelease);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.addedFilesToRelease(newFiles.length, newFiles.length == 1 ? '' : 's'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToAddFiles(e.toString()))),
        );
      }
    }
  }

  Future<void> _downloadAsZip(BuildContext context, Release release) async {
    if (release.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noFilesToDownload)),
      );
      return;
    }

    // Ask user where to save the ZIP
    final safeName = release.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: AppLocalizations.of(context)!.saveReleaseFilesZip,
      fileName: '${safeName}_files.zip',
      type: FileType.any,
    );

    if (savePath == null) {
      return; // user cancelled
    }

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.creatingZipFile,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final zipFile = File(savePath);
      if (!await zipFile.parent.exists()) {
        await zipFile.parent.create(recursive: true);
      }
      if (await zipFile.exists()) {
        await zipFile.delete();
      }

      final archive = Archive();
      
      // Separate audio files from other files
      final audioFiles = release.files.where((f) => f.fileType == 'audio').toList();
      final otherFiles = release.files.where((f) => f.fileType != 'audio').toList();
      
      // Add audio files using their display names
      for (final releaseFile in audioFiles) {
        final file = File(releaseFile.filePath);
        if (await file.exists()) {
          final fileData = await file.readAsBytes();
          // Use the display fileName (which may include track numbers if user added them)
          archive.addFile(
            ArchiveFile(
              releaseFile.fileName,
              fileData.length,
              fileData,
            ),
          );
        }
      }
      
      // Add other files without track numbers
      for (final releaseFile in otherFiles) {
        final file = File(releaseFile.filePath);
        if (await file.exists()) {
          final fileData = await file.readAsBytes();
          archive.addFile(
            ArchiveFile(
              releaseFile.fileName,
              fileData.length,
              fileData,
            ),
          );
        }
      }

      final zipData = ZipEncoder().encode(archive);
      await zipFile.writeAsBytes(zipData);
    
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.zipFileSaved(zipFile.path)),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.openFolder,
              onPressed: () async {
                final folderPath = path.dirname(zipFile.path);
                await FileLauncher.openFolder(folderPath);
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToCreateZip(e.toString()))),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final releases = ref.read(releasesProvider);
    final release = releases.asData?.value.firstWhere(
      (r) => r.id == widget.releaseId,
      orElse: () => throw StateError('Release not found'),
    );
    
    if (release == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.releaseNotFound)),
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final sourcePath = result.files.single.path!;
      final sourceFile = File(sourcePath);
      
      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.selectedFileDoesNotExist)),
          );
        }
        return;
      }

      try {
        // Get release artwork directory
        final releasesDirPath = await getReleaseArtworkPath();
        final releasesDir = Directory(releasesDirPath);
        
        // Create directory if it doesn't exist
        if (!await releasesDir.exists()) {
          await releasesDir.create(recursive: true);
        }

        // Generate unique filename
        final fileExtension = path.extension(sourcePath);
        final fileName = '${const Uuid().v4()}$fileExtension';
        final destPath = path.join(releasesDir.path, fileName);
        
        // Copy file to persistent location
        final destFile = await sourceFile.copy(destPath);
        
        // Delete old artwork if it exists and is in our app directory
        if (release.artworkImagePath != null && release.artworkImagePath!.contains('release_artwork')) {
          try {
            final oldFile = File(release.artworkImagePath!);
            if (await oldFile.exists()) {
              await oldFile.delete();
            }
          } catch (_) {
            // Ignore errors deleting old file
          }
        }
        
        final newImagePath = destFile.path;
        
        // Automatically save the release with the new image path
        final repo = await ref.read(repositoryProvider.future);
        final updatedRelease = release.copyWith(
          artworkImagePath: newImagePath,
        );
        await repo.updateRelease(updatedRelease);
        
      setState(() {
          _artworkImagePath = newImagePath;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.imageSavedSuccessfully)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToSaveImage(e.toString()))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) print('ReleaseDetailPage.build: Starting build');
    final releases = ref.watch(releasesProvider);
    final allProjectsAsync = ref.watch(allProjectsStreamProvider);

    // Handle loading/error states for both providers
    if (releases.isLoading || allProjectsAsync.isLoading) {
      if (kDebugMode) print('ReleaseDetailPage.build: Loading state');
      return Scaffold(
        appBar: null,
        body: Column(
          children: [
            DesktopTitleBar(title: AppLocalizations.of(context)!.releaseDetails, showBack: true),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    if (releases.hasError) {
      return Scaffold(
        appBar: null,
        body: Column(
          children: [
            DesktopTitleBar(title: AppLocalizations.of(context)!.error, showBack: true),
            Expanded(child: Center(child: Text(AppLocalizations.of(context)!.errorLoadingRelease(releases.error.toString())))),
          ],
        ),
      );
    }

    if (allProjectsAsync.hasError) {
      return Scaffold(
        appBar: null,
        body: Column(
          children: [
            DesktopTitleBar(title: AppLocalizations.of(context)!.error, showBack: true),
            Expanded(child: Center(child: Text('${AppLocalizations.of(context)!.errorLoadingProjects}: ${allProjectsAsync.error}'))),
          ],
        ),
      );
    }

    // Both providers have data
    final releasesList = releases.value ?? [];
    final allProjects = allProjectsAsync.value ?? [];

    try {
      final release = releasesList.firstWhere((r) => r.id == widget.releaseId);

      // Sync controllers and state with release data (only on initial load)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_titleController.text != release.title) {
          _titleController.text = release.title;
        }
        if (_descriptionController.text != (release.description ?? '')) {
          _descriptionController.text = release.description ?? '';
        }
        if (_artworkImagePath != release.artworkImagePath) {
          setState(() {
            _artworkImagePath = release.artworkImagePath;
          });
        }
        // Only set release date from storage if we haven't loaded it yet
        if (_releaseDate == null && release.releaseDate != null) {
          setState(() {
            _releaseDate = release.releaseDate;
          });
        }
      });

      // Maintain the explicit order defined in release.trackIds
      // Use allProjects from repository (includes preserved projects) instead of filtered projectsProvider
      final releaseProjects = <MusicProject>[];
      for (final id in release.trackIds) {
        try {
          final project = allProjects.firstWhere((p) => p.id == id);
          releaseProjects.add(project);
        } catch (_) {
          // Project not found - this shouldn't happen for preserved projects, but handle gracefully
        }
      }

      final isMobile = MobileUtils.isMobile();
      if (kDebugMode) {
        print('ReleaseDetailPage.build: Building release detail');
        print('  Release ID: ${widget.releaseId}');
        print('  Is Mobile: $isMobile');
        print('  Release projects count: ${releaseProjects.length}');
        print('  Release files count: ${release.files.length}');
      }
      
      if (isMobile) {
        return _buildMobileLayout(context, release, releaseProjects);
      } else {
        return _buildDesktopLayout(context, release, releaseProjects);
      }
    } catch (e) {
      final isMobile = MobileUtils.isMobile();
      return Scaffold(
        appBar: isMobile
            ? AppBar(
                title: Text(AppLocalizations.of(context)!.releaseNotFound),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
        body: Column(
          children: [
            if (!isMobile) DesktopTitleBar(title: AppLocalizations.of(context)!.releaseNotFound, showBack: true),
            Expanded(child: Center(child: Text(AppLocalizations.of(context)!.releaseNotFound))),
          ],
        ),
      );
    }
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================
  
  Widget _buildMobileLayout(BuildContext context, Release release, List<MusicProject> releaseProjects) {
    return Scaffold(
      appBar: AppBar(
        title: Text(release.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: MobileUtils.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildArtworkSection(context, release),
            const SizedBox(height: 16),
            _buildDetailsSection(context, release),
            const SizedBox(height: 24),
            _buildTracksSection(context, release, releaseProjects),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================
  
  Widget _buildDesktopLayout(BuildContext context, Release release, List<MusicProject> releaseProjects) {
    return Scaffold(
      body: Column(
        children: [
          DesktopTitleBar(title: release.title, showBack: true),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: Artwork and details
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDesktopArtworkSection(context, release),
                        const SizedBox(height: 16),
                        _buildDesktopDetailsSection(context, release),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Right side: Tracklist and Files
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDesktopTracksSection(context, release, releaseProjects),
                      const Divider(height: 2),
                      _buildDesktopFilesSection(context, release),
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

  // ============================================================================
  // DESKTOP SPECIFIC SECTIONS
  // ============================================================================
  
  Widget _buildDesktopArtworkSection(BuildContext context, Release release) {
    return GestureDetector(
      onTap: _pickImage,
      child: Card(
        child: Builder(
          builder: (context) {
            final imagePath = release.artworkImagePath ?? _artworkImagePath;
            if (imagePath != null && File(imagePath).existsSync()) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth * 0.5;
                  return Center(
                    child: SizedBox(
                      width: maxWidth,
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 50, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context)!.imageNotFound,
                                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 50, color: Theme.of(context).textTheme.bodySmall?.color),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.clickToBrowseArtwork,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopDetailsSection(BuildContext context, Release release) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.releaseTitle),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: AppLocalizations.of(context)!.save,
              onPressed: () async {
                final releases = ref.read(releasesProvider);
                final release = releases.asData?.value.firstWhere(
                  (r) => r.id == widget.releaseId,
                  orElse: () => throw StateError('Release not found'),
                );
                if (release != null) {
                  final repo = await ref.read(repositoryProvider.future);
                  final updatedRelease = release.copyWith(
                    title: _titleController.text,
                    description: _descriptionController.text,
                    artworkImagePath: _artworkImagePath,
                  );
                  await repo.updateRelease(updatedRelease);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.releaseSaved)),
                    );
                  }
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description),
          maxLines: 5,
        ),
        const SizedBox(height: 16),
        ListTile(
          title: Text(AppLocalizations.of(context)!.releaseDate),
          subtitle: Text(
            _releaseDate != null
                ? DateFormat.yMMMd().format(_releaseDate!)
                : AppLocalizations.of(context)!.noDateSet,
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_releaseDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _releaseDate = null;
                    });
                    _saveReleaseDate(release, null);
                  },
                  tooltip: AppLocalizations.of(context)!.tooltipClearDate,
                ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _releaseDate ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _releaseDate = DateTime(picked.year, picked.month, picked.day);
                    });
                    _saveReleaseDate(release, DateTime(picked.year, picked.month, picked.day));
                  }
                },
                tooltip: AppLocalizations.of(context)!.tooltipPickDate,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TodoListWidget(
          todos: release.todos,
          onTodosChanged: (updatedTodos) async {
            final repo = await ref.read(repositoryProvider.future);
            final updatedRelease = release.copyWith(todos: updatedTodos);
            await repo.updateRelease(updatedRelease);
          },
        ),
      ],
    );
  }

  Widget _buildDesktopTracksSection(BuildContext context, Release release, List<MusicProject> releaseProjects) {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.tracksCount(releaseProjects.length),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context)!.addTracks),
                  onPressed: () => _handleAddTracks(context, release),
                ),
              ],
            ),
          ),
          const Divider(),
          // Tracks list
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              buildDefaultDragHandles: false,
              itemCount: releaseProjects.length,
              onReorder: (oldIndex, newIndex) => _handleReorderTrack(release, oldIndex, newIndex),
              itemBuilder: (context, index) => _buildDesktopTrackTile(context, release, releaseProjects[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTrackTile(BuildContext context, Release release, MusicProject project, int index) {
    final folderPath = FileSystemEntity.isDirectorySync(project.filePath)
        ? project.filePath
        : path.dirname(project.filePath);

    return Card(
      key: ValueKey(project.id),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Theme.of(context).cardColor,
      child: GestureDetector(
        onDoubleTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProjectDetailPage(projectId: project.id),
            ),
          );
        },
        child: ListTile(
          leading: ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_indicator, color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
          title: Text(project.displayName),
          subtitle: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (project.dawType != null && project.dawType!.isNotEmpty) ...[
                Text(
                  project.dawVersion != null && project.dawVersion!.isNotEmpty
                      ? '${project.dawType!} ${project.dawVersion!}'
                      : project.dawType!,
                ),
                Text('•', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
              if (project.bpm != null) ...[
                Text('${project.bpm!.toStringAsFixed(0)} ${AppLocalizations.of(context)!.bpm}'),
                Text('•', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
              if (project.musicalKey != null && project.musicalKey!.isNotEmpty) ...[
                Text(project.musicalKey!),
                Text('•', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
              Text(
                _translateStatus(context, project.status),
                style: TextStyle(
                  color: _getStatusColor(project.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: AppLocalizations.of(context)!.tooltipLaunchInDaw,
                onPressed: () => _handleLaunchInDaw(context, project),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '|',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 18),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.assignment),
                tooltip: AppLocalizations.of(context)!.tooltipViewDetails,
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProjectDetailPage(projectId: project.id),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.folder_open),
                tooltip: AppLocalizations.of(context)!.openFolder,
                onPressed: () => _handleOpenFolder(context, project, folderPath),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '|',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 18),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.red.shade300,
                tooltip: AppLocalizations.of(context)!.tooltipRemoveFromRelease,
                onPressed: () => _handleRemoveTrack(context, release, project),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopFilesSection(BuildContext context, Release release) {
    return Flexible(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.releaseFilesCount(release.files.length),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_upload),
                      label: Text(AppLocalizations.of(context)!.addFiles),
                      onPressed: () => _addFiles(context, release),
                    ),
                    const SizedBox(width: 8),
                    if (release.files.isNotEmpty)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        label: Text(AppLocalizations.of(context)!.saveReleaseFilesZip),
                        onPressed: () => _downloadAsZip(context, release),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // Files list
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: release.files.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.noFilesAddedYet,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                    )
                  : _FilesSection(
                      files: release.files,
                      release: release,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS FOR DESKTOP ACTIONS
  // ============================================================================
  
  Future<void> _handleAddTracks(BuildContext context, Release release) async {
    final allProjectsAsync = ref.read(allProjectsStreamProvider);
    final allProjects = allProjectsAsync.value ?? [];
    final availableProjects = allProjects.where((p) => !release.trackIds.contains(p.id)).toList();
    
    if (availableProjects.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.allProjectsAlreadyInRelease)),
        );
      }
      return;
    }

    final selectedIds = await showDialog<List<String>>(
      context: context,
      builder: (context) => _TrackSelectionDialog(projects: availableProjects),
    );

    if (selectedIds != null && selectedIds.isNotEmpty) {
      final repo = await ref.read(repositoryProvider.future);
      final updatedTrackIds = {...release.trackIds, ...selectedIds}.toList();
      final updatedRelease = release.copyWith(trackIds: updatedTrackIds);
      await repo.updateRelease(updatedRelease);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.addedTracksToRelease(selectedIds.length, selectedIds.length == 1 ? '' : 's'))),
        );
      }
    }
  }

  void _handleReorderTrack(Release release, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final updatedTrackIds = List<String>.from(release.trackIds);
    final moved = updatedTrackIds.removeAt(oldIndex);
    updatedTrackIds.insert(newIndex, moved);

    setState(() {
      // Optimistic local update
    });

    // Persist
    () async {
      final repo = await ref.read(repositoryProvider.future);
      await repo.updateRelease(release.copyWith(trackIds: updatedTrackIds));
    }();
  }

  Future<void> _handleLaunchInDaw(BuildContext context, MusicProject project) async {
    final exists = File(project.filePath).existsSync() || Directory(project.filePath).existsSync();
    if (!exists) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.fileMissing)),
        );
      }
      return;
    }
    final success = await FileLauncher.launchProject(project.filePath);
    
    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.launchingProject(project.displayName))),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToLaunchProject(project.displayName))),
        );
      }
    }
  }

  Future<void> _handleOpenFolder(BuildContext context, MusicProject project, String folderPath) async {
    final exists = Directory(folderPath).existsSync();
    if (!exists) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.fileMissing)),
        );
      }
      return;
    }
    
    final success = await FileLauncher.openFolder(folderPath);
    
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.openingFolder(project.displayName))),
      );
    }
  }

  Future<void> _handleRemoveTrack(BuildContext context, Release release, MusicProject project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.tooltipRemoveFromRelease),
        content: Text(AppLocalizations.of(context)!.removeTrackFromReleaseMessage(project.displayName)),
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
            child: Text(AppLocalizations.of(context)!.remove),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final repo = await ref.read(repositoryProvider.future);
      final updatedTrackIds = release.trackIds.where((id) => id != project.id).toList();
      final updatedRelease = release.copyWith(trackIds: updatedTrackIds);
      await repo.updateRelease(updatedRelease);
    }
  }

  // ============================================================================
  // SHARED SECTIONS (used by both mobile and desktop)
  // ============================================================================

  Widget _buildArtworkSection(BuildContext context, Release release) {
    return GestureDetector(
      onTap: _pickImage,
      child: Card(
        child: Builder(
          builder: (context) {
            final imagePath = release.artworkImagePath ?? _artworkImagePath;
            if (imagePath != null && File(imagePath).existsSync()) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 50, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.imageNotFound,
                                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 50, color: Theme.of(context).textTheme.bodySmall?.color),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.clickToBrowseArtwork,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, Release release) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.releaseTitle),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: AppLocalizations.of(context)!.save,
                  onPressed: () async {
                    final releases = ref.read(releasesProvider);
                    final release = releases.asData?.value.firstWhere(
                      (r) => r.id == widget.releaseId,
                      orElse: () => throw StateError('Release not found'),
                    );
                    if (release != null) {
                      final repo = await ref.read(repositoryProvider.future);
                      final updatedRelease = release.copyWith(
                        title: _titleController.text,
                        description: _descriptionController.text,
                        artworkImagePath: _artworkImagePath,
                      );
                      await repo.updateRelease(updatedRelease);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.releaseSaved)),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(AppLocalizations.of(context)!.releaseDate),
              subtitle: Text(
                _releaseDate != null
                    ? DateFormat.yMMMd().format(_releaseDate!)
                    : AppLocalizations.of(context)!.noDateSet,
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_releaseDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _releaseDate = null;
                        });
                        _saveReleaseDate(release, null);
                      },
                      tooltip: AppLocalizations.of(context)!.tooltipClearDate,
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _releaseDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _releaseDate = DateTime(picked.year, picked.month, picked.day);
                        });
                        _saveReleaseDate(release, DateTime(picked.year, picked.month, picked.day));
                      }
                    },
                    tooltip: AppLocalizations.of(context)!.tooltipPickDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TodoListWidget(
              todos: release.todos,
              onTodosChanged: (updatedTodos) async {
                final repo = await ref.read(repositoryProvider.future);
                final updatedRelease = release.copyWith(todos: updatedTodos);
                await repo.updateRelease(updatedRelease);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTracksSection(BuildContext context, Release release, List<MusicProject> releaseProjects) {
    final isMobile = MobileUtils.isMobile();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tracks Section Header
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.tracksCount(releaseProjects.length),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(AppLocalizations.of(context)!.addTracks),
                          onPressed: () async {
                            final allProjectsAsync = ref.read(allProjectsStreamProvider);
                            final allProjects = allProjectsAsync.value ?? [];
                            final availableProjects = allProjects.where((p) => !release.trackIds.contains(p.id)).toList();
                            
                            if (availableProjects.isEmpty) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(AppLocalizations.of(context)!.allProjectsAlreadyInRelease)),
                                );
                              }
                              return;
                            }

                            final selectedIds = await showDialog<List<String>>(
                              context: context,
                              builder: (context) => _TrackSelectionDialog(projects: availableProjects),
                            );

                            if (selectedIds != null && selectedIds.isNotEmpty) {
                              final repo = await ref.read(repositoryProvider.future);
                              final updatedTrackIds = {...release.trackIds, ...selectedIds}.toList();
                              final updatedRelease = release.copyWith(trackIds: updatedTrackIds);
                              await repo.updateRelease(updatedRelease);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(AppLocalizations.of(context)!.addedTracksToRelease(selectedIds.length, selectedIds.length == 1 ? '' : 's'))),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.tracksCount(releaseProjects.length),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(AppLocalizations.of(context)!.addTracks),
                        onPressed: () async {
                          final allProjectsAsync = ref.read(allProjectsStreamProvider);
                          final allProjects = allProjectsAsync.value ?? [];
                          final availableProjects = allProjects.where((p) => !release.trackIds.contains(p.id)).toList();
                          
                          if (availableProjects.isEmpty) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)!.allProjectsAlreadyInRelease)),
                              );
                            }
                            return;
                          }

                          final selectedIds = await showDialog<List<String>>(
                            context: context,
                            builder: (context) => _TrackSelectionDialog(projects: availableProjects),
                          );

                          if (selectedIds != null && selectedIds.isNotEmpty) {
                            final repo = await ref.read(repositoryProvider.future);
                            final updatedTrackIds = {...release.trackIds, ...selectedIds}.toList();
                            final updatedRelease = release.copyWith(trackIds: updatedTrackIds);
                            await repo.updateRelease(updatedRelease);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)!.addedTracksToRelease(selectedIds.length, selectedIds.length == 1 ? '' : 's'))),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
            const Divider(),
            // Tracks List
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: isMobile ? 400 : 600,
              ),
              child: releaseProjects.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          AppLocalizations.of(context)!.noTracksFound,
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      buildDefaultDragHandles: false,
                      itemCount: releaseProjects.length,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final updatedTrackIds = List<String>.from(release.trackIds);
                        final moved = updatedTrackIds.removeAt(oldIndex);
                        updatedTrackIds.insert(newIndex, moved);
                        setState(() {});
                        () async {
                          final repo = await ref.read(repositoryProvider.future);
                          await repo.updateRelease(release.copyWith(trackIds: updatedTrackIds));
                        }();
                      },
                      itemBuilder: (context, index) {
                        final project = releaseProjects[index];
                        final folderPath = FileSystemEntity.isDirectorySync(project.filePath)
                            ? project.filePath
                            : path.dirname(project.filePath);

                        return Card(
                          key: ValueKey(project.id),
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: Theme.of(context).cardColor,
                          child: GestureDetector(
                            onDoubleTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProjectDetailPage(projectId: project.id),
                                ),
                              );
                            },
                            child: isMobile
                                ? _buildMobileTrackTile(context, project, release, folderPath, index)
                                : ListTile(
                                    leading: ReorderableDragStartListener(
                                      index: index,
                                      child: Icon(Icons.drag_indicator, color: Theme.of(context).textTheme.bodyMedium?.color),
                                    ),
                                    title: Text(project.displayName),
                                    subtitle: Wrap(
                                      spacing: 8,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        if (project.dawType != null && project.dawType!.isNotEmpty) ...[
                                          Text(
                                            project.dawVersion != null && project.dawVersion!.isNotEmpty
                                                ? '${project.dawType!} ${project.dawVersion!}'
                                                : project.dawType!,
                                          ),
                                          Text('•', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                                        ],
                                        if (project.bpm != null) ...[
                                          Text('${project.bpm!.toStringAsFixed(0)} ${AppLocalizations.of(context)!.bpm}'),
                                          Text('•', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                                        ],
                                        if (project.musicalKey != null && project.musicalKey!.isNotEmpty) ...[
                                          Text(project.musicalKey!),
                                          Text('•', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                                        ],
                                        Text(
                                          _translateStatus(context, project.status),
                                          style: TextStyle(
                                            color: _getStatusColor(project.status),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Launch button - only on desktop
                                        if (!isMobile)
                                          IconButton(
                                            icon: const Icon(Icons.open_in_new),
                                            tooltip: AppLocalizations.of(context)!.tooltipLaunchInDaw,
                                            onPressed: () async {
                                              final exists = File(project.filePath).existsSync() || 
                                                            Directory(project.filePath).existsSync();
                                              if (!exists) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(AppLocalizations.of(context)!.fileMissing)),
                                                  );
                                                }
                                                return;
                                              }
                                              final success = await FileLauncher.launchProject(project.filePath);
                                              
                                              if (success) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(AppLocalizations.of(context)!.launchingProject(project.displayName))),
                                                  );
                                                }
                                              } else {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(AppLocalizations.of(context)!.failedToLaunchProject(project.displayName))),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        // Separator - only if Launch button is shown
                                        if (!isMobile)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Text(
                                              '|',
                                              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 18),
                                            ),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.assignment),
                                          tooltip: AppLocalizations.of(context)!.tooltipViewDetails,
                                          onPressed: () async {
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => ProjectDetailPage(projectId: project.id),
                                              ),
                                            );
                                          },
                                        ),
                                        // Open Folder button - only on desktop
                                        if (!isMobile)
                                          IconButton(
                                            icon: const Icon(Icons.folder_open),
                                            tooltip: AppLocalizations.of(context)!.openFolder,
                                            onPressed: () async {
                                              final exists = Directory(folderPath).existsSync();
                                              if (!exists) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text(AppLocalizations.of(context)!.fileMissing)),
                                                  );
                                                }
                                                return;
                                              }
                                              
                                              final success = await FileLauncher.openFolder(folderPath);
                                              
                                              if (success && context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(AppLocalizations.of(context)!.openingFolder(project.displayName))),
                                                );
                                              }
                                            },
                                          ),
                                        // Separator - only if Open Folder button is shown
                                        if (!isMobile)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Text(
                                              '|',
                                              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 18),
                                            ),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline),
                                          color: Colors.red.shade300,
                                          tooltip: AppLocalizations.of(context)!.tooltipRemoveFromRelease,
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                backgroundColor: Theme.of(context).cardColor,
                                                title: Text(AppLocalizations.of(context)!.tooltipRemoveFromRelease),
                                                content: Text(AppLocalizations.of(context)!.removeTrackFromReleaseMessage(project.displayName)),
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
                                                    child: Text(AppLocalizations.of(context)!.remove),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true && mounted) {
                                              final repo = await ref.read(repositoryProvider.future);
                                              final updatedTrackIds = release.trackIds.where((id) => id != project.id).toList();
                                              final updatedRelease = release.copyWith(trackIds: updatedTrackIds);
                                              await repo.updateRelease(updatedRelease);
                                            }
                                          },
                                        ),
                                      ],
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
    );
  }

  Widget _buildMobileTrackTile(BuildContext context, MusicProject project, Release release, String folderPath, int index) {
    // This function is only used for mobile, so we don't show Launch and Open Folder buttons
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Icon(Icons.drag_indicator, color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.displayName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (project.dawType != null && project.dawType!.isNotEmpty)
                          Text(
                            project.dawVersion != null && project.dawVersion!.isNotEmpty
                                ? '${project.dawType!} ${project.dawVersion!}'
                                : project.dawType!,
                            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                        if (project.bpm != null)
                          Text(
                            '${project.bpm!.toStringAsFixed(0)} ${AppLocalizations.of(context)!.bpm}',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                        if (project.musicalKey != null && project.musicalKey!.isNotEmpty)
                          Text(
                            project.musicalKey!,
                            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                        Text(
                          _translateStatus(context, project.status),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(project.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // View Details button (available on all platforms)
              OutlinedButton.icon(
                icon: const Icon(Icons.assignment, size: 18),
                label: Text(AppLocalizations.of(context)!.tooltipViewDetails),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProjectDetailPage(projectId: project.id),
                    ),
                  );
                },
              ),
              OutlinedButton.icon(
                icon: Icon(Icons.remove_circle_outline, size: 18, color: Colors.red.shade300),
                label: Text(
                  AppLocalizations.of(context)!.tooltipRemoveFromRelease,
                  style: TextStyle(color: Colors.red.shade300),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Theme.of(context).cardColor,
                      title: Text(AppLocalizations.of(context)!.tooltipRemoveFromRelease),
                      content: Text(AppLocalizations.of(context)!.removeTrackFromReleaseMessage(project.displayName)),
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
                          child: Text(AppLocalizations.of(context)!.remove),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    final repo = await ref.read(repositoryProvider.future);
                    final updatedTrackIds = release.trackIds.where((id) => id != project.id).toList();
                    final updatedRelease = release.copyWith(trackIds: updatedTrackIds);
                    await repo.updateRelease(updatedRelease);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade300,
                  side: BorderSide(color: Colors.red.shade300),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilesSection(BuildContext context, Release release) {
    final isMobile = MobileUtils.isMobile();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Files Section Header
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.releaseFilesCount(release.files.length),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.file_upload),
                              label: Text(AppLocalizations.of(context)!.addFiles),
                              onPressed: () => _addFiles(context, release),
                            ),
                          ),
                          if (release.files.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.download),
                                label: Text(AppLocalizations.of(context)!.saveReleaseFilesZip),
                                onPressed: () => _downloadAsZip(context, release),
                              ),
                            ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.releaseFilesCount(release.files.length),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.file_upload),
                            label: Text(AppLocalizations.of(context)!.addFiles),
                            onPressed: () => _addFiles(context, release),
                          ),
                          const SizedBox(width: 8),
                          if (release.files.isNotEmpty)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.download),
                              label: Text(AppLocalizations.of(context)!.saveReleaseFilesZip),
                              onPressed: () => _downloadAsZip(context, release),
                            ),
                        ],
                      ),
                    ],
                  ),
            const Divider(),
            // Files List
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: isMobile ? 400 : 600,
              ),
              child: release.files.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          AppLocalizations.of(context)!.noFilesAddedYet,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ),
                    )
                  : _FilesSection(
                      files: release.files,
                      release: release,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilesSection extends ConsumerStatefulWidget {
  final List<ReleaseFile> files;
  final Release release;

  const _FilesSection({
    required this.files,
    required this.release,
  });

  @override
  ConsumerState<_FilesSection> createState() => _FilesSectionState();
}

class _FilesSectionState extends ConsumerState<_FilesSection> {
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType) {
      case 'audio':
        return Icons.audiotrack;
      case 'video':
        return Icons.videocam;
      case 'image':
        return Icons.image;
      case 'document':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _reorderAudioFiles(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final audioFiles = widget.files.where((f) => f.fileType == 'audio').toList();
    final otherFiles = widget.files.where((f) => f.fileType != 'audio').toList();

    final reorderedAudio = List<ReleaseFile>.from(audioFiles);
    final item = reorderedAudio.removeAt(oldIndex);
    reorderedAudio.insert(newIndex, item);

    // Reconstruct files list: audio files first (in new order), then other files
    final updatedFiles = [...reorderedAudio, ...otherFiles];

    final repo = await ref.read(repositoryProvider.future);
    final updatedRelease = widget.release.copyWith(files: updatedFiles);
    await repo.updateRelease(updatedRelease);
  }

  Future<void> _renameFile(ReleaseFile updatedFile) async {
    try {
      final repo = await ref.read(repositoryProvider.future);
      final updatedFiles = widget.release.files.map((f) {
        return f.id == updatedFile.id ? updatedFile : f;
      }).toList();
      
      final updatedRelease = widget.release.copyWith(files: updatedFiles);
      await repo.updateRelease(updatedRelease);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.fileNameUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorUpdatingFileName(e.toString()))),
        );
      }
    }
  }

  Future<void> _deleteFile(ReleaseFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.deleteFile),
        content: Text(AppLocalizations.of(context)!.deleteFileMessage(file.fileName)),
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
    if (confirm == true) {
      try {
        // Delete physical file
        final fileObj = File(file.filePath);
        if (await fileObj.exists()) {
          await fileObj.delete();
        }
        
        // Remove from release
        final repo = await ref.read(repositoryProvider.future);
        final updatedFiles = widget.release.files.where((f) => f.id != file.id).toList();
        final updatedRelease = widget.release.copyWith(files: updatedFiles);
        await repo.updateRelease(updatedRelease);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.fileDeleted(file.fileName))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToDeleteFile(e.toString()))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioFiles = widget.files.where((f) => f.fileType == 'audio').toList();
    final otherFiles = widget.files.where((f) => f.fileType != 'audio').toList();

    return ListView(
      children: [
        // Audio Files Section
        if (audioFiles.isNotEmpty) ...[
          Text(
            'Audio Files (${audioFiles.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: audioFiles.length,
            onReorder: _reorderAudioFiles,
            itemBuilder: (context, index) {
              final file = audioFiles[index];
              final fileExists = File(file.filePath).existsSync();

              if (fileExists) {
                return _AudioFileItem(
                  key: ValueKey(file.id),
                  file: file,
                  release: widget.release,
                  onDelete: () => _deleteFile(file),
                  onRename: (updatedFile) => _renameFile(updatedFile),
                );
              } else {
                return Card(
                  key: ValueKey(file.id),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Theme.of(context).cardColor,
                  child: ListTile(
                    leading: Icon(Icons.drag_indicator, color: Theme.of(context).textTheme.bodySmall?.color),
                    title: Text(
                      file.fileName,
                      style: const TextStyle(color: Colors.red),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.fileNotFound,
                      style: const TextStyle(color: Colors.red),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red.shade300,
                      onPressed: () => _deleteFile(file),
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],

        // Other Files Section
        if (otherFiles.isNotEmpty) ...[
          Text(
            'Other Files (${otherFiles.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...otherFiles.map((file) {
            final fileExists = File(file.filePath).existsSync();
            return ListTile(
              leading: Icon(
                _getFileTypeIcon(file.fileType),
                color: fileExists ? Theme.of(context).textTheme.bodyMedium?.color : Colors.red.shade300,
              ),
              title: Text(
                file.fileName,
                style: TextStyle(
                  color: fileExists ? Theme.of(context).textTheme.bodyLarge?.color : Colors.red.shade300,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${file.fileType.toUpperCase()} • ${_formatFileSize(file.fileSizeBytes)}',
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  if (file.description != null && file.description!.isNotEmpty)
                    Text(
                      file.description!,
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                    ),
                  Text(
                    DateFormat.yMMMd().add_jm().format(file.addedAt),
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 11),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!fileExists)
                    Tooltip(
                      message: AppLocalizations.of(context)!.fileNotFound,
                      child: const Icon(Icons.warning, color: Colors.red, size: 20),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red.shade300,
                    onPressed: () => _deleteFile(file),
                  ),
                ],
              ),
              onTap: fileExists
                  ? () async {
                      // Open file
                      final success = await FileLauncher.openFile(file.filePath);
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.failedToOpenFile('Unable to open file'))),
                        );
                      }
                    }
                  : null,
            );
          }),
        ],
      ],
    );
  }
}

class _AudioFileItem extends ConsumerStatefulWidget {
  final ReleaseFile file;
  final Release release;
  final VoidCallback onDelete;
  final Function(ReleaseFile) onRename;

  const _AudioFileItem({
    super.key,
    required this.file,
    required this.release,
    required this.onDelete,
    required this.onRename,
  });

  @override
  ConsumerState<_AudioFileItem> createState() => _AudioFileItemState();
}

class _AudioFileItemState extends ConsumerState<_AudioFileItem> {
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
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position == Duration.zero || _position >= _duration) {
          await _audioPlayer.play(DeviceFileSource(widget.file.filePath));
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToPlayAudio(e.toString()))),
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _showRenameDialog(BuildContext context) async {
    final controller = TextEditingController(text: widget.file.fileName);
    
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.renameFile),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.fileName,
            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.grey),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx, newName);
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );

    if (result != null && result != widget.file.fileName) {
      final updatedFile = widget.file.copyWith(fileName: result);
      widget.onRename(updatedFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File info header
            Row(
                    children: [
                      Icon(Icons.drag_indicator, color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(width: 8),
                      Icon(Icons.audiotrack, color: Theme.of(context).textTheme.bodyMedium?.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.file.fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_formatFileSize(widget.file.fileSizeBytes)} • ${DateFormat.yMMMd().add_jm().format(widget.file.addedAt)}',
                              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        tooltip: AppLocalizations.of(context)!.renameFile,
                        onPressed: () => _showRenameDialog(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red.shade300,
                        onPressed: widget.onDelete,
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
        ),
      ),
    );
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
      backgroundColor: Theme.of(context).cardColor,
      title: Text(AppLocalizations.of(context)!.selectTracksToAdd),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            Text(
              'Select tracks to add to this release (${_selectedIds.length} selected)',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
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
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
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
                            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
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
          child: Text(AppLocalizations.of(context)!.addTracks),
        ),
      ],
    );
  }
}
