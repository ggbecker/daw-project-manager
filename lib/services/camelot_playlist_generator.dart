import 'dart:math' as math;
import '../models/music_project.dart';

/// Result of a Camelot playlist generation.
class CamelotGenerationResult {
  final List<MusicProject> ordered;
  final int skippedCount;

  const CamelotGenerationResult({
    required this.ordered,
    required this.skippedCount,
  });
}

class CamelotPlaylistGenerator {
  static bool _hasPreview(MusicProject p) =>
      (p.previewSongPath != null && p.previewSongPath!.isNotEmpty) ||
      (p.previewSongAutoPath != null && p.previewSongAutoPath!.isNotEmpty);

  static CamelotGenerationResult generate(List<MusicProject> allTracks) {
    final eligible = allTracks
        .where((t) => t.camelotCode != null && _hasPreview(t))
        .toList();
    final skipped = allTracks.length - eligible.length;

    if (eligible.isEmpty) {
      return CamelotGenerationResult(ordered: [], skippedCount: skipped);
    }

    final result = <MusicProject>[];
    final remaining = List<MusicProject>.from(eligible);

    result.add(_pickStart(remaining));
    remaining.remove(result.first);

    while (remaining.isNotEmpty) {
      final next = _findBestNext(result.last, remaining);
      result.add(next);
      remaining.remove(next);
    }

    return CamelotGenerationResult(ordered: result, skippedCount: skipped);
  }

  /// Returns only the tracks that will be included (for UI preview).
  static int eligibleCount(List<MusicProject> tracks) =>
      tracks.where((t) => t.camelotCode != null && _hasPreview(t)).length;

  static MusicProject _pickStart(List<MusicProject> tracks) {
    final withBpm = tracks.where((t) => t.bpm != null).toList()
      ..sort((a, b) => a.bpm!.compareTo(b.bpm!));
    return withBpm.isNotEmpty ? withBpm[withBpm.length ~/ 2] : tracks.first;
  }

  static MusicProject _findBestNext(
      MusicProject current, List<MusicProject> candidates) {
    final compatibleCodes = current.compatibleCamelotCodes ?? [];
    MusicProject? best;
    double bestScore = double.infinity;

    for (final candidate in candidates) {
      final score = _score(current, candidate, compatibleCodes);
      if (score < bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return best ?? candidates.first;
  }

  static double _score(
      MusicProject current, MusicProject candidate, List<String> compatibleCodes) {
    final candidateCode = candidate.camelotCode;

    // Camelot score: 0 for compatible, wheel-distance × 100 otherwise.
    // This keeps compatible tracks always preferred over incompatible ones
    // unless BPM differs by 100+, which won't happen in practice.
    final double camelotScore;
    if (candidateCode != null && compatibleCodes.contains(candidateCode)) {
      camelotScore = 0.0;
    } else if (candidateCode != null && current.camelotCode != null) {
      camelotScore = _wheelDistance(current.camelotCode!, candidateCode) * 100.0;
    } else {
      camelotScore = 1200.0; // no key data — last resort
    }

    // BPM score: absolute difference, or 0 when either track has no BPM.
    final double bpmScore = (current.bpm != null && candidate.bpm != null)
        ? (current.bpm! - candidate.bpm!).abs()
        : 0.0;

    return camelotScore + bpmScore;
  }

  /// Circular distance on the 12-position Camelot wheel plus a half-point
  /// penalty for crossing the A/B (minor/major) boundary.
  static double _wheelDistance(String code1, String code2) {
    final n1 = int.tryParse(code1.substring(0, code1.length - 1));
    final n2 = int.tryParse(code2.substring(0, code2.length - 1));
    final l1 = code1[code1.length - 1];
    final l2 = code2[code2.length - 1];
    if (n1 == null || n2 == null) return 12.0;

    final numDist = math.min((n1 - n2).abs(), 12 - (n1 - n2).abs()).toDouble();
    final letterPenalty = l1 != l2 ? 0.5 : 0.0;
    return numDist + letterPenalty;
  }
}
