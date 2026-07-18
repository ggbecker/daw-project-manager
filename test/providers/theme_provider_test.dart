import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/theme_provider.dart';

/// Regression coverage for ThemeTypeNotifier.cycle(): it used to rotate
/// through every AppThemeType.values entry, which included the hidden
/// studioLight theme. CLAUDE.md requires studioLight to stay out of the
/// theme switcher cycle until it ships — cycle() must only ever land on
/// the two visible dark themes, even if state somehow starts on studioLight
/// (e.g. a value persisted by a future build that re-enables it).
///
/// This tests ThemeTypeNotifier.nextVisibleTheme() directly rather than
/// going through cycle()/setThemeType(), because those call
/// ensureHiveInitialized() (see lib/utils/app_paths.dart), which ignores
/// any Hive.init() a test has already done and falls back to the real
/// on-disk app-data directory the first time it runs in a process — a
/// widget/provider test must never risk writing to the developer's actual
/// settings.hive.
void main() {
  group('ThemeTypeNotifier.nextVisibleTheme', () {
    test('rotates neonDark -> classicDark', () {
      expect(
        ThemeTypeNotifier.nextVisibleTheme(AppThemeType.neonDark),
        AppThemeType.classicDark,
      );
    });

    test('rotates classicDark -> neonDark', () {
      expect(
        ThemeTypeNotifier.nextVisibleTheme(AppThemeType.classicDark),
        AppThemeType.neonDark,
      );
    });

    test('never returns the hidden studioLight theme, even starting from it', () {
      expect(
        ThemeTypeNotifier.nextVisibleTheme(AppThemeType.studioLight),
        isNot(AppThemeType.studioLight),
      );
    });
  });
}
