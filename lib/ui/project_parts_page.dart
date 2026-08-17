import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart';
import '../models/part_template.dart';
import '../models/project_part.dart';
import '../providers/providers.dart';
import '../services/parts_spreadsheet_import_service.dart';
import '../services/project_parts_csv_export_service.dart';
import '../services/project_parts_xlsx_export_service.dart';
import '../utils/mobile_utils.dart';
import '../utils/part_status_display.dart';
import '../utils/search_utils.dart';
import 'part_templates_page.dart';
import 'widgets/desktop_title_bar.dart';
import 'widgets/part_editor_dialog.dart';

/// Which column the table is sorted by. [manual] is the stored order — the
/// order the parts were arranged in — and is the only mode where dragging a
/// row means anything.
enum _PartSort { manual, name, performer, status }

enum _PartsMenuAction {
  importTemplate,
  importSpreadsheet,
  exportCsv,
  exportXlsx,
  manageTemplates,
}

/// Full-page workspace for one song's instrumentation: search, filter, sort,
/// multi-select and bulk-edit its parts, and move the whole list in and out of
/// a spreadsheet.
///
/// The project detail page keeps only a read-only summary that links here —
/// this is where the actual planning happens, so it gets the room for a real
/// table and toolbar instead of a 400px card.
///
/// This widget is only the Riverpod glue: it resolves the project and the
/// available templates and hands persistence to the repository. Everything
/// else lives in [ProjectPartsView], which takes a plain project and a
/// callback, so the table can be exercised without a Hive-backed repository
/// (writing to Hive inside a `testWidgets` body deadlocks against the faked
/// clock).
class ProjectPartsPage extends ConsumerWidget {
  final String projectId;

