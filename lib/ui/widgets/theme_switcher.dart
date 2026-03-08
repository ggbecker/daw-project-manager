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
    final isNeon = themeType == AppThemeType.neonDark;
    final themeName = isNeon ? l10n.neonDarkThemeName : l10n.classicDarkThemeName;
    final tooltip = isNeon ? l10n.switchToClassicTheme : l10n.switchToNeonTheme;

    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isNeon ? Icons.palette : Icons.palette_outlined,
                key: ValueKey(isNeon),
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            onPressed: () {
              ref.read(themeTypeProvider.notifier).cycle();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: tooltip,
          ),
          TextButton(
            onPressed: () {
              ref.read(themeTypeProvider.notifier).cycle();
            },
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
