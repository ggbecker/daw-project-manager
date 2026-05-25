import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../providers/providers.dart';
import 'google_drive_sync_page.dart';
import 'widgets/language_switcher.dart';
import 'widgets/theme_switcher.dart';

class OnboardingWizardPage extends ConsumerStatefulWidget {
  const OnboardingWizardPage({super.key});

  @override
  ConsumerState<OnboardingWizardPage> createState() => _OnboardingWizardPageState();
}

class _OnboardingWizardPageState extends ConsumerState<OnboardingWizardPage> {
  final _controller = PageController();
  int _page = 0;
  static const _totalPages = 7;

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
    await ref.read(onboardingCompleteProvider.notifier).complete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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
              children: [
                _WelcomePage(l10n: l10n),
                _LanguagePage(l10n: l10n),
                _ThemePage(l10n: l10n),
                _FoldersPage(l10n: l10n),
                _DrivePage(l10n: l10n, onNext: _next),
                _UpdatesPage(l10n: l10n),
                _DonePage(l10n: l10n),
              ],
            ),
          ),
          _WizardNav(
            page: _page,
            isLast: isLast,
            onBack: _back,
            onNext: _next,
            onFinish: _finish,
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
  final AppLocalizations l10n;
  final ThemeData theme;

  const _WizardNav({
    required this.page,
    required this.isLast,
    required this.onBack,
    required this.onNext,
    required this.onFinish,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (page > 0)
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(l10n.onboardingBack),
            )
          else
            const SizedBox.shrink(),
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

class _ThemePage extends StatelessWidget {
  final AppLocalizations l10n;
  const _ThemePage({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return _WizardStep(
      icon: Icons.palette_outlined,
      title: l10n.onboardingThemeTitle,
      child: Center(child: const ThemeSwitcher()),
    );
  }
}

// ── Page 3: Scan Root folders ─────────────────────────────────────────────────

class _FoldersPage extends ConsumerStatefulWidget {
  final AppLocalizations l10n;
  const _FoldersPage({required this.l10n});

  @override
  ConsumerState<_FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends ConsumerState<_FoldersPage> {
  bool _busy = false;

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  Future<void> _addFolder() async {
    if (_busy || !_isDesktop) return;
    final picked = await FilePicker.platform.getDirectoryPath(
      dialogTitle: widget.l10n.selectProjectsFolder,
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(repositoryProvider.future);
      await repo.addRoot(picked);
      ref.invalidate(rootsWatchProvider);
      ref.invalidate(scanRootsProvider);
      ref.invalidate(allProjectsStreamProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeFolder(String rootId) async {
    final repo = await ref.read(repositoryProvider.future);
    await repo.removeRoot(rootId);
    ref.invalidate(rootsWatchProvider);
    ref.invalidate(scanRootsProvider);
    ref.invalidate(allProjectsStreamProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final roots = ref.watch(scanRootsProvider);
    final theme = Theme.of(context);

    return _WizardStep(
      icon: Icons.folder_open,
      title: l10n.onboardingFoldersTitle,
      subtitle: l10n.onboardingFoldersBody,
      child: Column(
        children: [
          if (roots.isNotEmpty)
            Column(
              children: roots
                  .map((r) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.folder, size: 20),
                        title: Text(r.path, style: theme.textTheme.bodySmall),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => _removeFolder(r.id),
                        ),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 12),
          if (_isDesktop)
            OutlinedButton.icon(
              onPressed: _busy ? null : _addFolder,
              icon: _busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add, size: 18),
              label: Text(l10n.addFolder),
            ),
        ],
      ),
    );
  }
}

// ── Page 4: Google Drive ──────────────────────────────────────────────────────

class _DrivePage extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onNext;
  const _DrivePage({required this.l10n, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _WizardStep(
      icon: Icons.cloud_outlined,
      title: l10n.onboardingDriveTitle,
      subtitle: l10n.onboardingDriveBody,
      child: Column(
        children: [
          _ActionCard(
            icon: Icons.cloud_upload_outlined,
            title: l10n.startupGoogleDriveTitle,
            subtitle: l10n.startupGoogleDriveSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoogleDriveSyncPage()),
              ).then((_) => onNext());
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onNext,
            child: Text(
              l10n.onboardingNext,
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 5: Update checks ─────────────────────────────────────────────────────

class _UpdatesPage extends ConsumerWidget {
  final AppLocalizations l10n;
  const _UpdatesPage({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(checkForUpdatesProvider);
    return _WizardStep(
      icon: Icons.system_update_alt,
      title: l10n.onboardingUpdatesTitle,
      subtitle: l10n.onboardingUpdatesBody,
      child: Center(
        child: SwitchListTile(
          value: enabled,
          onChanged: (_) => ref.read(checkForUpdatesProvider.notifier).toggle(),
          title: Text(l10n.checkForUpdates),
          subtitle: Text(l10n.checkForUpdatesDescription,
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ),
    );
  }
}

// ── Page 6: Done ──────────────────────────────────────────────────────────────

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

// ── Reusable action card ──────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
