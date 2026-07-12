import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../services/audio_analysis_service.dart';

/// Desktop-only: a chip the user can drag straight onto another app's
/// window (e.g. WhatsApp Desktop) to share the file.
///
/// This exists because `Share.shareXFiles` on Windows goes through the
/// `DataTransferManager` API, which only works when the app is
/// MSIX-packaged — an unpackaged dev/debug build gets
/// `ShareResultStatus.unavailable` with no share sheet ever appearing.
/// OS-level drag-and-drop uses a different mechanism (CF_HDROP on Windows,
/// public.file-url on macOS) that works regardless of packaging.
class DragToShareButton extends StatefulWidget {
  final String sourcePath;

  const DragToShareButton({super.key, required this.sourcePath});

  @override
  State<DragToShareButton> createState() => _DragToShareButtonState();
}

class _DragToShareButtonState extends State<DragToShareButton> {
  // Keyed by source path so repeated drags of the same song don't
  // re-convert every time.
  static final Map<String, String> _conversionCache = {};

  Future<String?> _resolveDragPath() async {
    if (!AudioAnalysisService.needsConversionForSharing(widget.sourcePath)) {
      return widget.sourcePath;
    }
    final cached = _conversionCache[widget.sourcePath];
    if (cached != null && await File(cached).exists()) return cached;

    final tempDir = await getTemporaryDirectory();
    final converted = await AudioAnalysisService.convertForSharing(
      widget.sourcePath,
      tempDir.path,
    );
    if (converted == null) return null;
    _conversionCache[widget.sourcePath] = converted.path;
    return converted.path;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DragItemWidget(
      allowedOperations: () => [DropOperation.copy],
      dragItemProvider: (request) async {
        final path = await _resolveDragPath();
        if (path == null) return null;
        final item = DragItem(suggestedName: p.basename(path));
        item.add(Formats.fileUri(Uri.file(path)));
        return item;
      },
      child: DraggableWidget(
        child: Tooltip(
          message: l10n.dragToShareTooltip,
          child: Chip(
            avatar: const Icon(Icons.drag_indicator, size: 16),
            label: Text(l10n.dragToShare),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }
}
