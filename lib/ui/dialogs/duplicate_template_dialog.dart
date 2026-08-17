import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/project_template.dart';
import '../../providers/providers.dart';
import '../../services/template_duplication_service.dart';

/// Duplicates [template] into a brand new, independent [ProjectTemplate] —
/// see `TemplateDuplicationService` for what "independent" means here (a
/// plain folder copy, no shared history with the original).
class DuplicateTemplateDialog extends ConsumerStatefulWidget {
  final ProjectTemplate template;

  const DuplicateTemplateDialog({super.key, required this.template});

  @override
  ConsumerState<DuplicateTemplateDialog> createState() => _DuplicateTemplateDialogState();
}

class _DuplicateTemplateDialogState extends ConsumerState<DuplicateTemplateDialog> {
  late final _nameController = TextEditingController(text: '${widget.template.name} v2');
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _duplicate() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _busy = true);
    try {
      final newTemplate = await TemplateDuplicationService.duplicate(
        template: widget.template,
        newName: name,
      );
      await ref.read(projectTemplatesNotifierProvider.notifier).addTemplate(newTemplate);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.templateDuplicated)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.duplicateTemplate),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        enabled: !_busy,
        decoration: InputDecoration(labelText: l10n.newTemplateNameLabel),
        onSubmitted: (_) => _duplicate(),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _duplicate,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.create),
        ),
      ],
    );
  }
}
