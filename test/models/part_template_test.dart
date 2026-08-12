import 'dart:io';

import 'package:daw_project_manager/models/part_template.dart';
import 'package:daw_project_manager/models/project_part.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../helpers/hive_test_helper.dart';

void main() {
  PartTemplate makeTemplate({
    String id = 'pt-1',
    String name = 'Band Lineup',
    List<ProjectPart>? items,
  }) {
    return PartTemplate(
      id: id,
      name: name,
      items: items ??
          [
            const ProjectPart(id: 'i1', name: 'Drums', performer: 'Alex'),
            const ProjectPart(id: 'i2', name: 'Bass', performer: 'Sam'),
          ],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );
  }

  group('PartTemplate.parseItems', () {
    test('reads a bare instrument name with no performer', () {
      final items = PartTemplate.parseItems('Drums');
      expect(items.single.name, 'Drums');
      expect(items.single.performer, isNull);
    });

    test('splits a performer off after an em dash, en dash or hyphen', () {
      final items = PartTemplate.parseItems(
        'Drums — Alex\nBass – Sam\nGuitar - Jules',
      );

      expect(items.map((i) => i.name), ['Drums', 'Bass', 'Guitar']);
      expect(items.map((i) => i.performer), ['Alex', 'Sam', 'Jules']);
    });

    test('keeps hyphenated instrument names intact', () {
      // The separator must be surrounded by spaces, otherwise "Hi-Hat" would
      // be read as the part "Hi" played by "Hat".
      final items = PartTemplate.parseItems('Hi-Hat\nSub-Bass — Sam');

      expect(items.first.name, 'Hi-Hat');
      expect(items.first.performer, isNull);
      expect(items.last.name, 'Sub-Bass');
      expect(items.last.performer, 'Sam');
    });

    test('drops blank lines and lines with no part name', () {
      final items = PartTemplate.parseItems('Drums\n\n   \n — Alex\nBass');
      expect(items.map((i) => i.name), ['Drums', 'Bass']);
    });

    test('treats a trailing separator with no performer as unassigned', () {
      final items = PartTemplate.parseItems('Drums — ');
      expect(items.single.name, 'Drums');
      expect(items.single.performer, isNull);
    });

    test('gives every parsed item a distinct id', () {
      final items = PartTemplate.parseItems('Drums\nBass\nGuitar');
      expect(items.map((i) => i.id).toSet().length, 3);
    });

    test('defaults every parsed item to the needed status', () {
      final items = PartTemplate.parseItems('Drums — Alex');
      expect(items.single.status, PartTakeStatus.needed);
    });
  });

  group('PartTemplate.formatItems', () {
    test('round-trips through parseItems', () {
      const text = 'Drums — Alex\nBass — Sam\nLead Vocals';
      expect(PartTemplate.formatItems(PartTemplate.parseItems(text)), text);
    });

    test('omits the separator for unassigned parts', () {
      final text = PartTemplate.formatItems(
        [const ProjectPart(id: 'i1', name: 'Synth Pads')],
      );
      expect(text, 'Synth Pads');
    });
  });

  group('PartTemplate.instantiate', () {
    test('issues fresh ids so two projects never share a part id', () {
      final template = makeTemplate();
      final first = template.instantiate();
      final second = template.instantiate();

      expect(first.map((p) => p.id).toSet().intersection(
            second.map((p) => p.id).toSet(),
          ),
          isEmpty);
      expect(
        first.map((p) => p.id).toSet().intersection(
              template.items.map((p) => p.id).toSet(),
            ),
        isEmpty,
      );
    });

    test('carries over the name, performer and status of each item', () {
      final template = makeTemplate(items: [
        const ProjectPart(
          id: 'i1',
          name: 'Lead Vocals',
          performer: 'Nina',
          status: PartTakeStatus.earlyTake,
          notes: 'double-track',
        ),
      ]);

      final part = template.instantiate().single;

      expect(part.name, 'Lead Vocals');
      expect(part.performer, 'Nina');
      expect(part.status, PartTakeStatus.earlyTake);
      expect(part.notes, 'double-track');
    });
  });

  group('PartTemplate JSON', () {
    test('round-trips name, timestamps and items', () {
      final template = makeTemplate();
      final restored = PartTemplate.fromJson(template.toJson());

      expect(restored.id, template.id);
      expect(restored.name, template.name);
      expect(restored.createdAt, template.createdAt);
      expect(restored.updatedAt, template.updatedAt);
      expect(restored.items, template.items);
    });

    test('tolerates a template with no items key', () {
      final restored = PartTemplate.fromJson({
        'id': 'pt-1',
        'name': 'Empty',
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      });
      expect(restored.items, isEmpty);
    });
  });

  group('PartTemplateAdapter (Hive round-trip)', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await HiveTestHelper.setUp();
    });

    tearDown(() async {
      await HiveTestHelper.tearDown(tempDir);
    });

    test('preserves the template and its nested parts', () async {
      final template = makeTemplate();
      final box = await Hive.openBox<PartTemplate>('part_template_round_trip');
      await box.put(template.id, template);
      final restored = box.get(template.id)!;

      expect(restored.name, 'Band Lineup');
      expect(restored.updatedAt, template.updatedAt);
      expect(restored.items.map((i) => i.name), ['Drums', 'Bass']);
      expect(restored.items.map((i) => i.performer), ['Alex', 'Sam']);
    });
  });
}
