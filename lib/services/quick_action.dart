/// A taskbar jump-list / Dock-menu quick action, decoded from either
/// cold-start command-line arguments or the payload a second launch attempt
/// forwards over the single-instance socket (Windows) — see main.dart's
/// `_dispatchQuickAction` for how each variant is executed.
sealed class QuickAction {
  const QuickAction();
}

class NewProjectQuickAction extends QuickAction {
  const NewProjectQuickAction();
}

class ScanProjectsQuickAction extends QuickAction {
  const ScanProjectsQuickAction();
}

class OpenProjectQuickAction extends QuickAction {
  final String projectId;
  const OpenProjectQuickAction(this.projectId);
}

const _openProjectPrefix = '--open-project=';

/// Returns null when [args] don't encode a recognized quick action (e.g. a
/// plain relaunch with no arguments).
QuickAction? parseQuickAction(List<String> args) {
  if (args.isEmpty) return null;
  final first = args.first;
  switch (first) {
    case '--new-project':
      return const NewProjectQuickAction();
    case '--scan-projects':
      return const ScanProjectsQuickAction();
    default:
      if (first.startsWith(_openProjectPrefix)) {
        return OpenProjectQuickAction(first.substring(_openProjectPrefix.length));
      }
      return null;
  }
}