  const ProjectPartsPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final project = ref
        .watch(allProjectsStreamProvider)
        .value
        ?.where((p) => p.id == projectId)
        .firstOrNull;
    final templatesAsync = ref.watch(partTemplatesProvider);
    final templates = templatesAsync.value ?? const <PartTemplate>[];
    final isMobile = MobileUtils.isMobile();
    final title = project == null
        ? l10n.songParts
        : l10n.partsPageTitle(project.displayName);

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(title),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: Column(
        children: [
          DesktopTitleBar(title: title, showBack: true),
          if (project == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ProjectPartsView(
                project: project,
                templates: templates,
                templatesLoading: templatesAsync.isLoading,
                onPartsChanged: (parts) async {
                  final repo = await ref.read(repositoryProvider.future);
                  await repo.updateProject(
                    project.copyWith(parts: parts, updatedAt: DateTime.now()),
                  );
                  ref.invalidate(allProjectsStreamProvider);
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// The parts table, toolbar and bulk-action bar for [project].
///
/// Owns no persistence: every change is handed to [onPartsChanged] as a
/// complete new parts list, and the widget re-renders from whatever [project]
/// comes back.
class ProjectPartsView extends StatefulWidget {
  final MusicProject project;
  final List<PartTemplate> templates;

  /// True while the templates are still being read. Distinct from an empty
  /// [templates] list: "still loading" must not be reported to the user as
  /// "you have no templates".
  final bool templatesLoading;
  final Future<void> Function(List<ProjectPart>) onPartsChanged;

  const ProjectPartsView({
    super.key,
    required this.project,
    required this.onPartsChanged,
    this.templates = const [],
    this.templatesLoading = false,
  });

  @override
  State<ProjectPartsView> createState() => _ProjectPartsViewState();
}

class _ProjectPartsViewState extends State<ProjectPartsView> {
  final _uuid = const Uuid();
  final _addController = TextEditingController();
  final _searchController = TextEditingController();

  String _search = '';
  PartTakeStatus? _statusFilter;
  String? _performerFilter;
  _PartSort _sort = _PartSort.manual;
  bool _ascending = true;
  Set<String> _selectedIds = {};

  @override
  void dispose() {
    _addController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Dragging rows only makes sense against the full list in stored order —
  /// with a filter or sort applied, "drop it here" has no stable meaning.
  bool get _canReorder =>
      _sort == _PartSort.manual &&
      _search.isEmpty &&
      _statusFilter == null &&
      _performerFilter == null;

  List<ProjectPart> _visibleParts(List<ProjectPart> parts) {
    var visible = parts;
    if (_search.trim().isNotEmpty) {
      visible = visible
          .where((p) => fuzzyMatchAll(
                ProjectPart.searchableText([p]),
                _search,
              ))
          .toList();
    }
    if (_statusFilter != null) {
      visible = visible.where((p) => p.status == _statusFilter).toList();
    }
    if (_performerFilter != null) {
      visible = visible
          .where((p) => (p.performer ?? '') == _performerFilter)
          .toList();
    }
    if (_sort == _PartSort.manual) return visible;

    final sorted = [...visible];
    int compare(ProjectPart a, ProjectPart b) {
      switch (_sort) {
        case _PartSort.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _PartSort.performer:
          return (a.performer ?? '')
              .toLowerCase()
              .compareTo((b.performer ?? '').toLowerCase());
        case _PartSort.status:
          return a.status.index.compareTo(b.status.index);
        case _PartSort.manual:
          return 0;
      }
    }

    sorted.sort((a, b) => _ascending ? compare(a, b) : compare(b, a));
    return sorted;
  }

  MusicProject get _project => widget.project;

  Future<void> _save(MusicProject project, List<ProjectPart> parts) =>
      widget.onPartsChanged(parts);

  Future<void> _addPart(MusicProject project) async {
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    _addController.clear();
    await _save(project, [
      ...project.parts,
      ProjectPart(id: _uuid.v4(), name: name),
    ]);
  }

  Future<void> _editPart(MusicProject project, ProjectPart part) async {
    final edited = await PartEditorDialog.show(context, part);
    if (edited == null) return;
    await _save(
      project,
      project.parts.map((p) => p.id == edited.id ? edited : p).toList(),
    );
  }

  Future<void> _setStatus(
    MusicProject project,
    Iterable<String> ids,
    PartTakeStatus status,
  ) async {
    final target = ids.toSet();
    await _save(
      project,
      project.parts
          .map((p) => target.contains(p.id) ? p.copyWith(status: status) : p)
          .toList(),
    );
  }

  Future<void> _assignPerformer(MusicProject project) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final performer = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(l10n.assignPartPerformer),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.partPerformerLabel,
            hintText: l10n.partPerformerHint,
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (performer == null) return;

    // An empty name is a deliberate "unassign", not a cancel — cancel returns
    // null above.
    await _save(
      project,
      project.parts
          .map((p) => _selectedIds.contains(p.id)
              ? p.copyWith(
                  performer: performer.isEmpty ? null : performer,
                  clearPerformer: performer.isEmpty,
                )
              : p)
          .toList(),
    );
  }

  Future<void> _deleteSelected(MusicProject project) async {
    final l10n = AppLocalizations.of(context)!;
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(l10n.deleteSelectedParts),
        content: Text(l10n.deleteSelectedPartsConfirm(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _save(
      project,
      project.parts.where((p) => !_selectedIds.contains(p.id)).toList(),
    );
    if (!mounted) return;
    setState(() => _selectedIds = {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.partsDeleted(count))),
    );
  }

  Future<void> _reorder(MusicProject project, int oldIndex, int newIndex) async {
    final reordered = [...project.parts];
    // ReorderableListView reports the drop index as if the dragged row were
    // still in place, so anything moving down lands one slot too far.
    if (newIndex > oldIndex) newIndex -= 1;
    reordered.insert(newIndex, reordered.removeAt(oldIndex));
    await _save(project, reordered);
  }

  /// Opens the template picker.
  ///
  /// "You have no templates" is shown *inside* the picker rather than as a
  /// snackbar with a Create action. A SnackBar carrying a SnackBarAction does
  /// not auto-dismiss, so that bar sat on screen indefinitely, and its action
  /// closed over this State's context — tapping Create after navigating away
  /// threw "This widget has been unmounted". A dialog has neither problem.
  Future<void> _importFromTemplate(
    MusicProject project,
    List<PartTemplate> templates,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    // Captured before the await so nothing reaches through a stale context.
    final navigator = Navigator.of(context);

    final selected = await showDialog<PartTemplate>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(l10n.selectPartTemplate),
        content: SizedBox(
          width: 380,
          child: widget.templatesLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : templates.isEmpty
                  ? _NoTemplatesYet(onCreate: () {
                      Navigator.pop(dialogContext);
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => const PartTemplatesPage(),
                        ),
                      );
                    })
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return ListTile(
                          leading: const Icon(Icons.queue_music),
                          title: Text(template.name),
                          subtitle: Text(
                            l10n.partTemplateItemCount(template.items.length),
                          ),
                          onTap: () => Navigator.pop(dialogContext, template),
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (selected == null) return;

    final imported = selected.instantiate();
    await _save(project, [...project.parts, ...imported]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(l10n.partTemplateImported(selected.name, imported.length)),
      ),
    );
  }

  Future<void> _importFromSpreadsheet(MusicProject project) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: PartsSpreadsheetImportService.supportedExtensions,
        dialogTitle: l10n.partsImportPickerTitle,
      );
      final path = picked?.files.single.path;
      if (path == null) return; // user cancelled

      final result = PartsSpreadsheetImportService.importInto(
        existing: project.parts,
        rows: PartsSpreadsheetImportService.parseRows(
          await File(path).readAsBytes(),
          path,
        ),
        projectName: project.displayName,
        l10n: l10n,
      );

      if (result.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.partsImportNothingFound)),
        );
        return;
      }

      await _save(project, result.parts);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.partsImported(result.added, result.updated)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.partsImportFailed(e.toString()))),
      );
    }
  }

  Future<void> _export(MusicProject project, {required bool asXlsx}) async {
    final l10n = AppLocalizations.of(context)!;
    if (project.parts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noPartsToExport)),
      );
      return;
    }
    try {
      final destPath = await FilePicker.saveFile(
        dialogTitle: asXlsx ? l10n.exportPartsXlsx : l10n.exportPartsCsv,
        fileName: asXlsx
            ? ProjectPartsXlsxExportService.suggestedFileNameFor(project)
            : ProjectPartsCsvExportService.suggestedFileNameFor(project),
        type: FileType.custom,
        allowedExtensions: [asXlsx ? 'xlsx' : 'csv'],
      );
      if (destPath == null) return; // user cancelled

      if (asXlsx) {
        final workbook =
            ProjectPartsXlsxExportService.buildWorkbook([project], l10n);
        if (workbook == null) return;
        await File(destPath).writeAsBytes(workbook);
      } else {
        await File(destPath).writeAsString(
          ProjectPartsCsvExportService.formatProject(project, l10n),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.savedCopyTo(destPath))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToExportProjectInfo(e.toString()))),
      );
    }
  }

  void _toggleSort(_PartSort column) {
    setState(() {
      if (_sort == column) {
        // Third tap on the same column drops back to the stored order, so the
        // list is always one click away from being draggable again.
        if (_ascending) {
          _ascending = false;
        } else {
          _sort = _PartSort.manual;
          _ascending = true;
        }
      } else {
        _sort = column;
        _ascending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final project = _project;
    final parts = project.parts;
    final visible = _visibleParts(parts);
    final templates = widget.templates;
    // Selection survives edits but must not outlive the parts themselves.
    final liveIds = parts.map((p) => p.id).toSet();
    final selected = _selectedIds.intersection(liveIds);

    return Column(
      children: [
        _buildToolbar(context, l10n, project, templates),
        const Divider(height: 1),
        Expanded(
          child: parts.isEmpty
              ? _EmptyParts(l10n: l10n)
              : visible.isEmpty
                  ? Center(child: Text(l10n.noPartsMatchFilters))
                  : _buildTable(context, l10n, project, visible, selected),
        ),
        if (selected.isNotEmpty)
          _BulkActionBar(
            count: selected.length,
            onSetStatus: (status) => _setStatus(project, selected, status),
            onAssignPerformer: () => _assignPerformer(project),
            onDelete: () => _deleteSelected(project),
            onClear: () => setState(() => _selectedIds = {}),
          ),
      ],
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    AppLocalizations l10n,
    MusicProject project,
    List<PartTemplate> templates,
  ) {
    final performers = ProjectPart.performers(project.parts);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addController,
                  decoration: InputDecoration(
                    labelText: l10n.addPart,
                    hintText: l10n.addPartHint,
                    isDense: true,
                    prefixIcon: const Icon(Icons.add, size: 18),
                  ),
                  onSubmitted: (_) => _addPart(project),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => _addPart(project),
                icon: const Icon(Icons.add, size: 18),
                tooltip: l10n.addPart,
              ),
              const SizedBox(width: 8),
              _PartsProgressChip(parts: project.parts),
              const SizedBox(width: 8),
              PopupMenuButton<_PartsMenuAction>(
                icon: const Icon(Icons.more_vert),
                tooltip: l10n.partsMoreActions,
                onSelected: (action) {
                  switch (action) {
                    case _PartsMenuAction.importTemplate:
                      _importFromTemplate(project, templates);
                    case _PartsMenuAction.importSpreadsheet:
                      _importFromSpreadsheet(project);
                    case _PartsMenuAction.exportCsv:
                      _export(project, asXlsx: false);
                    case _PartsMenuAction.exportXlsx:
                      _export(project, asXlsx: true);
                    case _PartsMenuAction.manageTemplates:
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PartTemplatesPage(),
                        ),
                      );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _PartsMenuAction.importTemplate,
                    child: _menuRow(
                        Icons.file_download, l10n.importPartsFromTemplate),
                  ),
                  PopupMenuItem(
                    value: _PartsMenuAction.importSpreadsheet,
                    child: _menuRow(
                        Icons.upload_file, l10n.importPartsFromSpreadsheet),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: _PartsMenuAction.exportCsv,
                    child:
                        _menuRow(Icons.table_view_outlined, l10n.exportPartsCsv),
                  ),
                  PopupMenuItem(
                    value: _PartsMenuAction.exportXlsx,
                    child: _menuRow(Icons.grid_on, l10n.exportPartsXlsx),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: _PartsMenuAction.manageTemplates,
                    child:
                        _menuRow(Icons.queue_music, l10n.managePartTemplates),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Wrap rather than Row: search + two dropdowns + the reorder hint do
          // not fit side by side in a narrow window, and a toolbar that
          // overflows is worse than one that takes a second line.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchParts,
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            tooltip: l10n.clear,
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          ),
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
              ),
              DropdownButton<PartTakeStatus?>(
                value: _statusFilter,
                hint: Text(l10n.allStatuses),
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.allStatuses)),
                  for (final status in PartTakeStatus.values)
                    DropdownMenuItem(
                      value: status,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status.icon, color: status.color, size: 16),
                          const SizedBox(width: 6),
                          Text(status.label(l10n)),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _statusFilter = value),
              ),
              DropdownButton<String?>(
                value: _performerFilter,
                hint: Text(l10n.allPerformers),
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.allPerformers)),
                  for (final performer in performers)
                    DropdownMenuItem(value: performer, child: Text(performer)),
                ],
                onChanged: (value) => setState(() => _performerFilter = value),
              ),
              if (!_canReorder && project.parts.length > 1)
                Text(
                  l10n.reorderNeedsUnfilteredList,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
    BuildContext context,
    AppLocalizations l10n,
    MusicProject project,
    List<ProjectPart> visible,
    Set<String> selected,
  ) {
    final allVisibleSelected =
        visible.every((p) => selected.contains(p.id));

    return Column(
      children: [
        _TableHeader(
          allSelected: allVisibleSelected,
          onSelectAll: (value) => setState(() {
            _selectedIds = value == true
                ? {...selected, ...visible.map((p) => p.id)}
                : selected.difference(visible.map((p) => p.id).toSet());
          }),
          sort: _sort,
          ascending: _ascending,
          onSort: _toggleSort,
          showDragColumn: _canReorder,
        ),
        const Divider(height: 1),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            itemCount: visible.length,
            onReorder: (oldIndex, newIndex) =>
                _reorder(project, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final part = visible[index];
              return _PartTableRow(
                key: ValueKey(part.id),
                index: index,
                part: part,
                selected: selected.contains(part.id),
                draggable: _canReorder,
                onSelected: (value) => setState(() {
                  _selectedIds = value == true
                      ? {...selected, part.id}
                      : (selected.toSet()..remove(part.id));
                }),
                onStatusChanged: (status) =>
                    _setStatus(project, [part.id], status),
                onEdit: () => _editPart(project, part),
              );
            },
          ),
        ),
      ],
    );
  }
}

