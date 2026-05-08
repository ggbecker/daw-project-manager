import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/music_project.dart';
import '../providers/providers.dart';
import '../services/audio_analysis_service.dart';
import 'widgets/waveform_widget.dart';

class MusicPlayerPage extends ConsumerStatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  ConsumerState<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends ConsumerState<MusicPlayerPage> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  bool _isMono = false;
  bool _isGeneratingMono = false;
  String? _monoFilePath;
  AudioFileInfo? _fileInfo;
  WaveformPeaks? _peaks;
  int _currentIndex = -1;
  List<MusicProject> _tracks = [];

  MusicProject? get _current =>
      _currentIndex >= 0 && _currentIndex < _tracks.length
          ? _tracks[_currentIndex]
          : null;

  bool _handleKeyboard(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    if (FocusManager.instance.primaryFocus?.context?.widget is EditableText) {
      return false;
    }
    final modified = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (_current != null) _togglePlayPause();
      return _current != null;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_current != null) { _seek(modified ? -30 : -5); return true; }
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_current != null) { _seek(modified ? 30 : 5); return true; }
    }
    return false;
  }

  String? _resolvedPath(MusicProject project) =>
      project.previewSongPath?.isNotEmpty == true
          ? project.previewSongPath
          : project.previewSongAutoPath;

  String get _activePath {
    final base = _resolvedPath(_current!);
    return (_isMono && _monoFilePath != null) ? _monoFilePath! : base!;
  }

  bool _supportsMonoMix(String filePath) {
    final ext = filePath.toLowerCase().split('.').last;
    if (ext == 'wav') return true;
    if (Platform.isMacOS || Platform.isIOS) {
      return const {'mp3', 'flac', 'aif', 'aiff', 'aac', 'm4a'}.contains(ext);
    }
    return const {'mp3', 'flac', 'aif', 'aiff', 'ogg', 'aac', 'm4a'}.contains(ext);
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyboard);
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _isPlaying = s == PlayerState.playing);
    });
    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) _playNext();
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyboard);
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  void _buildTrackList(List<MusicProject> projects) {
    final tracks = projects
        .where((p) => _resolvedPath(p) != null)
        .toList()
      ..sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));
    if (listEquals(tracks.map((t) => t.id).toList(),
        _tracks.map((t) => t.id).toList())) { return; }
    setState(() {
      final prevId = _current?.id;
      _tracks = tracks;
      if (prevId != null) {
        final idx = _tracks.indexWhere((t) => t.id == prevId);
        _currentIndex = idx >= 0 ? idx : _currentIndex.clamp(-1, _tracks.length - 1);
      }
    });
  }

  Future<void> _selectTrack(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    final track = _tracks[index];
    final filePath = _resolvedPath(track)!;

    await _player.stop();
    setState(() {
      _currentIndex = index;
      _position = Duration.zero;
      _duration = Duration.zero;
      _isMono = false;
      _monoFilePath = null;
      _fileInfo = null;
      _peaks = null;
      _isGeneratingMono = false;
    });

    // Waveform — memory → disk → extraction
    final trackAtDispatch = track;
    ref.read(waveformCacheProvider.notifier).getOrExtract(filePath).then((peaks) {
      if (!mounted || peaks == null) return;
      if (_current?.id == trackAtDispatch.id) setState(() => _peaks = peaks);
    });

    AudioAnalysisService.getFileInfo(filePath).then((info) {
      if (mounted && info != null && _current?.id == track.id) {
        setState(() => _fileInfo = info);
      }
    });

    if (_supportsMonoMix(filePath)) _prepareMonoFile(track, filePath);

    try {
      await _player.play(DeviceFileSource(filePath));
    } catch (_) {}
  }

  Future<void> _prepareMonoFile(MusicProject track, String filePath) async {
    final tmpDir = await getTemporaryDirectory();
    final outPath = '${tmpDir.path}/mono_player_${track.id}.wav';
    final ok = await AudioAnalysisService.writeMonoWavFile(filePath, outPath);
    if (!mounted || _current?.id != track.id) return;
    if (ok) {
      setState(() => _monoFilePath = outPath);
    } else {
      final ch = await AudioAnalysisService.getChannelCount(filePath);
      if (mounted && _current?.id == track.id && ch == 1) {
        setState(() => _monoFilePath = filePath);
      }
    }
  }

  void _playNext() {
    if (_tracks.isEmpty) return;
    _selectTrack((_currentIndex + 1) % _tracks.length);
  }

  void _playPrev() {
    if (_tracks.isEmpty) return;
    _selectTrack((_currentIndex - 1 + _tracks.length) % _tracks.length);
  }

  Future<void> _togglePlayPause() async {
    if (_current == null) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_duration > Duration.zero && _position >= _duration) {
        await _player.play(DeviceFileSource(_activePath));
      } else {
        await _player.resume();
      }
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    if (mounted) setState(() => _position = Duration.zero);
  }

  Future<void> _seek(int seconds) async {
    final target = _position + Duration(seconds: seconds);
    final clamped = target.isNegative
        ? Duration.zero
        : (_duration > Duration.zero && target > _duration ? _duration : target);
    await _player.seek(clamped);
  }

  Future<void> _toggleMono() async {
    if (_current == null) return;
    final filePath = _resolvedPath(_current!)!;
    if (!_supportsMonoMix(filePath)) return;
    final newMono = !_isMono;
    if (newMono && _monoFilePath == null) {
      setState(() => _isGeneratingMono = true);
      final tmpDir = await getTemporaryDirectory();
      final outPath = '${tmpDir.path}/mono_player_${_current!.id}.wav';
      final ok = await AudioAnalysisService.writeMonoWavFile(filePath, outPath);
      if (!mounted) return;
      if (!ok) {
        final ch = await AudioAnalysisService.getChannelCount(filePath);
        if (!mounted) return;
        if (ch == 1) {
          setState(() { _monoFilePath = filePath; _isGeneratingMono = false; });
        } else {
          setState(() => _isGeneratingMono = false);
          return;
        }
      } else {
        setState(() { _monoFilePath = outPath; _isGeneratingMono = false; });
      }
    }
    final wasPlaying = _isPlaying;
    final savedPos = _position;
    setState(() => _isMono = newMono);
    try {
      if (wasPlaying) {
        await _player.play(DeviceFileSource(_activePath), position: savedPos);
      } else {
        await _player.setSource(DeviceFileSource(_activePath));
        if (savedPos > Duration.zero) await _player.seek(savedPos);
      }
    } catch (_) {}
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final allProjects = ref.watch(allProjectsStreamProvider).value ?? [];
    // Build / refresh track list reactively
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildTrackList(allProjects));

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        // ── Left: track list ──────────────────────────────────────────────
        SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.headphones, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text('Music Player',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${_tracks.length} tracks',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        )),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _tracks.isEmpty
                    ? Center(
                        child: Text(
                          'No preview songs found.\nOpen a project and set a preview song.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _tracks.length,
                        itemBuilder: (context, i) {
                          final track = _tracks[i];
                          final selected = i == _currentIndex;
                          return ListTile(
                            dense: true,
                            selected: selected,
                            selectedTileColor: cs.primary.withValues(alpha: 0.1),
                            leading: Icon(
                              selected && _isPlaying
                                  ? Icons.volume_up
                                  : Icons.music_note,
                              size: 18,
                              color: selected ? cs.primary : null,
                            ),
                            title: Text(
                              track.displayName,
                              style: TextStyle(
                                fontWeight: selected ? FontWeight.w600 : null,
                                color: selected ? cs.primary : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              p.basename(_resolvedPath(track) ?? ''),
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            onTap: () => _selectTrack(i),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // ── Right: player ─────────────────────────────────────────────────
        Expanded(
          child: _current == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.headphones, size: 64,
                          color: cs.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text('Select a track to start playing',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.4),
                          )),
                    ],
                  ),
                )
              : _buildPlayer(context),
        ),
      ],
    );
  }

  Widget _buildPlayer(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final track = _current!;
    final filePath = _resolvedPath(track)!;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final ext = filePath.toLowerCase().split('.').last;
    final formatLabel = switch (ext) {
      'wav' => 'WAV', 'mp3' => 'MP3', 'flac' => 'FLAC',
      'aif' || 'aiff' => 'AIFF', 'ogg' => 'OGG',
      'aac' => 'AAC', 'm4a' => 'M4A',
      _ => ext.toUpperCase(),
    };
    final infoParts = <String>[];
    if (_fileInfo != null) {
      final sr = _fileInfo!.sampleRate;
      infoParts.add(sr % 1000 == 0 ? '${sr ~/ 1000}kHz' : '${(sr / 1000).toStringAsFixed(1)}kHz');
      if (_fileInfo!.bitDepth != null) {
        infoParts.add('${_fileInfo!.bitDepth}-bit');
      } else if (_fileInfo!.bitrateKbps != null) {
        infoParts.add('${_fileInfo!.bitrateKbps}kbps');
      }
      infoParts.add(_fileInfo!.channels == 1 ? 'Mono' : _fileInfo!.channels == 2 ? 'Stereo' : '${_fileInfo!.channels}ch');
    }
    infoParts.add(formatLabel);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Track title + file info
          Row(
            children: [
              Icon(Icons.music_note, size: 20, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.displayName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                    Text(p.basename(filePath),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(infoParts.join(' · '),
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.5))),
            ],
          ),
          const SizedBox(height: 20),
          // Waveform
          SizedBox(
            height: 120,
            child: WaveformWidget(
              peaks: _peaks,
              progress: progress,
              height: 120,
              onSeek: (p) {
                if (_duration > Duration.zero) {
                  _player.seek(Duration(
                    milliseconds: (p * _duration.inMilliseconds).round(),
                  ));
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          // Time row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 44,
                child: Text(_fmt(_position),
                    style: theme.textTheme.bodySmall),
              ),
              Text(_fmt(_duration),
                  style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          // Transport controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 28,
                  onPressed: _tracks.length > 1 ? _playPrev : null),
              Tooltip(
                  message: Platform.isMacOS ? '−5s  (←)  •  ⌘+← −30s' : '−5s  (←)  •  Ctrl+← −30s',
                  child: IconButton(
                      icon: const Icon(Icons.replay_5),
                      iconSize: 24,
                      onPressed: () => _seek(-5))),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(_isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled),
                iconSize: 52,
                color: cs.primary,
                onPressed: _togglePlayPause,
              ),
              const SizedBox(width: 8),
              IconButton(
                  icon: const Icon(Icons.stop_circle_outlined),
                  iconSize: 26,
                  onPressed: _isPlaying || _position > Duration.zero
                      ? _stop
                      : null),
              Tooltip(
                  message: Platform.isMacOS ? '+5s  (→)  •  ⌘+→ +30s' : '+5s  (→)  •  Ctrl+→ +30s',
                  child: IconButton(
                      icon: const Icon(Icons.forward_5),
                      iconSize: 24,
                      onPressed: () => _seek(5))),
              IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 28,
                  onPressed: _tracks.length > 1 ? _playNext : null),
            ],
          ),
          const SizedBox(height: 12),
          // Volume + mono row
          Row(
            children: [
              Icon(
                _volume == 0
                    ? Icons.volume_off
                    : (_volume < 0.5 ? Icons.volume_down : Icons.volume_up),
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
              SizedBox(
                width: 160,
                child: Slider(
                  value: _volume, min: 0, max: 1,
                  onChanged: (v) {
                    setState(() => _volume = v);
                    _player.setVolume(v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              if (_supportsMonoMix(filePath))
                _isGeneratingMono
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : FilterChip(
                        label: Text('Mono',
                            style: TextStyle(
                                fontSize: 12,
                                color: _isMono ? Colors.red : null,
                                fontWeight: _isMono ? FontWeight.bold : null)),
                        selected: _isMono,
                        showCheckmark: true,
                        selectedColor: Colors.red.withValues(alpha: 0.15),
                        onSelected: (_) => _toggleMono(),
                        visualDensity: VisualDensity.compact,
                      ),
            ],
          ),
        ],
      ),
    );
  }
}

