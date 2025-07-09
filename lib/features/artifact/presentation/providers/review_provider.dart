import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/review.dart';
import 'package:flutter/material.dart';

final reviewFormProvider = StateNotifierProvider<ReviewFormNotifier, ReviewFormState>((ref) {
  return ReviewFormNotifier();
});

class ReviewFormState {
  final String comment;
  final List<DrawingPoint> annotations;
  final bool isSaving;

  ReviewFormState({
    this.comment = '',
    this.annotations = const [],
    this.isSaving = false,
  });

  ReviewFormState copyWith({
    String? comment,
    List<DrawingPoint>? annotations,
    bool? isSaving,
  }) {
    return ReviewFormState(
      comment: comment ?? this.comment,
      annotations: annotations ?? this.annotations,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class ReviewFormNotifier extends StateNotifier<ReviewFormState> {
  ReviewFormNotifier() : super(ReviewFormState());

  void updateComment(String comment) {
    state = state.copyWith(comment: comment);
  }

  void addAnnotation(DrawingPoint annotation) {
    final newAnnotations = List<DrawingPoint>.from(state.annotations)
      ..add(annotation);
    state = state.copyWith(annotations: newAnnotations);
  }

  void clearAnnotations() {
    state = state.copyWith(annotations: []);
  }

  void undoLastAnnotation() {
    if (state.annotations.isNotEmpty) {
      final newAnnotations = List<DrawingPoint>.from(state.annotations)
        ..removeLast();
      state = state.copyWith(annotations: newAnnotations);
    }
  }

  Future<void> saveReview(String artifactId) async {
    state = state.copyWith(isSaving: true);
    
    try {
      final review = Review(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        artifactId: artifactId,
        comment: state.comment,
        annotations: state.annotations,
        createdAt: DateTime.now(),
      );
      
      // TODO: Implement save logic
      print('Saving review: ${review.id}');
      
      // Reset form after successful save
      state = ReviewFormState();
    } catch (e) {
      print('Error saving review: $e');
      state = state.copyWith(isSaving: false);
    }
  }
} 

class DrawingSettings {
  final Color? color;
  final double strokeWidth;
  final bool isEraser;

  const DrawingSettings({
    this.color,
    this.strokeWidth = 3.0,
    this.isEraser = false,
  });

  DrawingSettings copyWith({
    Color? color,
    double? strokeWidth,
    bool? isEraser,
  }) {
    return DrawingSettings(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isEraser: isEraser ?? this.isEraser,
    );
  }
}

class DrawingSettingsNotifier extends StateNotifier<DrawingSettings> {
  DrawingSettingsNotifier() : super(const DrawingSettings());

  void setColor(Color color) {
    state = state.copyWith(color: color, isEraser: false);
  }

  void setStrokeWidth(double width) {
    state = state.copyWith(strokeWidth: width);
  }

  void setEraser(bool isEraser) {
    state = state.copyWith(isEraser: isEraser);
  }

  void reset() {
    state = const DrawingSettings();
  }
}

final drawingSettingsProvider = StateNotifierProvider<DrawingSettingsNotifier, DrawingSettings>((ref) {
  return DrawingSettingsNotifier();
}); 