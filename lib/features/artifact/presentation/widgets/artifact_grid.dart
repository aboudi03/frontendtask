import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../di/dependency_injection.dart';
import '../providers/artifact_provider.dart';
import 'artifact_card.dart';

final hoveredArtifactIndexProvider = StateProvider<int?>((ref) => null);

class ArtifactGrid extends ConsumerWidget {
  const ArtifactGrid({super.key});

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 8;
    if (width > 1200) return 7;
    if (width > 1000) return 6;
    if (width > 800) return 5;
    if (width > 600) return 4;
    if (width > 400) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artifactsAsync = ref.watch(artifactsProvider);
    final expansionState = ref.watch(artifactExpansionProvider);
    final hoveredIndex = ref.watch(hoveredArtifactIndexProvider);

    return artifactsAsync.when(
      data: (artifacts) {
        if (artifacts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No artifacts found',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final dataSource = ref.read(artifactLocalDataSourceProvider);
                      await dataSource.initializeSampleData();
                      ref.read(refreshTriggerProvider.notifier).state++;
                    } catch (e) {
                      print('Error: $e');
                    }
                  },
                  child: const Text('Initialize Sample Data'),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AppConstants.gridPadding),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: AppConstants.gridCrossAxisCount,
            childAspectRatio: AppConstants.gridChildAspectRatio,
            crossAxisSpacing: AppConstants.gridSpacing,
            mainAxisSpacing: AppConstants.gridSpacing,
          ),
          itemCount: artifacts.length,
          itemBuilder: (context, index) {
            final artifact = artifacts[index];
            final isExpanded = expansionState.selectedArtifact?.id == artifact.id;
            final hasExpandedArtifact = expansionState.isExpanded;
            final isHovered = hoveredIndex == index;
            final isDimmed = hoveredIndex != null && hoveredIndex != index;

            return AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: hasExpandedArtifact && !isExpanded ? 0.3 : 1.0,
              child: MouseRegion(
                onEnter: (_) => ref.read(hoveredArtifactIndexProvider.notifier).state = index,
                onExit: (_) => ref.read(hoveredArtifactIndexProvider.notifier).state = null,
                child: ArtifactCard(
                  artifact: artifact,
                  isExpanded: isExpanded,
                  isHovered: isHovered,
                  isDimmed: isDimmed,
                  onTap: () {
                    final notifier = ref.read(artifactExpansionProvider.notifier);
                    notifier.collapseArtifact();
                    Future.delayed(const Duration(milliseconds: 10), () {
                      notifier.expandArtifact(artifact);
                    });
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
} 