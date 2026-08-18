import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart';
import '../providers/providers.dart';
import '../utils/file_launcher.dart';
import '../utils/launch_diagnostics.dart';
import 'dialogs/daw_launch_command_dialog.dart';
import 'dialogs/launch_diagnostics_dialog.dart';

/// Launches [project] in its DAW, preferring a Linux-only registered binary
/// override for its DAW type (see Settings > DAW Locations) over the OS
/// default file-type handler, which has no reliable association for most
/// DAWs there. Shared by every "launch in DAW" entry point in the app (the
/// main projects grid, the active-session chip, the idle-session
/// suggestions, project/release detail pages) so the override — and its
/// missing-binary remediation / first-run configure prompt — behaves
/// identically everywhere instead of only from wherever it was implemented
/// first.
Future<void> launchProjectInDaw(
  BuildContext context,
  WidgetRef ref,
  MusicProject project,
) async {
  // Start a fresh record so the "Details" dialog on a failure shows this
  // attempt rather than every attempt since the app started.
  LaunchDiagnostics.clear();
  LaunchDiagnostics.record('launch requested', {
    'os': Platform.operatingSystem,
    'osVersion': Platform.operatingSystemVersion,
    'dawType': project.dawType,
    'dawVersion': project.dawVersion,
  });

  final fileExists = File(project.filePath).existsSync();
  final directoryExists = Directory(project.filePath).existsSync();
  final exists = fileExists || directoryExists;
  LaunchDiagnostics.record('project path', {
    'fileExists': fileExists,
    'directoryExists': directoryExists,
    ...LaunchDiagnostics.describePath(project.filePath),
    'path': project.filePath,
  });
  if (!exists) {
    LaunchDiagnostics.record('FAILED: project path does not exist');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fileMissing)),
      );
    }
    return;
  }

  if (Platform.isLinux && project.dawType != null) {
    final repo = await ref.read(repositoryProvider.future);
    final binaryPath = repo.getDawLaunchCommand(project.dawType!);
    LaunchDiagnostics.record('linux binary override', {'binaryPath': binaryPath});
    if (binaryPath == null) {
      // No override configured yet: on Linux there's no reliable OS-level
      // file association to fall back on for most DAWs (see the class doc
      // above), and xdg-open reports success even when nothing actually
      // opens — so there's no "it failed, ask now" signal to wait for.
      // Go straight to the configure-a-binary prompt instead of silently
      // doing nothing.
      if (!context.mounted) return;
      await showDawLaunchCommandDialog(
        context,
        dawType: project.dawType!,
        project: project,
      );
      return;
    }
    if (!File(binaryPath).existsSync()) {
      if (!context.mounted) return;
      await showDawLaunchCommandDialog(
        context,
        dawType: project.dawType!,
        currentPath: binaryPath,
        pathMissing: true,
        project: project,
      );
      return;
    }
    final launched = await FileLauncher.launchWithBinary(
      binaryPath,
      project.filePath,
    );
    LaunchDiagnostics.record('launch result', {'launched': launched});
    if (!context.mounted) return;
    showLaunchResultSnackBar(context, project, launched);
    return;
  }

  final success = await FileLauncher.launchProject(project.filePath);
  LaunchDiagnostics.record('launch result', {'launched': success});

  if (!context.mounted) return;
  showLaunchResultSnackBar(context, project, success);
}

/// Reports the outcome of a launch attempt.
///
/// A success is the plain one-line message it has always been. A failure
/// carries the record of the attempt in the snackbar itself, with **Copy**
/// in the action slot — `Failed to launch [project]` on its own is the
/// report we keep receiving and it says nothing about *why*, and asking a
/// tester to go and find a log file (behind a Settings toggle that is off
/// by default, and that they would have had to enable *before* hitting the
/// bug) loses most of them. Copying from the message that just appeared is
/// the one step they will actually take.
///
/// The log sits in a scroll view rather than expanding to fit: a snackbar
/// that grows to the height of a 20-line report covers the app. "Details"
/// opens the same content in [showLaunchDiagnosticsDialog], which is
/// selectable and comfortable to read at length.
@visibleForTesting
void showLaunchResultSnackBar(
  BuildContext context,
  MusicProject project,
  bool launched,
) {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);

  if (launched) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.launchingProject(project.displayName))),
    );
    return;
  }

  final report = LaunchDiagnostics.report;
  final cause = describeLaunchFailureCause(l10n);
  // Long enough to read a few lines and reach the button, since the whole
  // point is that the tester leaves with the text in their clipboard.
  const failureDuration = Duration(seconds: 30);

  messenger.showSnackBar(
    SnackBar(
      duration: failureDuration,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.failedToLaunchProject(project.displayName)),
          // When the diagnostics identified the cause outright, lead with it
          // in plain language — a tester should not have to spot
          // `openCommand=null` in the log to learn that Windows has nothing
          // registered to open their project files.
          if (cause != null) ...[
            const SizedBox(height: 6),
            Text(cause, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
          if (report.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 132),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  // Tinted with the snackbar's own text colour so the panel
                  // reads as inset whichever way round the theme puts the
                  // snackbar (its surface is the *inverse* of the app's, so
                  // a hardcoded black or white overlay is wrong half the
                  // time).
                  color: Theme.of(context)
                      .colorScheme
                      .onInverseSurface
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    report,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  if (context.mounted) showLaunchDiagnosticsDialog(context);
                },
                child: Text(l10n.launchDiagnosticsAction),
              ),
            ),
          ],
        ],
      ),
      action: SnackBarAction(
        label: l10n.launchDiagnosticsCopy,
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: report));
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.launchDiagnosticsCopied)),
          );
        },
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
