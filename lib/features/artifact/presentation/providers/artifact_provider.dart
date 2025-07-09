import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/artifact.dart';
import '../../../../di/dependency_injection.dart';
import '../../domain/entities/review.dart';

final selectedArtifactProvider = StateProvider<Artifact?>((ref) => null);

final isExpandedProvider = StateProvider<bool>((ref) => false);

final refreshTriggerProvider = StateProvider<int>((ref) => 0);

final artifactsProvider = FutureProvider<List<Artifact>>((ref) async {
  // Watch the refresh trigger to force reload
  ref.watch(refreshTriggerProvider);
  
  final useCase = ref.watch(getArtifactsUseCaseProvider);
  final artifacts = await useCase();
  print('Loaded ${artifacts.length} artifacts');
  return artifacts;
});

final artifactExpansionProvider = StateNotifierProvider<ArtifactExpansionNotifier, ArtifactExpansionState>((ref) {
  return ArtifactExpansionNotifier();
});

final reviewForArtifactProvider = FutureProvider.family<Review?, String>((ref, artifactId) async {
  final useCase = ref.watch(getReviewsByArtifactUseCaseProvider);
  final reviews = await useCase(artifactId);
  return reviews.isNotEmpty ? reviews.first : null;
});

final reviewsForArtifactProvider = FutureProvider.family<List<Review>, String>((ref, artifactId) async {
  final getReviewsByArtifact = ref.watch(getReviewsByArtifactUseCaseProvider);
  return await getReviewsByArtifact(artifactId);
});

class ArtifactExpansionState {
  final Artifact? selectedArtifact;
  final bool isExpanded;
  final List<Artifact> artifacts;

  ArtifactExpansionState({
    this.selectedArtifact,
    this.isExpanded = false,
    this.artifacts = const [],
  });

  ArtifactExpansionState copyWith({
    Artifact? selectedArtifact,
    bool? isExpanded,
    List<Artifact>? artifacts,
  }) {
    return ArtifactExpansionState(
      selectedArtifact: selectedArtifact ?? this.selectedArtifact,
      isExpanded: isExpanded ?? this.isExpanded,
      artifacts: artifacts ?? this.artifacts,
    );
  }
}

class ArtifactExpansionNotifier extends StateNotifier<ArtifactExpansionState> {
  ArtifactExpansionNotifier() : super(ArtifactExpansionState());

  void expandArtifact(Artifact artifact) {
    state = state.copyWith(
      selectedArtifact: artifact,
      isExpanded: true,
    );
  }

  void collapseArtifact() {
    state = state.copyWith(
      selectedArtifact: null,
      isExpanded: false,
    );
  }

  void updateArtifacts(List<Artifact> artifacts) {
    state = state.copyWith(artifacts: artifacts);
  }
} 