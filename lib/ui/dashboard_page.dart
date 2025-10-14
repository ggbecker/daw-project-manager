import 'dart:io';

import 'package:pluto_grid/pluto_grid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/scanner_service.dart';
import 'project_detail_page.dart';

import '../models/music_project.dart';
import '../providers/providers.dart';
import '../repository/project_repository.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // Campos de estado desnecessários foram removidos
  bool _scanning = false;

  Future<void> _scanAll() async {
    if (_scanning) return;
    final repo = await ref.read(repositoryProvider.future);
    setState(() => _scanning = true);
    try {
      final scanner = ScannerService();
      int foundCount = 0;
      await repo.clearMissingFiles();
      for (final root in repo.getRoots()) {
        await for (final entity in scanner.scanDirectory(root.path)) {
          await repo.upsertFromFileSystemEntity(entity);
          foundCount++;
        }
      }
      if (mounted) {
        final msg = foundCount == 0
            ? 'No projects found in selected roots.'
            : 'Scan complete: $foundCount project${foundCount == 1 ? '' : 's'} added/updated.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = ref.watch(dateFormatProvider);
    final repoAsync = ref.watch(repositoryProvider);
    final roots = ref.watch(scanRootsProvider);
    
    // Observa o estado (QueryParams) do Notifier
    final currentParams = ref.watch(queryParamsNotifierProvider);

    // Agora apenas observamos o projectsProvider, que já está filtrado e ordenado
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DAW Project Manager'),
        actions: [
          SizedBox(
            width: 360,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name...',
                  isDense: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                // CHAMA O MÉTODO DO NOTIFIER (sintaxe Riverpod v3)
                onChanged: (text) {
                  ref.read(queryParamsNotifierProvider.notifier).setSearchText(text);
                },
              ),
            ),
          ),
          IconButton(
            tooltip: 'Toggle sort',
            // CHAMA O MÉTODO DO NOTIFIER (sintaxe Riverpod v3)
            onPressed: () {
              ref.read(queryParamsNotifierProvider.notifier).toggleSortDesc();
            },
            icon: Icon(currentParams.sortDesc ? Icons.sort_by_alpha : Icons.sort),
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (context) {
              return IconButton(
                tooltip: 'Clear Library (projects & roots)',
                icon: const Icon(Icons.delete_forever),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF2B2D31),
                      title: const Text('Clear Library'),
                      content: const Text('This will remove all saved projects and source folders. Continue?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final repo = await ref.read(repositoryProvider.future);
                    await repo.clearAllData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Library cleared.')));
                    }
                  }
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _scanning
                      ? null
                      : () async {
                          final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select root folder');
                          if (path != null) {
                            final repo = await ref.read(repositoryProvider.future);
                            await repo.addRoot(path);
                            await _scanAll();
                          }
                        },
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: const Text('Add Root & Scan'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _scanning
                      ? null
                      : () async {
                          await _scanAll();
                        },
                  icon: _scanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_scanning ? 'Scanning…' : 'Rescan'),
                ),
                const Spacer(),
                repoAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (repo) => Text('Roots: ${repo.getRoots().length}   Projects: ${projects.length}'),
                ),
              ],
            ),
          ),
          if (roots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in roots)
                      Chip(
                        label: Text(r.path),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () async {
                          final repo = await ref.read(repositoryProvider.future);
                          await repo.removeRoot(r.id);
                        },
                        backgroundColor: const Color(0xFF2B2D31),
                        labelStyle: const TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(child: _PlutoProjectsTable(projects: projects, dateFormat: dateFormat)),
        ],
      ),
    );
  }
} // Fim da classe _DashboardPageState

class _PlutoProjectsTable extends StatefulWidget {
  final List<MusicProject> projects;
  final DateFormat dateFormat;
  const _PlutoProjectsTable({required this.projects, required this.dateFormat});

  @override
  State<_PlutoProjectsTable> createState() => _PlutoProjectsTableState();
}

