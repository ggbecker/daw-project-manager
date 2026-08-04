import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:daw_project_manager/ui/widgets/desktop_title_bar.dart';

void main() {
  group('windowMaximizeToggleIcon', () {
    // The rest of the maximize/restore wiring (WindowListener, real
    // onWindowMaximize/onWindowUnmaximize events from the OS) goes through
    // window_manager's platform channel and isn't practically testable
    // without a real window manager — this covers the deterministic part:
    // picking the right icon for each state.

    test('shows a single square when not maximized (can still maximize)', () {
      expect(windowMaximizeToggleIcon(false), Icons.crop_square_sharp);
    });

    test('shows two overlapping squares once maximized (can restore)', () {
      expect(windowMaximizeToggleIcon(true), Icons.filter_none);
    });
  });
}
