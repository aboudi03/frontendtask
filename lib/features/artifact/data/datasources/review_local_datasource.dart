import 'package:hive_flutter/hive_flutter.dart';
import '../models/review_model.dart';
import '../../domain/entities/review.dart';
import '../../../../core/constants/app_constants.dart';

abstract class ReviewLocalDataSource {
  Future<List<Review>> getReviews();
  Future<List<Review>> getReviewsByArtifactId(String artifactId);
  Future<Review?> getReviewById(String id);
  Future<void> saveReview(Review review);
  Future<void> deleteReview(String id);
  Future<void> updateReview(Review review);
  Future<void> deleteReviewsByArtifactId(String artifactId);
}

class ReviewLocalDataSourceImpl implements ReviewLocalDataSource {
  late Box<ReviewModel> _box;

  Future<void> _initBox() async {
    if (!Hive.isBoxOpen(AppConstants.reviewsBoxName)) {
      _box = await Hive.openBox<ReviewModel>(AppConstants.reviewsBoxName);
    } else {
      _box = Hive.box<ReviewModel>(AppConstants.reviewsBoxName);
    }
  }

  @override
  Future<List<Review>> getReviews() async {
    await _initBox();
    final models = _box.values.toList();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Review>> getReviewsByArtifactId(String artifactId) async {
    await _initBox();
    final models = _box.values.where((model) => model.artifactId == artifactId).toList();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Review?> getReviewById(String id) async {
    await _initBox();
    final model = _box.get(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveReview(Review review) async {
    await _initBox();
    final model = ReviewModel.fromEntity(review);
    await _box.put(review.id, model);
  }

  @override
  Future<void> deleteReview(String id) async {
    await _initBox();
    await _box.delete(id);
  }

  @override
  Future<void> updateReview(Review review) async {
    await _initBox();
    final model = ReviewModel.fromEntity(review);
    await _box.put(review.id, model);
  }

  @override
  Future<void> deleteReviewsByArtifactId(String artifactId) async {
    await _initBox();
    final keysToDelete = _box.keys
        .where((key) => _box.get(key)?.artifactId == artifactId)
        .toList();
    
    for (final key in keysToDelete) {
      await _box.delete(key);
    }
  }
} 