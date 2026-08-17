import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/part_template.dart';
import '../models/project_part.dart';
import '../providers/providers.dart';
import '../utils/mobile_utils.dart';
import '../utils/part_status_display.dart';
import 'widgets/desktop_title_bar.dart';

/// CRUD for reusable lineups — the fixed set of parts a band records for
/// every song — so the same instrument list isn't retyped per project.
class PartTemplatesPage extends ConsumerStatefulWidget {
  const PartTemplatesPage({super.key});

  @override
  ConsumerState<PartTemplatesPage> createState() => _PartTemplatesPageState();
}

class _PartTemplatesPageState extends ConsumerState<PartTemplatesPage> {
  final _uuid = const Uuid();

  Future<void> _createTemplate() async {
    final result = await _showEditor();
    if (result == null) return;

    final now = DateTime.now();
    await ref.read(partTemplatesNotifierProvider.notifier).addTemplate(
          PartTemplate(
            id: _uuid.v4(),
            name: result.name,
            items: result.items,
            createdAt: now,
            updatedAt: now,
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.partTemplateCreated)),
    );
  }

  Future<void> _editTemplate(PartTemplate template) async {
    final result = await _showEditor(template: template);
    if (result == null) return;

    await ref.read(partTemplatesNotifierProvider.notifier).updateTemplate(
          template.copyWith(
            name: result.name,
            items: result.items,
            updatedAt: DateTime.now(),
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.partTemplateUpdated)),
    );
  }

  Future<void> _deleteTemplate(PartTemplate template) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(l10n.deletePartTemplate),
        content: Text(l10n.deletePartTemplateConfirm(template.name)),
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

    await ref
        .read(partTemplatesNotifierProvider.notifier)
        .deleteTemplate(template.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.partTemplateDeleted)),
    );
  }

  /// Shared create/edit form. Returns null when cancelled or invalid.
  Future<({String name, List<ProjectPart> items})?> _showEditor({
    PartTemplate? template,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: template?.name ?? '');
    final itemsController = TextEditingController(
      text: template == null ? '' : PartTemplate.formatItems(template.items),
    );

    return showDialog<({String name, List<ProjectPart> items})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          template == null ? l10n.createPartTemplate : l10n.editPartTemplate,
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.templateName,
                  hintText: l10n.templateNameHint,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: itemsController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: l10n.partTemplateItems,
                  hintText: l10n.partTemplateItemsHint,
                  helperText: l10n.partTemplateItemsHelp,
                  helperMaxLines: 2,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final itemsText = itemsController.text.trim();
              if (name.isEmpty || itemsText.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(l10n.partTemplateNameAndItemsRequired),
                  ),
                );
                return;
              }
              final items = PartTemplate.parseItems(itemsText);
              if (items.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(l10n.partTemplateItemsRequired)),
                );
                return;
              }
              Navigator.pop(dialogContext, (name: name, items: items));
            },
            child: Text(template == null ? l10n.create : l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final templatesAsync = ref.watch(partTemplatesProvider);
    final isMobile = MobileUtils.isMobile();

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(l10n.partTemplates),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: Column(
        children: [
          DesktopTitleBar(title: l10n.partTemplates, showBack: true),
          Expanded(
            child: templatesAsync.when(
              data: (templates) => templates.isEmpty
                  ? _EmptyState(onCreate: _createTemplate)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            leading: const Icon(Icons.queue_music),
                            title: Text(template.name),
                            subtitle: Text(
                              l10n.partTemplateItemCount(template.items.length),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editTemplate(template);
                                } else if (value == 'delete') {
                                  _deleteTemplate(template);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit),
                                      const SizedBox(width: 8),
                                      Text(l10n.edit),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete,
                                          color: Colors.red),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.delete,
                                        style:
                                            const TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              for (final item in template.items)
                                ListTile(
                                  dense: true,
                                  leading: Icon(
                                    item.status.icon,
                                    size: 18,
                                    color: item.status.color,
                                  ),
                                  title: Text(item.name),
                                  subtitle: Text(
                                    item.performer?.isNotEmpty == true
                                        ? item.performer!
                                        : l10n.partsUnassignedPerformer,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text(l10n.errorLoadingPartTemplates)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTemplate,
        tooltip: l10n.createPartTemplate,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_music,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noPartTemplatesYet,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createFirstPartTemplate,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: Text(l10n.createPartTemplate),
          ),
        ],
      ),
    );
  }
}
