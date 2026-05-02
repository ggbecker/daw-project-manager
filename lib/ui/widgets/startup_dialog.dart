import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../google_drive_sync_page.dart';

const _kHideStartupDialogKey = 'hideStartupDialog';

Future<bool> loadHideStartupDialog() async {
  final box = await Hive.openBox<String>('settings');
  return box.get(_kHideStartupDialogKey) == 'true';
}

void showStartupDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _StartupDialog(),
  );
}

class _StartupDialog extends ConsumerStatefulWidget {
  const _StartupDialog();

  @override
  ConsumerState<_StartupDialog> createState() => _StartupDialogState();
}

class _StartupDialogState extends ConsumerState<_StartupDialog> {
  bool _dontShowAgain = false;
  bool _busy = false;

  Future<void> _savePref() async {
    if (_dontShowAgain) {
      final box = await Hive.openBox<String>('settings');
      await box.put(_kHideStartupDialogKey, 'true');
    }
  }

  Future<void> _addFolder() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await FilePicker.platform.getDirectoryPath(
      dialogTitle: l10n.selectProjectsFolder,
    );
    if (picked == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final repo = await ref.read(repositoryProvider.future);
      await repo.addRoot(picked);
      ref.invalidate(rootsWatchProvider);
      ref.invalidate(scanRootsProvider);
      ref.invalidate(allProjectsStreamProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorAddingFolder(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    await _savePref();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _openGoogleDrive() async {
    await _savePref();
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GoogleDriveSyncPage()));
  }

  Future<void> _dismiss() async {
    await _savePref();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(l10n.startupDialogTitle),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.startupDialogSubtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            _OptionCard(
              icon: Icons.folder_open,
              title: l10n.startupAddFolderTitle,
              subtitle: l10n.startupAddFolderSubtitle,
              onTap: _busy ? null : _addFolder,
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.cloud_download_outlined,
              title: l10n.startupGoogleDriveTitle,
              subtitle: l10n.startupGoogleDriveSubtitle,
              onTap: _busy ? null : _openGoogleDrive,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _dontShowAgain,
              onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
              title: Text(l10n.startupDontShowAgain, style: theme.textTheme.bodySmall),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : _dismiss,
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
