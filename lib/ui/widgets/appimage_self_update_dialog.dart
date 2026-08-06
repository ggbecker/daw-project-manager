import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../services/appimage_update_service.dart';

enum _Stage { fetching, downloading, verifying, cancelling, ready, error }

/// Drives the actual AppImage self-update (fetch release assets, download,
/// verify, replace, offer a restart) after the user picks "Update Now" in
/// [UpdateAvailableDialog]. Kept as a separate dialog/widget so the parent
/// dialog can stay a simple StatelessWidget.
class AppImageSelfUpdateDialog extends StatefulWidget {
  final String version;

  const AppImageSelfUpdateDialog({super.key, required this.version});

  static void show(BuildContext context, String version) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppImageSelfUpdateDialog(version: version),
    );
  }

  @override
  State<AppImageSelfUpdateDialog> createState() => _AppImageSelfUpdateDialogState();
}

class _AppImageSelfUpdateDialogState extends State<AppImageSelfUpdateDialog> {
  _Stage _stage = _Stage.fetching;
  double? _progress;
  String? _errorDetails;
  UpdateCancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _stage = _Stage.fetching;
      _progress = null;
      _errorDetails = null;
    });
    final cancelToken = UpdateCancelToken();
    _cancelToken = cancelToken;
    final service = AppImageUpdateService();
    try {
      final assets = await service.fetchReleaseAssets(widget.version);
      if (cancelToken.isCancelled) throw const UpdateCancelledException();
      if (assets == null) {
        throw StateError('No AppImage asset found for v${widget.version}.');
      }
      if (!mounted) return;
      setState(() => _stage = _Stage.downloading);
      await service.applyUpdate(
        assets,
        cancelToken: cancelToken,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _stage = progress == null ? _Stage.verifying : _Stage.downloading;
            _progress = progress;
          });
        },
      );
      if (!mounted) return;
      setState(() => _stage = _Stage.ready);
    } on UpdateCancelledException {
      // Cleanup already happened inside applyUpdate before this was thrown —
      // just close the dialog, this isn't a failure the user needs to see.
      if (mounted) Navigator.of(context).pop();
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _errorDetails = '$e\n\n$stackTrace';
      });
    } finally {
      service.close();
    }
  }

  void _cancel() {
    if (_stage == _Stage.cancelling) return;
    setState(() => _stage = _Stage.cancelling);
    _cancelToken?.cancel();
  }

  Future<void> _restartNow() async {
    final service = AppImageUpdateService();
    await service.relaunch();
    exit(0);
  }

  Future<void> _copyErrorDetails(AppLocalizations l10n) async {
    await Clipboard.setData(ClipboardData(text: _errorDetails ?? ''));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.appImageUpdateErrorDetailsCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openNewIssue() async {
    final uri = Uri(
      scheme: 'https',
      host: 'github.com',
      path: '/bandpassrecords/daw-project-manager/issues/new',
      queryParameters: {
        'template': 'issue.yml',
        'type': 'Bug report',
        'actual': 'The in-app AppImage update failed with:\n\n${_errorDetails ?? ''}',
      },
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return PopScope(
      canPop: _stage == _Stage.ready || _stage == _Stage.error,
      child: AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_titleFor(l10n)),
        content: SizedBox(
          width: 380,
          child: _buildBody(context, l10n, theme),
        ),
        actions: _buildActions(context, l10n),
      ),
    );
  }

  String _titleFor(AppLocalizations l10n) {
    switch (_stage) {
      case _Stage.ready:
        return l10n.appImageUpdateReadyTitle;
      case _Stage.error:
        return l10n.appImageUpdateFailedTitle;
      case _Stage.fetching:
      case _Stage.downloading:
      case _Stage.verifying:
      case _Stage.cancelling:
        return l10n.updateNowButtonLabel;
    }
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    switch (_stage) {
      case _Stage.fetching:
        return _ProgressRow(label: l10n.appImageUpdateFetching, progress: null);
      case _Stage.downloading:
        final percent = _progress == null ? null : (_progress! * 100).round();
        return _ProgressRow(
          label: percent == null
              ? l10n.appImageUpdateDownloading
              : l10n.appImageUpdateDownloadingProgress(percent),
          progress: _progress,
        );
      case _Stage.verifying:
        return _ProgressRow(label: l10n.appImageUpdateVerifying, progress: null);
      case _Stage.cancelling:
        return _ProgressRow(label: l10n.cancelling, progress: null);
      case _Stage.ready:
        return Row(
          children: [
            Icon(Icons.check_circle, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.appImageUpdateReadyMessage(widget.version))),
          ],
        );
      case _Stage.error:
        return _buildErrorBody(context, l10n, theme);
    }
  }

  Widget _buildErrorBody(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    final details = _errorDetails;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.appImageUpdateErrorMessage)),
            ],
          ),
          if (details != null) ...[
            const SizedBox(height: 4),
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(l10n.appImageUpdateErrorDetailsLabel, style: theme.textTheme.bodyMedium),
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 160),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        details,
                        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _copyErrorDetails(l10n),
                      icon: const Icon(Icons.copy_outlined, size: 16),
                      label: Text(l10n.appImageUpdateCopyErrorDetails),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, AppLocalizations l10n) {
    switch (_stage) {
      case _Stage.fetching:
      case _Stage.downloading:
      case _Stage.verifying:
        return [
          TextButton(
            onPressed: _cancel,
            child: Text(l10n.cancel),
          ),
        ];
      case _Stage.cancelling:
        return const [];
      case _Stage.ready:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.dismiss),
          ),
          FilledButton(
            onPressed: _restartNow,
            child: Text(l10n.appImageUpdateRestartNow),
          ),
        ];
      case _Stage.error:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
          OutlinedButton.icon(
            onPressed: _openNewIssue,
            icon: const Icon(Icons.bug_report_outlined, size: 16),
            label: Text(l10n.reportIssue),
          ),
          FilledButton(
            onPressed: _run,
            child: Text(l10n.appImageUpdateRetry),
          ),
        ];
    }
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double? progress;

  const _ProgressRow({required this.label, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: progress),
      ],
    );
  }
}
