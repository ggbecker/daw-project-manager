import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../models/project_template.dart';
import '../../providers/providers.dart';

/// Promotes [project] into a brand new [ProjectTemplate] — a copy, never a
/// move: the project itself is left completely untouched. Mirrors how
/// "Register Template" on the templates page points a template straight at
/// an existing folder rather than copying it up front — no file I/O here,
/// the new template just points at the project's own folder in place.
class SaveAsTemplateDialog extends ConsumerStatefulWidget {
  final MusicProject project;

  const SaveAsTemplateDialog({super.key, required this.project});

  @override
  ConsumerState<SaveAsTemplateDialog> createState() => _SaveAsTemplateDialogState();
}

class _SaveAsTemplateDialogState extends ConsumerState<SaveAsTemplateDialog> {
  static const _uuid = Uuid();
  late final _nameController = TextEditingController(text: widget.project.displayName);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final now = DateTime.now();
    final template = ProjectTemplate(
      id: _uuid.v4(),
      name: name,
      sourceFolderPath: p.dirname(widget.project.filePath),
      mainFileRelativePath: p.basename(widget.project.filePath),
      createdAt: now,
      updatedAt: now,
      bpm: widget.project.bpm,
      musicalKey: widget.project.musicalKey,
      dawVersion: widget.project.dawVersion,
      projectNotes: widget.project.projectNotes,
    );

    ref.read(projectTemplatesNotifierProvider.notifier).addTemplate(template);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.savedAsTemplate)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.saveAsTemplate),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.newTemplateNameLabel),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.create)),
      ],
    );
  }
}
