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
Future<void> showLaunchDiagnosticsDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final report = LaunchDiagnostics.report;

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
