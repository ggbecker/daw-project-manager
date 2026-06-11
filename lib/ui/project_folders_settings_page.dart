import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_settings_page.dart';
import 'phases_settings_page.dart';
import 'widgets/desktop_title_bar.dart';
import 'widgets/update_available_dialog.dart';
import 'dashboard_page.dart' show appVersion;

import '../generated/l10n/app_localizations.dart';
import '../models/scan_mode.dart';
import 'onboarding_wizard_page.dart';
import '../providers/providers.dart';
import '../repository/project_repository.dart';
import '../services/scanner_service.dart';
import '../services/update_check_service.dart';
import '../utils/file_launcher.dart';
import '../utils/mobile_utils.dart';

class ProjectFoldersSettingsPage extends ConsumerStatefulWidget {
  const ProjectFoldersSettingsPage({super.key});

  @override
  ConsumerState<ProjectFoldersSettingsPage> createState() => _ProjectFoldersSettingsPageState();
}


class _ProjectFoldersSettingsPageState extends ConsumerState<ProjectFoldersSettingsPage> {
  bool _busy = false;
  bool _checkingUpdate = false;
  late final TextEditingController _customMixdownCtrl;

  @override
  void initState() {
    super.initState();
    _customMixdownCtrl = TextEditingController();
    // Populate once the provider resolves
    ref.read(customMixdownFolderProvider.future).then((val) {
      if (mounted) _customMixdownCtrl.text = val ?? '';
    });
  }

