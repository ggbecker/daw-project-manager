import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart';
import '../providers/providers.dart';
import '../utils/file_launcher.dart';
import 'dialogs/daw_launch_command_dialog.dart';

/// What [launchProjectInDaw] should do for a project, once its DAW type and
/// any configured executable override are known. Pure decision, split out so
/// the branching is unit-testable without a widget tree or a real launcher.
enum DawLaunchAction {
  /// Run the configured override directly with [FileLauncher.launchWithBinary].
  useOverride,

  /// An override is configured but its path is gone — open the configure
  /// dialog in "path missing" mode.
  overrideMissing,

  /// No override and no dependable OS fallback (Linux) — open the configure
  /// dialog so the user can set one now.
  promptConfigure,

  /// Hand the project to the OS default application handler.
  systemDefault,
}

/// Resolves the launch strategy. [overridePath] is the stored executable
/// override for the project's DAW type (null if none); [overridePathExists]
/// is whether that path still resolves on disk. [isLinux] gets its own
/// branch because Linux has no dependable file association for most DAWs and
/// `xdg-open` reports success even when nothing opens — so there's no
/// "it failed, ask now" signal to wait for, unlike Windows/macOS.
@visibleForTesting
DawLaunchAction resolveDawLaunchAction({
  required String? dawType,
  required String? overridePath,
  required bool overridePathExists,
  required bool isLinux,
}) {
  if (dawType == null) return DawLaunchAction.systemDefault;
  if (overridePath != null) {
    return overridePathExists
        ? DawLaunchAction.useOverride
        : DawLaunchAction.overrideMissing;
  }
  return isLinux
      ? DawLaunchAction.promptConfigure
      : DawLaunchAction.systemDefault;
}

/// Whether, after the OS default launch reported failure, the user should be
/// offered the "configure a DAW executable" dialog as a fallback. Only on
/// Windows/macOS with a known DAW type: Linux already prompts up front
/// ([DawLaunchAction.promptConfigure]) and mobile has no such dialog.
@visibleForTesting
bool shouldPromptDawLocationAfterFailedLaunch({
  required String? dawType,
  required bool isMacOS,
  required bool isWindows,
}) =>
    dawType != null && (isMacOS || isWindows);

/// Launches [project] in its DAW.
///
/// Preference order: a user-registered executable override for the DAW type
/// (Settings > DAW Locations) → the OS default file-type handler. The
/// override is always used on Linux (no dependable association there); on
/// Windows/macOS it's a fallback offered via a dialog when the standard
/// launch fails.
///
/// Shared by every "launch in DAW" entry point in the app (the main
/// projects grid, the active-session chip, the idle-session suggestions,
/// project/release detail pages) so the override — and its missing-binary
/// remediation / configure prompt — behaves identically everywhere instead
/// of only from wherever it was implemented first.
Future<void> launchProjectInDaw(
  BuildContext context,
  WidgetRef ref,
  MusicProject project,
) async {
  final l10n = AppLocalizations.of(context)!;

  if (!FileLauncher.targetExists(project.filePath)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fileMissing)),
      );
    }
    return;
  }

  final dawType = project.dawType;

  if (dawType != null) {
    final repo = await ref.read(repositoryProvider.future);
    final overridePath = repo.getDawLaunchCommand(dawType);
    final action = resolveDawLaunchAction(
      dawType: dawType,
      overridePath: overridePath,
      overridePathExists:
          overridePath != null && FileLauncher.targetExists(overridePath),
      isLinux: Platform.isLinux,
    );

    switch (action) {
      case DawLaunchAction.useOverride:
        final launched =
            await FileLauncher.launchWithBinary(overridePath!, project.filePath);
        if (!context.mounted) return;
        _showLaunchResultSnackBar(context, l10n, project, launched);
        return;
      case DawLaunchAction.overrideMissing:
        if (!context.mounted) return;
        await showDawLaunchCommandDialog(
          context,
          dawType: dawType,
          currentPath: overridePath,
          pathMissing: true,
          project: project,
        );
        return;
      case DawLaunchAction.promptConfigure:
        if (!context.mounted) return;
        await showDawLaunchCommandDialog(
          context,
          dawType: dawType,
          project: project,
        );
        return;
      case DawLaunchAction.systemDefault:
        break;
    }
  }

  final success = await FileLauncher.launchProject(project.filePath);
  if (!context.mounted) return;

  if (!success &&
      shouldPromptDawLocationAfterFailedLaunch(
        dawType: dawType,
        isMacOS: Platform.isMacOS,
        isWindows: Platform.isWindows,
      )) {
    await showDawLaunchCommandDialog(
      context,
      dawType: dawType!,
      project: project,
      launchFailed: true,
    );
    return;
  }

  _showLaunchResultSnackBar(context, l10n, project, success);
}

void _showLaunchResultSnackBar(
  BuildContext context,
  AppLocalizations l10n,
  MusicProject project,
  bool launched,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        launched
            ? l10n.launchingProject(project.displayName)
            : l10n.failedToLaunchProject(project.displayName),
      ),
    ),
  );
}

/// Shows a confirmation dialog before ending the active session.
/// Displays the project name and elapsed session time so the user can review
/// before committing.
Future<void> confirmEndSession(BuildContext context, WidgetRef ref) async {
  final project = ref.read(activeProjectProvider);
  if (project == null) return;

  final elapsed = ref.read(workTimerProvider);
  final l10n = AppLocalizations.of(context)!;

  String fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '< 1m';
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.endSession),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.displayName,
            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (elapsed > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 16,
                    color: Theme.of(ctx).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  '${l10n.sessionDuration}: ${fmt(elapsed)}',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          child: Text(l10n.endSession),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    ref.read(activeProjectProvider.notifier).clear();
  }
}

/// Shows a confirmation dialog before starting a session on a project.
/// If another session is already active, offers to switch instead.
Future<void> confirmStartSession(
    BuildContext context, WidgetRef ref, MusicProject project) async {
  final l10n = AppLocalizations.of(context)!;
  final current = ref.read(activeProjectProvider);

  if (current != null) {
    // ── Switch dialog ──────────────────────────────────────────────────────
    final elapsed = ref.read(workTimerProvider);

    String fmt(int s) {
      final h = s ~/ 3600;
      final m = (s % 3600) ~/ 60;
      if (h > 0) return '${h}h ${m}m';
      if (m > 0) return '${m}m';
      return '< 1m';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: Text(l10n.switchSession),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.switchSessionBody,
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 14),
              // Current project row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bookmark, size: 14, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.switchSessionCurrent(current.displayName),
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (elapsed > 0)
                      Text(
                        fmt(elapsed),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Center(child: Icon(Icons.arrow_downward, size: 16)),
              ),
              // New project row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bookmark_add_outlined,
                        size: 14, color: Colors.green.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.switchSessionNew(project.displayName),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.switchSession),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      ref.read(activeProjectProvider.notifier).set(project);
    }
    return;
  }

  // ── Simple start dialog ────────────────────────────────────────────────
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.startSession),
      content: Text(
        project.displayName,
        style: Theme.of(ctx)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.startSession),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    ref.read(activeProjectProvider.notifier).set(project);
  }
}
