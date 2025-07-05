import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_local_datasource.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewLocalDataSource localDataSource;

  ReviewRepositoryImpl(this.localDataSource);

  @override
  Future<List<Review>> getReviews() async {
    return await localDataSource.getReviews();
  }

  @override
  Future<List<Review>> getReviewsByArtifactId(String artifactId) async {
    return await localDataSource.getReviewsByArtifactId(artifactId);
  }

  @override
  Future<Review?> getReviewById(String id) async {
    return await localDataSource.getReviewById(id);
  }

  @override
  Future<void> saveReview(Review review) async {
    await localDataSource.saveReview(review);
  }

  @override
  Future<void> deleteReview(String id) async {
    await localDataSource.deleteReview(id);
  }

  @override
  Future<void> updateReview(Review review) async {
    await localDataSource.updateReview(review);
  }

  @override
  Future<void> deleteReviewsByArtifactId(String artifactId) async {
    await localDataSource.deleteReviewsByArtifactId(artifactId);
  }
} 