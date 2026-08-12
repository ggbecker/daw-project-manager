import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import 'project_part.dart';

const _uuid = Uuid();

/// A reusable lineup — the set of parts a band or a genre of track always
/// needs — so the same instrument list doesn't have to be re-typed per song.
///
/// Global (not per-profile), stored in the `partTemplates` box, mirroring
/// [TodoTemplate]'s pattern.
@HiveType(typeId: 15)
class PartTemplate extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  /// The parts to seed a project with. Each item's [ProjectPart.id] is a
  /// template-local id; [instantiate] issues fresh ones on import so two
  /// projects created from one template never share part ids.
  @HiveField(2)
  final List<ProjectPart> items;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  PartTemplate({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  PartTemplate copyWith({
    String? id,
    String? name,
    List<ProjectPart>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PartTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Fresh [ProjectPart]s for a project, with new ids and the template's
  /// performers/notes carried over.
  List<ProjectPart> instantiate() =>
      items.map((item) => item.copyWith(id: _uuid.v4())).toList();

  /// Parses the "one part per line" text the template editor collects.
  ///
  /// A line may name a performer after an em dash, en dash or hyphen:
  ///   `Drums — Alex`, `Bass - Sam`, `Lead Vocals`
  /// Blank lines, and lines that are only a separator, are dropped. The dash
  /// must sit at a word boundary (space, start or end of line) so hyphenated
  /// instrument names ("Hi-Hat", "Sub-Bass") stay intact.
  static List<ProjectPart> parseItems(String text) {
    final separator = RegExp(r'(?:^|\s)[—–-](?:\s|$)');
    final parts = <ProjectPart>[];
    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final match = separator.firstMatch(line);
      final name = (match == null ? line : line.substring(0, match.start)).trim();
      if (name.isEmpty) continue;
      final performer =
          match == null ? null : line.substring(match.end).trim();
      parts.add(ProjectPart(
        id: _uuid.v4(),
        name: name,
        performer: (performer == null || performer.isEmpty) ? null : performer,
      ));
    }
    return parts;
  }

  /// The inverse of [parseItems] — what the editor shows when reopening a
  /// template.
  static String formatItems(List<ProjectPart> items) => items
      .map((i) => (i.performer == null || i.performer!.isEmpty)
          ? i.name
          : '${i.name} — ${i.performer}')
      .join('\n');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((i) => i.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PartTemplate.fromJson(Map<String, dynamic> json) {
    return PartTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((i) => ProjectPart.fromJson(i as Map<dynamic, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class PartTemplateAdapter extends TypeAdapter<PartTemplate> {
  @override
  final int typeId = 15;

  @override
  PartTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return PartTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      items: fields[2] == null
          ? const []
          : (fields[2] as List).cast<ProjectPart>(),
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PartTemplate obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }
}
