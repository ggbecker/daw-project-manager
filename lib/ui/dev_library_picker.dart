import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/dev_library_service.dart';
import '../utils/app_paths.dart';

/// Startup gate that asks a dev build which library to open.
///
/// Runs before Hive is initialised, because every path the app uses is derived
/// from the chosen directory and several boxes are opened during startup —
/// so this cannot be a settings screen.
///
/// Deliberately not localized: it exists only in debug and profile builds and
/// is never present in anything a user receives, so the usual "hardcoded
/// strings break nine locales" rule has nothing to bite on here.
///
/// No-ops unless [canPickAppDataDir] — a release build, or a pull-request
/// build pinned with `--dart-define=DPM_DATA_DIR`, must not be offered a
/// choice that could point it at the installed app's real library.
Future<void> maybePickAppDataLibrary() async {
  if (!canPickAppDataDir) return;

  final root = await DevLibraryService.resolveRoot();

  final remembered = DevLibraryService.readSelection(root);
  if (remembered != null) {
    selectAppDataDir(remembered);
    return;
  }

  final libraries = DevLibraryService.discover(root);
  final completer = Completer<void>();

  runApp(
    _DevLibraryPickerApp(
      root: root,
      libraries: libraries,
      onSelected: (library, remember) {
        selectAppDataDir(library.dirName);
        if (remember) {
          DevLibraryService.writeSelection(root, library.dirName);
        }
        if (!completer.isCompleted) completer.complete();
      },
    ),
  );

  await completer.future;

  // Tear the picker down and wait for the frame to finish before startup
  // continues.
  //
  // Startup ends in its own runApp() with another MaterialApp at this same
  // root, and Flutter *updates* one MaterialApp into the other rather than
  // rebuilding it — which reparents keyed subtrees instead of unmounting
  // them, and trips "A GlobalKey can only be specified on one widget at a
  // time" against the app's root navigatorKey. Swapping to a plain widget
  // first unmounts this tree, so the real app attaches to a clean root.
  //
  // The colour matches the launch background so the gap between the two apps
  // is not a white flash.
  runApp(const ColoredBox(color: Color(0xFF1E1F22)));
  await WidgetsBinding.instance.endOfFrame;
}

class _DevLibraryPickerApp extends StatelessWidget {
  final Directory root;
  final List<DevLibrary> libraries;
  final void Function(DevLibrary library, bool remember) onSelected;

  const _DevLibraryPickerApp({
    required this.root,
    required this.libraries,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: _DevLibraryPickerPage(
        root: root,
        libraries: libraries,
        onSelected: onSelected,
      ),
    );
  }
}

class _DevLibraryPickerPage extends StatefulWidget {
  final Directory root;
  final List<DevLibrary> libraries;
  final void Function(DevLibrary library, bool remember) onSelected;

  const _DevLibraryPickerPage({
    required this.root,
    required this.libraries,
    required this.onSelected,
  });

  @override
  State<_DevLibraryPickerPage> createState() => _DevLibraryPickerPageState();
}

class _DevLibraryPickerPageState extends State<_DevLibraryPickerPage> {
  bool _remember = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.science_outlined, size: 28),
                    const SizedBox(width: 12),
                    Text('Which library should this build open?',
                        style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Development build. Writing a newly added Hive type into the '
                  'release library leaves the installed app unable to read it, '
                  'so choose deliberately.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                for (final library in widget.libraries)
                  _LibraryTile(
                    library: library,
                    onTap: () => widget.onSelected(library, _remember),
                  ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _remember,
                  onChanged: (value) =>
                      setState(() => _remember = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Remember this choice'),
                  subtitle: Text(
                    'Stored in ${DevLibraryService.selectionFileName}. '
                    'Delete that file, or run with '
                    '--dart-define=DPM_DATA_DIR=<name>, to change it.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  final DevLibrary library;
  final VoidCallback onTap;

  const _LibraryTile({required this.library, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = StringBuffer();
    if (!library.exists) {
      subtitle.write('Does not exist yet — will be created empty');
    } else {
      subtitle.write(library.projectBoxCount == 1
          ? '1 project box'
          : '${library.projectBoxCount} project boxes');
      subtitle.write(' · ${DevLibraryService.formatBytes(library.totalBytes)}');
      final modified = library.lastModified;
      if (modified != null) {
        subtitle.write(' · last written '
            '${modified.year.toString().padLeft(4, '0')}-'
            '${modified.month.toString().padLeft(2, '0')}-'
            '${modified.day.toString().padLeft(2, '0')}');
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          library.isRelease ? Icons.inventory_2_outlined : Icons.build_outlined,
          color: library.isRelease ? Colors.amber : null,
        ),
        title: Row(
          children: [
            Flexible(child: Text(library.dirName)),
            if (library.isRelease) ...[
              const SizedBox(width: 8),
              Chip(
                label: const Text('release'),
                labelStyle: theme.textTheme.labelSmall,
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.amber.withValues(alpha: 0.2),
                side: BorderSide.none,
              ),
            ],
          ],
        ),
        subtitle: Text(subtitle.toString()),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
