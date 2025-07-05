import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/review.dart';

part 'review_model.g.dart';

@HiveType(typeId: 2)
class ReviewModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String artifactId;

  @HiveField(2)
  final String comment;

  @HiveField(3)
  final List<DrawingPointModel> annotations;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime? updatedAt;

  ReviewModel({
    required this.id,
    required this.artifactId,
    required this.comment,
    required this.annotations,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReviewModel.fromEntity(Review review) {
    return ReviewModel(
      id: review.id,
      artifactId: review.artifactId,
      comment: review.comment,
      annotations: review.annotations.map((e) => DrawingPointModel.fromEntity(e)).toList(),
      createdAt: review.createdAt,
      updatedAt: review.updatedAt,
    );
  }

  Review toEntity() {
    return Review(
      id: id,
      artifactId: artifactId,
      comment: comment,
      annotations: annotations.map((e) => e.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 3)
class DrawingPointModel {
  @HiveField(0)
  final double dx;

  @HiveField(1)
  final double dy;

  @HiveField(2)
  final PaintModel paint;

  @HiveField(3)
  final bool isEraser;

  DrawingPointModel({
    required this.dx,
    required this.dy,
    required this.paint,
    required this.isEraser,
  });

  factory DrawingPointModel.fromEntity(DrawingPoint point) {
    return DrawingPointModel(
      dx: point.point.dx,
      dy: point.point.dy,
      paint: PaintModel.fromEntity(point.paint),
      isEraser: point.isEraser,
    );
  }

  DrawingPoint toEntity() {
    return DrawingPoint(
      point: Offset(dx, dy),
      paint: paint.toEntity(),
      isEraser: isEraser,
    );
  }
}

@HiveType(typeId: 4)
class PaintModel {
  @HiveField(0)
  final int color;

  @HiveField(1)
  final double strokeWidth;

  @HiveField(2)
  final PaintingStyle style;

  @HiveField(3)
  final StrokeCap strokeCap;

  @HiveField(4)
  final StrokeJoin strokeJoin;

  PaintModel({
    required this.color,
    required this.strokeWidth,
    required this.style,
    required this.strokeCap,
    required this.strokeJoin,
  });

  factory PaintModel.fromEntity(Paint paint) {
    return PaintModel(
      color: paint.color.value,
      strokeWidth: paint.strokeWidth,
      style: paint.style,
      strokeCap: paint.strokeCap,
      strokeJoin: paint.strokeJoin,
    );
  }

  Paint toEntity() {
    return Paint(
      color: Color(color),
      strokeWidth: strokeWidth,
      style: style,
      strokeCap: strokeCap,
      strokeJoin: strokeJoin,
    );
  }
}

@HiveType(typeId: 5)
enum PaintingStyle {
  @HiveField(0)
  fill,
  @HiveField(1)
  stroke,
}

@HiveType(typeId: 6)
enum StrokeCap {
  @HiveField(0)
  butt,
  @HiveField(1)
  round,
  @HiveField(2)
  square,
}

@HiveType(typeId: 7)
enum StrokeJoin {
  @HiveField(0)
  miter,
  @HiveField(1)
  round,
  @HiveField(2)
  bevel,
} 