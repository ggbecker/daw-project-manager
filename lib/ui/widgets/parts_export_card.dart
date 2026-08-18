import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';

/// The "export every project's parts as a spreadsheet" card on the settings
/// page.
///
/// Split out of `settings_page.dart` so the layout can be pumped on its own in
/// a widget test, without standing up the whole settings page and the
/// Hive-backed providers it reads.
class PartsExportCard extends StatelessWidget {
  const PartsExportCard({
    super.key,
    required this.busy,
    required this.onExport,
  });

  /// Disables both buttons while another settings task is already running.
  final bool busy;

  /// Runs the export. `asXlsx` picks the .xlsx writer over the .csv one.
  final void Function({required bool asXlsx}) onExport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.table_view_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.exportAllPartsCsv,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    l10n.exportAllPartsCsvSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.exportAllPartsXlsxSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // IntrinsicWidth is load-bearing, not decoration. A Row hands its
            // non-flex children an unbounded width, and CrossAxisAlignment
            // .stretch against an unbounded width is exactly what throws
            // "BoxConstraints forces an infinite width" — the card could not
            // render at all without this. Bounding the column to its widest
            // button also keeps the two buttons equal width, which is what
            // stretch was there for.
            IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: busy ? null : () => onExport(asXlsx: false),
                    icon: const Icon(Icons.table_view_outlined),
                    label: const Text('CSV'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: busy ? null : () => onExport(asXlsx: true),
                    icon: const Icon(Icons.grid_on),
                    label: const Text('Excel (.xlsx)'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
