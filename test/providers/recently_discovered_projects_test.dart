import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/providers.dart';

void main() {
  group('RecentlyDiscoveredProjectsNotifier', () {
    test('defaults to an empty set', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      expect(c.read(recentlyDiscoveredProjectsProvider), isEmpty);
    });

    test('addAll merges ids into state without dropping existing ones', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(recentlyDiscoveredProjectsProvider.notifier);

      notifier.addAll(['a', 'b']);
      notifier.addAll(['b', 'c']);

      expect(c.read(recentlyDiscoveredProjectsProvider), {'a', 'b', 'c'});
    });

    test('dismiss removes a single id and leaves the rest untouched', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(recentlyDiscoveredProjectsProvider.notifier);

      notifier.addAll(['a', 'b']);
      notifier.dismiss('a');

      expect(c.read(recentlyDiscoveredProjectsProvider), {'b'});
    });

    test('dismissing an id that was never added is a no-op', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(recentlyDiscoveredProjectsProvider.notifier);

      notifier.addAll(['a']);
      notifier.dismiss('does-not-exist');

      expect(c.read(recentlyDiscoveredProjectsProvider), {'a'});
    });

    test(
        'a fresh container ("app restart") always starts empty, regardless '
        'of what a previous container found — this is intentionally '
        'session-only, not persisted', () {
      final first = ProviderContainer();
      first.read(recentlyDiscoveredProjectsProvider.notifier).addAll(['a']);
      expect(first.read(recentlyDiscoveredProjectsProvider), {'a'});
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);
      expect(second.read(recentlyDiscoveredProjectsProvider), isEmpty);
    });
  });
}
