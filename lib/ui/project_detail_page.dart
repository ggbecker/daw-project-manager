import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/music_project.dart';
import '../providers/providers.dart';

class ProjectDetailPage extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends ConsumerState<ProjectDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _bpmCtrl;
  late TextEditingController _keyCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bpmCtrl = TextEditingController();
    _keyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bpmCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(repositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: repoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
        data: (repo) {
          final project = repo.getAllProjects().firstWhere((p) => p.id == widget.projectId);
          _nameCtrl.text = project.fileName;
          _bpmCtrl.text = project.bpm?.toString() ?? '';
          _keyCtrl.text = project.musicalKey ?? '';
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text(project.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(project.filePath, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  Text('Last modified: ${project.lastModifiedAt}'),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'File Name (editable)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bpmCtrl,
                    decoration: const InputDecoration(labelText: 'BPM'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _keyCtrl,
                    decoration: const InputDecoration(labelText: 'Key (e.g., C#m, F major)'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final updated = project.copyWith(
                            fileName: _nameCtrl.text.trim().isEmpty ? project.fileName : _nameCtrl.text.trim(),
                            bpm: _bpmCtrl.text.trim().isEmpty ? null : double.tryParse(_bpmCtrl.text.trim()),
                            musicalKey: _keyCtrl.text.trim().isEmpty ? null : _keyCtrl.text.trim(),
                          );
                          await repo.updateProject(updated);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            if (Platform.isMacOS) {
                              await Process.start('open', [project.filePath]);
                            } else if (Platform.isWindows) {
                              await Process.start('cmd', ['/c', 'start', '', project.filePath]);
                            }
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open in DAW'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


