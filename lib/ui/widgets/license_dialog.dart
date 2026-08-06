import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../generated/l10n/app_localizations.dart';

void showLicenseDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const LicenseTextDialog(),
  );
}

class LicenseTextDialog extends StatefulWidget {
  const LicenseTextDialog({super.key});

  @override
  State<LicenseTextDialog> createState() => _LicenseTextDialogState();
}

class _LicenseTextDialogState extends State<LicenseTextDialog> {
  late final Future<String> _licenseText = rootBundle.loadString('LICENSE');
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.gavel_outlined, size: 20),
          const SizedBox(width: 8),
          Text(l10n.license),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      content: SizedBox(
        width: 480,
        height: 420,
        child: FutureBuilder<String>(
          future: _licenseText,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: SelectableText(
                  snapshot.data!,
                  style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            );
          },
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.close,
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
