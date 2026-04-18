import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import '../../providers/providers.dart';
import '../../providers/theme_provider.dart';
import '../../main.dart' show navigatorKey;
import '../dashboard_page.dart' show appVersion;
import 'language_switcher.dart';

/// Wraps the app with a native macOS menu bar (PlatformMenuBar).
/// On non-macOS platforms it is a transparent pass-through.
class MacOSMenuBar extends ConsumerWidget {
  final Widget child;
  const MacOSMenuBar({super.key, required this.child});

  void _showAboutDialog() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    showDialog(
      context: context,
      builder: (ctx) => const _AboutDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb || !Platform.isMacOS) return child;

    final themeType = ref.watch(themeTypeProvider);
    final currentLocale = ref.watch(localeProvider);
    final warnBeforeQuit = ref.watch(warnBeforeQuitProvider);

    final l10n = AppLocalizations.of(context)!;
    final themeLabel = themeType == AppThemeType.neonDark
        ? l10n.switchToClassicDark
        : l10n.switchToNeonDark;

    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: l10n.menuView,
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: l10n.menuAbout,
                  onSelected: _showAboutDialog,
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: themeLabel,
                  onSelected: () => ref.read(themeTypeProvider.notifier).cycle(),
                ),
                PlatformMenu(
                  label: l10n.menuLanguage,
                  menus: [
                    for (final entry in LanguageSwitcher.languageNames.entries)
                      PlatformMenuItem(
                        label: '${entry.value}${currentLocale.languageCode == entry.key ? ' ✓' : ''}',
                        onSelected: () =>
                            ref.read(localeProvider.notifier).setLocale(Locale(entry.key)),
                      ),
                  ],
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: '${warnBeforeQuit ? '✓ ' : ''}${l10n.menuWarnBeforeQuit}',
                  onSelected: () => ref.read(warnBeforeQuitProvider.notifier).toggle(),
                ),
                PlatformMenuItem(
                  label: l10n.menuQuit,
                  onSelected: () => windowManager.close(),
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: l10n.menuWindow,
          menus: [
            const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.toggleFullScreen,
            ),
          ],
        ),
      ],
      child: child,
    );
  }
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('app_icon.png', width: 80, height: 80),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.appTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (appVersion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.versionLabel(appVersion),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.appDescription,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '© ${DateTime.now().year} Bandpass Records',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
        ],
      ),
      actions: [
        FilledButton.icon(
          onPressed: () {
            launchUrl(
              Uri.parse('https://www.paypal.com/donate/?hosted_button_id=QHVVZ3LAF39BL'),
              mode: LaunchMode.externalApplication,
            );
          },
          icon: const Icon(Icons.favorite, size: 16),
          label: Text(AppLocalizations.of(context)!.donate),
        ),
        FilledButton.icon(
          onPressed: () {
            launchUrl(
              Uri.parse('https://dpm.bandpassrecords.com'),
              mode: LaunchMode.externalApplication,
            );
          },
          icon: const Icon(Icons.web, size: 16),
          label: Text(AppLocalizations.of(context)!.website),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }
}
