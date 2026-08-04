import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../main.dart' show navigatorKey;

/// Column menu delegate that extends the default TrinaGrid header context
/// menu with an "Auto-resize columns" option that calls autoFitColumn on
/// every column at once. Shared by every TrinaGrid in the app so the entry
/// (and its wording) stays identical everywhere.
class FitAllColumnsMenuDelegate implements TrinaColumnMenuDelegate<dynamic> {
  const FitAllColumnsMenuDelegate();

  static const String _menuFitAll = 'fitAll';

  @override
  List<PopupMenuEntry<dynamic>> buildMenuItems({
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
  }) {
    final defaults = const TrinaColumnMenuDelegateDefault().buildMenuItems(
      stateManager: stateManager,
      column: column,
    );
    final context = navigatorKey.currentContext;
    final label = context != null
        ? AppLocalizations.of(context)!.autoFitAllColumns
        : 'Auto-resize columns';
    return [
      ...defaults,
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: _menuFitAll,
        child: Row(
          children: [
            const Icon(Icons.fit_screen, size: 16),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    ];
  }

  @override
  void onSelected({
    required BuildContext context,
    required TrinaGridStateManager stateManager,
    required TrinaColumn column,
    required bool mounted,
    required dynamic selected,
  }) {
    if (selected == _menuFitAll) {
      if (!mounted) return;
      for (final col in stateManager.columns) {
        stateManager.autoFitColumn(context, col);
      }
      stateManager.notifyResizingListeners();
      return;
    }
    const TrinaColumnMenuDelegateDefault().onSelected(
      context: context,
      stateManager: stateManager,
      column: column,
      mounted: mounted,
      selected: selected,
    );
  }
}
