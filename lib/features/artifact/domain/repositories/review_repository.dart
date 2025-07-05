import '../entities/review.dart';

abstract class ReviewRepository {
  /// Get all reviews
  Future<List<Review>> getReviews();
  
  /// Get reviews by artifact ID
  Future<List<Review>> getReviewsByArtifactId(String artifactId);
  
  /// Get review by ID
  Future<Review?> getReviewById(String id);
  
  /// Save review
  Future<void> saveReview(Review review);
  
  /// Delete review
  Future<void> deleteReview(String id);
  
  /// Update review
  Future<void> updateReview(Review review);
  
  /// Delete all reviews for an artifact
  Future<void> deleteReviewsByArtifactId(String artifactId);
} 