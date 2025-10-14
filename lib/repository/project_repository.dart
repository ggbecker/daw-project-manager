import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/music_project.dart';
import '../models/scan_root.dart';

class ProjectRepository {
  static const projectsBoxName = 'projects';
  static const rootsBoxName = 'roots';

  final Box<MusicProject> projectsBox;
  final Box<ScanRoot> rootsBox;
  final _uuid = const Uuid();

  ProjectRepository({required this.projectsBox, required this.rootsBox});

  static Future<ProjectRepository> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MusicProjectAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ScanRootAdapter());
    }

    final projects = await Hive.openBox<MusicProject>(projectsBoxName);
    final roots = await Hive.openBox<ScanRoot>(rootsBoxName);
    return ProjectRepository(projectsBox: projects, rootsBox: roots);
  }

  // Roots
  Future<void> addRoot(String path) async {
    final id = _uuid.v4();
    await rootsBox.put(id, ScanRoot(id: id, path: path, addedAt: DateTime.now()));
  }

  Future<void> removeRoot(String id) async {
    await rootsBox.delete(id);
  }

  List<ScanRoot> getRoots() => rootsBox.values.toList(growable: false);

  // Projects
  MusicProject? getByPath(String path) {
    try {
      return projectsBox.values.firstWhere((p) => p.filePath == path);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertFromFileSystemEntity(FileSystemEntity entity) async {
    final isLogicBundle = entity is Directory && entity.path.toLowerCase().endsWith('.logicx');
    final filePath = entity.path;
    final stat = await entity.stat();
    final fileName = p.basename(filePath);
    final ext = isLogicBundle ? '.logicx' : p.extension(filePath).toLowerCase();
    final size = stat.size;
    final lastModified = stat.modified;

    final existing = getByPath(filePath);
    final project = (existing ?? MusicProject(
      id: _uuid.v4(),
      filePath: filePath,
      fileName: fileName,
      fileSizeBytes: size,
      lastModifiedAt: lastModified,
      fileExtension: ext,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    )).copyWith(
      // preserve user-edited fileName if existing
      fileName: existing?.fileName ?? fileName,
      fileSizeBytes: size,
      lastModifiedAt: lastModified,
      fileExtension: ext,
      updatedAt: DateTime.now(),
    );

    await projectsBox.put(project.id, project);
  }

  List<MusicProject> getAllProjects() => projectsBox.values.toList(growable: false);

  Future<void> updateProject(MusicProject project) async {
    await projectsBox.put(project.id, project.copyWith(updatedAt: DateTime.now()));
  }

  // Reactive listeners
  ValueListenable<Box<MusicProject>> projectsListenable() => projectsBox.listenable();
  ValueListenable<Box<ScanRoot>> rootsListenable() => rootsBox.listenable();

  // Stream watch for Riverpod StreamProvider usage
  Stream<BoxEvent> watchProjects() => projectsBox.watch();
  Stream<BoxEvent> watchRoots() => rootsBox.watch();

  Future<void> clearAllData() async {
    await projectsBox.clear();
    await rootsBox.clear();
  }

  Future<void> clearMissingFiles() async {
    final toDelete = <dynamic>[];
    for (final entry in projectsBox.values) {
      if (!File(entry.filePath).existsSync() && !Directory(entry.filePath).existsSync()) {
        toDelete.add(entry.id);
      }
    }
    await projectsBox.deleteAll(toDelete);
  }
}


