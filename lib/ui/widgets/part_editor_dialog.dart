import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/project_part.dart';
import '../../utils/part_status_display.dart';

/// Name / performer / status / notes editor for a single [ProjectPart].
///
/// Pops the edited part, or null when cancelled. Never mutates anything
/// itself — the caller owns saving, because a part lives inside its project.
class PartEditorDialog extends StatefulWidget {
  final ProjectPart part;

  const PartEditorDialog({super.key, required this.part});

  /// Convenience wrapper so call sites don't repeat the generic type.
  static Future<ProjectPart?> show(BuildContext context, ProjectPart part) =>
      showDialog<ProjectPart>(
        context: context,
        builder: (_) => PartEditorDialog(part: part),
      );

  @override
  State<PartEditorDialog> createState() => _PartEditorDialogState();
}

class _PartEditorDialogState extends State<PartEditorDialog> {
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
        child: SingleChildScrollView(
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
