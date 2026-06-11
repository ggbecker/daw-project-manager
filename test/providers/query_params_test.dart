import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/providers/providers.dart';

void main() {
  group('QueryParamsNotifier', () {
    test('initial state has empty searchText', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(queryParamsNotifierProvider).searchText, '');
    });

    test('initial state has sortDesc = true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(queryParamsNotifierProvider).sortDesc, isTrue);
    });

    test('setSearchText updates searchText', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(queryParamsNotifierProvider.notifier).setSearchText('my track');
      expect(container.read(queryParamsNotifierProvider).searchText, 'my track');
    });

    test('setSearchText to empty string clears the search', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(queryParamsNotifierProvider.notifier).setSearchText('hello');
      container.read(queryParamsNotifierProvider.notifier).setSearchText('');
      expect(container.read(queryParamsNotifierProvider).searchText, '');
    });

    test('toggleSortDesc flips sortDesc from true to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(queryParamsNotifierProvider.notifier).toggleSortDesc();
      expect(container.read(queryParamsNotifierProvider).sortDesc, isFalse);
    });

    test('toggleSortDesc flips sortDesc back to true on second call', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(queryParamsNotifierProvider.notifier).toggleSortDesc();
      container.read(queryParamsNotifierProvider.notifier).toggleSortDesc();
      expect(container.read(queryParamsNotifierProvider).sortDesc, isTrue);
    });

    test('setSearchText does not affect sortDesc', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(queryParamsNotifierProvider.notifier).setSearchText('test');
      expect(container.read(queryParamsNotifierProvider).sortDesc, isTrue);
    });

    test('toggleSortDesc does not affect searchText', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(queryParamsNotifierProvider.notifier).setSearchText('test');
      container.read(queryParamsNotifierProvider.notifier).toggleSortDesc();
      expect(container.read(queryParamsNotifierProvider).searchText, 'test');
    });
  });
}
