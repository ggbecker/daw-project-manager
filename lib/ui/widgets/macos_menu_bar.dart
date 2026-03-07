import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

    final themeLabel = themeType == AppThemeType.neonDark
        ? 'Switch to Classic Dark'
        : 'Switch to Neon Dark';

    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'View',
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'About DAW Project Manager',
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
                  label: 'Language',
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
                  label: '${warnBeforeQuit ? '✓ ' : ''}Warn Before Quitting (Cmd+Q)',
                  onSelected: () => ref.read(warnBeforeQuitProvider.notifier).toggle(),
                ),
                PlatformMenuItem(
                  label: 'Quit DAW Project Manager',
                  onSelected: () => windowManager.close(),
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: 'Window',
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
            'DAW Project Manager',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (appVersion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Version $appVersion',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'A project manager for music producers and sound designers.',
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
          label: const Text('Donate'),
        ),
        FilledButton.icon(
          onPressed: () {
            launchUrl(
              Uri.parse('https://dpm.bandpassrecords.com'),
              mode: LaunchMode.externalApplication,
            );
          },
          icon: const Icon(Icons.web, size: 16),
          label: const Text('Website'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
