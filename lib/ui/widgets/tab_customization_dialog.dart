import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../utils/mobile_utils.dart';

void showTabCustomizationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const TabCustomizationDialog(),
  );
}

class TabCustomizationDialog extends ConsumerWidget {
  const TabCustomizationDialog({super.key});

  static const _icons = {
    AppTab.projects:   Icons.library_music,
    AppTab.releases:   Icons.album,
    AppTab.playlists:  Icons.playlist_play,
    AppTab.queue:      Icons.checklist,
    AppTab.statistics: Icons.bar_chart_rounded,
  };

  String _label(AppTab tab, AppLocalizations l10n) => switch (tab) {
    AppTab.projects   => l10n.projectsTab,
    AppTab.releases   => l10n.releasesTab,
    AppTab.playlists  => l10n.playlists,
    AppTab.queue      => l10n.queueTab,
    AppTab.statistics => l10n.statisticsTab,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final visibleSet = ref.watch(visibleTabsProvider);
    final isMobile = MobileUtils.isMobile();

    final allTabs = VisibleTabsNotifier.canonicalOrder
        .where((t) => isMobile || t != AppTab.playlists)
        .toList();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.tab_outlined, size: 20),
          const SizedBox(width: 8),
          Text(l10n.customizeTabs),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.customizeTabsDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final tab in allTabs)
              CheckboxListTile(
                value: visibleSet.contains(tab),
                onChanged: tab == AppTab.projects
                    ? null
                    : (v) => ref
                        .read(visibleTabsProvider.notifier)
                        .setTabVisible(tab, v ?? false),
                secondary: Icon(_icons[tab]),
                title: Text(_label(tab, l10n)),
                subtitle: tab == AppTab.projects
                    ? Text(
                        '(always visible)',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : null,
                controlAffinity: ListTileControlAffinity.trailing,
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
