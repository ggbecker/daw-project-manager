import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/providers.dart';

void main() {
  group('ShowHiddenProjectsNotifier', () {
    test('defaults to 0 (show only visible)', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      expect(c.read(showHiddenProjectsProvider), 0);
    });

    test('setShowAll(true) sets state to 1 synchronously', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c.read(showHiddenProjectsProvider.notifier).setShowAll(true);

      expect(c.read(showHiddenProjectsProvider), 1);
    });

    test('setShowOnlyHidden(true) sets state to 2 synchronously', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c.read(showHiddenProjectsProvider.notifier).setShowOnlyHidden(true);

      expect(c.read(showHiddenProjectsProvider), 2);
    });

    test('setShowOnlyHidden(false) resets state to 0', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(showHiddenProjectsProvider.notifier);

      notifier.setShowOnlyHidden(true);
      notifier.setShowOnlyHidden(false);

      expect(c.read(showHiddenProjectsProvider), 0);
    });

    test(
        'a fresh container ("app restart") always starts at 0, regardless '
        'of what a previous container left the state at — this setting is '
        'intentionally session-only, not persisted', () {
      final first = ProviderContainer();
      first.read(showHiddenProjectsProvider.notifier).setShowOnlyHidden(true);
      expect(first.read(showHiddenProjectsProvider), 2);
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);
      expect(second.read(showHiddenProjectsProvider), 0);
    });
  });
}
