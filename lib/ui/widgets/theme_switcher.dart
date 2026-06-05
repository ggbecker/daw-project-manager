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
      AppThemeType.studioLight => l10n.studioLightThemeName,
    };
    final tooltip = switch (themeType) {
      AppThemeType.neonDark    => l10n.switchToClassicTheme,
      AppThemeType.classicDark => l10n.switchToStudioLight,
      AppThemeType.studioLight => l10n.switchToNeonTheme,
    };
    final icon = switch (themeType) {
      AppThemeType.neonDark    => Icons.palette,
      AppThemeType.classicDark => Icons.palette_outlined,
      AppThemeType.studioLight => Icons.wb_sunny_outlined,
    };

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
            onPressed: () => ref.read(themeTypeProvider.notifier).cycle(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: tooltip,
          ),
          TextButton(
            onPressed: () => ref.read(themeTypeProvider.notifier).cycle(),
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
