import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/providers.dart';

void main() {
  group('SelectedTemplatesNotifier', () {
    test('defaults to an empty set', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      expect(c.read(selectedTemplatesProvider), isEmpty);
    });

    test('toggle adds an unselected id and removes a selected one', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(selectedTemplatesProvider.notifier);

      notifier.toggle('a');
      expect(c.read(selectedTemplatesProvider), {'a'});

      notifier.toggle('a');
      expect(c.read(selectedTemplatesProvider), isEmpty);
    });

    test('selectAll replaces the current selection entirely', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(selectedTemplatesProvider.notifier);

      notifier.toggle('stale');
      notifier.selectAll(['a', 'b']);

      expect(c.read(selectedTemplatesProvider), {'a', 'b'});
    });

    test('clear empties the selection', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final notifier = c.read(selectedTemplatesProvider.notifier);

      notifier.selectAll(['a', 'b']);
      notifier.clear();

      expect(c.read(selectedTemplatesProvider), isEmpty);
    });

    group('selectRange', () {
      const ordered = ['a', 'b', 'c', 'd', 'e'];

      test('selects every id between anchor and target when target is after anchor', () {
        final c = ProviderContainer();
        addTearDown(c.dispose);
        final notifier = c.read(selectedTemplatesProvider.notifier);

        notifier.selectRange(ordered, 'b', 'd');

        expect(c.read(selectedTemplatesProvider), {'b', 'c', 'd'});
      });

      test('selects every id between target and anchor when target is before anchor', () {
        final c = ProviderContainer();
        addTearDown(c.dispose);
        final notifier = c.read(selectedTemplatesProvider.notifier);

        notifier.selectRange(ordered, 'd', 'b');

        expect(c.read(selectedTemplatesProvider), {'b', 'c', 'd'});
      });

      test('falls back to toggling target when anchor is not in orderedIds', () {
        final c = ProviderContainer();
        addTearDown(c.dispose);
        final notifier = c.read(selectedTemplatesProvider.notifier);

        notifier.selectRange(ordered, 'not-in-list', 'c');

        expect(c.read(selectedTemplatesProvider), {'c'});
      });

      test('adds the range to the existing selection rather than replacing it', () {
        // Regression: a second shift-click range starting from a new anchor
        // used to wipe out an earlier, unrelated range selection. Both
        // ranges should survive.
        final c = ProviderContainer();
        addTearDown(c.dispose);
        final notifier = c.read(selectedTemplatesProvider.notifier);

        notifier.toggle('e');
        notifier.selectRange(ordered, 'a', 'b');

        expect(c.read(selectedTemplatesProvider), {'a', 'b', 'e'});
      });
    });
  });
}