  @override
  void dispose() {
    _customMixdownCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCustomMixdownFolder(String value) async {
    final repo = await ref.read(repositoryProvider.future);
    await repo.setCustomMixdownFolder(value.isEmpty ? null : value);
    ref.invalidate(customMixdownFolderProvider);
  }

  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  Future<void> _scanOnlyFolder(ProjectRepository repo, String folderId, String folderPath) async {
    final scanner = ScannerService();
    final excluded = repo.getIgnoredPaths().map((p) => p.path).toList(growable: false);
    final scanTime = DateTime.now();
    int found = 0;
    final foundPaths = <String>{};

    await for (final entity in scanner.scanDirectory(folderPath, ignoredPaths: excluded)) {
      await repo.upsertFromFileSystemEntity(entity, fullMetadata: false);
      foundPaths.add(entity.path);
      found++;
    }
    await repo.removeOrphanedProjectsFromRoot(folderPath, foundPaths);
    await repo.updateRootLastScanAt(folderId, scanTime);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final msg = found == 0
        ? l10n.noProjectsFoundInRoots
        : l10n.scanComplete(l10n.rescan, found, found == 1 ? '' : 's');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addProjectFolder() async {
    if (_busy || !_isDesktop) return;
    final l10n = AppLocalizations.of(context)!;

    final picked = await FilePicker.getDirectoryPath(dialogTitle: l10n.selectProjectsFolder);
    if (picked == null) return;

    // Reject if this exact folder is already a scan root.
    final existingRoots = ref.read(scanRootsProvider);
    final pickedNorm = p.normalize(picked);
    if (existingRoots.any((r) => p.normalize(r.path) == pickedNorm)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.folderAlreadyAdded)),
        );
      }
      return;
    }

    setState(() => _busy = true);
    try {
      final repo = await ref.read(repositoryProvider.future);
      await repo.addRoot(picked);

      ref.invalidate(rootsWatchProvider);
      ref.invalidate(scanRootsProvider);

      // Scan only the newly-added folder
      final added = repo.getRoots().where((r) => r.path == picked).toList();
      if (added.isNotEmpty) {
        await _scanOnlyFolder(repo, added.first.id, added.first.path);
      }

      ref.invalidate(allProjectsStreamProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorAddingFolder(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _relocateProjectFolder(String folderId, String oldPath) async {
    if (_busy || !_isDesktop) return;
    final l10n = AppLocalizations.of(context)!;

    final picked = await FilePicker.getDirectoryPath(
      dialogTitle: l10n.relocateFolderDialogTitle,
    );
    if (picked == null) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      final repo = await ref.read(repositoryProvider.future);
      final count = await repo.relocateRoot(folderId, picked);
      ref.invalidate(rootsWatchProvider);
      ref.invalidate(scanRootsProvider);
      ref.invalidate(allProjectsStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.relocateFolderSuccess(count))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorAddingFolder(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeProjectFolder(String folderId) async {
    if (_busy || !_isDesktop) return;

    final l10n = AppLocalizations.of(context)!;
    final folders = ref.read(scanRootsProvider);
    final folder = folders.where((r) => r.id == folderId).toList();
    final folderPath = folder.isNotEmpty ? folder.first.path : '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text(l10n.removeProjectFolderTitle),
        content: Text(l10n.removeProjectFolderMessage(folderPath)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      final repo = await ref.read(repositoryProvider.future);
      await repo.removeRoot(folderId);
      ref.invalidate(rootsWatchProvider);
      ref.invalidate(scanRootsProvider);
      ref.invalidate(allProjectsStreamProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addExcludedFolder() async {
    if (_busy || !_isDesktop) return;

    final l10n = AppLocalizations.of(context)!;
    final picked = await FilePicker.getDirectoryPath(dialogTitle: l10n.selectExcludedFolder);
    if (picked == null) return;

    setState(() => _busy = true);
    try {
      final repo = await ref.read(repositoryProvider.future);
      await repo.addIgnoredPath(picked);
      ref.invalidate(ignoredPathsWatchProvider);
      ref.invalidate(ignoredPathsProvider);
      ref.invalidate(allProjectsStreamProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeExcludedFolder(String excludedId) async {
    if (_busy || !_isDesktop) return;

    final l10n = AppLocalizations.of(context)!;
    final excludedFolders = ref.read(ignoredPathsProvider);
    final excluded = excludedFolders.where((p) => p.id == excludedId).toList();
    final excludedPath = excluded.isNotEmpty ? excluded.first.path : '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text(l10n.removeExcludedFolderTitle),
        content: Text(
          excludedPath.isEmpty ? l10n.removeExcludedFolderMessageNoPath : l10n.removeExcludedFolderMessage(excludedPath),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      final repo = await ref.read(repositoryProvider.future);
      await repo.removeIgnoredPath(excludedId);
      ref.invalidate(ignoredPathsWatchProvider);
      ref.invalidate(ignoredPathsProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_isDesktop) {
      return Scaffold(
        appBar: AppBar(title: Text('${l10n.settings} • ${l10n.roots}')),
        body: Padding(
          padding: MobileUtils.getResponsivePadding(context),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.desktop_windows_outlined, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.desktopOnlyPathsSettings,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final projectFolders = ref.watch(scanRootsProvider);
    final excludedFolders = ref.watch(ignoredPathsProvider);

    final sessionMode = ref.watch(sessionModeProvider);
    final suggestionsEnabled = ref.watch(suggestionsEnabledProvider);
    final checkUpdates = ref.watch(checkForUpdatesProvider);
    final lastModifiedColors = ref.watch(lastModifiedColorProvider);

    final listBody = ListView(
      padding: MobileUtils.getResponsivePadding(context),
      children: [
        // General settings
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_outlined),
                    const SizedBox(width: 10),
                    Text(l10n.general, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: sessionMode,
                  onChanged: (v) => ref.read(sessionModeProvider.notifier).set(v),
                  title: Text(l10n.sessionMode),
                  subtitle: Text(l10n.sessionModeDescription,
                      style: Theme.of(context).textTheme.bodySmall),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                SwitchListTile(
                  value: suggestionsEnabled,
                  onChanged: (v) =>
                      ref.read(suggestionsEnabledProvider.notifier).set(v),
                  title: Text(l10n.showSuggestions),
                  subtitle: Text(
                    l10n.showSuggestionsDescription,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                SwitchListTile(
                  value: checkUpdates,
                  onChanged: (v) => ref.read(checkForUpdatesProvider.notifier).toggle(),
                  title: Text(l10n.checkForUpdates),
                  subtitle: Text(l10n.checkForUpdatesDescription,
                      style: Theme.of(context).textTheme.bodySmall),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _checkingUpdate
                        ? null
                        : () async {
                            setState(() => _checkingUpdate = true);
                            final result = await UpdateCheckService.checkForUpdate(appVersion);
                            if (!mounted) return;
                            setState(() => _checkingUpdate = false);
                            if (result != null) {
                              ref.read(availableUpdateProvider.notifier).set(result);
                              UpdateAvailableDialog.show(context, result);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.upToDate)),
                              );
                            }
                          },
                    icon: _checkingUpdate
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 16),
                    label: Text(l10n.checkNow),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ),
                SwitchListTile(
                  value: lastModifiedColors,
                  onChanged: (_) => ref.read(lastModifiedColorProvider.notifier).toggle(),
                  title: Text(l10n.lastModifiedColors),
                  subtitle: Text(l10n.lastModifiedColorsDescription,
                      style: Theme.of(context).textTheme.bodySmall),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                const Divider(height: 20),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: Text(l10n.phases),
                  subtitle: Text(l10n.phasesSubtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                  trailing: const Icon(Icons.chevron_right),
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PhasesSettingsPage(),
                    ),
                  ),
                ),
                const Divider(height: 20),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(l10n.notificationSettings),
                  subtitle: Text(l10n.workTimerSection,
                      style: Theme.of(context).textTheme.bodySmall),
                  trailing: const Icon(Icons.chevron_right),
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsPage(),
                    ),
                  ),
                ),
                const Divider(height: 20),
                TextButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.resetOnboarding),
                        content: const Text('This will restart the setup wizard. Continue?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(l10n.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                            child: Text(l10n.resetOnboarding),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    ref.read(onboardingCompleteProvider.notifier).reset();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const OnboardingWizardPage()),
                      (route) => false,
                    );
                  },
                  icon: Icon(Icons.restart_alt, size: 16,
                      color: Theme.of(context).colorScheme.error),
                  label: Text(l10n.resetOnboarding,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Project folders section
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.projectFoldersSectionTitle, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            l10n.projectFoldersSectionSubtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : _addProjectFolder,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addFolder),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (projectFolders.isEmpty)
                  _EmptyState(
                    icon: Icons.folder_open,
                    title: l10n.projectFoldersEmptyTitle,
                    subtitle: l10n.projectFoldersEmptySubtitle,
                    actionLabel: l10n.addFolder,
                    onAction: _busy ? null : _addProjectFolder,
                  )
                else
                  ...projectFolders.map((f) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.folder),
                      title: Text(f.path),
                      subtitle: f.lastScanAt == null
                          ? Text(l10n.notScannedYet)
                          : Text(l10n.lastScan(f.lastScanAt.toString())),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: l10n.openFolder,
                            onPressed: () => FileLauncher.openFolder(f.path),
                            icon: const Icon(Icons.folder_open_outlined),
                          ),
                          IconButton(
                            tooltip: l10n.relocateFolderDialogTitle,
                            onPressed: _busy ? null : () => _relocateProjectFolder(f.id, f.path),
                            icon: const Icon(Icons.drive_file_move_outline),
                          ),
                          IconButton(
                            tooltip: l10n.remove,
                            onPressed: _busy ? null : () => _removeProjectFolder(f.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Scan Mode card — one selector per folder
        if (projectFolders.isNotEmpty)
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.view_agenda_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.scanModeSectionTitle,
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              l10n.scanModeSectionDescription,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final entry in projectFolders.asMap().entries) ...[
                    if (projectFolders.length > 1) ...[
                      if (entry.key > 0) const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.folder, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry.value.path,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.openFolder,
                            onPressed: () => FileLauncher.openFolder(entry.value.path),
                            icon: const Icon(Icons.folder_open_outlined),
                            iconSize: 16,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    _ScanModeSelector(
                      currentMode: entry.value.scanMode,
                      disabled: _busy,
                      onChanged: (newMode) async {
                        final newDepth = newMode == ScanMode.smartFolder ? 1 : 0;
                        if (newDepth == entry.value.scanDepth) return;
                        setState(() => _busy = true);
                        try {
                          final repo = await ref.read(repositoryProvider.future);
                          await repo.updateRootScanDepth(entry.value.id, newDepth);
                          ref.invalidate(scanRootsProvider);
                          ref.invalidate(allProjectsStreamProvider);
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Excluded folders section
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.block),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.excludedFoldersSectionTitle, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            l10n.excludedFoldersSectionSubtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : _addExcludedFolder,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addExcludedFolder),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (excludedFolders.isEmpty)
                  _EmptyState(
                    icon: Icons.block,
                    title: l10n.excludedFoldersEmptyTitle,
                    subtitle: l10n.excludedFoldersEmptySubtitle,
                  )
                else
                  ...excludedFolders.map((p) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.block),
                      title: Text(p.path),
                      trailing: IconButton(
                        tooltip: l10n.remove,
                        onPressed: _busy ? null : () => _removeExcludedFolder(p.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Custom mixdown folder
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.audio_file_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.previewMixdownFolderTitle, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            AppLocalizations.of(context)!.previewMixdownFolderSubtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customMixdownCtrl,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.previewMixdownFolderHint,
                          prefixIcon: Icon(Icons.folder_open),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: _saveCustomMixdownFolder,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () => _saveCustomMixdownFolder(_customMixdownCtrl.text),
                      child: Text(AppLocalizations.of(context)!.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Danger zone / Library management
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.pathsSettingsDangerZoneTitle, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            l10n.pathsSettingsDangerZoneSubtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Theme.of(context).cardColor,
                                  title: Text(l10n.clearLibrary),
                                  content: Text(l10n.clearLibraryMessage),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(l10n.cancel),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                                      child: Text(l10n.clear),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                              if (!mounted) return;

                              setState(() => _busy = true);
                              try {
                                final repo = await ref.read(repositoryProvider.future);
                                await repo.clearAllData();
                                ref.invalidate(repositoryProvider);
                                ref.invalidate(rootsWatchProvider);
                                ref.invalidate(scanRootsProvider);
                                ref.invalidate(ignoredPathsWatchProvider);
                                ref.invalidate(ignoredPathsProvider);
                                ref.invalidate(allProjectsStreamProvider);
                                await ref.read(repositoryProvider.future);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.libraryCleared)),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _busy = false);
                              }
                            },
                      icon: const Icon(Icons.delete_forever),
                      label: Text(l10n.clearLibrary),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.deleteAllData, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            l10n.deleteAllDataSubtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () async {
                              // First confirmation
                              final confirm1 = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Theme.of(context).cardColor,
                                  title: Text(l10n.deleteAllDataConfirm1Title),
                                  content: Text(l10n.deleteAllDataConfirm1Message),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(l10n.cancel),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                                      child: Text(l10n.deleteAllData),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm1 != true || !mounted) return;

                              // Second confirmation
                              final confirm2 = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Theme.of(context).cardColor,
                                  title: Text(l10n.deleteAllDataConfirm2Title),
                                  content: Text(l10n.deleteAllDataConfirm2Message),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(l10n.cancel),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                                      child: Text(l10n.deleteEverything),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm2 != true || !mounted) return;

                              setState(() => _busy = true);
                              try {
                                await ProjectRepository.deleteAllAppData();
                                // Invalidate root provider first so all dependents
                                // (currentProfileProvider, repositoryProvider, etc.)
                                // rebuild against fresh Hive boxes.
                                ref.invalidate(profileRepositoryProvider);
                                ref.invalidate(currentProfileProvider);
                                ref.invalidate(allProfilesProvider);
                                ref.invalidate(repositoryProvider);
                                ref.invalidate(rootsWatchProvider);
                                ref.invalidate(scanRootsProvider);
                                ref.invalidate(ignoredPathsWatchProvider);
                                ref.invalidate(ignoredPathsProvider);
                                ref.invalidate(allProjectsStreamProvider);
                                await ref.read(profileRepositoryProvider.future);
                                await ref.read(repositoryProvider.future);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.allDataDeleted)),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _busy = false);
                              }
                            },
                      icon: const Icon(Icons.delete_sweep_rounded),
                      label: Text(l10n.deleteAllData),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: !_isDesktop ? AppBar(
        title: Text('${l10n.settings} • ${l10n.roots}'),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ) : null,
      body: Column(
        children: [
          DesktopTitleBar(title: l10n.settings, showBack: true),
          Expanded(child: listBody),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                if (actionLabel != null) ...[
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: onAction,
                    icon: const Icon(Icons.add),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scan mode selector — two side-by-side cards with visual previews
// ---------------------------------------------------------------------------

class _ScanModeSelector extends StatelessWidget {
  final ScanMode currentMode;
  final bool disabled;
  final ValueChanged<ScanMode> onChanged;

  const _ScanModeSelector({
    required this.currentMode,
    required this.disabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.view_agenda_outlined, size: 14, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              l10n.scanModeLabel,
              style: tt.labelMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          currentMode == ScanMode.flat
              ? l10n.scanModeFlatDescription
              : l10n.scanModeSmartFolderDescription,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ScanModeCard(
                  mode: ScanMode.flat,
                  label: l10n.scanModeFlat,
                  description: l10n.scanModeFlatDescription,
                  preview: const _FlatModePreview(),
                  selected: currentMode == ScanMode.flat,
                  disabled: disabled,
                  onTap: () => onChanged(ScanMode.flat),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScanModeCard(
                  mode: ScanMode.smartFolder,
                  label: l10n.scanModeSmartFolder,
                  description: l10n.scanModeSmartFolderDescription,
                  preview: const _SmartFolderModePreview(),
                  selected: currentMode == ScanMode.smartFolder,
                  disabled: disabled,
                  onTap: () => onChanged(ScanMode.smartFolder),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanModeCard extends StatelessWidget {
  final ScanMode mode;
  final String label;
  final String description;
  final Widget preview;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _ScanModeCard({
    required this.mode,
    required this.label,
    required this.description,
    required this.preview,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = selected ? colorScheme.primary : colorScheme.outlineVariant;
    final bgColor = selected
        ? colorScheme.primaryContainer.withValues(alpha: 0.25)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: selected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (selected)
                  Icon(Icons.radio_button_checked, size: 14, color: colorScheme.primary)
                else
                  Icon(Icons.radio_button_unchecked, size: 14, color: colorScheme.outline),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? colorScheme.primary : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            preview,
            const SizedBox(height: 6),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Flat mode preview — simple rows, no grouping
class _FlatModePreview extends StatelessWidget {
  const _FlatModePreview();

  @override
  Widget build(BuildContext context) {
    const rows = ['Song Alpha', 'Song Beta', 'Remix Final', 'Dark Ambient'];
    return _PreviewFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows
            .map((name) => _PreviewRow(icon: Icons.music_note, label: name))
            .toList(),
      ),
    );
  }
}

// Smart Folder mode preview — groups when >1, flat otherwise
class _SmartFolderModePreview extends StatelessWidget {
  const _SmartFolderModePreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewRow(icon: Icons.folder_open, label: 'EP Project', bold: true),
          _PreviewRow(icon: Icons.music_note, label: 'Track 01', indent: true),
          _PreviewRow(icon: Icons.music_note, label: 'Track 02', indent: true, last: true),
          _PreviewRow(icon: Icons.music_note, label: 'Song Alpha'),
          _PreviewRow(icon: Icons.folder_open, label: 'Album', bold: true),
          _PreviewRow(icon: Icons.music_note, label: 'Intro', indent: true),
          _PreviewRow(icon: Icons.music_note, label: 'Chorus', indent: true, last: true),
        ],
      ),
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  final Widget child;
  const _PreviewFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: child,
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool indent;
  final bool bold;
  final bool last;

  const _PreviewRow({
    required this.icon,
    required this.label,
    this.indent = false,
    this.bold = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.only(left: indent ? 14.0 : 0, bottom: 2),
      child: Row(
        children: [
          if (indent) ...[
            Text(
              last ? '└ ' : '├ ',
              style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.4), fontFamily: 'monospace'),
            ),
          ],
          Icon(icon, size: 12, color: color.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: bold ? 0.9 : 0.7),
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