class _PlutoProjectsTableState extends State<_PlutoProjectsTable> {
  @override
  Widget build(BuildContext context) {
    final columns = [
      PlutoColumn(
        title: 'Name',
        field: 'name',
        type: PlutoColumnType.text(),
        enableColumnDrag: true,
        enableContextMenu: false,
        width: 380,
        minWidth: 200,
        frozen: PlutoColumnFrozen.start,
      ),
      PlutoColumn(
        title: 'Status',
        field: 'status',
        type: PlutoColumnType.text(),
        width: 140,
        minWidth: 120,
      ),
      PlutoColumn(
        title: 'BPM',
        field: 'bpm',
        type: PlutoColumnType.text(),
        width: 100,
        minWidth: 80,
      ),
      PlutoColumn(
        title: 'Key',
        field: 'key',
        type: PlutoColumnType.text(),
        width: 120,
        minWidth: 100,
      ),
      PlutoColumn(
        title: 'Last Modified',
        field: 'lastModified',
        type: PlutoColumnType.text(),
        width: 200,
        minWidth: 160,
      ),
      PlutoColumn(
        title: 'Launch',
        field: 'launch',
        type: PlutoColumnType.text(),
        width: 120,
        minWidth: 100,
        renderer: (ctx) {
          final project = ctx.row.cells['data']!.value as MusicProject;
          return ElevatedButton(
            onPressed: () async {
              final exists = File(project.filePath).existsSync() || Directory(project.filePath).existsSync();
              if (!exists) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File missing.')));
                }
                return;
              }
              try {
                if (Platform.isMacOS) {
                  await Process.start('open', [project.filePath]);
                } else if (Platform.isWindows) {
                  await Process.start('cmd', ['/c', 'start', '', project.filePath]);
                } else {
                  await Process.start(project.filePath, []);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Launching ${project.displayName}…')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to launch: $e')));
                }
              }
            },
            child: const Text('Launch'),
          );
        },
      ),
      // Hidden backing column for passing the model instance
      PlutoColumn(
        title: 'data',
        field: 'data',
        type: PlutoColumnType.text(),
        width: 0,
        hide: true,
      ),
    ];

    final rows = widget.projects.map((p) {
      return PlutoRow(cells: {
        'name': PlutoCell(value: p.displayName),
        'status': PlutoCell(value: p.status),
        'bpm': PlutoCell(value: p.bpm?.toString() ?? ''),
        'key': PlutoCell(value: p.musicalKey ?? ''),
        'lastModified': PlutoCell(value: widget.dateFormat.format(p.lastModifiedAt)),
        'launch': PlutoCell(value: ''),
        'data': PlutoCell(value: p), // hidden data cell
      });
    }).toList();
    return PlutoGrid(
      columns: columns,
      rows: rows,
      configuration: PlutoGridConfiguration(
        style: PlutoGridStyleConfig(
          gridBackgroundColor: const Color(0xFF1E1F22),
          gridBorderColor: const Color(0xFF3C3F43),
          gridBorderRadius: BorderRadius.zero,
          rowColor: const Color(0xFF2B2D31),
          cellColorInEditState: const Color(0xFF2F3136),
          cellColorInReadOnlyState: const Color(0xFF2B2D31),
          columnTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          cellTextStyle: const TextStyle(color: Colors.white),
          columnHeight: 44,
          rowHeight: 48,
          activatedBorderColor: const Color(0xFF5A6B7A),
          activatedColor: const Color(0xFF263238),
          iconColor: Colors.white70,
          menuBackgroundColor: const Color(0xFF2B2D31),
          evenRowColor: const Color(0xFF27292D),
        ),
        columnSize: const PlutoGridColumnSizeConfig(
          autoSizeMode: PlutoAutoSizeMode.scale,
          resizeMode: PlutoResizeMode.normal,
        ),
      ),
      onRowChecked: null,
      onSelected: (e) async {
        final project = e.row?.cells['data']?.value as MusicProject?;
        if (project != null) {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: project.id)),
          );
        }
      },
      createFooter: (stateManager) => const SizedBox.shrink(),
    );
  }
}