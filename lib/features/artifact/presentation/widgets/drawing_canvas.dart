import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/review.dart' as review_entities;
import '../providers/review_provider.dart';
import 'dart:ui' as ui;
import 'dart:math';
import '../../data/models/review_model.dart' as review_model;

class DrawingCanvas extends ConsumerStatefulWidget {
  final String artifactId;
  final List<review_entities.DrawingPoint>? initialPoints;

  const DrawingCanvas({
    super.key,
    required this.artifactId,
    this.initialPoints,
  });

  @override
  DrawingCanvasState createState() => DrawingCanvasState();
}

class DrawingCanvasState extends ConsumerState<DrawingCanvas> {
  List<review_entities.DrawingPoint?> _points = [];
  bool _isDrawing = false;
  Offset? _mousePosition;

  List<review_entities.DrawingPoint?> get points => _points;

  @override
  void initState() {
    super.initState();
    if (widget.initialPoints != null) {
      _points = List.from(widget.initialPoints!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawingSettings = ref.watch(drawingSettingsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (event) {
            setState(() {
              _mousePosition = event.localPosition;
            });
          },
          onExit: (_) {
            setState(() {
              _mousePosition = null;
            });
          },
          child: Stack(
            children: [
              GestureDetector(
                onPanStart: (details) => _onPanStart(details, drawingSettings),
                onPanUpdate: (details) => _onPanUpdate(details, drawingSettings),
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: DrawingPainter(_points),
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                ),
              ),
              // Custom eraser cursor overlay
              if (drawingSettings.isEraser && _mousePosition != null)
                Positioned(
                  left: _mousePosition!.dx - drawingSettings.strokeWidth / 2,
                  top: _mousePosition!.dy - drawingSettings.strokeWidth / 2,
                  child: IgnorePointer(
                    child: Container(
                      width: drawingSettings.strokeWidth,
                      height: drawingSettings.strokeWidth,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color.fromARGB(255, 251, 251, 251), width: 2),
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _onPanStart(DragStartDetails details, DrawingSettings settings) {
    setState(() {
      _isDrawing = true;
      _mousePosition = details.localPosition;
      if (settings.isEraser) {
        _eraseAt(details.localPosition, settings.strokeWidth);
      } else {
        _points.add(review_entities.DrawingPoint(
          point: details.localPosition,
          paint: review_entities.Paint(
            color: settings.color,
            strokeWidth: settings.strokeWidth,
          ),
          isEraser: false,
        ));
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details, DrawingSettings settings) {
    if (_isDrawing) {
      setState(() {
        _mousePosition = details.localPosition;
        if (settings.isEraser) {
          _eraseAt(details.localPosition, settings.strokeWidth);
        } else {
          _points.add(review_entities.DrawingPoint(
            point: details.localPosition,
            paint: review_entities.Paint(
              color: settings.color,
              strokeWidth: settings.strokeWidth,
            ),
            isEraser: false,
          ));
        }
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDrawing = false;
      _points.add(null); // Add a break between strokes
    });
  }

  void _eraseAt(Offset position, double eraseRadius) {
    // Collect indices to break after the loop to avoid modifying the list while iterating
    final breakIndices = <int>[];
    for (int i = 0; i < _points.length - 1; i++) {
      final current = _points[i];
      final next = _points[i + 1];
      if (current == null || next == null) continue;
      final bool currentInCircle = (current.point - position).distance <= eraseRadius;
      final bool nextInCircle = (next.point - position).distance <= eraseRadius;
      if (currentInCircle || nextInCircle || _lineIntersectsCircle(current.point, next.point, position, eraseRadius)) {
        breakIndices.add(i + 1);
      }
    }
    if (breakIndices.isNotEmpty) {
      setState(() {
        // Insert nulls in reverse order to keep indices valid
        for (final idx in breakIndices.reversed) {
          _points.insert(idx, null);
        }
      });
    }
  }

  // Helper: Check if a line segment (p1-p2) intersects a circle (center, radius)
  bool _lineIntersectsCircle(Offset p1, Offset p2, Offset center, double radius) {
    // Vector from p1 to p2
    final d = p2 - p1;
    // Vector from p1 to center
    final f = p1 - center;
    final a = d.dx * d.dx + d.dy * d.dy;
    final b = 2 * (f.dx * d.dx + f.dy * d.dy);
    final c = f.dx * f.dx + f.dy * f.dy - radius * radius;
    double discriminant = b * b - 4 * a * c;
    if (discriminant < 0) {
      return false;
    } else {
      discriminant = sqrt(discriminant);
      double t1 = (-b - discriminant) / (2 * a);
      double t2 = (-b + discriminant) / (2 * a);
      return (t1 >= 0 && t1 <= 1) || (t2 >= 0 && t2 <= 1);
    }
  }

  void clearCanvas() {
    setState(() {
      _points.clear();
    });
  }

  void undo() {
    if (_points.isNotEmpty) {
      setState(() {
        _points.removeLast();
      });
    }
  }
}

class DrawingPainter extends CustomPainter {
  final List<review_entities.DrawingPoint?> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      if (current == null || next == null) continue;
      final paint = _toUiPaint(current.paint);
      canvas.drawLine(current.point, next.point, paint);
    }
  }

  ui.Paint _toUiPaint(review_entities.Paint paint) {
    return ui.Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = paint.style == review_model.PaintingStyle.fill ? ui.PaintingStyle.fill : ui.PaintingStyle.stroke
      ..strokeCap = _toUiStrokeCap(paint.strokeCap)
      ..strokeJoin = _toUiStrokeJoin(paint.strokeJoin);
  }

  ui.StrokeCap _toUiStrokeCap(review_model.StrokeCap cap) {
    switch (cap) {
      case review_model.StrokeCap.butt:
        return ui.StrokeCap.butt;
      case review_model.StrokeCap.round:
        return ui.StrokeCap.round;
      case review_model.StrokeCap.square:
        return ui.StrokeCap.square;
    }
  }

  ui.StrokeJoin _toUiStrokeJoin(review_model.StrokeJoin join) {
    switch (join) {
      case review_model.StrokeJoin.miter:
        return ui.StrokeJoin.miter;
      case review_model.StrokeJoin.round:
        return ui.StrokeJoin.round;
      case review_model.StrokeJoin.bevel:
        return ui.StrokeJoin.bevel;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 