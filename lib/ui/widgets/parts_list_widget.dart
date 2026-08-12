import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../models/part_template.dart';
import '../../models/project_part.dart';
import '../../providers/providers.dart';
import '../../services/parts_spreadsheet_import_service.dart';
import '../../services/project_parts_csv_export_service.dart';
import '../../services/project_parts_xlsx_export_service.dart';
import '../../utils/part_status_display.dart';
import '../part_templates_page.dart';

enum _PartsMenuAction {
  importSpreadsheet,
  exportCsv,
  exportXlsx,
  manageTemplates,
}

Widget _menuRow(IconData icon, String label) => Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ],
    );

/// The instrumentation checklist for one song: which parts it needs, who plays
/// them and how far along each take is.
///
/// Sits alongside [TodoListWidget] on the project detail page but tracks a
/// different thing — a standing property of the arrangement rather than a
/// one-off task list.
class PartsListWidget extends ConsumerStatefulWidget {
  final MusicProject project;
  final Future<void> Function(List<ProjectPart>) onPartsChanged;

  const PartsListWidget({
    super.key,
    required this.project,
    required this.onPartsChanged,
  });

  @override
  ConsumerState<PartsListWidget> createState() => _PartsListWidgetState();
}

class _PartsListWidgetState extends ConsumerState<PartsListWidget> {
  final _nameController = TextEditingController();
  final _uuid = const Uuid();

  List<ProjectPart> get _parts => widget.project.parts;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addPart() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    _nameController.clear();
    await widget.onPartsChanged([
      ..._parts,
      ProjectPart(id: _uuid.v4(), name: name),
    ]);
  }

  Future<void> _updatePart(ProjectPart updated) async {
    await widget.onPartsChanged(
      _parts.map((p) => p.id == updated.id ? updated : p).toList(),
    );
  }

  Future<void> _deletePart(ProjectPart part) async {
    await widget.onPartsChanged(
      _parts.where((p) => p.id != part.id).toList(),
    );
  }

  Future<void> _reorderPart(int oldIndex, int newIndex) async {
    final reordered = [..._parts];
    // ReorderableListView reports the drop index as if the dragged row were
    // still in place, so anything moving down lands one slot too far.
    if (newIndex > oldIndex) newIndex -= 1;
    reordered.insert(newIndex, reordered.removeAt(oldIndex));
    await widget.onPartsChanged(reordered);
  }

  /// Opens the full editor. No confirmation snackbar afterwards — the row
  /// updating in place is feedback enough for an edit the user just made.
  Future<void> _editPart(ProjectPart part) async {
    final edited = await showDialog<ProjectPart>(
      context: context,
      builder: (_) => _PartEditorDialog(part: part),
    );
    if (edited == null) return;
    await _updatePart(edited);
  }

  /// [templates] comes from the `ref.watch` in [build] rather than a `ref.read`
  /// here: the provider is auto-disposed while nothing listens, so a read at
  /// tap time would see an empty loading state and wrongly report that no
  /// templates exist.
  Future<void> _importFromTemplate(List<PartTemplate> templates) async {
    final l10n = AppLocalizations.of(context)!;

    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noPartTemplatesAvailable),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: l10n.create,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PartTemplatesPage()),
              );
            },
          ),
        ),
      );
      return;
    }

    final selected = await showDialog<PartTemplate>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(l10n.selectPartTemplate),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                leading: const Icon(Icons.queue_music),
                title: Text(template.name),
                subtitle:
                    Text(l10n.partTemplateItemCount(template.items.length)),
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
    await widget.onPartsChanged([..._parts, ...imported]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(l10n.partTemplateImported(selected.name, imported.length)),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_ensureHasParts(l10n)) return;
    await _saveExport(
      l10n: l10n,
      dialogTitle: l10n.exportPartsCsv,
      fileName:
          ProjectPartsCsvExportService.suggestedFileNameFor(widget.project),
      extension: 'csv',
      write: (path) => File(path).writeAsString(
        ProjectPartsCsvExportService.formatProject(widget.project, l10n),
      ),
    );
  }

  Future<void> _exportXlsx() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_ensureHasParts(l10n)) return;
    final workbook =
        ProjectPartsXlsxExportService.buildWorkbook([widget.project], l10n);
    if (workbook == null) return;
    await _saveExport(
      l10n: l10n,
      dialogTitle: l10n.exportPartsXlsx,
      fileName:
          ProjectPartsXlsxExportService.suggestedFileNameFor(widget.project),
      extension: 'xlsx',
      write: (path) => File(path).writeAsBytes(workbook),
    );
  }

  bool _ensureHasParts(AppLocalizations l10n) {
    if (_parts.isNotEmpty) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.noPartsToExport)),
    );
    return false;
  }

  Future<void> _saveExport({
    required AppLocalizations l10n,
    required String dialogTitle,
    required String fileName,
    required String extension,
    required Future<void> Function(String path) write,
  }) async {
    try {
      final destPath = await FilePicker.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [extension],
      );
      if (destPath == null) return; // user cancelled

      await write(destPath);
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

  /// Reads a CSV/XLSX back in, matching rows to existing parts by name so an
  /// exported sheet that a collaborator filled in updates this list rather
  /// than duplicating it.
  Future<void> _importFromSpreadsheet() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: PartsSpreadsheetImportService.supportedExtensions,
        dialogTitle: l10n.partsImportPickerTitle,
      );
      final path = picked?.files.single.path;
      if (path == null) return; // user cancelled

      final rows = PartsSpreadsheetImportService.parseRows(
        await File(path).readAsBytes(),
        path,
      );
      final result = PartsSpreadsheetImportService.importInto(
        existing: _parts,
        rows: rows,
        projectName: widget.project.displayName,
        l10n: l10n,
      );

      if (result.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.partsImportNothingFound)),
        );
        return;
      }

      await widget.onPartsChanged(result.parts);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.partsImported(result.added, result.updated))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.partsImportFailed(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final parts = _parts;
    final templates =
        ref.watch(partTemplatesProvider).value ?? const <PartTemplate>[];

    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.piano, color: theme.textTheme.bodyMedium?.color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.songParts,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (parts.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _PartsProgressChip(parts: parts),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.file_download),
                  iconSize: 20,
                  tooltip: l10n.importPartsFromTemplate,
                  onPressed: () => _importFromTemplate(templates),
                ),
                // Spreadsheet round-tripping and template management live
                // behind one overflow menu — four bare icons crowded the
                // header out at narrow widths.
                PopupMenuButton<_PartsMenuAction>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  tooltip: l10n.partsMoreActions,
                  onSelected: (action) {
                    switch (action) {
                      case _PartsMenuAction.importSpreadsheet:
                        _importFromSpreadsheet();
                      case _PartsMenuAction.exportCsv:
                        _exportCsv();
                      case _PartsMenuAction.exportXlsx:
                        _exportXlsx();
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
                      value: _PartsMenuAction.importSpreadsheet,
                      child: _menuRow(
                        Icons.upload_file,
                        l10n.importPartsFromSpreadsheet,
                      ),
                    ),
                    PopupMenuItem(
                      value: _PartsMenuAction.exportCsv,
                      child: _menuRow(
                        Icons.table_view_outlined,
                        l10n.exportPartsCsv,
                      ),
                    ),
                    PopupMenuItem(
                      value: _PartsMenuAction.exportXlsx,
                      child: _menuRow(Icons.grid_on, l10n.exportPartsXlsx),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: _PartsMenuAction.manageTemplates,
                      child: _menuRow(
                        Icons.queue_music,
                        l10n.managePartTemplates,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.addPart,
                      hintText: l10n.addPartHint,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addPart(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addPart,
                  tooltip: l10n.addPart,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (parts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      l10n.noPartsYet,
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.noPartsYetHint,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: parts.length,
                  onReorder: _reorderPart,
                  itemBuilder: (context, index) {
                    final part = parts[index];
                    return _PartRow(
                      key: ValueKey(part.id),
                      index: index,
                      part: part,
                      onStatusChanged: (status) =>
                          _updatePart(part.copyWith(status: status)),
                      onEdit: () => _editPart(part),
                      onDelete: () => _deletePart(part),
                    );
                  },
                ),
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
    final l10n = AppLocalizations.of(context)!;
    final done = ProjectPart.doneCount(parts);
    final color = ProjectPart.allDone(parts)
        ? PartTakeStatus.finalTake.color
        : Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        l10n.partsProgress(done, parts.length),
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}

class _PartRow extends StatelessWidget {
  final int index;
  final ProjectPart part;
  final ValueChanged<PartTakeStatus> onStatusChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PartRow({
    super.key,
    required this.index,
    required this.part,
    required this.onStatusChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final performer = part.performer?.trim();
    final notes = part.notes?.trim();

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: ReorderableDragStartListener(
        index: index,
        child: PopupMenuButton<PartTakeStatus>(
          tooltip: l10n.partStatusLabel,
          icon: Icon(part.status.icon, color: part.status.color, size: 20),
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
        ),
      ),
      title: Text(part.name, style: theme.textTheme.bodyMedium),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${performer == null || performer.isEmpty ? l10n.partsUnassignedPerformer : performer}'
            ' · ${part.status.label(l10n)}',
            style: theme.textTheme.bodySmall,
          ),
          if (notes != null && notes.isNotEmpty)
            Text(notes, style: theme.textTheme.bodySmall),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: theme.textTheme.bodyMedium?.color,
            onPressed: onEdit,
            tooltip: l10n.editPart,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red.shade300,
            onPressed: onDelete,
            tooltip: l10n.deletePart,
          ),
        ],
      ),
    );
  }
}

