import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart';
import '../providers/providers.dart';

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
