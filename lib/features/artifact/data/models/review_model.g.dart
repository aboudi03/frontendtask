// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReviewModelAdapter extends TypeAdapter<ReviewModel> {
  @override
  final int typeId = 2;

  @override
  ReviewModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReviewModel(
      id: fields[0] as String,
      artifactId: fields[1] as String,
      comment: fields[2] as String,
      annotations: (fields[3] as List).cast<DrawingPointModel>(),
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ReviewModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.artifactId)
      ..writeByte(2)
      ..write(obj.comment)
      ..writeByte(3)
      ..write(obj.annotations)
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
      other is ReviewModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DrawingPointModelAdapter extends TypeAdapter<DrawingPointModel> {
  @override
  final int typeId = 3;

  @override
  DrawingPointModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DrawingPointModel(
      dx: fields[0] as double,
      dy: fields[1] as double,
      paint: fields[2] as PaintModel,
      isEraser: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DrawingPointModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.dx)
      ..writeByte(1)
      ..write(obj.dy)
      ..writeByte(2)
      ..write(obj.paint)
      ..writeByte(3)
      ..write(obj.isEraser);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingPointModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaintModelAdapter extends TypeAdapter<PaintModel> {
  @override
  final int typeId = 4;

  @override
  PaintModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaintModel(
      color: fields[0] as int,
      strokeWidth: fields[1] as double,
      style: fields[2] as PaintingStyle,
      strokeCap: fields[3] as StrokeCap,
      strokeJoin: fields[4] as StrokeJoin,
    );
  }

  @override
  void write(BinaryWriter writer, PaintModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.color)
      ..writeByte(1)
      ..write(obj.strokeWidth)
      ..writeByte(2)
      ..write(obj.style)
      ..writeByte(3)
      ..write(obj.strokeCap)
      ..writeByte(4)
      ..write(obj.strokeJoin);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaintModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaintingStyleAdapter extends TypeAdapter<PaintingStyle> {
  @override
  final int typeId = 5;

  @override
  PaintingStyle read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaintingStyle.fill;
      case 1:
        return PaintingStyle.stroke;
      default:
        return PaintingStyle.fill;
    }
  }

  @override
  void write(BinaryWriter writer, PaintingStyle obj) {
    switch (obj) {
      case PaintingStyle.fill:
        writer.writeByte(0);
        break;
      case PaintingStyle.stroke:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaintingStyleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StrokeCapAdapter extends TypeAdapter<StrokeCap> {
  @override
  final int typeId = 6;

  @override
  StrokeCap read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StrokeCap.butt;
      case 1:
        return StrokeCap.round;
      case 2:
        return StrokeCap.square;
      default:
        return StrokeCap.butt;
    }
  }

  @override
  void write(BinaryWriter writer, StrokeCap obj) {
    switch (obj) {
      case StrokeCap.butt:
        writer.writeByte(0);
        break;
      case StrokeCap.round:
        writer.writeByte(1);
        break;
      case StrokeCap.square:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokeCapAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StrokeJoinAdapter extends TypeAdapter<StrokeJoin> {
  @override
  final int typeId = 7;

  @override
  StrokeJoin read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StrokeJoin.miter;
      case 1:
        return StrokeJoin.round;
      case 2:
        return StrokeJoin.bevel;
      default:
        return StrokeJoin.miter;
    }
  }

  @override
  void write(BinaryWriter writer, StrokeJoin obj) {
    switch (obj) {
      case StrokeJoin.miter:
        writer.writeByte(0);
        break;
      case StrokeJoin.round:
        writer.writeByte(1);
        break;
      case StrokeJoin.bevel:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokeJoinAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
