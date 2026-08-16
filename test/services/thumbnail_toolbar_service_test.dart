import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/thumbnail_toolbar_service.dart';

/// Regression tests for #119 — Windows Explorer crashed when switching from
/// the dashboard preview player to a detail-page player.
///
/// The trigger was volume: the toolbar was pushed to the shell on every change
/// of two providers that always change together, so one user action produced
/// several native calls, each one leaking an HICON and handing explorer.exe a
/// fresh button set while it was still painting the previous one.
///
/// These tests pin the two properties that keep that volume down: identical
/// state is never pushed, and a burst collapses to a single push of the final
/// state.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.alexmercerind/windows_taskbar');

  late List<MethodCall> calls;
  late ThumbnailToolbarController controller;

  /// Fails the call with a PlatformException when set — mirrors the plugin
  /// returning result->Error (e.g. the window is hidden to tray).
  bool failNextCalls = false;

  ThumbnailToolbarController makeController({
    String? Function(bool isPlaying)? resolveIcon,
  }) => ThumbnailToolbarController(
    channel: channel,
    resolveIcon: resolveIcon ?? (isPlaying) => isPlaying ? 'pause.ico' : 'play.ico',
    // Zero keeps the tests fast and deterministic: the Timer still defers the
    // push to a later event-loop turn, so coalescing is exercised exactly as
    // it is in production, but a single `await` flushes it.
    debounce: Duration.zero,
  );

  /// Lets the debounce timer fire.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    calls = [];
    failNextCalls = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (failNextCalls) {
            throw PlatformException(code: '-1', message: 'mock failure');
          }
          return null;
        });
    controller = makeController();
  });

  tearDown(() {
    controller.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('ThumbnailToolbarState', () {
    test('hidden states compare equal regardless of isPlaying', () {
      // Teardown order can report "not visible but still playing"; that must
      // not read as a state change, or it pushes a redundant Reset.
      expect(
        ThumbnailToolbarState(visible: false, isPlaying: true),
        ThumbnailToolbarState(visible: false, isPlaying: false),
      );
    });

    test('visible states differ by isPlaying', () {
      expect(
        ThumbnailToolbarState(visible: true, isPlaying: true),
        isNot(ThumbnailToolbarState(visible: true, isPlaying: false)),
      );
    });
  });

  group('deduplication', () {
    test('pushes the first state', () async {
      controller.update(ThumbnailToolbarState(visible: true, isPlaying: true));
      await settle();

      expect(calls, hasLength(1));
      expect(calls.single.method, 'SetThumbnailToolbar');
      expect(controller.nativeCallCount, 1);
    });

    test('does not push a state that is already on screen', () async {
      controller.update(ThumbnailToolbarState(visible: true, isPlaying: true));
      await settle();
      calls.clear();

      // The old code called the channel again here — this is the leak driver.
      for (var i = 0; i < 10; i++) {
        controller.update(ThumbnailToolbarState(visible: true, isPlaying: true));
        await settle();
      }

      expect(calls, isEmpty);
      expect(controller.nativeCallCount, 1);
    });

    test('pushes again once the state actually changes', () async {
      controller.update(ThumbnailToolbarState(visible: true, isPlaying: true));
      await settle();
      controller.update(ThumbnailToolbarState(visible: true, isPlaying: false));
      await settle();

      expect(calls, hasLength(2));
      expect(
        (calls.last.arguments['buttons'] as List).single['tooltip'],
        'Play',
      );
    });

    test('hiding pushes Reset, and only once', () async {
      controller.update(ThumbnailToolbarState(visible: true, isPlaying: true));
      await settle();
      calls.clear();

      controller.update(ThumbnailToolbarState.hidden);
      await settle();
      controller.update(ThumbnailToolbarState.hidden);
      await settle();

      expect(calls, hasLength(1));
      expect(calls.single.method, 'ResetThumbnailToolbar');
    });
  });

  group('burst coalescing', () {
    test(
      'switching players collapses to one push of the final state',
      () async {
        // The exact #119 sequence: playing in the dashboard preview player,
        // then pressing play on a detail page, which closes the dashboard
        // player (visible -> false) and flips isPlaying to false. Previously
        // this was four native calls in a few milliseconds.
        controller.update(
          ThumbnailToolbarState(visible: true, isPlaying: true),
        );
        await settle();
        calls.clear();

        controller.update(
          ThumbnailToolbarState(visible: true, isPlaying: false),
        );
        controller.update(ThumbnailToolbarState.hidden);
        controller.update(ThumbnailToolbarState.hidden);
        await settle();

        expect(calls, hasLength(1));
        expect(calls.single.method, 'ResetThumbnailToolbar');
      },
    );

    test('a burst returning to the on-screen state pushes nothing', () async {
      controller.update(ThumbnailToolbarState(visible: true, isPlaying: true));
      await settle();
      calls.clear();

      controller.update(ThumbnailToolbarState(visible: true, isPlaying: false));
      controller.update(ThumbnailToolbarState.hidden);
      controller.update(ThumbnailToolbarState(visible: true, isPlaying: true));
      await settle();

      expect(calls, isEmpty);
    });
  });

  group('kill switch', () {
    // #119: Windows 11's XAML taskbar crashes explorer.exe, and this button is
    // not worth the user's shell. The feature is off; these pin that the guard
    // actually prevents shell calls rather than merely hiding the button.
    test('a disabled controller never touches the channel', () async {
      controller.dispose();
      controller = ThumbnailToolbarController(
        channel: channel,
        resolveIcon: (isPlaying) => 'play.ico',
        debounce: Duration.zero,
        enabled: false,
      );

      controller.update(ThumbnailToolbarState(visible: true, isPlaying: true));
      controller.update(ThumbnailToolbarState(visible: true, isPlaying: false));
      controller.update(ThumbnailToolbarState.hidden);
      await settle();

      expect(calls, isEmpty);
      expect(controller.nativeCallCount, 0);
    });

    test('the shipped default is off', () {
      // Deliberate: flipping this back on is a decision that needs #119
      // re-checked against current Windows, not something to do casually.
      expect(kThumbnailToolbarEnabled, isFalse);
    });
  });

  group('failure handling', () {
    test('a failed push is retried on the next change', () async {
      failNextCalls = true;
      controller.update(ThumbnailToolbarState(visible: true, isPlaying: true));
      await settle();
      expect(calls, hasLength(1));

      // Same state again: because the push failed, it is not on screen, so it
      // must not be deduped away.
      failNextCalls = false;
      calls.clear();
      controller.update(ThumbnailToolbarState(visible: true, isPlaying: true));
      await settle();

      expect(calls, hasLength(1));
    });

    test('nothing is pushed before the icons exist, and it retries', () async {
      controller.dispose();
      var iconsReady = false;
      controller = makeController(
        resolveIcon: (isPlaying) => iconsReady ? 'play.ico' : null,
      );

      controller.update(ThumbnailToolbarState(visible: true, isPlaying: false));
      await settle();
      expect(calls, isEmpty);
      expect(controller.nativeCallCount, 0);

      iconsReady = true;
      controller.update(ThumbnailToolbarState(visible: true, isPlaying: false));
      await settle();
      expect(calls, hasLength(1));
    });
  });
}
