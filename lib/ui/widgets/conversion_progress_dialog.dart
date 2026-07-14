import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../services/audio_analysis_service.dart';

/// Runs [AudioAnalysisService.convertForSharing] on [sourcePath] with a
/// blocking "Preparing audio for sharing…" dialog, since converting a large
/// WAV can take several seconds with no other feedback. Returns the
/// converted file, or null when conversion isn't possible — failure
/// messaging is left to the caller, which knows its own context.
///
/// [convert] is a test seam; production callers use the default, which
/// converts into the system temp directory.
Future<File?> convertForSharingWithProgress(
  BuildContext context,
  String sourcePath, {
  Future<File?> Function(String sourcePath)? convert,
}) async {
  // Captured before any await: the caller's context can unmount while the
  // conversion runs, but this NavigatorState (root) stays valid.
  final nav = Navigator.of(context, rootNavigator: true);

  // Deliberately not awaited — awaiting showDialog would block until the
  // dialog is popped, i.e. before the conversion ever starts.
  showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(ctx).cardColor,
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Flexible(child: Text(AppLocalizations.of(ctx)!.convertingAudioForSharing)),
        ],
      ),
    ),
  );

  try {
    return await (convert ?? _convertIntoTempDir)(sourcePath);
  } finally {
    nav.pop();
  }
}

Future<File?> _convertIntoTempDir(String sourcePath) async {
  final tempDir = await getTemporaryDirectory();
  return AudioAnalysisService.convertForSharing(sourcePath, tempDir.path);
}
