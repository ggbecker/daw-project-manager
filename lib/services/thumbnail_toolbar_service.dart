import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What the Windows taskbar thumbnail toolbar should be showing.
///
/// When [visible] is false the toolbar is hidden entirely, and [isPlaying]
/// is forced to false so that "hidden while playing" and "hidden while
/// paused" compare equal — otherwise a pause that happens during teardown
/// would look like a state change and push a redundant native call.
@immutable
class ThumbnailToolbarState {
  const ThumbnailToolbarState._(this.visible, this.isPlaying);

  factory ThumbnailToolbarState({
    required bool visible,
    required bool isPlaying,
  }) => visible ? ThumbnailToolbarState._(true, isPlaying) : hidden;

  /// No track loaded — the toolbar is not shown at all.
  static const ThumbnailToolbarState hidden = ThumbnailToolbarState._(
    false,
    false,
  );

  final bool visible;
  final bool isPlaying;

  @override
  bool operator ==(Object other) =>
      other is ThumbnailToolbarState &&
      other.visible == visible &&
      other.isPlaying == isPlaying;

  @override
  int get hashCode => Object.hash(visible, isPlaying);

  @override
  String toString() =>
      'ThumbnailToolbarState(visible: $visible, isPlaying: $isPlaying)';
}

/// Resolves the .ico path for the play/pause button, or null when the icons
/// have not been written to disk yet.
typedef ThumbnailIconResolver = String? Function(bool isPlaying);

/// Kill switch for the taskbar hover-preview play/pause button.
///
/// **Currently off (2026-08-17), deliberately and temporarily.**
///
/// Windows 11's XAML taskbar (`Taskbar.View.dll`) crashes explorer.exe with a
/// stowed WinRT exception, taking the user's whole shell down. On the machine
/// where this was investigated it had crashed 11 times in 30 days — at an
/// identical fault offset, across two versions of that DLL, most of them with
/// this app nowhere near it, and it is widely reported against unrelated
/// software too. We cannot fix code inside the shell, and #120's handle-leak
/// fixes did not stop it.
///
/// So we stop poking it. This button is a small convenience whose worst case
/// is the user losing their desktop — a trade that does not favour shipping it
/// on by default while the shell is this fragile.
///
/// Turning it back on is this one line. Nothing else was removed: the
/// controller, its tests, the icon generation and the click handler are all
/// intact. Before flipping it, check whether the shell crash is still
/// reproducible on current Windows — see #119.
///
/// The taskbar *overlay* icon (work-session badge) and *progress* bar are
/// separate APIs and are untouched. If shell crashes continue with this off,
/// they are the next things to suspect.
const bool kThumbnailToolbarEnabled = false;

/// Pushes [ThumbnailToolbarState] to the Windows shell, coalescing bursts and
/// skipping pushes that would not change what the shell is already showing.
///
/// Both matter for stability, not just efficiency. Every `SetThumbnailToolbar`
/// call leaks an `HICON` inside the plugin's native code (`LoadImage` without a
/// matching `DestroyIcon` — `ImageList_AddIcon` copies the icon), so the number
/// of calls is a direct multiplier on a USER-object leak. And the shell renders
/// the toolbar asynchronously from another process (explorer.exe), so a rapid
/// Reset→Set burst — which is exactly what switching between the dashboard
/// preview player and a detail-page player produced — hands the shell several
/// button sets in the time it takes to paint one.
///
/// See issue #119.
class ThumbnailToolbarController {
  ThumbnailToolbarController({
    required MethodChannel channel,
    required ThumbnailIconResolver resolveIcon,
    Duration debounce = const Duration(milliseconds: 120),
    bool enabled = true,
  }) : _channel = channel,
       _resolveIcon = resolveIcon,
       _debounce = debounce,
       _enabled = enabled;

  final MethodChannel _channel;
  final ThumbnailIconResolver _resolveIcon;
  final Duration _debounce;

  /// When false, [update] never touches the channel. See
  /// [kThumbnailToolbarEnabled] — the guard lives here as well as at the call
  /// site so a future caller cannot re-enable the shell calls by accident.
  final bool _enabled;

  /// The last state actually handed to the shell. Null means "unknown" — the
  /// next update pushes unconditionally.
  ThumbnailToolbarState? _lastPushed;
  ThumbnailToolbarState? _pending;
  Timer? _timer;

  /// Number of native calls made. Test-only; the point of this class is that
  /// this number stays small.
  @visibleForTesting
  int nativeCallCount = 0;

  /// Requests that the toolbar show [next].
  ///
  /// Returns without touching the channel when [next] is already on screen.
  /// Otherwise the push is deferred by the debounce interval, so a burst of
  /// changes collapses into a single native call carrying the final state.
  void update(ThumbnailToolbarState next) {
    if (!_enabled) return;
    if (next == _lastPushed) {
      // Already showing this. Drop any queued push — a burst that ends back
      // where it started should not touch the shell at all.
      _pending = null;
      _timer?.cancel();
      _timer = null;
      return;
    }
    _pending = next;
    _timer?.cancel();
    _timer = Timer(_debounce, _flush);
  }

  Future<void> _flush() async {
    _timer = null;
    final next = _pending;
    _pending = null;
    if (next == null || next == _lastPushed) return;

    // Recorded before awaiting so a second flush overlapping this one cannot
    // push the same state twice.
    _lastPushed = next;
    nativeCallCount++;
    try {
      if (!next.visible) {
        await _channel.invokeMethod<void>(
          'ResetThumbnailToolbar',
          <String, Object?>{},
        );
        return;
      }
      final icon = _resolveIcon(next.isPlaying);
      if (icon == null) {
        // Icons are written at startup; if they are not there yet, forget the
        // state so the next change retries rather than deduping against a
        // push that never happened.
        _lastPushed = null;
        nativeCallCount--;
        return;
      }
      await _channel.invokeMethod<void>('SetThumbnailToolbar', <String, Object?>{
        'buttons': [
          {
            'icon': icon,
            'tooltip': next.isPlaying ? 'Pause' : 'Play',
            'mode': 0,
          },
        ],
      });
    } catch (e) {
      // Failed pushes must not be remembered as on-screen, or the toolbar
      // stays stale until the state happens to change twice.
      _lastPushed = null;
      if (kDebugMode) {
        debugPrint('[ThumbnailToolbar] push failed for $next: $e');
      }
    }
  }

  /// Flushes any pending push immediately. Test-only.
  @visibleForTesting
  Future<void> flushForTest() async {
    _timer?.cancel();
    await _flush();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }
}
