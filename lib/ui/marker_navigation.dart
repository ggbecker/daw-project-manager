import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/music_project.dart';
import '../models/project_marker.dart';
import '../providers/providers.dart';
import '../utils/mobile_utils.dart';

/// Whether tapping a marker can actually take the user anywhere.
///
/// Markers describe the DAW project's timeline, but the app can only play the
/// preview song rendered from it — so with no playable preview there is
/// nothing to seek in and the marker rows are shown inert rather than lying
/// about what a tap will do.
bool canJumpToProjectMarkers(MusicProject project) => isPlayablePreview(project);

/// Jumps the preview player to [marker]'s position in [project].
///
/// Starts the track first when it isn't the one already loaded, so a marker
/// works as a "play this song from here" action and not only as a scrub
/// control for whatever happens to be playing.
///
/// Marker positions come from the DAW timeline while the audio is a render of
/// it, so a position can land past the end of a preview that covers only part
/// of the session. Both players clamp rather than fail.
Future<void> jumpToProjectMarker(
  WidgetRef ref,
  MusicProject project,
  ProjectMarker marker,
) async {
  if (!canJumpToProjectMarkers(project)) return;
  final path = resolvedPreviewPath(project);

  if (MobileUtils.isMobile()) {
    final player = ref.read(mobilePlayerProvider.notifier);
    final current = ref.read(mobilePlayerProvider).currentProject;
    if (current?.id != project.id) {
      await player.playProject(project, path);
    }
    await player.seek(marker.position);
    return;
  }

  final loaded = ref.read(desktopPlayerProvider);
  if (loaded != null && loaded.project.id == project.id) {
    ref.read(desktopPlayerSeekRequestProvider.notifier).seekTo(marker.position);
    return;
  }
  // The player bar doesn't exist yet, so the start position has to ride along
  // with the play request instead of being a seek sent right after it.
  ref
      .read(desktopPlayerProvider.notifier)
      .play(project, path, startAt: marker.position);
}
