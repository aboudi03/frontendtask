import '../entities/review.dart';
import '../repositories/review_repository.dart';

class SaveReviewUseCase {
  final ReviewRepository repository;

  SaveReviewUseCase(this.repository);

  Future<void> call(Review review) async {
    await repository.saveReview(review);
  }
} 