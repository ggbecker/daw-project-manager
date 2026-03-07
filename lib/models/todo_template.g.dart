// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TodoTemplateAdapter extends TypeAdapter<TodoTemplate> {
  @override
  final typeId = 9;

  @override
  TodoTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TodoTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      items: (fields[2] as List).cast<String>(),
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TodoTemplate obj) {
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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