/// Name / performer / status / notes editor for a single part.
class _PartEditorDialog extends StatefulWidget {
  final ProjectPart part;

  const _PartEditorDialog({required this.part});

  @override
  State<_PartEditorDialog> createState() => _PartEditorDialogState();
}

class _PartEditorDialogState extends State<_PartEditorDialog> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.part.name);
  late final TextEditingController _performerController =
      TextEditingController(text: widget.part.performer ?? '');
  late final TextEditingController _notesController =
      TextEditingController(text: widget.part.notes ?? '');
  late PartTakeStatus _status = widget.part.status;
  bool _nameMissing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _performerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameMissing = true);
      return;
    }
    final performer = _performerController.text.trim();
    final notes = _notesController.text.trim();
    Navigator.pop(
      context,
      widget.part.copyWith(
        name: name,
        performer: performer.isEmpty ? null : performer,
        clearPerformer: performer.isEmpty,
        status: _status,
        notes: notes.isEmpty ? null : notes,
        clearNotes: notes.isEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(l10n.editPart),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.partNameLabel,
                hintText: l10n.addPartHint,
                errorText: _nameMissing ? l10n.partNameRequired : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _performerController,
              decoration: InputDecoration(
                labelText: l10n.partPerformerLabel,
                hintText: l10n.partPerformerHint,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PartTakeStatus>(
              initialValue: _status,
              decoration: InputDecoration(labelText: l10n.partStatusLabel),
              items: [
                for (final status in PartTakeStatus.values)
                  DropdownMenuItem(
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
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: l10n.partNotesLabel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
