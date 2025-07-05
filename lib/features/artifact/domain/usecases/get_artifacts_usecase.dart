import '../entities/artifact.dart';
import '../repositories/artifact_repository.dart';

class GetArtifactsUseCase {
  final ArtifactRepository repository;

  GetArtifactsUseCase(this.repository);

  Future<List<Artifact>> call() async {
    return await repository.getArtifacts();
  }
} 