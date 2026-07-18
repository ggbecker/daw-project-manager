import 'dart:async';
import 'dart:io';

import '../models/scan_root.dart';

/// Watches configured scan-root directories for filesystem activity and
/// emits the root path after a quiet period, so callers can run a light,
/// targeted rescan of just that root instead of a full rescan of every root.
class FolderWatcherService {
  FolderWatcherService({this.debounce = const Duration(seconds: 2)});

  final Duration debounce;
  final _subscriptions = <String, StreamSubscription<FileSystemEvent>>{};
  final _timers = <String, Timer>{};
  final _controller = StreamController<String>.broadcast();

  /// Emits a scan root path whenever activity under it has settled.
  Stream<String> get changes => _controller.stream;

  /// Starts/stops watchers so the watched set matches [roots] exactly.
  /// Safe to call repeatedly (e.g. every time scan roots change).
  void syncRoots(List<ScanRoot> roots) {
    final desired = {for (final r in roots) r.path: r};

    for (final path in _subscriptions.keys.toList()) {
      if (!desired.containsKey(path)) _stopWatching(path);
    }
    for (final path in desired.keys) {
      if (!_subscriptions.containsKey(path)) _startWatching(path);
    }
  }

  void _startWatching(String rootPath) {
    if (!Directory(rootPath).existsSync()) return;
    try {
      final sub = Directory(rootPath).watch(recursive: true).listen(
            (_) => _scheduleEmit(rootPath),
            onError: (_) => _stopWatching(rootPath),
          );
      _subscriptions[rootPath] = sub;
    } catch (_) {
      // Directory.watch throws synchronously on some unsupported paths
      // (e.g. certain network drives). Leave it uncovered by the watcher —
      // manual/periodic rescan still finds new files there.
    }
  }

  void _stopWatching(String rootPath) {
    _subscriptions.remove(rootPath)?.cancel();
    _timers.remove(rootPath)?.cancel();
  }

  void _scheduleEmit(String rootPath) {
    _timers[rootPath]?.cancel();
    _timers[rootPath] = Timer(debounce, () {
      _timers.remove(rootPath);
      if (!_controller.isClosed) _controller.add(rootPath);
    });
  }

  Future<void> dispose() async {
    for (final sub in _subscriptions.values) {
      await sub.cancel();
    }
    _subscriptions.clear();
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    await _controller.close();
  }
}
