/// Represents the progress of an upload operation
class UploadProgress {
  final String currentItem;
  final int currentIndex;
  final int totalItems;
  final UploadType type;
  final bool isComplete;
  final String? error;

  const UploadProgress({
    required this.currentItem,
    required this.currentIndex,
    required this.totalItems,
    required this.type,
    this.isComplete = false,
    this.error,
  });

  double get progress => totalItems > 0 ? currentIndex / totalItems : 0.0;
  String get progressText => '$currentIndex / $totalItems';

  UploadProgress copyWith({
    String? currentItem,
    int? currentIndex,
    int? totalItems,
    UploadType? type,
    bool? isComplete,
    String? error,
  }) {
    return UploadProgress(
      currentItem: currentItem ?? this.currentItem,
      currentIndex: currentIndex ?? this.currentIndex,
      totalItems: totalItems ?? this.totalItems,
      type: type ?? this.type,
      isComplete: isComplete ?? this.isComplete,
      error: error ?? this.error,
    );
  }
}

enum UploadType {
  previewSong,
  project,
  release,
  database,
}
