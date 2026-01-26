/// Model for tracking backup upload progress
class BackupProgress {
  final BackupProgressStage stage;
  final String currentItem;
  final int currentIndex;
  final int totalItems;
  final double progress; // 0.0 to 1.0

  BackupProgress({
    required this.stage,
    required this.currentItem,
    required this.currentIndex,
    required this.totalItems,
    required this.progress,
  });

  BackupProgress copyWith({
    BackupProgressStage? stage,
    String? currentItem,
    int? currentIndex,
    int? totalItems,
    double? progress,
  }) {
    return BackupProgress(
      stage: stage ?? this.stage,
      currentItem: currentItem ?? this.currentItem,
      currentIndex: currentIndex ?? this.currentIndex,
      totalItems: totalItems ?? this.totalItems,
      progress: progress ?? this.progress,
    );
  }
}

enum BackupProgressStage {
  collectingData,
  uploadingPreviewSongs,
  uploadingProfilePhotos,
  uploadingReleaseArtwork,
  uploadingDatabase,
  downloadingDatabase,
  downloadingPreviewSongs,
  downloadingProfilePhotos,
  downloadingReleaseArtwork,
  mergingData,
  completed,
}
