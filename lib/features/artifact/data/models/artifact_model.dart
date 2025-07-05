import 'package:hive/hive.dart';
import '../../domain/entities/artifact.dart';

part 'artifact_model.g.dart';

@HiveType(typeId: 0)
class ArtifactModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String path;

  @HiveField(3)
  final ArtifactType type;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime? updatedAt;

  ArtifactModel({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.createdAt,
    this.updatedAt,
  });

  factory ArtifactModel.fromEntity(Artifact artifact) {
    return ArtifactModel(
      id: artifact.id,
      name: artifact.name,
      path: artifact.path,
      type: artifact.type,
      createdAt: artifact.createdAt,
      updatedAt: artifact.updatedAt,
    );
  }

  Artifact toEntity() {
    return Artifact(
      id: id,
      name: name,
      path: path,
      type: type,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArtifactModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 1)
enum ArtifactType {
  @HiveField(0)
  image,
  @HiveField(1)
  document,
  @HiveField(2)
  video,
}

extension ArtifactTypeExtension on ArtifactType {
  String get displayName {
    switch (this) {
      case ArtifactType.image:
        return 'Image';
      case ArtifactType.document:
        return 'Document';
      case ArtifactType.video:
        return 'Video';
    }
  }

  String get icon {
    switch (this) {
      case ArtifactType.image:
        return '🖼️';
      case ArtifactType.document:
        return '📄';
      case ArtifactType.video:
        return '🎥';
    }
  }
} 