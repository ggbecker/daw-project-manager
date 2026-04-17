import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/desktop_title_bar.dart';

import '../generated/l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../repository/project_repository.dart';
import '../services/scanner_service.dart';
import '../utils/mobile_utils.dart';

class ProjectFoldersSettingsPage extends ConsumerStatefulWidget {
  const ProjectFoldersSettingsPage({super.key});

  @override
  ConsumerState<ProjectFoldersSettingsPage> createState() => _ProjectFoldersSettingsPageState();
}


class _ProjectFoldersSettingsPageState extends ConsumerState<ProjectFoldersSettingsPage> {
  bool _busy = false;
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

    await for (final entity in scanner.scanDirectory(folderPath, ignoredPaths: excluded)) {
      await repo.upsertFromFileSystemEntity(entity, fullMetadata: false);
      found++;
    }
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

    final picked = await FilePicker.platform.getDirectoryPath(dialogTitle: l10n.selectProjectsFolder);
    if (picked == null) return;

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
    final picked = await FilePicker.platform.getDirectoryPath(dialogTitle: l10n.selectExcludedFolder);
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

    final listBody = ListView(
      padding: MobileUtils.getResponsivePadding(context),
      children: [
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
                      trailing: IconButton(
                        tooltip: l10n.remove,
                        onPressed: _busy ? null : () => _removeProjectFolder(f.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    );
                  }),
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
                          Text('Preview Mixdown Folder', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            'Subfolder name inside each project folder to check first when auto-detecting preview songs. Leave empty to use DAW defaults.',
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
                        decoration: const InputDecoration(
                          hintText: 'e.g. Mixdowns',
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
                      child: const Text('Save'),
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
          DesktopTitleBar(title: l10n.roots, showBack: true),
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

