import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart' if (dart.library.html) 'package:window_manager/window_manager_stub.dart';
import '../models/todo_template.dart';
import '../providers/providers.dart';
import '../generated/l10n/app_localizations.dart';

// Window control buttons for desktop platforms
class _WindowButtons extends StatelessWidget {
  const _WindowButtons();

  void _toggleMaximize() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      if (await windowManager.isMaximized()) {
        windowManager.restore();
      } else {
        windowManager.maximize();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show on Windows/Linux (macOS has native traffic lights)
    if (kIsWeb || (!Platform.isWindows && !Platform.isLinux)) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        // Minimize
        IconButton(
          icon: Icon(Icons.minimize, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
          onPressed: () => windowManager.minimize(),
        ),
        // Maximize/Restore
        IconButton(
          icon: Icon(Icons.crop_square_sharp, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
          onPressed: _toggleMaximize,
        ),
        // Close
        IconButton(
          icon: Icon(Icons.close, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}

class TodoTemplatesPage extends ConsumerStatefulWidget {
  const TodoTemplatesPage({super.key});

  @override
  ConsumerState<TodoTemplatesPage> createState() => _TodoTemplatesPageState();
}

class _TodoTemplatesPageState extends ConsumerState<TodoTemplatesPage> {
  final _uuid = const Uuid();

  Future<void> _createTemplate() async {
    final nameController = TextEditingController();
    final itemsController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.createTemplate),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.templateName,
                hintText: AppLocalizations.of(context)!.templateNameHint,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: itemsController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.templateItems,
                hintText: AppLocalizations.of(context)!.templateItemsHint,
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final itemsText = itemsController.text.trim();
              
              if (name.isEmpty || itemsText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.templateNameAndItemsRequired),
                  ),
                );
                return;
              }

              final items = itemsText
                  .split('\n')
                  .map((line) => line.trim())
                  .where((line) => line.isNotEmpty)
                  .toList();

              if (items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.templateItemsRequired),
                  ),
                );
                return;
              }

              final template = TodoTemplate(
                id: _uuid.v4(),
                name: name,
                items: items,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              ref.read(todoTemplatesNotifierProvider.notifier).addTemplate(template);
              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.templateCreated),
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );
  }

  Future<void> _editTemplate(TodoTemplate template) async {
    final nameController = TextEditingController(text: template.name);
    final itemsController = TextEditingController(text: template.items.join('\n'));

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.editTemplate),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.templateName,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: itemsController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.templateItems,
                hintText: AppLocalizations.of(context)!.templateItemsHint,
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final itemsText = itemsController.text.trim();
              
              if (name.isEmpty || itemsText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.templateNameAndItemsRequired),
                  ),
                );
                return;
              }

              final items = itemsText
                  .split('\n')
                  .map((line) => line.trim())
                  .where((line) => line.isNotEmpty)
                  .toList();

              if (items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.templateItemsRequired),
                  ),
                );
                return;
              }

              final updated = template.copyWith(
                name: name,
                items: items,
                updatedAt: DateTime.now(),
              );

              ref.read(todoTemplatesNotifierProvider.notifier).updateTemplate(updated);
              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.templateUpdated),
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTemplate(TodoTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.deleteTemplate),
        content: Text(
          AppLocalizations.of(context)!.deleteTemplateConfirm(template.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(todoTemplatesNotifierProvider.notifier).deleteTemplate(template.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.templateDeleted),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(todoTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.todoTemplates),
        actions: const [
          _WindowButtons(),
        ],
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noTemplatesYet,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.createFirstTemplate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: const Icon(Icons.note),
                  title: Text(template.name),
                  subtitle: Text(
                    AppLocalizations.of(context)!.templateItemCount(template.items.length),
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
                            Text(AppLocalizations.of(context)!.edit),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.delete,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...template.items.asMap().entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${entry.key + 1}. ',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(entry.value),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(AppLocalizations.of(context)!.errorLoadingTemplates),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTemplate,
        child: const Icon(Icons.add),
      ),
    );
  }
}
