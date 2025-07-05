import '../entities/artifact.dart';

abstract class ArtifactRepository {
  /// Get all artifacts
  Future<List<Artifact>> getArtifacts();
  
  /// Get artifact by ID
  Future<Artifact?> getArtifactById(String id);
  
  /// Save artifact
  Future<void> saveArtifact(Artifact artifact);
  
  /// Delete artifact
  Future<void> deleteArtifact(String id);
  
  /// Update artifact
  Future<void> updateArtifact(Artifact artifact);
} 