import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../features/artifact/data/datasources/artifact_local_datasource.dart';
import '../features/artifact/data/datasources/review_local_datasource.dart';
import '../features/artifact/data/models/artifact_model.dart';
import '../features/artifact/data/models/review_model.dart';
import '../features/artifact/data/repositories/artifact_repository_impl.dart';
import '../features/artifact/data/repositories/review_repository_impl.dart';
import '../features/artifact/domain/repositories/artifact_repository.dart';
import '../features/artifact/domain/repositories/review_repository.dart';
import '../features/artifact/domain/usecases/get_artifacts_usecase.dart';
import '../features/artifact/domain/usecases/get_reviews_by_artifact_usecase.dart';
import '../features/artifact/domain/usecases/save_review_usecase.dart';

// Hive Box Providers
final artifactsBoxProvider = Provider<Box<ArtifactModel>>((ref) {
  throw UnimplementedError('Initialize Hive first');
});

final reviewsBoxProvider = Provider<Box<ReviewModel>>((ref) {
  throw UnimplementedError('Initialize Hive first');
});

// Data Sources
final artifactLocalDataSourceProvider = Provider<ArtifactLocalDataSource>((ref) {
  return ArtifactLocalDataSourceImpl();
});

final reviewLocalDataSourceProvider = Provider<ReviewLocalDataSource>((ref) {
  return ReviewLocalDataSourceImpl();
});

// Repositories
final artifactRepositoryProvider = Provider<ArtifactRepository>((ref) {
  final localDataSource = ref.watch(artifactLocalDataSourceProvider);
  return ArtifactRepositoryImpl(localDataSource);
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final localDataSource = ref.watch(reviewLocalDataSourceProvider);
  return ReviewRepositoryImpl(localDataSource);
});

// Use Cases
final getArtifactsUseCaseProvider = Provider<GetArtifactsUseCase>((ref) {
  final repository = ref.watch(artifactRepositoryProvider);
  return GetArtifactsUseCase(repository);
});

final saveReviewUseCaseProvider = Provider<SaveReviewUseCase>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  return SaveReviewUseCase(repository);
});

final getReviewsByArtifactUseCaseProvider = Provider<GetReviewsByArtifactUseCase>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  return GetReviewsByArtifactUseCase(repository);
});

// Initialize Hive
Future<void> initializeHive() async {
  await Hive.initFlutter();

  // DEV ONLY: Delete old boxes to avoid typeId errors
  await Hive.deleteBoxFromDisk('artifacts');
  await Hive.deleteBoxFromDisk('artifact_reviews');

  // Register adapters
  Hive.registerAdapter(ArtifactModelAdapter());
  Hive.registerAdapter(ArtifactTypeAdapter());
  Hive.registerAdapter(ReviewModelAdapter());
  Hive.registerAdapter(DrawingPointModelAdapter());
  Hive.registerAdapter(PaintModelAdapter());
  Hive.registerAdapter(PaintingStyleAdapter());
  Hive.registerAdapter(StrokeCapAdapter());
  Hive.registerAdapter(StrokeJoinAdapter());

  // Open boxes
  await Hive.openBox<ArtifactModel>('artifacts');
  await Hive.openBox<ReviewModel>('artifact_reviews');
} 