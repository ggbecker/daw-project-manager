import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';

class ThemeSwitcher extends ConsumerWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeType = ref.watch(themeTypeProvider);

    final themeName = switch (themeType) {
      AppThemeType.neonDark    => l10n.neonDarkThemeName,
      AppThemeType.classicDark => l10n.classicDarkThemeName,
      // studioLight hidden from UI
      AppThemeType.studioLight => l10n.classicDarkThemeName,
    };
    final tooltip = switch (themeType) {
      AppThemeType.neonDark    => l10n.switchToClassicTheme,
      // studioLight hidden — cycle goes neonDark ↔ classicDark only
      AppThemeType.classicDark => l10n.switchToNeonTheme,
      AppThemeType.studioLight => l10n.switchToNeonTheme,
    };
    final icon = switch (themeType) {
      AppThemeType.neonDark    => Icons.palette,
      AppThemeType.classicDark => Icons.palette_outlined,
      // studioLight hidden from UI
      AppThemeType.studioLight => Icons.palette_outlined,
    };

    // Cycles between dark themes only while studioLight is hidden.
    void cycleVisible() {
      final next = themeType == AppThemeType.neonDark
          ? AppThemeType.classicDark
          : AppThemeType.neonDark;
      ref.read(themeTypeProvider.notifier).setThemeType(next);
    }

    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                icon,
                key: ValueKey(themeType),
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            onPressed: () => cycleVisible(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: tooltip,
          ),
          TextButton(
            onPressed: () => cycleVisible(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              themeName,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
