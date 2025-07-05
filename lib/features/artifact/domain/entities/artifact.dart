import 'package:uuid/uuid.dart';
import '../../data/models/artifact_model.dart';

class Artifact {
  final String id;
  final String name;
  final String path;
  final ArtifactType type;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Artifact({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.createdAt,
    this.updatedAt,
  });

  factory Artifact.create({
    required String name,
    required String path,
    required ArtifactType type,
  }) {
    return Artifact(
      id: const Uuid().v4(),
      name: name,
      path: path,
      type: type,
      createdAt: DateTime.now(),
    );
  }

  Artifact copyWith({
    String? id,
    String? name,
    String? path,
    ArtifactType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Artifact(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Artifact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Artifact(id: $id, name: $name, type: $type)';
  }
}

// ArtifactType is defined in the data model to avoid conflicts 