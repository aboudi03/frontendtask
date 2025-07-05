import '../entities/review.dart';
import '../repositories/review_repository.dart';

class GetReviewsByArtifactUseCase {
  final ReviewRepository repository;

  GetReviewsByArtifactUseCase(this.repository);

  Future<List<Review>> call(String artifactId) async {
    return await repository.getReviewsByArtifactId(artifactId);
  }
} 