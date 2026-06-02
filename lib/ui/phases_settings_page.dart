import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../utils/mobile_utils.dart';
import 'widgets/desktop_title_bar.dart';

class PhasesSettingsPage extends ConsumerStatefulWidget {
  const PhasesSettingsPage({super.key});

  @override
  ConsumerState<PhasesSettingsPage> createState() => _PhasesSettingsPageState();
}

class _PhasesSettingsPageState extends ConsumerState<PhasesSettingsPage> {
  final _addController = TextEditingController();
  String? _addError;

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _save(List<String> phases) async {
    final repo = ref.read(repositoryProvider).asData?.value;
    if (repo == null) return;
    await repo.setCustomPhases(phases);
    ref.invalidate(customPhasesProvider);
  }

  Future<void> _resetToDefaults() async {
    const defaults = ['Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'];
    await _save(defaults);
  }

  Future<void> _deletePhase(String phase, List<String> current) async {
    final l10n = AppLocalizations.of(context)!;
    final projects = ref.read(projectsProvider);
    final count = projects.where((p) => p.status == phase).length;

    if (count > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deletePhaseWarning(count))),
      );
    }

    final updated = List<String>.from(current)..remove(phase);
    await _save(updated);
  }

  Future<void> _addPhase(List<String> current) async {
    final l10n = AppLocalizations.of(context)!;
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    if (current.any((p) => p.toLowerCase() == name.toLowerCase())) {
      setState(() => _addError = l10n.phaseDuplicateError);
      return;
    }
    setState(() => _addError = null);
    _addController.clear();
    await _save([...current, name]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final phases = ref.watch(customPhasesProvider);
    final isDesktop = !kIsWeb && MobileUtils.isDesktop();

    return Scaffold(
      body: Column(
        children: [
          DesktopTitleBar(title: l10n.phases, showBack: true),
          if (!isDesktop)
            AppBar(
              title: Text(l10n.phases),
              leading: const BackButton(),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: EdgeInsets.all(MobileUtils.isDesktop() ? 24 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.phases,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton(
                              onPressed: _resetToDefaults,
                              child: Text(l10n.resetToDefaults),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            buildDefaultDragHandles: false,
                            itemCount: phases.length,
                            onReorder: (oldIndex, newIndex) {
                              if (newIndex > oldIndex) newIndex--;
                              final updated = List<String>.from(phases);
                              updated.insert(newIndex, updated.removeAt(oldIndex));
                              _save(updated);
                            },
                            itemBuilder: (context, index) {
                              final phase = phases[index];
                              return ListTile(
                                key: ValueKey(phase),
                                leading: ReorderableDragStartListener(
                                  index: index,
                                  child: Icon(
                                    Icons.drag_indicator,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                title: Text(phase),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Theme.of(context).colorScheme.error,
                                  tooltip: 'Delete',
                                  onPressed: phases.length > 1
                                      ? () => _deletePhase(phase, phases)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Add phase row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _addController,
                                decoration: InputDecoration(
                                  labelText: l10n.phaseNameHint,
                                  errorText: _addError,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _addPhase(phases),
                                textInputAction: TextInputAction.done,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonalIcon(
                              onPressed: () => _addPhase(phases),
                              icon: const Icon(Icons.add),
                              label: Text(l10n.addPhase),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
