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

    group('selectRange', () {
      const ordered = ['a', 'b', 'c', 'd', 'e'];

      test('selects every id between anchor and target when target is after anchor', () {
        final c = ProviderContainer();
        addTearDown(c.dispose);
        final notifier = c.read(selectedProjectsProvider.notifier);

        notifier.selectRange(ordered, 'b', 'd');

        expect(c.read(selectedProjectsProvider), {'b', 'c', 'd'});
      });

      test('selects every id between target and anchor when target is before anchor', () {
        final c = ProviderContainer();
        addTearDown(c.dispose);
        final notifier = c.read(selectedProjectsProvider.notifier);

        notifier.selectRange(ordered, 'd', 'b');

        expect(c.read(selectedProjectsProvider), {'b', 'c', 'd'});
      });

      test('adds the range to the existing selection rather than replacing it', () {
        // Regression: a second shift-click range starting from a new anchor
        // used to wipe out an earlier, unrelated range selection. Both
        // ranges should survive.
        final c = ProviderContainer();
        addTearDown(c.dispose);
        final notifier = c.read(selectedProjectsProvider.notifier);

        notifier.addAll(['e']);
        notifier.selectRange(ordered, 'a', 'b');

        expect(c.read(selectedProjectsProvider), {'a', 'b', 'e'});
      });

      test('preserves an earlier shift-click range when a later one is made elsewhere', () {
        final c = ProviderContainer();
        addTearDown(c.dispose);
        final notifier = c.read(selectedProjectsProvider.notifier);
        const extended = ['a', 'b', 'c', 'd', 'e', 'f', 'g'];

        notifier.selectRange(extended, 'a', 'c'); // {a, b, c}
        notifier.toggle('e'); // individually select a new anchor: {a, b, c, e}
        notifier.selectRange(extended, 'e', 'g'); // {a, b, c, e, f, g}

        expect(c.read(selectedProjectsProvider), {'a', 'b', 'c', 'e', 'f', 'g'});
      });

      test('anchor equal to target selects just that one id', () {
        final c = ProviderContainer();
        addTearDown(c.dispose);
        final notifier = c.read(selectedProjectsProvider.notifier);

        notifier.selectRange(ordered, 'c', 'c');

        expect(c.read(selectedProjectsProvider), {'c'});
      });

      test('falls back to toggling target when anchor is not in orderedIds', () {
        final c = ProviderContainer();
        addTearDown(c.dispose);
        final notifier = c.read(selectedProjectsProvider.notifier);

        notifier.selectRange(ordered, 'not-in-list', 'c');

        expect(c.read(selectedProjectsProvider), {'c'});
      });

      test('falls back to toggling target when target is not in orderedIds', () {
        final c = ProviderContainer();
        addTearDown(c.dispose);
        final notifier = c.read(selectedProjectsProvider.notifier);

        notifier.selectRange(ordered, 'a', 'not-in-list');

        expect(c.read(selectedProjectsProvider), {'not-in-list'});
      });
    });
  });
}