Widget _menuRow(IconData icon, String label) => Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        // Menu width is driven by the widest item; some translations of these
        // labels are long enough to overflow it without this.
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

class _TableHeader extends StatelessWidget {
  final bool allSelected;
  final ValueChanged<bool?> onSelectAll;
  final _PartSort sort;
  final bool ascending;
  final ValueChanged<_PartSort> onSort;
  final bool showDragColumn;

  const _TableHeader({
    required this.allSelected,
    required this.onSelectAll,
    required this.sort,
    required this.ascending,
    required this.onSort,
    required this.showDragColumn,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = Theme.of(context)
        .textTheme
        .labelLarge
        ?.copyWith(fontWeight: FontWeight.w600);

    Widget sortable(String label, _PartSort column, int flex) => Expanded(
          flex: flex,
          child: InkWell(
            onTap: () => onSort(column),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Flexible(
                    child:
                        Text(label, style: style, overflow: TextOverflow.ellipsis),
                  ),
                  if (sort == column)
                    Icon(
                      ascending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                    ),
                ],
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Checkbox(value: allSelected, onChanged: onSelectAll),
          SizedBox(width: showDragColumn ? 32 : 0),
          sortable(l10n.csvHeaderPart, _PartSort.name, 3),
          sortable(l10n.csvHeaderPerformer, _PartSort.performer, 2),
          sortable(l10n.csvHeaderStatus, _PartSort.status, 2),
          Expanded(flex: 3, child: Text(l10n.csvHeaderNotes, style: style)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _PartTableRow extends StatelessWidget {
  final int index;
  final ProjectPart part;
  final bool selected;
  final bool draggable;
  final ValueChanged<bool?> onSelected;
  final ValueChanged<PartTakeStatus> onStatusChanged;
  final VoidCallback onEdit;

  const _PartTableRow({
    super.key,
    required this.index,
    required this.part,
    required this.selected,
    required this.draggable,
    required this.onSelected,
    required this.onStatusChanged,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final performer = part.performer?.trim();

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Checkbox(value: selected, onChanged: onSelected),
              if (draggable)
                ReorderableDragStartListener(
                  index: index,
                  child: const SizedBox(
                    width: 32,
                    child: Icon(Icons.drag_indicator, size: 18),
                  ),
                ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(part.name, style: theme.textTheme.bodyMedium),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  performer == null || performer.isEmpty
                      ? l10n.partsUnassignedPerformer
                      : performer,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PopupMenuButton<PartTakeStatus>(
                    tooltip: l10n.partStatusLabel,
                    onSelected: onStatusChanged,
                    itemBuilder: (context) => [
                      for (final status in PartTakeStatus.values)
                        PopupMenuItem(
                          value: status,
                          child: Row(
                            children: [
                              Icon(status.icon, color: status.color, size: 18),
                              const SizedBox(width: 8),
                              Text(status.label(l10n)),
                            ],
                          ),
                        ),
                    ],
                    child: _StatusPill(status: part.status),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  part.notes ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              SizedBox(
                width: 48,
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: l10n.editPart,
                  onPressed: onEdit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final PartTakeStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: status.color, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              status.label(l10n),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: status.color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkActionBar extends StatelessWidget {
  final int count;
  final ValueChanged<PartTakeStatus> onSetStatus;
  final VoidCallback onAssignPerformer;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  const _BulkActionBar({
    required this.count,
    required this.onSetStatus,
    required this.onAssignPerformer,
    required this.onDelete,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.partsSelectedCount(count)),
            PopupMenuButton<PartTakeStatus>(
              onSelected: onSetStatus,
              itemBuilder: (context) => [
                for (final status in PartTakeStatus.values)
                  PopupMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Icon(status.icon, color: status.color, size: 18),
                        const SizedBox(width: 8),
                        Text(status.label(l10n)),
                      ],
                    ),
                  ),
              ],
              // A styled child rather than an OutlinedButton: a button inside
              // a PopupMenuButton has to have onPressed: null to let the taps
              // through, which would render it greyed out and disabled.
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.playlist_add_check, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.setPartStatus),
                  ],
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onAssignPerformer,
              icon: const Icon(Icons.person_outline, size: 18),
              label: Text(l10n.assignPartPerformer),
            ),
            OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(l10n.deleteSelectedParts),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
            TextButton(onPressed: onClear, child: Text(l10n.clearSelection)),
          ],
        ),
      ),
    );
  }
}

/// Empty state inside the template picker, with the way out of it.
class _NoTemplatesYet extends StatelessWidget {
  final VoidCallback onCreate;

  const _NoTemplatesYet({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.noPartTemplatesYet,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
          l10n.createFirstPartTemplate,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.createPartTemplate),
        ),
      ],
    );
  }
}

class _EmptyParts extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyParts({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.piano,
              size: 64,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(l10n.noPartsYet,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              l10n.noPartsYetHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// "3 of 5 final takes", tinted green once every part is done.
class _PartsProgressChip extends StatelessWidget {
  final List<ProjectPart> parts;

  const _PartsProgressChip({required this.parts});

  @override
  Widget build(BuildContext context) {
    if (parts.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final color = ProjectPart.allDone(parts)
        ? PartTakeStatus.finalTake.color
        : Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        l10n.partsProgress(ProjectPart.doneCount(parts), parts.length),
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}
