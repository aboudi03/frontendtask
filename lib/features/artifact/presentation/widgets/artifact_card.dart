import 'package:flutter/material.dart';
import '../../domain/entities/artifact.dart';
import '../../data/models/artifact_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/artifact_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ArtifactCard extends StatefulWidget {
  final Artifact artifact;
  final bool isExpanded;
  final VoidCallback onTap;
  final bool isHovered;
  final bool isDimmed;

  const ArtifactCard({
    super.key,
    required this.artifact,
    required this.isExpanded,
    required this.onTap,
    this.isHovered = false,
    this.isDimmed = false,
  });

  @override
  State<ArtifactCard> createState() => _ArtifactCardState();
}

class _ArtifactCardState extends State<ArtifactCard> {
  // ignore: unused_field
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = widget.isHovered ? 1.05 : (widget.isDimmed ? 0.8 : 1.0);
    final shadow = widget.isHovered
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 48,
              spreadRadius: 6,
              offset: const Offset(0, 12),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ];
    final overlay = widget.isHovered
        ? Colors.black.withOpacity(0.18)
        : widget.isDimmed
            ? Colors.black.withOpacity(0.08)
            : Colors.transparent;
    final infoTextStyle = widget.isHovered
        ? AppTheme.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
        : AppTheme.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600);
    final captionStyle = widget.isHovered
        ? AppTheme.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold)
        : AppTheme.caption.copyWith(color: Colors.white70);

    return Stack(
      children: [
        Hero(
          tag: widget.artifact.id,
          child: AnimatedContainer(
            duration: AppConstants.cardExpandDuration,
            curve: Curves.easeInOut,
            transform: Matrix4.identity()..scale(scale),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.isExpanded ? 16 : 8),
              boxShadow: shadow,
            ),
            child: GestureDetector(
              onTap: widget.onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.isExpanded ? 16 : 8),
                child: Stack(
                  children: [
                    // Artifact Image/Preview
                    Positioned.fill(
                      child: _buildArtifactPreview(),
                    ),
                    // Overlay with artifact info
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: AppConstants.cardExpandDuration,
                        color: overlay,
                      ),
                    ),
                    // Artifact info
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.92), // darker shadow
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.artifact.name,
                                    style: infoTextStyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.artifact.type.displayName,
                              style: captionStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Expand indicator
                    if (!widget.isExpanded)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Edited badge
        Positioned(
          top: 8,
          left: 8,
          child: _EditedBadge(artifactId: widget.artifact.id),
        ),
      ],
    );
  }

  Widget _buildArtifactPreview() {
    switch (widget.artifact.type) {
      case ArtifactType.image:
        if (widget.artifact.path.startsWith('assets/')) {
          return Image.asset(
            widget.artifact.path,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          );
        } else if (widget.artifact.path.startsWith('http')) {
          return Image.network(
            widget.artifact.path,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          );
        } else {
          return Image.file(
            File(widget.artifact.path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          );
        }
      case ArtifactType.document:
        return _buildDocumentPreview();
      case ArtifactType.video:
        return _buildVideoPreview();
      default:
        return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Text(
              widget.artifact.type.displayName,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textLightColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPreview() {
    final isAsset = widget.artifact.path.startsWith('assets/');
    final pdfWidget = isAsset
        ? SfPdfViewer.asset(
            widget.artifact.path,
            key: ValueKey(widget.artifact.path),
            canShowScrollHead: false,
            canShowScrollStatus: false,
            enableDoubleTapZooming: false,
            pageLayoutMode: PdfPageLayoutMode.single,
            scrollDirection: PdfScrollDirection.vertical,
          )
        : SfPdfViewer.file(
            File(widget.artifact.path),
            key: ValueKey(widget.artifact.path),
            canShowScrollHead: false,
            canShowScrollStatus: false,
            enableDoubleTapZooming: false,
            pageLayoutMode: PdfPageLayoutMode.single,
            scrollDirection: PdfScrollDirection.vertical,
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.isExpanded ? 16 : 8),
      child: SizedBox(
        height: 120,
        child: pdfWidget,
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      color: AppTheme.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text(
              'Video File',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.artifact.name,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 

class _EditedBadge extends ConsumerWidget {
  final String artifactId;
  const _EditedBadge({required this.artifactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(reviewForArtifactProvider(artifactId));
    return reviewAsync.when(
      data: (review) {
        if (review == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'edited',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
} 