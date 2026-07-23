import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:trina_grid/trina_grid.dart';
import 'package:uuid/uuid.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/project_template.dart';
import '../models/template_root.dart';
import '../providers/providers.dart';
import '../providers/theme_provider.dart';
import '../services/metadata_extractor.dart';
import '../services/project_template_service.dart';
import '../services/scanner_service.dart';
import '../utils/daw_logo.dart';
import '../utils/mobile_utils.dart';
import 'dialogs/create_project_dialog.dart';
import 'widgets/desktop_title_bar.dart';

class ProjectTemplatesPage extends ConsumerStatefulWidget {
  const ProjectTemplatesPage({super.key});

  @override
  ConsumerState<ProjectTemplatesPage> createState() => _ProjectTemplatesPageState();
}

class _ProjectTemplatesPageState extends ConsumerState<ProjectTemplatesPage> {
  final _uuid = const Uuid();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickMainFile() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ScannerService.supportedExtensions.map((e) => e.substring(1)).toList(),
      dialogTitle: l10n.selectTemplateMainFile,
    );
    if (!mounted || result == null || result.files.single.path == null) return;

    final mainFilePath = result.files.single.path!;
    final nameController = TextEditingController(text: p.basenameWithoutExtension(mainFilePath));

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.registerTemplate),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.templateName),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Text(
              mainFilePath,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final template = ProjectTemplate(
                id: _uuid.v4(),
                name: name,
                sourceFolderPath: p.dirname(mainFilePath),
                mainFileRelativePath: p.basename(mainFilePath),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              ref.read(projectTemplatesNotifierProvider.notifier).addTemplate(template);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.templateCreated)),
              );
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  /// Registers a new template root folder, then immediately runs a refresh
  /// so any qualifying subfolders it already contains get imported right
  /// away instead of waiting for the next manual refresh.
  Future<void> _addTemplateRoot() async {
    final l10n = AppLocalizations.of(context)!;
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: l10n.selectTemplatesParentFolder,
    );
    if (!mounted || path == null) return;

    await ref.read(templateRootsNotifierProvider.notifier).addRoot(TemplateRoot(
          id: _uuid.v4(),
          path: path,
          addedAt: DateTime.now(),
        ));
    await _refreshTemplateRoots();
  }

  /// Re-scans every registered [TemplateRoot] for subfolders that
  /// unambiguously look like templates (see
  /// [ProjectTemplateService.discoverTemplateCandidates]) and registers any
  /// that aren't already a template (compared by source folder path), so
  /// re-running this only adds what's new rather than duplicating existing
  /// templates. Reports how many were added in a snackbar.
  Future<void> _refreshTemplateRoots() async {
    final l10n = AppLocalizations.of(context)!;
    final roots = await ref.read(templateRootsProvider.future);
    if (roots.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noTemplateFoldersRegistered)),
        );
      }
      return;
    }

    final existingTemplates = await ref.read(projectTemplatesProvider.future);
    final existingPaths = existingTemplates.map((t) => t.sourceFolderPath).toSet();

    final allCandidates = <TemplateFolderCandidate>[];
    for (final root in roots) {
      allCandidates.addAll(ProjectTemplateService.discoverTemplateCandidates(root.path));
    }
    final newCandidates = ProjectTemplateService.filterNewCandidates(allCandidates, existingPaths);

    final templatesNotifier = ref.read(projectTemplatesNotifierProvider.notifier);
    for (final candidate in newCandidates) {
      await templatesNotifier.addTemplate(ProjectTemplate(
        id: _uuid.v4(),
        name: candidate.name,
        sourceFolderPath: candidate.sourceFolderPath,
        mainFileRelativePath: candidate.mainFileRelativePath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    final rootsNotifier = ref.read(templateRootsNotifierProvider.notifier);
    for (final root in roots) {
      await rootsNotifier.updateRoot(root.copyWith(lastRefreshedAt: DateTime.now()));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.templatesRefreshedSummary(newCandidates.length))),
      );
    }
  }

  Future<void> _removeTemplateRoot(TemplateRoot root) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.removeTemplateFolder),
        content: Text(l10n.removeTemplateFolderConfirm(root.path)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(templateRootsNotifierProvider.notifier).removeRoot(root.id);
    }
  }

  Future<void> _manageTemplateFolders() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.manageTemplateFolders),
        content: SizedBox(
          width: 480,
          child: Consumer(
            builder: (context, ref, child) {
              final rootsAsync = ref.watch(templateRootsProvider);
              return rootsAsync.when(
                data: (roots) {
                  if (roots.isEmpty) {
                    return Text(l10n.noTemplateFoldersRegistered);
                  }
                  return SizedBox(
                    height: 240,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: roots.length,
                      itemBuilder: (context, index) {
                        final root = roots[index];
                        return ListTile(
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(root.path, overflow: TextOverflow.ellipsis),
                          subtitle: root.lastRefreshedAt != null
                              ? Text(l10n.lastRefreshed(DateFormat('yyyy-MM-dd HH:mm').format(root.lastRefreshedAt!)))
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeTemplateRoot(root),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text(l10n.errorLoadingTemplates),
              );
            },
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.create_new_folder_outlined, size: 18),
            label: Text(l10n.addTemplateFolder),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _addTemplateRoot();
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _renameTemplate(ProjectTemplate template) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: template.name);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.editTemplate),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: l10n.templateName),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              ref.read(projectTemplatesNotifierProvider.notifier).updateTemplate(
                    template.copyWith(name: name, updatedAt: DateTime.now()),
                  );
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.templateUpdated)),
              );
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTemplate(ProjectTemplate template) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteTemplate),
        content: Text(l10n.deleteTemplateConfirm(template.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(projectTemplatesNotifierProvider.notifier).deleteTemplate(template.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.templateDeleted)),
        );
      }
    }
  }

  void _useTemplate(ProjectTemplate template) {
    showDialog(
      context: context,
      builder: (_) => CreateProjectDialog(initialTemplate: template),
    );
  }

  List<TrinaColumn> _buildColumns(AppLocalizations l10n) {
    return [
      TrinaColumn(
        title: l10n.templateName,
        field: 'name',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        enableContextMenu: false,
        width: 260,
        minWidth: 160,
        renderer: (ctx) {
          final template = ctx.row.cells['data']!.value as ProjectTemplate;
          final ext = p.extension(template.mainFileRelativePath);
          final dawType = MetadataExtractor.getDawTypeFromExtension(ext);
          final logoPath = getDawLogoPath(dawType);
          return Row(
            children: [
              logoPath != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Image.asset(
                        logoPath,
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.piano_outlined, size: 20),
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.piano_outlined, size: 20),
                    ),
              Expanded(child: Text(template.name, overflow: TextOverflow.ellipsis)),
            ],
          );
        },
      ),
      TrinaColumn(
        title: l10n.templateSourceFolder,
        field: 'path',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        enableContextMenu: false,
        width: 380,
        minWidth: 200,
        renderer: (ctx) {
          final template = ctx.row.cells['data']!.value as ProjectTemplate;
          final fullPath = p.join(template.sourceFolderPath, template.mainFileRelativePath);
          final sourceExists = File(fullPath).existsSync();
          return Row(
            children: [
              if (!sourceExists) ...[
                Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange.shade400),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Tooltip(
                  message: fullPath,
                  child: Text(
                    sourceExists ? fullPath : AppLocalizations.of(context)!.templateSourceMissing,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      TrinaColumn(
        title: l10n.dateCreatedColumn,
        field: 'createdAt',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        enableContextMenu: false,
        width: 130,
        minWidth: 110,
      ),
      TrinaColumn(
        title: l10n.actions,
        field: 'actions',
        type: TrinaColumnType.text(),
        enableEditingMode: false,
        enableContextMenu: false,
        enableSorting: false,
        enableColumnDrag: false,
        width: 150,
        minWidth: 150,
        renderer: (ctx) {
          final template = ctx.row.cells['data']!.value as ProjectTemplate;
          final fullPath = p.join(template.sourceFolderPath, template.mainFileRelativePath);
          final sourceExists = File(fullPath).existsSync();
          final l10n = AppLocalizations.of(context)!;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                tooltip: l10n.useTemplate,
                visualDensity: VisualDensity.compact,
                onPressed: sourceExists ? () => _useTemplate(template) : null,
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: l10n.edit,
                visualDensity: VisualDensity.compact,
                onPressed: () => _renameTemplate(template),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                tooltip: l10n.delete,
                visualDensity: VisualDensity.compact,
                onPressed: () => _deleteTemplate(template),
              ),
            ],
          );
        },
      ),
    ];
  }

  List<TrinaRow> _buildRows(List<ProjectTemplate> templates) {
    return templates
        .map((template) => TrinaRow(cells: {
              'name': TrinaCell(value: template.name),
              'path': TrinaCell(value: template.sourceFolderPath),
              'createdAt': TrinaCell(value: DateFormat('yyyy-MM-dd').format(template.createdAt)),
              'actions': TrinaCell(value: ''),
              'data': TrinaCell(value: template),
            }))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final templatesAsync = ref.watch(projectTemplatesProvider);
    final isMobile = MobileUtils.isMobile();
    final activeTheme = ref.watch(themeDataProvider);
    final isNeon = ref.watch(themeTypeProvider) == AppThemeType.neonDark;
    final isDark = activeTheme.brightness == Brightness.dark;
    final oddColor = isNeon ? activeTheme.scaffoldBackgroundColor : activeTheme.cardColor;
    final evenColor = isNeon
        ? activeTheme.cardColor
        : isDark
            ? Color.alphaBlend(Colors.white.withValues(alpha: 0.05), activeTheme.cardColor)
            : Color.alphaBlend(Colors.black.withValues(alpha: 0.04), activeTheme.cardColor);

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(l10n.projectTemplates),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: Column(
        children: [
          DesktopTitleBar(title: l10n.projectTemplates, showBack: true),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchTemplates,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.note_add_outlined, size: 18),
                  label: Text(l10n.registerTemplate),
                  onPressed: _pickMainFile,
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.folder_special_outlined, size: 18),
                  label: Text(l10n.manageTemplateFolders),
                  onPressed: _manageTemplateFolders,
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: l10n.refreshTemplateFolders,
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshTemplateRoots,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: templatesAsync.when(
              data: (templates) {
                final filtered = _query.isEmpty
                    ? templates
                    : templates.where((t) => t.name.toLowerCase().contains(_query)).toList();

                if (templates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_copy_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noTemplatesYet,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.createFirstProjectTemplate, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(child: Text(l10n.noMatchingTemplates));
                }

                return TrinaGrid(
                  key: ValueKey(
                    'project_templates_grid_${l10n.localeName}_${ref.watch(themeTypeProvider).name}_${filtered.map((t) => '${t.id}_${t.updatedAt}').join(',')}',
                  ),
                  columns: _buildColumns(l10n),
                  rows: _buildRows(filtered),
                  rowColorCallback: (TrinaRowColorContext ctx) => ctx.rowIdx.isOdd ? oddColor : evenColor,
                  configuration: TrinaGridConfiguration(
                    style: TrinaGridStyleConfig(
                      gridBackgroundColor: activeTheme.cardColor,
                      gridBorderColor: isNeon
                          ? activeTheme.colorScheme.primary.withValues(alpha: 0.25)
                          : activeTheme.dividerColor.withValues(alpha: 0.4),
                      borderColor: isNeon
                          ? activeTheme.colorScheme.primary.withValues(alpha: 0.15)
                          : activeTheme.dividerColor.withValues(alpha: 0.25),
                      gridBorderRadius: BorderRadius.zero,
                      rowColor: activeTheme.cardColor,
                      cellColorInEditState: Colors.transparent,
                      cellColorInReadOnlyState: Colors.transparent,
                      columnTextStyle: TextStyle(
                        color: isNeon ? activeTheme.colorScheme.primary : activeTheme.textTheme.titleMedium?.color,
                        fontWeight: FontWeight.w600,
                      ),
                      cellTextStyle: TextStyle(color: activeTheme.textTheme.bodyMedium?.color),
                      columnHeight: 44,
                      rowHeight: 48,
                      activatedBorderColor: activeTheme.colorScheme.primary,
                      activatedColor: Colors.transparent,
                      iconColor: isNeon
                          ? activeTheme.colorScheme.primary.withValues(alpha: 0.7)
                          : activeTheme.textTheme.bodyMedium?.color ?? Colors.grey,
                      menuBackgroundColor: activeTheme.cardColor,
                      oddRowColor: oddColor,
                      evenRowColor: evenColor,
                    ),
                    columnSize: const TrinaGridColumnSizeConfig(
                      autoSizeMode: TrinaAutoSizeMode.scale,
                      resizeMode: TrinaResizeMode.pushAndPull,
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text(l10n.errorLoadingTemplates)),
            ),
          ),
        ],
      ),
    );
  }
}
