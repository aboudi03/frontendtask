import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/review_model.dart';

class Review {
  final String id;
  final String artifactId;
  final String comment;
  final List<DrawingPoint> annotations;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Review({
    required this.id,
    required this.artifactId,
    required this.comment,
    required this.annotations,
    required this.createdAt,
    this.updatedAt,
  });

  factory Review.create({
    required String artifactId,
    required String comment,
    required List<DrawingPoint> annotations,
  }) {
    return Review(
      id: const Uuid().v4(),
      artifactId: artifactId,
      comment: comment,
      annotations: annotations,
      createdAt: DateTime.now(),
    );
  }

  Review copyWith({
    String? id,
    String? artifactId,
    String? comment,
    List<DrawingPoint>? annotations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      artifactId: artifactId ?? this.artifactId,
      comment: comment ?? this.comment,
      annotations: annotations ?? this.annotations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Review && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Review(id: $id, artifactId: $artifactId, comment: $comment)';
  }
}

class DrawingPoint {
  final Offset point;
  final Paint paint;
  final bool isEraser;

  const DrawingPoint({
    required this.point,
    required this.paint,
    this.isEraser = false,
  });

  DrawingPoint copyWith({
    Offset? point,
    Paint? paint,
    bool? isEraser,
  }) {
    return DrawingPoint(
      point: point ?? this.point,
      paint: paint ?? this.paint,
      isEraser: isEraser ?? this.isEraser,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrawingPoint &&
        other.point == point &&
        other.paint == paint &&
        other.isEraser == isEraser;
  }

  @override
  int get hashCode => point.hashCode ^ paint.hashCode ^ isEraser.hashCode;
}

class Paint {
  final Color color;
  final double strokeWidth;
  final PaintingStyle style;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;

  const Paint({
    this.color = Colors.black,
    this.strokeWidth = 3.0,
    this.style = PaintingStyle.stroke,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
  });

  Paint copyWith({
    Color? color,
    double? strokeWidth,
    PaintingStyle? style,
    StrokeCap? strokeCap,
    StrokeJoin? strokeJoin,
  }) {
    return Paint(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      style: style ?? this.style,
      strokeCap: strokeCap ?? this.strokeCap,
      strokeJoin: strokeJoin ?? this.strokeJoin,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Paint &&
        other.color == color &&
        other.strokeWidth == strokeWidth &&
        other.style == style &&
        other.strokeCap == strokeCap &&
        other.strokeJoin == strokeJoin;
  }

  @override
  int get hashCode =>
      color.hashCode ^
      strokeWidth.hashCode ^
      style.hashCode ^
      strokeCap.hashCode ^
      strokeJoin.hashCode;
}

// Enums are defined in the data model to avoid conflicts 