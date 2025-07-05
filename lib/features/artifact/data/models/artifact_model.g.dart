// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artifact_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArtifactModelAdapter extends TypeAdapter<ArtifactModel> {
  @override
  final int typeId = 0;

  @override
  ArtifactModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ArtifactModel(
      id: fields[0] as String,
      name: fields[1] as String,
      path: fields[2] as String,
      type: fields[3] as ArtifactType,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ArtifactModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ArtifactTypeAdapter extends TypeAdapter<ArtifactType> {
  @override
  final int typeId = 1;

  @override
  ArtifactType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ArtifactType.image;
      case 1:
        return ArtifactType.document;
      case 2:
        return ArtifactType.video;
      default:
        return ArtifactType.image;
    }
  }

  @override
  void write(BinaryWriter writer, ArtifactType obj) {
    switch (obj) {
      case ArtifactType.image:
        writer.writeByte(0);
        break;
      case ArtifactType.document:
        writer.writeByte(1);
        break;
      case ArtifactType.video:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
