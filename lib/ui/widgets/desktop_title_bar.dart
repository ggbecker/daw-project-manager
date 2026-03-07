import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart'
    if (dart.library.html) 'package:window_manager/window_manager_stub.dart';

/// A cross-platform desktop title bar widget.
///
/// **Windows / Linux (release mode):** Renders a full custom title bar with a
/// draggable area, title, optional back button, optional extra [actions], and
/// native-style window control buttons (minimize / maximize / close).
///
/// **macOS:** The native macOS title bar (traffic-light buttons + window title)
/// is shown automatically when [TitleBarStyle.normal] is used in window setup.
/// This widget renders only a slim in-content navigation bar when [showBack]
/// is true so the user can navigate back. No drag handle and no window buttons
/// are included – the native chrome handles those.
///
/// **Mobile / web / debug mode:** Returns an empty widget.
class DesktopTitleBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      return const SizedBox.shrink();
    }

    // macOS: native title bar handles window chrome; only show slim nav bar
    // for pages that need a back button.
    if (Platform.isMacOS) {
      if (!showBack) return const SizedBox.shrink();
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
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.titleMedium?.color,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    // Windows / Linux: full custom title bar (release mode only).
    if (kDebugMode) return const SizedBox.shrink();

    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () async {
        if (await windowManager.isMaximized()) {
          windowManager.restore();
        } else {
          windowManager.maximize();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        height: 40,
        child: Row(
          children: [
            if (showBack)
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            Padding(
              padding: EdgeInsets.only(left: showBack ? 4 : 12),
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleMedium?.color,
                  fontSize: 16,
                  fontWeight:
                      showBack ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            ...actions,
            _WindowControlButtons(),
          ],
        ),
      ),
    );
  }
}

/// Minimize / Maximize / Close buttons for Windows and Linux only.
class _WindowControlButtons extends StatelessWidget {
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
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              windowManager.restore();
            } else {
              windowManager.maximize();
            }
          },
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
