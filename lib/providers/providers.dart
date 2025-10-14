import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/music_project.dart';
import '../models/scan_root.dart';
import '../repository/project_repository.dart';
import '../services/scanner_service.dart';

final repositoryProvider = FutureProvider<ProjectRepository>((ref) async {
  return ProjectRepository.init();
});

final rootsWatchProvider = StreamProvider<void>((ref) async* {
  final repo = await ref.watch(repositoryProvider.future);
  yield* repo.watchRoots().map((_) => null);
});

final scanRootsProvider = Provider<List<ScanRoot>>((ref) {
  // Rebuild when roots box changes
  ref.watch(rootsWatchProvider);
  final repoAsync = ref.watch(repositoryProvider);
  return repoAsync.maybeWhen(
    data: (repo) => repo.getRoots(),
    orElse: () => const <ScanRoot>[],
  );
});

// scanning state is managed in UI now

class QueryParams {
  final String searchText;
  final bool sortDesc;
  const QueryParams({this.searchText = '', this.sortDesc = true});
}

final queryParamsProvider = Provider<QueryParams>((ref) => const QueryParams());

final projectsWatchProvider = StreamProvider<void>((ref) async* {
  final repo = await ref.watch(repositoryProvider.future);
  yield* repo.watchProjects().map((_) => null);
});

final projectsProvider = Provider<List<MusicProject>>((ref) {
  // Watch for changes in Hive box
  ref.watch(projectsWatchProvider);
  final repoAsync = ref.watch(repositoryProvider);
  final params = ref.watch(queryParamsProvider);
  return repoAsync.maybeWhen(
    data: (repo) {
      var projects = repo.getAllProjects();
      if (params.searchText.trim().isNotEmpty) {
        final needle = params.searchText.toLowerCase();
        projects = projects.where((p) => p.displayName.toLowerCase().contains(needle)).toList();
      }
      projects.sort((a, b) => a.lastModifiedAt.compareTo(b.lastModifiedAt));
      if (params.sortDesc) {
        projects = projects.reversed.toList();
      }
      return projects;
    },
    orElse: () => const <MusicProject>[],
  );
});

final dateFormatProvider = Provider<DateFormat>((ref) => DateFormat.yMMMd().add_jm());


