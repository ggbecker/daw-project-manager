import 'dart:io';

import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../services/appimage_update_service.dart';

enum _Stage { fetching, downloading, verifying, ready, error }

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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _stage = _Stage.fetching;
      _progress = null;
      _errorMessage = null;
    });
    final service = AppImageUpdateService();
    try {
      final assets = await service.fetchReleaseAssets(widget.version);
      if (assets == null) {
        throw StateError('No AppImage asset found for v${widget.version}.');
      }
      if (!mounted) return;
      setState(() => _stage = _Stage.downloading);
      await service.applyUpdate(
        assets,
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _errorMessage = e.toString();
      });
    } finally {
      service.close();
    }
  }

  Future<void> _restartNow() async {
    final service = AppImageUpdateService();
    await service.relaunch();
    exit(0);
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
      case _Stage.ready:
        return Row(
          children: [
            Icon(Icons.check_circle, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.appImageUpdateReadyMessage(widget.version))),
          ],
        );
      case _Stage.error:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(child: Text(_errorMessage ?? '')),
          ],
        );
    }
  }

  List<Widget> _buildActions(BuildContext context, AppLocalizations l10n) {
    switch (_stage) {
      case _Stage.fetching:
      case _Stage.downloading:
      case _Stage.verifying:
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
