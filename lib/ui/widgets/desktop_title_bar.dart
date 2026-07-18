import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart'
    if (dart.library.html) 'package:window_manager/window_manager_stub.dart';

import '../../utils/mobile_utils.dart';

/// A cross-platform desktop title bar widget.
///
/// **Windows / Linux (release mode):** Renders a full custom title bar with a
/// draggable area, title, optional back button, optional extra [actions], and
/// native-style window control buttons (minimize / maximize / close).
///
/// **macOS:** [TitleBarStyle.hidden] + fullSizeContentView is used so Flutter
/// content fills the entire window and the traffic-light buttons float over it.
/// This widget reserves 28 pt at the top when [showBack] is false, or renders
/// a slim back-navigation bar when [showBack] is true.
///
/// **Mobile / web:** Returns an empty widget.
class DesktopTitleBar extends StatefulWidget {
  final String title;

  /// Show a back button that calls [Navigator.pop].
  final bool showBack;

  /// Extra action widgets placed before the window buttons.
  /// Only shown on Windows / Linux (not on macOS where they belong in the
  /// native menu bar via [MacOSMenuBar]).
  final List<Widget> actions;

  const DesktopTitleBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.actions = const [],
  });

  @override
  State<DesktopTitleBar> createState() => _DesktopTitleBarState();
}

class _DesktopTitleBarState extends State<DesktopTitleBar> {
  // Manual double-tap detection for the drag area — avoids placing a
  // DoubleTapGestureRecognizer over the entire bar (which would delay the
  // window-control buttons by the double-tap timeout).
  DateTime? _lastDragAreaTap;

  void _handleDragAreaTap() {
    final now = DateTime.now();
    if (_lastDragAreaTap != null &&
        now.difference(_lastDragAreaTap!) < const Duration(milliseconds: 350)) {
      _lastDragAreaTap = null;
      _toggleMaximize();
    } else {
      _lastDragAreaTap = now;
    }
  }

  Future<void> _toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      windowManager.restore();
    } else {
      windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || MobileUtils.isMobile()) {
      return const SizedBox.shrink();
    }

    // macOS: TitleBarStyle.hidden + fullSizeContentView means Flutter content
    // starts at y=0, with the traffic lights floating over the top-left area.
    // Reserve 28pt at the top so content doesn't slide under the buttons.
    if (Platform.isMacOS) {
      if (!widget.showBack) {
        // Drag and double-click-to-maximize are handled natively in
        // MainFlutterWindow.swift via NSEvent monitors — no Flutter
        // gesture detection needed here.
        return const SizedBox(height: 28, width: double.infinity);
      }
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        height: 40,
        child: Row(
          children: [
            // Reserve space for macOS traffic lights (~75pt from left edge).
            const SizedBox(width: 75),
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                size: 20,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
            ),
            Text(
              widget.title,
              style: TextStyle(
                color: Theme.of(context).textTheme.titleMedium?.color,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    // Windows / Linux: full custom title bar.
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      height: 40,
      child: Row(
        children: [
          // ── Drag area: pan-to-drag + manual double-tap-to-maximize ──────────
          // The GestureDetector here covers only the title/drag region, NOT the
          // window-control buttons. This prevents DoubleTapGestureRecognizer
          // from delaying button tap callbacks.
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => windowManager.startDragging(),
              onTapDown: (_) => _handleDragAreaTap(),
              child: SizedBox.expand(
                child: Row(
                  children: [
                    if (widget.showBack)
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    Padding(
                      padding: EdgeInsets.only(left: widget.showBack ? 4 : 12),
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.titleMedium?.color,
                          fontSize: 16,
                          fontWeight: widget.showBack
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Window controls: completely outside the drag-area detector ──────
          ...widget.actions,
          _WindowControlButtons(onToggleMaximize: _toggleMaximize),
        ],
      ),
    );
  }
}

/// Minimize / Maximize / Close buttons for Windows and Linux only.
class _WindowControlButtons extends StatelessWidget {
  final VoidCallback onToggleMaximize;

  const _WindowControlButtons({required this.onToggleMaximize});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.minimize, size: 18,
              color: Theme.of(context).textTheme.bodyMedium?.color),
          onPressed: () => windowManager.minimize(),
        ),
        IconButton(
          icon: Icon(Icons.crop_square_sharp, size: 18,
              color: Theme.of(context).textTheme.bodyMedium?.color),
          onPressed: onToggleMaximize,
        ),
        IconButton(
          icon: Icon(Icons.close, size: 18,
              color: Theme.of(context).textTheme.bodyMedium?.color),
          onPressed: () => windowManager.close(),
          highlightColor: const Color(0xFFC42B1C),
        ),
      ],
    );
  }
}
