import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../utils/daw_logo.dart';

/// Asks which of several configured [paths] to launch [project] with, when a
/// DAW type has more than one "DAW Locations" override that resolves on disk.
/// Returns the chosen path, or null on Cancel / barrier dismiss.
Future<String?> showDawLaunchPickerDialog(
  BuildContext context, {
  required String dawType,
  required MusicProject project,
  required List<String> paths,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _DawLaunchPickerDialog(
      dawType: dawType,
      project: project,
      paths: paths,
    ),
  );
}

class _DawLaunchPickerDialog extends StatelessWidget {
  final String dawType;
  final MusicProject project;
  final List<String> paths;

  const _DawLaunchPickerDialog({
    required this.dawType,
    required this.project,
    required this.paths,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final logoPath = getDawLogoPath(dawType);

    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(l10n.dawLaunchPickerTitle(dawType)),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dawLaunchPickerBody(dawType, project.displayName),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final path in paths)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: logoPath != null
                    ? Image.asset(
                        logoPath,
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stack) =>
                            const Icon(Icons.piano_outlined),
                      )
                    : const Icon(Icons.piano_outlined),
                title: Text(path, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.of(context).pop(path),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
