import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../providers/theme_provider.dart';
import '../services/auto_start_service.dart';
import '../utils/mobile_utils.dart';
import 'dashboard_page.dart' show DashboardPage;
import 'widgets/language_switcher.dart';

class OnboardingWizardPage extends ConsumerStatefulWidget {
  const OnboardingWizardPage({super.key});

  @override
  ConsumerState<OnboardingWizardPage> createState() => _OnboardingWizardPageState();
}

class _OnboardingWizardPageState extends ConsumerState<OnboardingWizardPage> {
  final _controller = PageController();
  int _page = 0;

  /// The startup step is skipped entirely on platforms that have no
  /// launch-at-login concept (mobile), so the page count is derived from the
  /// built list rather than hardcoded.
  List<Widget> _pages(AppLocalizations l10n) => [
        _WelcomePage(l10n: l10n),
        _LanguagePage(l10n: l10n),
        _ThemePage(l10n: l10n),
        _TabsPage(l10n: l10n),
        _PhasesPage(l10n: l10n),
        if (AutoStartService.isSupported) _StartupPage(l10n: l10n),
        _DonePage(l10n: l10n),
      ];

  // Welcome, Language, Theme, Tabs, Phases, [Startup], Done.
  int get _totalPages => AutoStartService.isSupported ? 7 : 6;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _back() {
    if (_page > 0) {
      _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _finish() async {
    // Captura notifiers antes do await — ref não pode ser usado após unmount.
    final completeNotifier = ref.read(onboardingCompleteProvider.notifier);
    final playerNotifier = ref.read(desktopPlayerProvider.notifier);
    await completeNotifier.complete();
    if (!mounted) return;
    playerNotifier.close();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pages = _pages(l10n);
    assert(pages.length == _totalPages);
    final isLast = _page == _totalPages - 1;

    return Scaffold(
      body: Column(
        children: [
          _WizardProgress(current: _page, total: _totalPages),
          Expanded(
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              children: pages,
            ),
          ),
          _WizardNav(
            page: _page,
            isLast: isLast,
            onBack: _back,
            onNext: _next,
            onFinish: _finish,
            onSkip: _finish,
            l10n: l10n,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

// ── Progress indicator ────────────────────────────────────────────────────────

class _WizardProgress extends StatelessWidget {
  final int current;
  final int total;
  const _WizardProgress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return LinearProgressIndicator(
      value: (current + 1) / total,
      color: color,
      backgroundColor: color.withValues(alpha: 0.15),
      minHeight: 3,
    );
  }
}

// ── Navigation row ────────────────────────────────────────────────────────────

class _WizardNav extends StatelessWidget {
  final int page;
  final bool isLast;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final VoidCallback onSkip;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _WizardNav({
    required this.page,
    required this.isLast,
    required this.onBack,
    required this.onNext,
    required this.onFinish,
    required this.onSkip,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Row(
        children: [
          // Back button
          if (page > 0)
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(l10n.onboardingBack),
            )
          else
            const SizedBox.shrink(),

          const Spacer(),

          // Skip link (hidden on last page)
          if (!isLast)
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              child: Text(l10n.skip),
            ),

          if (!isLast) const SizedBox(width: 8),

          // Next / Finish button
          if (isLast)
            FilledButton.icon(
              onPressed: onFinish,
              icon: const Icon(Icons.check, size: 18),
              label: Text(l10n.onboardingGetStarted),
            )
          else
            FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(l10n.onboardingNext),
            ),
        ],
      ),
    );
  }
}

// ── Shared page scaffold ──────────────────────────────────────────────────────

class _WizardStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final double iconSize;

  const _WizardStep({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(icon, size: iconSize, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page 0: Welcome ───────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final AppLocalizations l10n;
  const _WelcomePage({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _WizardStep(
      icon: Icons.music_note,
      iconSize: 80,
      title: l10n.onboardingWelcomeTitle,
      subtitle: l10n.onboardingWelcomeBody,
      child: _FeatureList(theme: theme),
    );
  }
}

class _FeatureList extends StatelessWidget {
  final ThemeData theme;
  const _FeatureList({required this.theme});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.folder_open, 'Scan DAW project folders automatically'),
      (Icons.bar_chart, 'Track BPM, key, status and deadlines'),
      (Icons.cloud_upload_outlined, 'Sync metadata to Google Drive'),
      (Icons.timer_outlined, 'Track time spent on each project'),
    ];
    return Column(
      children: items
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(e.$1, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(e.$2, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ── Page 1: Language ──────────────────────────────────────────────────────────

class _LanguagePage extends StatelessWidget {
  final AppLocalizations l10n;
  const _LanguagePage({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return _WizardStep(
      icon: Icons.language,
      title: l10n.onboardingLanguageTitle,
      child: Center(child: _LanguageGrid()),
    );
  }
}

class _LanguageGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final languages = LanguageSwitcher.languageNames;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: languages.entries.map((e) {
        final selected = current.languageCode == e.key;
        return ChoiceChip(
          label: Text(e.value),
          selected: selected,
          selectedColor: theme.colorScheme.primaryContainer,
          onSelected: (_) => ref.read(localeProvider.notifier).setLocale(Locale(e.key)),
        );
      }).toList(),
    );
  }
}

// ── Page 2: Theme ─────────────────────────────────────────────────────────────

class _ThemePage extends ConsumerWidget {
  final AppLocalizations l10n;
  const _ThemePage({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeTypeProvider);
    return _WizardStep(
      icon: Icons.palette_outlined,
      title: l10n.onboardingThemeTitle,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _ThemeCard(
            themeType: AppThemeType.classicDark,
            label: l10n.classicDarkThemeName,
            bg: const Color(0xFF1E1F22),
            card: const Color(0xFF2B2D31),
            primary: const Color(0xFF5A6B7A),
            accent: const Color(0xFF7E8C99),
            selected: current == AppThemeType.classicDark,
            onTap: () => ref.read(themeTypeProvider.notifier).setThemeType(AppThemeType.classicDark),
          ),
          _ThemeCard(
            themeType: AppThemeType.neonDark,
            label: l10n.neonDarkThemeName,
            bg: const Color(0xFF0A0A14),
            card: const Color(0xFF1A1A2E),
            primary: const Color(0xFF00D4FF),
            accent: const Color(0xFF7B2CBF),
            selected: current == AppThemeType.neonDark,
            onTap: () => ref.read(themeTypeProvider.notifier).setThemeType(AppThemeType.neonDark),
          ),
          // studioLight hidden from UI — see theme_switcher.dart.
        ],
      ),
    );
  }
}

// ── Page 5: Phases ────────────────────────────────────────────────────────────

class _PhasesPage extends ConsumerStatefulWidget {
  final AppLocalizations l10n;
  const _PhasesPage({required this.l10n});

  @override
  ConsumerState<_PhasesPage> createState() => _PhasesPageState();
}

class _PhasesPageState extends ConsumerState<_PhasesPage> {
  final _addCtrl = TextEditingController();
  String? _addError;

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleFinished(String phase, Set<String> current) async {
    final repo = ref.read(repositoryProvider).asData?.value;
    if (repo == null) return;
    final updated = Set<String>.from(current);
    if (updated.contains(phase)) {
      if (updated.length > 1) updated.remove(phase);
    } else {
      updated.add(phase);
    }
    await repo.setFinishedPhases(updated);
    ref.invalidate(finishedPhaseProvider);
  }

  Future<void> _addPhase(List<String> current) async {
    final name = _addCtrl.text.trim();
    if (name.isEmpty) return;
    if (current.any((p) => p.toLowerCase() == name.toLowerCase())) {
      setState(() => _addError = widget.l10n.phaseDuplicateError);
      return;
    }
    setState(() => _addError = null);
    _addCtrl.clear();
    final repo = ref.read(repositoryProvider).asData?.value;
    if (repo == null) return;
    await repo.setCustomPhases([...current, name]);
    ref.invalidate(customPhasesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final phases = ref.watch(customPhasesProvider);
    final finishedPhases = ref.watch(finishedPhaseProvider);
    final theme = Theme.of(context);

    return _WizardStep(
      icon: Icons.tune,
      title: l10n.phases,
      subtitle: l10n.phasesSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.markAsFinished,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < phases.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      finishedPhases.contains(phases[i])
                          ? Icons.flag
                          : Icons.flag_outlined,
                      size: 20,
                      color: finishedPhases.contains(phases[i])
                          ? Colors.green
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    title: Text(phases[i]),
                    trailing: finishedPhases.contains(phases[i])
                        ? Chip(
                            label: Text(
                              'done',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade200,
                              ),
                            ),
                            backgroundColor:
                                Colors.green.withValues(alpha: 0.15),
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          )
                        : null,
                    onTap: () => _toggleFinished(phases[i], finishedPhases),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _addCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.phaseNameHint,
                    errorText: _addError,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addPhase(phases),
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => _addPhase(phases),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addPhase),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.canBeChangedInSettings,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 5: Launch at startup (desktop only) ─────────────────────────────────

class _StartupPage extends ConsumerStatefulWidget {
  final AppLocalizations l10n;
  const _StartupPage({required this.l10n});

  @override
  ConsumerState<_StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends ConsumerState<_StartupPage> {
  bool _busy = false;

  /// [apply] performs the toggle and reports whether the OS accepted it.
  Future<void> _run(Future<bool> Function() apply) async {
    setState(() => _busy = true);
    final ok = await apply();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.l10n.autoStartFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);
    final enabled = ref.watch(autoStartProvider);
    final minimized = ref.watch(startMinimizedProvider);

    return _WizardStep(
      icon: Icons.rocket_launch_outlined,
      title: l10n.onboardingStartupTitle,
      subtitle: l10n.onboardingStartupBody,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  value: enabled,
                  onChanged: _busy
                      ? null
                      : (v) => _run(
                          () => ref.read(autoStartProvider.notifier).set(v)),
                  title: Text(l10n.autoStart),
                  subtitle: Text(
                    l10n.autoStartDescription,
                    style: theme.textTheme.bodySmall,
                  ),
                  secondary: const Icon(Icons.power_settings_new),
                ),
                const Divider(height: 1),
                // Only does anything alongside the switch above, so it stays
                // disabled until auto-start is on.
                SwitchListTile(
                  value: minimized,
                  onChanged: (_busy || !enabled)
                      ? null
                      : (v) => _run(() =>
                          ref.read(startMinimizedProvider.notifier).set(v)),
                  title: Text(l10n.onboardingStartMinimized),
                  subtitle: Text(
                    l10n.startMinimizedDescription,
                    style: theme.textTheme.bodySmall,
                  ),
                  secondary: const Icon(Icons.move_to_inbox_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.canBeChangedInSettings,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 8: Done ──────────────────────────────────────────────────────────────

class _DonePage extends StatelessWidget {
  final AppLocalizations l10n;
  const _DonePage({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return _WizardStep(
      icon: Icons.check_circle_outline,
      iconSize: 80,
      title: l10n.onboardingDoneTitle,
      subtitle: l10n.onboardingDoneBody,
      child: const SizedBox.shrink(),
    );
  }
}

// ── Theme card ────────────────────────────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  final AppThemeType themeType;
  final String label;
  final Color bg;
  final Color card;
  final Color primary;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.themeType,
    required this.label,
    required this.bg,
    required this.card,
    required this.primary,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mini app preview
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: _ThemePreviewMockup(bg: bg, card: card, primary: primary, accent: accent),
            ),
            // Label + selection indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  if (selected)
                    Icon(Icons.radio_button_checked, size: 14, color: cs.primary)
                  else
                    Icon(Icons.radio_button_unchecked, size: 14, color: cs.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                        color: selected ? cs.primary : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePreviewMockup extends StatelessWidget {
  final Color bg;
  final Color card;
  final Color primary;
  final Color accent;

  const _ThemePreviewMockup({
    required this.bg,
    required this.card,
    required this.primary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const textColor = Colors.white;
    const dimText = Color(0xFFAAAAAA);

    final rows = [
      ('Song Alpha',    'In Progress', '120'),
      ('Dark Ambient',  'Done',        '90'),
      ('Remix Final',   'In Progress', '128'),
    ];

    return Container(
      color: bg,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fake sidebar + header bar
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: primary, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Container(width: 40, height: 5, color: textColor.withValues(alpha: 0.3)),
                const Spacer(),
                Container(width: 24, height: 5, decoration: BoxDecoration(color: accent.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(3))),
              ],
            ),
          ),
          const SizedBox(height: 5),
          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                _previewText(l10n.name, dimText, flex: 3),
                _previewText(l10n.status, dimText, flex: 2),
                _previewText(l10n.bpm, dimText, flex: 1),
              ],
            ),
          ),
          const SizedBox(height: 3),
          // Fake project rows
          ...rows.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: r.$2 == 'Done' ? Colors.greenAccent.shade400 : primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                _previewText(r.$1, textColor, flex: 3),
                _previewText(r.$2, dimText, flex: 2),
                _previewText(r.$3, dimText, flex: 1),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _previewText(String text, Color color, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Page 3: Tab layout ────────────────────────────────────────────────────────

class _TabsPage extends ConsumerWidget {
  final AppLocalizations l10n;
  const _TabsPage({required this.l10n});

  static const _icons = {
    AppTab.projects:   Icons.library_music,
    AppTab.releases:   Icons.album,
    AppTab.playlists:  Icons.playlist_play,
    AppTab.queue:      Icons.checklist,
    AppTab.statistics: Icons.bar_chart_rounded,
    AppTab.player:     Icons.headphones,
  };

  String _label(AppTab tab, AppLocalizations l10n) => switch (tab) {
    AppTab.projects   => l10n.projectsTab,
    AppTab.releases   => l10n.releasesTab,
    AppTab.playlists  => l10n.playlists,
    AppTab.queue      => l10n.queueTab,
    AppTab.statistics => l10n.statisticsTab,
    AppTab.player     => 'Music Player',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabPos = ref.watch(tabPositionProvider);
    final visibleSet = ref.watch(visibleTabsProvider);
    final isMobile = MobileUtils.isMobile();

    final allTabs = VisibleTabsNotifier.canonicalOrder
        .where((t) => isMobile || t != AppTab.playlists)  // playlists is mobile-only
        .where((t) => !isMobile || t != AppTab.player)    // player is desktop-only
        .toList();

    return _WizardStep(
      icon: Icons.tab_outlined,
      title: l10n.customizeTabs,
      subtitle: l10n.customizeTabsDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab position cards (desktop only)
          if (!isMobile) ...[
            Text(l10n.tabPosition, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TabPositionCard(
                    position: TabPosition.left,
                    label: l10n.tabPositionLeft,
                    selected: tabPos == TabPosition.left,
                    onTap: () => ref.read(tabPositionProvider.notifier).set(TabPosition.left),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TabPositionCard(
                    position: TabPosition.top,
                    label: l10n.tabPositionTop,
                    selected: tabPos == TabPosition.top,
                    onTap: () => ref.read(tabPositionProvider.notifier).set(TabPosition.top),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Tab visibility toggles
          Text(l10n.customizeTabs, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allTabs.map((tab) {
              final isProjects = tab == AppTab.projects;
              final visible = visibleSet.contains(tab);
              return FilterChip(
                avatar: Icon(_icons[tab], size: 16),
                label: Text(_label(tab, l10n)),
                selected: visible,
                onSelected: isProjects ? null : (v) =>
                    ref.read(visibleTabsProvider.notifier).setTabVisible(tab, v),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TabPositionCard extends StatelessWidget {
  final TabPosition position;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabPositionCard({
    required this.position,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer.withValues(alpha: 0.25) : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? cs.primary : cs.outlineVariant, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            _TabLayoutDiagram(position: position, primary: cs.primary),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected)
                  Icon(Icons.radio_button_checked, size: 13, color: cs.primary)
                else
                  Icon(Icons.radio_button_unchecked, size: 13, color: cs.outline),
                const SizedBox(width: 4),
                Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                  color: selected ? cs.primary : null,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabLayoutDiagram extends StatelessWidget {
  final TabPosition position;
  final Color primary;

  const _TabLayoutDiagram({required this.position, required this.primary});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final tabColor = primary.withValues(alpha: 0.8);
    final contentColor = Colors.white.withValues(alpha: 0.12);

    if (position == TabPosition.top) {
      return Container(
        height: 84,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Column(
          children: [
            // Tab bar at top
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  _tabChip(tabColor, active: true),
                  const SizedBox(width: 4),
                  _tabChip(tabColor.withValues(alpha: 0.35)),
                  const SizedBox(width: 4),
                  _tabChip(tabColor.withValues(alpha: 0.35)),
                ],
              ),
            ),
            // Content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 5, width: double.infinity, color: contentColor),
                    Container(height: 5, width: 120, color: contentColor),
                    Container(height: 5, width: double.infinity, color: contentColor),
                    Container(height: 5, width: 80, color: contentColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Left rail layout
      return Container(
        height: 84,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Row(
          children: [
            // Left rail
            Container(
              width: 26,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _tabDot(tabColor, active: true),
                  const SizedBox(height: 5),
                  _tabDot(tabColor.withValues(alpha: 0.35)),
                  const SizedBox(height: 5),
                  _tabDot(tabColor.withValues(alpha: 0.35)),
                ],
              ),
            ),
            // Content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 5, width: double.infinity, color: contentColor),
                    Container(height: 5, width: 60, color: contentColor),
                    Container(height: 5, width: double.infinity, color: contentColor),
                    Container(height: 5, width: 40, color: contentColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _tabChip(Color color, {bool active = false}) {
    return Container(
      width: active ? 30 : 20,
      height: 12,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    );
  }

  Widget _tabDot(Color color, {bool active = false}) {
    return Container(
      width: 14,
      height: active ? 14 : 12,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    );
  }
}
