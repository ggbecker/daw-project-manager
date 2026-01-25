import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';

/// Audio handler for playlist playback with system notifications
class PlaylistAudioHandler extends BaseAudioHandler {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Function(int index)? onIndexChanged;
  final Function(Duration position)? onPositionChanged;
  final Function(Duration duration)? onDurationChanged;
  final Function()? onCompleted;
  
  List<MediaItem> _queue = [];
  int _currentIndex = 0;

  PlaylistAudioHandler({
    this.onIndexChanged,
    this.onPositionChanged,
    this.onDurationChanged,
    this.onCompleted,
  }) {
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      switch (state) {
        case PlayerState.playing:
          playbackState.add(playbackState.value.copyWith(
            playing: true,
            controls: [
              MediaControl.skipToPrevious,
              MediaControl.pause,
              MediaControl.skipToNext,
              MediaControl.stop,
            ],
            processingState: AudioProcessingState.ready,
          ));
          break;
        case PlayerState.paused:
          playbackState.add(playbackState.value.copyWith(
            playing: false,
            controls: [
              MediaControl.skipToPrevious,
              MediaControl.play,
              MediaControl.skipToNext,
              MediaControl.stop,
            ],
            processingState: AudioProcessingState.ready,
          ));
          break;
        case PlayerState.stopped:
          playbackState.add(playbackState.value.copyWith(
            playing: false,
            controls: [
              MediaControl.play,
            ],
            processingState: AudioProcessingState.idle,
          ));
          break;
        default:
          break;
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      onDurationChanged?.call(duration);
      playbackState.add(playbackState.value.copyWith(
        updatePosition: playbackState.value.position,
      ));
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      onPositionChanged?.call(position);
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    // Listen to completion
    _audioPlayer.onPlayerComplete.listen((_) {
      onCompleted?.call();
      if (_currentIndex < _queue.length - 1) {
        skipToNext();
      } else {
        stop();
      }
    });
  }

  /// Update the queue with new items
  @override
  Future<void> updateQueue(List<MediaItem> items) async {
    _queue = items;
    queue.add(_queue);
    
    if (_queue.isNotEmpty) {
      mediaItem.add(_queue[_currentIndex]);
    }
  }
  
  /// Set initial index for playback
  void setInitialIndex(int index) {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      if (_queue.isNotEmpty) {
        mediaItem.add(_queue[_currentIndex]);
      }
    }
  }

  /// Get current index
  int get currentIndex => _currentIndex;

  @override
  Future<void> play() async {
    if (_queue.isEmpty) return;
    
    final item = _queue[_currentIndex];
    final uri = item.extras?['filePath'] as String?;
    
    if (uri == null || uri.isEmpty) {
      skipToNext();
      return;
    }

    final file = File(uri);
    if (!await file.exists()) {
      skipToNext();
      return;
    }

    try {
      await _audioPlayer.play(DeviceFileSource(uri));
      mediaItem.add(item);
    } catch (e) {
      skipToNext();
    }
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
      updatePosition: Duration.zero,
    ));
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      onIndexChanged?.call(_currentIndex);
      mediaItem.add(_queue[_currentIndex]);
      await play();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      onIndexChanged?.call(_currentIndex);
      mediaItem.add(_queue[_currentIndex]);
      await play();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      onIndexChanged?.call(_currentIndex);
      mediaItem.add(_queue[_currentIndex]);
      await play();
    }
  }

  /// Dispose audio player
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
