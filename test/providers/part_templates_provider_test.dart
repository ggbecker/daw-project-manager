import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/models/part_template.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:daw_project_manager/providers/providers.dart';

import '../helpers/hive_test_helper.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
  });

  tearDown(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  PartTemplate makeTemplate({
    String id = 'pt-1',
    String name = 'Band Lineup',
    DateTime? updatedAt,
  }) {
    return PartTemplate(
      id: id,
      name: name,
      items: const [ProjectPart(id: 'i1', name: 'Drums', performer: 'Alex')],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: updatedAt ?? DateTime(2026, 1, 1),
    );
  }

  group('PartTemplatesNotifier', () {
    test('addTemplate persists the template so it can be read back', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(partTemplatesNotifierProvider.notifier)
          .addTemplate(makeTemplate());

      final box = await Hive.openBox<PartTemplate>('partTemplates');
      expect(box.get('pt-1')?.name, 'Band Lineup');
      expect(box.get('pt-1')?.items.single.performer, 'Alex');
    });

    test('updateTemplate overwrites the entry for the same id', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(partTemplatesNotifierProvider.notifier);

      await notifier.addTemplate(makeTemplate());
      await notifier.updateTemplate(makeTemplate().copyWith(name: 'Trio'));

      final box = await Hive.openBox<PartTemplate>('partTemplates');
      expect(box.get('pt-1')?.name, 'Trio');
      expect(box.length, 1);
    });

    test('deleteTemplate removes only the given id', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(partTemplatesNotifierProvider.notifier);

      await notifier.addTemplate(makeTemplate());
      await notifier.addTemplate(makeTemplate(id: 'pt-2', name: 'Duo'));
      await notifier.deleteTemplate('pt-1');

      final box = await Hive.openBox<PartTemplate>('partTemplates');
      expect(box.get('pt-1'), isNull);
      expect(box.get('pt-2')?.name, 'Duo');
    });
  });

  group('partTemplatesProvider', () {
    // Providers are auto-disposed while nothing is listening, and a bare
    // read(...future) would tear the stream down before it emits — so every
    // test here holds a subscription for the duration.
    Future<List<PartTemplate>> readTemplates(ProviderContainer container) {
      container.listen(partTemplatesProvider, (_, _) {});
      return container.read(partTemplatesProvider.future);
    }

    test('emits saved templates most-recently-updated first', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(partTemplatesNotifierProvider.notifier);

      await notifier.addTemplate(
        makeTemplate(id: 'old', name: 'Older', updatedAt: DateTime(2026, 1, 1)),
      );
      await notifier.addTemplate(
        makeTemplate(id: 'new', name: 'Newer', updatedAt: DateTime(2026, 6, 1)),
      );

      final templates = await readTemplates(container);

      expect(templates.map((t) => t.name), ['Newer', 'Older']);
    });

    test('emits an empty list when nothing has been saved', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await readTemplates(container), isEmpty);
    });
  });
}
