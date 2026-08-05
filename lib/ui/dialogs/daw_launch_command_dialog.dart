import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../providers/providers.dart';
import '../../services/daw_detector.dart';
import '../../utils/file_launcher.dart';

/// Shows the Linux "configure a launch command for this DAW" dialog. The
/// dialog persists the change (or removal) itself via
/// [ProjectRepository.setDawLaunchCommand] — callers don't need to do
/// anything with the result; re-read [dawLaunchCommandsProvider] (or just
/// retry the launch) to see the effect.
///
/// Used both from Settings (edit/add an entry) and in-context, the first
/// time "Launch in DAW" fails for a DAW with no override configured yet, or
/// when a previously-configured binary no longer exists ([pathMissing]).
/// When [project] is given (the in-context cases — Settings has no specific
/// project to launch), the primary button reads "Save & Launch" and, once
/// the path is saved, immediately launches [project] with it instead of
/// making the user close the dialog and retry "Launch in DAW" themselves.
Future<void> showDawLaunchCommandDialog(
  BuildContext context, {
  required String dawType,
  String? currentPath,
  bool pathMissing = false,
  MusicProject? project,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => DawLaunchCommandDialog(
      dawType: dawType,
      currentPath: currentPath,
      pathMissing: pathMissing,
      project: project,
    ),
  );
}

class DawLaunchCommandDialog extends ConsumerStatefulWidget {
  final String dawType;
  final String? currentPath;
  final bool pathMissing;
  final MusicProject? project;

  const DawLaunchCommandDialog({
    super.key,
    required this.dawType,
    this.currentPath,
    this.pathMissing = false,
    this.project,
  });

  @override
  ConsumerState<DawLaunchCommandDialog> createState() =>
      _DawLaunchCommandDialogState();
}

class _DawLaunchCommandDialogState
    extends ConsumerState<DawLaunchCommandDialog> {
  late final TextEditingController _pathController;
  List<DetectedDaw> _detectedCandidates = const [];
  bool _loadingDetected = true;
  String? _errorText;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(text: widget.currentPath ?? '');
    _loadDetectedCandidates();
  }

  Future<void> _loadDetectedCandidates() async {
    final all = await DawDetector.detectInstalledDaws();
    if (!mounted) return;
    setState(() {
      _detectedCandidates =
          all.where((d) => d.name == widget.dawType).toList();
      _loadingDetected = false;
    });
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _browse() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      dialogTitle: l10n.dawLaunchCommandDialogBrowseButton,
    );
    if (!mounted || result == null || result.files.single.path == null) {
      return;
    }
    setState(() {
      _pathController.text = result.files.single.path!;
      _errorText = null;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final path = _pathController.text.trim();
    if (path.isEmpty || !File(path).existsSync()) {
      setState(() => _errorText = l10n.dawLaunchCommandDialogInvalidPath);
      return;
    }
    setState(() => _busy = true);
    final repo = await ref.read(repositoryProvider.future);
    await repo.setDawLaunchCommand(widget.dawType, path);
    ref.invalidate(dawLaunchCommandsProvider);
    if (!mounted) return;

    final project = widget.project;
    if (project == null) {
      Navigator.of(context).pop();
      return;
    }

    // Save & Launch: grab the messenger before popping — the dialog's own
    // context is gone right after, but the underlying page's is still valid
    // to show the result snackbar on.
    final messenger = ScaffoldMessenger.of(context);
    final launched = await FileLauncher.launchWithBinary(path, project.filePath);
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          launched
              ? l10n.launchingProject(project.displayName)
              : l10n.failedToLaunchProject(project.displayName),
        ),
      ),
    );
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text(l10n.dawLaunchCommandRemoveConfirmTitle),
        content: Text(
          l10n.dawLaunchCommandRemoveConfirmMessage(widget.dawType),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    final repo = await ref.read(repositoryProvider.future);
    await repo.setDawLaunchCommand(widget.dawType, null);
    ref.invalidate(dawLaunchCommandsProvider);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(l10n.dawLaunchCommandDialogTitle(widget.dawType)),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.pathMissing && widget.currentPath != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade400,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.dawLaunchCommandDialogMissingBanner(
                          widget.dawType,
                          widget.currentPath!,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else
              Text(
                l10n.dawLaunchCommandDialogBody(widget.dawType),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            if (_loadingDetected)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_detectedCandidates.isNotEmpty) ...[
              Text(
                l10n.dawLaunchCommandDialogDetectedHeading,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              for (final candidate in _detectedCandidates)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(
                    candidate.executablePath,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => setState(() {
                    _pathController.text = candidate.executablePath;
                    _errorText = null;
                  }),
                ),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    decoration: InputDecoration(
                      hintText: l10n.dawLaunchCommandDialogManualHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: _errorText,
                    ),
                    onChanged: (_) {
                      if (_errorText != null) setState(() => _errorText = null);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _busy ? null : _browse,
                  child: Text(l10n.dawLaunchCommandDialogBrowseButton),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (widget.currentPath != null)
          TextButton(
            onPressed: _busy ? null : _remove,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.remove),
          ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _save,
          child: Text(
            widget.project != null
                ? l10n.dawLaunchCommandDialogSaveAndLaunchButton
                : l10n.dawLaunchCommandDialogSaveButton,
          ),
        ),
      ],
    );
  }
}
