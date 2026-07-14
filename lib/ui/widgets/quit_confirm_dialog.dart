import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';

/// Shared quit-confirmation dialog for every desktop quit path (window X,
/// macOS menu ⌘+Q). Returns true when the user confirms quitting, false on
/// Cancel, null when dismissed.
Future<bool?> showQuitConfirmDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(ctx).cardColor,
      title: Text(l10n.quitConfirmTitle),
      content: Text(l10n.quitConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.quit),
        ),
      ],
    ),
  );
}
