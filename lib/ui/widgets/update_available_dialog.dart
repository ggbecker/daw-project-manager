import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/l10n/app_localizations.dart';

const String _kWindowsStoreId =
    String.fromEnvironment('WINDOWS_STORE_ID', defaultValue: '9n8hxzd3hwx7');
const String _kGithubOwner =
    String.fromEnvironment('GITHUB_OWNER', defaultValue: 'bandpassrecords');
const String _kGithubRepo =
    String.fromEnvironment('GITHUB_REPO', defaultValue: 'daw-project-manager');
const String _kCurrentVersion =
    String.fromEnvironment('APP_VERSION', defaultValue: '0.0.0');

class UpdateAvailableDialog extends StatelessWidget {
  final String version;

  const UpdateAvailableDialog({super.key, required this.version});

  /// Show the dialog from anywhere using any valid BuildContext.
  static void show(BuildContext context, String version) {
    showDialog(
      context: context,
      builder: (_) => UpdateAvailableDialog(version: version),
    );
  }

  Future<void> _launch(Uri uri, ScaffoldMessengerState messenger, String couldNotOpenLinkMessage) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(
        SnackBar(content: Text(couldNotOpenLinkMessage)),
      );
    }
  }

  Future<void> _openStoreLink(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final couldNotOpenLinkMessage = AppLocalizations.of(context)!.couldNotOpenLink;
    Uri uri;
    if (Platform.isWindows && _kWindowsStoreId.isNotEmpty) {
      uri = Uri.parse('https://www.microsoft.com/store/apps/$_kWindowsStoreId');
    } else if (_kGithubOwner.isNotEmpty && _kGithubRepo.isNotEmpty) {
      uri = Uri.parse(
          'https://github.com/$_kGithubOwner/$_kGithubRepo/releases/tag/v$version');
    } else {
      return;
    }
    await _launch(uri, messenger, couldNotOpenLinkMessage);
  }

  Future<void> _openGitHubRelease(BuildContext context) async {
    if (_kGithubOwner.isEmpty || _kGithubRepo.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final couldNotOpenLinkMessage = AppLocalizations.of(context)!.couldNotOpenLink;
    final uri = Uri.parse(
        'https://github.com/$_kGithubOwner/$_kGithubRepo/releases/tag/v$version');
    await _launch(uri, messenger, couldNotOpenLinkMessage);
  }

  Future<void> _openMsStoreApp(BuildContext context) async {
    if (_kWindowsStoreId.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final couldNotOpenLinkMessage = AppLocalizations.of(context)!.couldNotOpenLink;
    final storeUri =
        Uri.parse('ms-windows-store://pdp/?productid=$_kWindowsStoreId');
    final webUri = Uri.parse(
        'https://www.microsoft.com/store/apps/$_kWindowsStoreId');
    // Try the ms-windows-store:// protocol first; fall back to web URL.
    if (!await launchUrl(storeUri)) {
      await _launch(webUri, messenger, couldNotOpenLinkMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isWindows = !kIsDesktopOverride && Platform.isWindows;
    final isMacOS = !kIsDesktopOverride && Platform.isMacOS;

    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.system_update_alt,
                color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l10n.updateAvailableTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version chips row
            Row(
              children: [
                _VersionChip(
                  label: l10n.updateCurrentVersion(_kCurrentVersion),
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
                const SizedBox(width: 8),
                _VersionChip(
                  label: 'v$version',
                  color: theme.colorScheme.primary,
                  bold: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.updateAvailableVersion(version),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            // Platform-specific update section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isWindows
                            ? Icons.store
                            : Icons.code,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isWindows ? 'Microsoft Store' : 'GitHub Releases',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isWindows
                        ? l10n.updateWindowsInstructions
                        : l10n.updateMacInstructions,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  // Primary CTA button
                  if (isWindows)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.store, size: 18),
                        label: Text(l10n.getOnMicrosoftStore),
                        onPressed: () => _openMsStoreApp(context),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    )
                  else if (isMacOS || _kGithubOwner.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.download, size: 18),
                        label: Text(l10n.downloadFromGitHub),
                        onPressed: () => _openStoreLink(context),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_kGithubOwner.isNotEmpty && _kGithubRepo.isNotEmpty)
          TextButton.icon(
            icon: const Icon(Icons.open_in_new, size: 14),
            label: Text(AppLocalizations.of(context)!.githubButtonLabel),
            onPressed: () => _openGitHubRelease(context),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.dismiss),
        ),
      ],
    );
  }
}

// Allows overriding platform checks in tests; not used in production.
const bool kIsDesktopOverride = false;

class _VersionChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool bold;

  const _VersionChip(
      {required this.label, required this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
}
