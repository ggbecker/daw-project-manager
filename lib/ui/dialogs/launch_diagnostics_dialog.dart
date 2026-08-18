import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../utils/launch_diagnostics.dart';

/// Shows what the app recorded during the last "Launch in DAW" attempt, with
/// a button to copy it.
///
/// Reached from the "Details" action on the `Failed to launch [project]`
/// snackbar. That message is all a tester can currently report, and it says
/// nothing about the cause; this puts the actual record of the attempt —
/// which branch ran, what the path looked like, what Windows had registered
/// for the file type, what the shell returned — somewhere they can copy it
/// out of and paste into an issue, with nothing to enable first.
/// The cause the diagnostics identified for the last attempt, in the user's
/// language, or null if none was pinned down.
///
/// Lives here rather than beside the snackbar because both the snackbar and
/// this dialog lead with it, and this file is the one they share.
String? describeLaunchFailureCause(AppLocalizations l10n) {
  final cause = LaunchDiagnostics.probableCause;
  if (cause == null) return null;
  switch (cause) {
    case LaunchFailureCause.noFileAssociation:
      return l10n.launchFailureNoAssociation(
        LaunchDiagnostics.probableCauseDetail ?? '',
      );
  }
}

Future<void> showLaunchDiagnosticsDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final report = LaunchDiagnostics.report;
  final cause = describeLaunchFailureCause(l10n);

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.launchDiagnosticsTitle),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cause != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(ctx)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Theme.of(ctx).colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cause,
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(ctx).colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              l10n.launchDiagnosticsIntro,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    report.isEmpty ? l10n.launchDiagnosticsEmpty : report,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.close),
        ),
        FilledButton.icon(
          onPressed: report.isEmpty
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: report));
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(l10n.launchDiagnosticsCopied)),
                  );
                },
          icon: const Icon(Icons.copy, size: 16),
          label: Text(l10n.launchDiagnosticsCopy),
        ),
      ],
    ),
  );
}
