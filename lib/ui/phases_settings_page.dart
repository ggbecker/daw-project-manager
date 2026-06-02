import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../utils/mobile_utils.dart';
import '../utils/phase_colors.dart';
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

  Future<void> _savePhases(List<String> phases) async {
    final repo = ref.read(repositoryProvider).asData?.value;
    if (repo == null) return;
    await repo.setCustomPhases(phases);
    ref.invalidate(customPhasesProvider);
  }

  Future<void> _saveColor(String phase, Color color) async {
    final repo = ref.read(repositoryProvider).asData?.value;
    if (repo == null) return;
    final current = Map<String, String>.from(repo.getPhaseColors());
    current[phase] = colorToHex(color);
    await repo.setPhaseColors(current);
    ref.invalidate(phaseColorsProvider);
  }

  Future<void> _resetToDefaults() async {
    const defaults = ['Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'];
    final repo = ref.read(repositoryProvider).asData?.value;
    if (repo == null) return;
    await repo.setCustomPhases(defaults);
    await repo.setPhaseColors({});
    await repo.setFinishedPhases({'Finished'});
    ref.invalidate(customPhasesProvider);
    ref.invalidate(phaseColorsProvider);
    ref.invalidate(finishedPhaseProvider);
  }

  Future<void> _toggleFinishedPhase(String phase, Set<String> current) async {
    final repo = ref.read(repositoryProvider).asData?.value;
    if (repo == null) return;
    final updated = Set<String>.from(current);
    if (updated.contains(phase)) {
      if (updated.length > 1) updated.remove(phase);
    } else {
      updated.add(phase);
    }
    await repo.setFinishedPhases(updated);
    ref.invalidate(finishedPhaseProvider);
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
    await _savePhases(updated);
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
    await _savePhases([...current, name]);
  }

  Future<void> _pickColor(
    String phase,
    Color currentColor,
    List<String> phases,
  ) async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => _ColorPickerDialog(
        phaseName: phase,
        currentColor: currentColor,
      ),
    );
    if (picked != null) await _saveColor(phase, picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final phases = ref.watch(customPhasesProvider);
    final storedColors = ref.watch(phaseColorsProvider);
    final finishedPhase = ref.watch(finishedPhaseProvider);
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
                              updated.insert(
                                  newIndex, updated.removeAt(oldIndex));
                              _savePhases(updated);
                            },
                            itemBuilder: (context, index) {
                              final phase = phases[index];
                              final color = resolvePhaseColor(
                                  phase, storedColors, phases);
                              return ListTile(
                                key: ValueKey(phase),
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Icon(
                                        Icons.drag_indicator,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Tooltip(
                                      message: l10n.selectPhaseColor,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _pickColor(phase, color, phases),
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .dividerColor,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text(phase),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Tooltip(
                                      message: l10n.markAsFinished,
                                      child: IconButton(
                                        icon: Icon(
                                          finishedPhase.contains(phase)
                                              ? Icons.flag
                                              : Icons.flag_outlined,
                                          color: finishedPhase.contains(phase)
                                              ? Colors.green
                                              : null,
                                        ),
                                        onPressed: () => _toggleFinishedPhase(phase, finishedPhase),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: Theme.of(context).colorScheme.error,
                                      tooltip: 'Delete',
                                      onPressed: phases.length > 1
                                          ? () => _deletePhase(phase, phases)
                                          : null,
                                    ),
                                  ],
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

// ---------------------------------------------------------------------------
// Color picker dialog
// ---------------------------------------------------------------------------

class _ColorPickerDialog extends StatelessWidget {
  final String phaseName;
  final Color currentColor;

  const _ColorPickerDialog({
    required this.phaseName,
    required this.currentColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(phaseName),
      content: SizedBox(
        width: 220,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: kPhaseColorPalette.map((color) {
            final isSelected = color.toARGB32() == currentColor.toARGB32();
            return GestureDetector(
              onTap: () => Navigator.pop(context, color),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 6,
                          )
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 18,
                        color: ThemeData.estimateBrightnessForColor(color) ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
