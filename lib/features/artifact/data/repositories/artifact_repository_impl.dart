import '../../domain/entities/artifact.dart';
import '../../domain/repositories/artifact_repository.dart';
import '../datasources/artifact_local_datasource.dart';

class ArtifactRepositoryImpl implements ArtifactRepository {
  final ArtifactLocalDataSource localDataSource;

  ArtifactRepositoryImpl(this.localDataSource);

  @override
  Future<List<Artifact>> getArtifacts() async {
    return await localDataSource.getArtifacts();
  }

  @override
  Future<Artifact?> getArtifactById(String id) async {
    return await localDataSource.getArtifactById(id);
  }

  @override
  Future<void> saveArtifact(Artifact artifact) async {
    await localDataSource.saveArtifact(artifact);
  }

  @override
  Future<void> deleteArtifact(String id) async {
    await localDataSource.deleteArtifact(id);
  }

  @override
  Future<void> updateArtifact(Artifact artifact) async {
    await localDataSource.updateArtifact(artifact);
  }
} 