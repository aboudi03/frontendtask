import 'package:hive_flutter/hive_flutter.dart';
import '../models/artifact_model.dart';
import '../../domain/entities/artifact.dart';
import '../../../../core/constants/app_constants.dart';

abstract class ArtifactLocalDataSource {
  Future<List<Artifact>> getArtifacts();
  Future<Artifact?> getArtifactById(String id);
  Future<void> saveArtifact(Artifact artifact);
  Future<void> deleteArtifact(String id);
  Future<void> updateArtifact(Artifact artifact);
  Future<void> initializeSampleData();
}

class ArtifactLocalDataSourceImpl implements ArtifactLocalDataSource {
  late Box<ArtifactModel> _box;

  Future<void> _initBox() async {
    if (!Hive.isBoxOpen(AppConstants.artifactsBoxName)) {
      _box = await Hive.openBox<ArtifactModel>(AppConstants.artifactsBoxName);
    } else {
      _box = Hive.box<ArtifactModel>(AppConstants.artifactsBoxName);
    }
  }

  @override
  Future<List<Artifact>> getArtifacts() async {
    await _initBox();
    final models = _box.values.toList();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Artifact?> getArtifactById(String id) async {
    await _initBox();
    final model = _box.get(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveArtifact(Artifact artifact) async {
    await _initBox();
    final model = ArtifactModel.fromEntity(artifact);
    await _box.put(artifact.id, model);
  }

  @override
  Future<void> deleteArtifact(String id) async {
    await _initBox();
    await _box.delete(id);
  }

  @override
  Future<void> updateArtifact(Artifact artifact) async {
    await _initBox();
    final model = ArtifactModel.fromEntity(artifact);
    await _box.put(artifact.id, model);
  }

  @override
  Future<void> initializeSampleData() async {
    await _initBox();
    
    // Only initialize if box is empty
    if (_box.isEmpty) {
      final sampleArtifacts = [
        // Images
        for (final path in AppConstants.sampleArtifactImages)
          Artifact.create(
            name: path.split('/').last, // Use filename as name
            path: path,
            type: ArtifactType.image,
          ),
        // Documents
        for (final path in AppConstants.sampleArtifactDocuments)
          Artifact.create(
            name: path.split('/').last, // Use filename as name
            path: path,
            type: ArtifactType.document,
          ),
      ];

      for (final artifact in sampleArtifacts) {
        await saveArtifact(artifact);
      }
    }
  }
} 