import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/music_project.dart';
import '../models/release.dart';
import '../models/todo_item.dart';
import '../providers/providers.dart';
import '../utils/search_utils.dart';
import '../generated/l10n/app_localizations.dart';
import 'project_detail_page.dart';
import 'release_detail_page.dart';

Color _phaseColor(String status) {
  switch (status) {
    case 'Idea':
      return Colors.blue.shade300;
    case 'Arranging':
      return Colors.orange.shade300;
    case 'Mixing':
      return Colors.purple.shade300;
    case 'Mastering':
      return Colors.pink.shade300;
    case 'Finished':
      return Colors.green.shade300;
    default:
      return Colors.grey;
  }
}

class QueuePage extends ConsumerWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final projectsAsync = ref.watch(allProjectsStreamProvider);
    final releasesAsync = ref.watch(releasesProvider);
    final searchText = ref.watch(queueSearchProvider).toLowerCase().trim();

    final releases = releasesAsync.value ?? [];

    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.errorLoadingProjects)),
      data: (allProjects) {
        // Build list of (project, pendingTodos) pairs, filtering by search
        final projectEntries = <MapEntry<MusicProject, List<TodoItem>>>[];
        for (final project in allProjects) {
          if (searchText.isEmpty) {
            final pending = project.todos.where((t) => !t.completed).toList();
            if (pending.isNotEmpty) projectEntries.add(MapEntry(project, pending));
          } else {
            final matchProject = fuzzyMatchAll(project.displayName, searchText);
            final matchingTodos = project.todos
                .where((t) =>
                    !t.completed &&
                    (matchProject || fuzzyMatchAll(t.text, searchText)))
                .toList();
            if (matchingTodos.isNotEmpty) {
              projectEntries.add(MapEntry(project, matchingTodos));
            }
          }
        }

        // Build list of (release, pendingTodos) pairs, filtering by search
        final releaseEntries = <MapEntry<Release, List<TodoItem>>>[];
        for (final release in releases) {
          if (searchText.isEmpty) {
            final pending = release.todos.where((t) => !t.completed).toList();
            if (pending.isNotEmpty) releaseEntries.add(MapEntry(release, pending));
          } else {
            final matchRelease = fuzzyMatchAll(release.title, searchText);
            final matchingTodos = release.todos
                .where((t) =>
                    !t.completed &&
                    (matchRelease || fuzzyMatchAll(t.text, searchText)))
                .toList();
            if (matchingTodos.isNotEmpty) {
              releaseEntries.add(MapEntry(release, matchingTodos));
            }
          }
        }

        // Sort each group by pending count descending, then by name
        projectEntries.sort((a, b) {
          final cmp = b.value.length.compareTo(a.value.length);
          if (cmp != 0) return cmp;
          return a.key.displayName.toLowerCase().compareTo(b.key.displayName.toLowerCase());
        });
        releaseEntries.sort((a, b) {
          final cmp = b.value.length.compareTo(a.value.length);
          if (cmp != 0) return cmp;
          return a.key.title.toLowerCase().compareTo(b.key.title.toLowerCase());
        });

        final totalPending = projectEntries.fold<int>(0, (sum, e) => sum + e.value.length)
            + releaseEntries.fold<int>(0, (sum, e) => sum + e.value.length);
        final totalSections = projectEntries.length + releaseEntries.length;

        if (totalSections == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  searchText.isEmpty
                      ? Icons.check_circle_outline
                      : Icons.search_off,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  searchText.isEmpty
                      ? l10n.queueNoPendingTasks
                      : l10n.queueNoMatchingTasks,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (searchText.isEmpty)
                  Text(
                    l10n.queueNoPendingTasksHint,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          );
        }

        // Interleave project and release sections sorted by pending count
        final items = <Widget>[];
        int pi = 0, ri = 0;
        while (pi < projectEntries.length || ri < releaseEntries.length) {
          final pCount = pi < projectEntries.length ? projectEntries[pi].value.length : -1;
          final rCount = ri < releaseEntries.length ? releaseEntries[ri].value.length : -1;
          if (pCount >= rCount) {
            final e = projectEntries[pi++];
            items.add(_ProjectTodoSection(project: e.key, pendingTodos: e.value));
          } else {
            final e = releaseEntries[ri++];
            items.add(_ReleaseTodoSection(release: e.key, pendingTodos: e.value));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.checklist,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.queuePendingSummary(totalPending, totalSections),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: items,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProjectTodoSection extends ConsumerStatefulWidget {
  final MusicProject project;
  final List<TodoItem> pendingTodos;

  const _ProjectTodoSection({
    required this.project,
    required this.pendingTodos,
  });

  @override
  ConsumerState<_ProjectTodoSection> createState() =>
      _ProjectTodoSectionState();
}

class _ProjectTodoSectionState extends ConsumerState<_ProjectTodoSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final pendingTodos = widget.pendingTodos;
    final phaseColor = _phaseColor(project.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Project header — tapping navigates to detail page
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectDetailPage(projectId: project.id),
              ),
            ),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: _expanded ? Radius.zero : const Radius.circular(12),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Phase dot
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: phaseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Project name
                  Expanded(
                    child: Text(
                      project.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Phase badge
                  _Badge(
                    label: project.status,
                    color: phaseColor,
                  ),
                  const SizedBox(width: 6),
                  // Pending count badge
                  _Badge(
                    label: '${pendingTodos.length}',
                    color: Theme.of(context).colorScheme.primary,
                    filled: true,
                  ),
                  const SizedBox(width: 2),
                  // Expand toggle
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            ...pendingTodos.map(
              (todo) => _TodoCheckItem(
                project: project,
                todo: todo,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const _Badge({
    required this.label,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TodoCheckItem extends ConsumerWidget {
  final MusicProject project;
  final TodoItem todo;
  final VoidCallback? onTap;

  const _TodoCheckItem({
    required this.project,
    required this.todo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      value: false,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        todo.text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      onChanged: (_) async {
        final repo = await ref.read(repositoryProvider.future);
        final updatedTodos = project.todos
            .map((t) => t.id == todo.id ? t.copyWith(completed: true) : t)
            .toList();
        await repo.updateProject(project.copyWith(todos: updatedTodos));
        ref.invalidate(allProjectsStreamProvider);
      },
    );
  }
}

// ─── Release sections ────────────────────────────────────────────────────────

class _ReleaseTodoSection extends ConsumerStatefulWidget {
  final Release release;
  final List<TodoItem> pendingTodos;

  const _ReleaseTodoSection({
    required this.release,
    required this.pendingTodos,
  });

  @override
  ConsumerState<_ReleaseTodoSection> createState() => _ReleaseTodoSectionState();
}

class _ReleaseTodoSectionState extends ConsumerState<_ReleaseTodoSection> {
  bool _expanded = true;

  static const _accentColor = Colors.teal;

  @override
  Widget build(BuildContext context) {
    final release = widget.release;
    final pendingTodos = widget.pendingTodos;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReleaseDetailPage(releaseId: release.id),
              ),
            ),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: _expanded ? Radius.zero : const Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.album, size: 13, color: _accentColor.shade300),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      release.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Badge(
                    label: 'Release',
                    color: _accentColor.shade300,
                  ),
                  const SizedBox(width: 6),
                  _Badge(
                    label: '${pendingTodos.length}',
                    color: Theme.of(context).colorScheme.primary,
                    filled: true,
                  ),
                  const SizedBox(width: 2),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            ...pendingTodos.map(
              (todo) => _ReleaseTodoCheckItem(release: release, todo: todo),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReleaseTodoCheckItem extends ConsumerWidget {
  final Release release;
  final TodoItem todo;

  const _ReleaseTodoCheckItem({
    required this.release,
    required this.todo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      value: false,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        todo.text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      onChanged: (_) async {
        final repo = await ref.read(repositoryProvider.future);
        final updatedTodos = release.todos
            .map((t) => t.id == todo.id ? t.copyWith(completed: true) : t)
            .toList();
        await repo.updateRelease(release.copyWith(todos: updatedTodos));
        ref.invalidate(releasesProvider);
      },
    );
  }
}
