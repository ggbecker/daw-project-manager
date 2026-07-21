import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/providers.dart';

void main() {
  group('SelectedProjectsNotifier', () {
    test('defaults to an empty set', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      expect(c.read(selectedProjectsProvider), isEmpty);
    });

    test('toggle adds an unselected id and removes a selected one', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(selectedProjectsProvider.notifier);

      notifier.toggle('a');
      expect(c.read(selectedProjectsProvider), {'a'});

      notifier.toggle('a');
      expect(c.read(selectedProjectsProvider), isEmpty);
    });

    test('selectAll replaces the current selection entirely', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(selectedProjectsProvider.notifier);

      notifier.toggle('stale');
      notifier.selectAll(['a', 'b']);

      expect(c.read(selectedProjectsProvider), {'a', 'b'});
    });

    test('addAll merges ids into the selection without dropping existing ones', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(selectedProjectsProvider.notifier);

      notifier.addAll(['a', 'b']);
      notifier.addAll(['b', 'c']);

      expect(c.read(selectedProjectsProvider), {'a', 'b', 'c'});
    });

    test('removeAll clears only the given ids, leaving unrelated selections intact', () {
      // Regression: the per-group checkbox on a smart-folder group needs to
      // deselect just that group's members without wiping out a selection
      // the user made elsewhere in the table (unlike the header "select
      // all", which is a global replace via selectAll()).
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(selectedProjectsProvider.notifier);

      notifier.addAll(['a', 'b', 'unrelated']);
      notifier.removeAll(['a', 'b']);

      expect(c.read(selectedProjectsProvider), {'unrelated'});
    });

    test('removeAll silently ignores ids that were never selected', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(selectedProjectsProvider.notifier);

      notifier.addAll(['a']);
      notifier.removeAll(['a', 'does-not-exist']);

      expect(c.read(selectedProjectsProvider), isEmpty);
    });

    test('clear empties the selection', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(selectedProjectsProvider.notifier);

      notifier.addAll(['a', 'b']);
      notifier.clear();

      expect(c.read(selectedProjectsProvider), isEmpty);
    });
  });
}
