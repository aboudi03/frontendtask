import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/artifact_model.dart';
import '../providers/artifact_provider.dart';
import '../../../../di/dependency_injection.dart';
import 'artifact_grid.dart';
import 'drawing_canvas.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'drawing_toolbar.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/review.dart';
import '../providers/review_provider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

// Dashed border painter for comment box
class DashedBorderPainter extends CustomPainter { 
  final Color color;
  final double strokeWidth;       
  final double gap;
  final double dashLength;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2,
    this.gap = 6,
    this.dashLength = 10,
    this.radius = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = ui.Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = ui.PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    _drawDashedRRect(canvas, rrect, paint);
  }

  void _drawDashedRRect(Canvas canvas, RRect rrect, ui.Paint paint) {
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    double distance = 0.0;
    while (distance < metrics.length) {
      final next = distance + dashLength;
      canvas.drawPath(
        metrics.extractPath(distance, next),
        paint,
      );
      distance = next + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ArtifactPortalScreen extends ConsumerStatefulWidget {
  const ArtifactPortalScreen({super.key});

  @override
  ConsumerState<ArtifactPortalScreen> createState() => _ArtifactPortalScreenState();
}

class _ArtifactPortalScreenState extends ConsumerState<ArtifactPortalScreen> {

  TextEditingController? _commentController;
  String? _lastArtifactId;

  // Per-artifact GlobalKey map for DrawingCanvasState
  final Map<String, GlobalKey<DrawingCanvasState>> _drawingCanvasKeys = {};
  GlobalKey<DrawingCanvasState> _getCanvasKey(String artifactId) {
    return _drawingCanvasKeys.putIfAbsent(artifactId, () => GlobalKey<DrawingCanvasState>());
  }

  // Toggle for image full view vs scroll view
  bool _isFullView = false;

  // Add toolbar visibility state
  bool _showToolbar = true;
  bool _showReviewSection = false;

  late final ScrollController _photoScrollController;
  late final ScrollController _commentsController;

  @override
  void initState() {
    super.initState();
    _photoScrollController = ScrollController();
    _commentsController = ScrollController();
  }

  @override
  void dispose() {
    _photoScrollController.dispose();
    _commentsController.dispose();
    _commentController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expansionState = ref.watch(artifactExpansionProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar
              // Main content
              Expanded(
                child: Column(
                  children: [
                    // Main content area
                    Expanded(
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              // Toggle button for review section
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black.withOpacity(0.85),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showReviewSection = !_showReviewSection;
                                      });
                                    },
                                    child: Text(_showReviewSection ? 'Hide Review History' : 'Show Review History'),
                                  ),
                                ),
                              ),
                              const Expanded(child: ArtifactGrid()),
                              if (_showReviewSection) _ReviewTabSection(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Modal overlay for expanded artifact
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1600),
            reverseDuration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            child: (expansionState.isExpanded && expansionState.selectedArtifact != null)
                ? Consumer(
                    key: ValueKey('expanded-${expansionState.selectedArtifact!.id}'),
                    builder: (context, ref, _) {
                      final artifactsAsync = ref.watch(artifactsProvider);
                      return artifactsAsync.when(
                        data: (artifacts) {
                          final artifact = artifacts.firstWhere(
                            (a) => a.id == expansionState.selectedArtifact!.id,
                            orElse: () => expansionState.selectedArtifact!,
                          );
                          final currentIndex = artifacts.indexWhere((a) => a.id == artifact.id);
                          final prevIndex = (currentIndex - 1 + artifacts.length) % artifacts.length;
                          final nextIndex = (currentIndex + 1) % artifacts.length;
                          final prevArtifact = artifacts[prevIndex];
                          final nextArtifact = artifacts[nextIndex];
                          return Positioned.fill(
                            child: GestureDetector(
                              onTap: () => ref.read(artifactExpansionProvider.notifier).collapseArtifact(),
                              child: Container(
                                color: Colors.black.withOpacity(0.7),
                                child: Row(
                                  children: [
                                    // Left preview (previous artifact)
                                    if (artifacts.length > 1)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 4.0),
                                              child: SizedBox(
                                                width: MediaQuery.of(context).size.width * 0.1,
                                                child: Text(
                                                  prevArtifact.name,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis),
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                ref.read(artifactExpansionProvider.notifier).expandArtifact(prevArtifact);
                                              },
                                              child: Container(
                                                width: MediaQuery.of(context).size.width * 0.1,
                                                height: MediaQuery.of(context).size.height * 0.42,
                                                margin: EdgeInsets.only(left: 0),
                                                alignment: Alignment.centerLeft,
                                                child: Opacity(
                                                  opacity: 0.7,
                                                  child: SizedBox(
                                                    width: MediaQuery.of(context).size.width * 0.1,
                                                    height: MediaQuery.of(context).size.height * 0.42,
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(16),
                                                      child: _buildArtifactPreview(prevArtifact),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    // Left navigation button
                                    if (artifacts.length > 1)
                                      Container(
                                        alignment: Alignment.center,
                                        height: MediaQuery.of(context).size.height * 0.8,
                                        child: IconButton(
                                          icon: Icon(Icons.chevron_left, size: 36, color: Colors.black.withOpacity(0.7)),
                                          onPressed: () {
                                            ref.read(artifactExpansionProvider.notifier).expandArtifact(prevArtifact);
                                          },
                                          style: ButtonStyle(
                                            backgroundColor: MaterialStateProperty.all(Colors.white.withOpacity(0.7)),
                                            shape: MaterialStateProperty.all(CircleBorder()),
                                            elevation: MaterialStateProperty.all(4),
                                          ),
                                        ),
                                      ),
                                    // Center modal (main artifact)
                                    Expanded(
                                      child: Center(
                                        child: GestureDetector(
                                          onTap: () {}, // Prevent tap from propagating to background
                                          child: Container(
                                            width: MediaQuery.of(context).size.width * 0.7,
                                            height: MediaQuery.of(context).size.height * 0.8,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 24,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              children: [
                                                Flexible(
                                                  flex: 6, // 60% of space
                                                  child: Hero(
                                                    tag: artifact.id,
                                                    child: SizedBox(
                                                      width: double.infinity,
                                                      child: _buildArtifactPreviewWithKey(artifact),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Flexible(
                                                  flex: 3, // 30% of space
                                                  child: Scrollbar(
                                                    controller: _commentsController,
                                                    thumbVisibility: true,
                                                    child: ListView(
                                                      controller: _commentsController,
                                                      padding: EdgeInsets.zero,
                                                      children: [
                                                        _ArtifactCommentsFeed(artifactId: artifact.id),
                                                        const SizedBox(height: 8),
                                                        _buildReviewFormWithSave(artifact),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Right navigation button
                                    if (artifacts.length > 1)
                                      Container(
                                        alignment: Alignment.center,
                                        height: MediaQuery.of(context).size.height * 0.8,
                                        child: IconButton(
                                          icon: Icon(Icons.chevron_right, size: 36, color: Colors.black.withOpacity(0.7)),
                                          onPressed: () {
                                            ref.read(artifactExpansionProvider.notifier).expandArtifact(nextArtifact);
                                          },
                                          style: ButtonStyle(
                                            backgroundColor: MaterialStateProperty.all(Colors.white.withOpacity(0.7)),
                                            shape: MaterialStateProperty.all(CircleBorder()),
                                            elevation: MaterialStateProperty.all(4),
                                          ),
                                        ),
                                      ),
                                    // Right preview (next artifact)
                                    if (artifacts.length > 1)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 4.0),
                                              child: SizedBox(
                                                width: MediaQuery.of(context).size.width * 0.1,
                                                child: Text(
                                                  nextArtifact.name,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis),
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                ref.read(artifactExpansionProvider.notifier).expandArtifact(nextArtifact);
                                              },
                                              child: Container(
                                                width: MediaQuery.of(context).size.width * 0.1,
                                                height: MediaQuery.of(context).size.height * 0.42,
                                                margin: EdgeInsets.only(right: 0),
                                                alignment: Alignment.centerRight,
                                                child: Opacity(
                                                  opacity: 0.7,
                                                  child: SizedBox(
                                                    width: MediaQuery.of(context).size.width * 0.1,
                                                    height: MediaQuery.of(context).size.height * 0.42,
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(16),
                                                      child: _buildArtifactPreview(nextArtifact),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, st) => const SizedBox.shrink(),
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildArtifactPreview(artifact) {
    print('USING _buildArtifactPreview for artifact  [32m${artifact.id} [0m');
    return Consumer(
      builder: (context, ref, _) {
        final reviewAsync = ref.watch(reviewForArtifactProvider(artifact.id));
        return reviewAsync.when(
          data: (review) {
            switch (artifact.type) {
              case ArtifactType.image:
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        artifact.path.startsWith('assets/')
                            ? Image.asset(
                                artifact.path,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Image.network(
                                artifact.path,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                ),
                              ),
                      ],
                    ),
                  ),
                );
              case ArtifactType.document:
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        artifact.path.startsWith('assets/')
                            ? SfPdfViewer.asset(
                                artifact.path,
                                key: ValueKey(artifact.path),
                                enableDoubleTapZooming: true,
                                enableTextSelection: false,
                                canShowScrollHead: true,
                                canShowScrollStatus: true,
                                pageSpacing: 4,
                                pageLayoutMode: PdfPageLayoutMode.single,
                                scrollDirection: PdfScrollDirection.vertical,
                              )
                            : SfPdfViewer.file(
                                File(artifact.path),
                                key: ValueKey(artifact.path),
                                enableDoubleTapZooming: true,
                                enableTextSelection: false,
                                canShowScrollHead: true,
                                canShowScrollStatus: true,
                                pageSpacing: 4,
                                pageLayoutMode: PdfPageLayoutMode.single,
                                scrollDirection: PdfScrollDirection.vertical,
                              ),
                        // No DrawingCanvas here for preview (only in modal)
                      ],
                    ),
                  ),
                );
              case ArtifactType.video:
                return _buildVideoPreview(artifact);
              default:
                return _buildPlaceholder(artifact);
            }
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => _buildPlaceholder(artifact),
        );
      },
    );
  }

  Widget _buildArtifactPreviewWithKey(artifact) {
    print('USING _buildArtifactPreviewWithKey for artifact  [35m${artifact.id} [0m');
    final canvasKey = _getCanvasKey(artifact.id); // <-- assign once here
    return Consumer(
      builder: (context, ref, _) {
        final reviewAsync = ref.watch(reviewForArtifactProvider(artifact.id));
        return reviewAsync.when(
          data: (review) {
            final initialPoints = review?.annotations;
            switch (artifact.type) {
              case ArtifactType.image:
                print('Artifact image path: ${artifact.path}');
                return Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _isFullView
                          ? Container(
                              key: const ValueKey('full'),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[100],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    artifact.path.startsWith('assets/')
                                        ? (() { print('Using Image.asset: ${artifact.path}'); return Image.asset(
                                            artifact.path,
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ); })()
                                        : artifact.path.startsWith('http')
                                            ? (() { print('Using Image.network: ${artifact.path}'); return Image.network(
                                                artifact.path,
                                                fit: BoxFit.contain,
                                                width: double.infinity,
                                                height: double.infinity,
                                                errorBuilder: (context, error, stackTrace) => const Center(
                                                  child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                                ),
                                              ); })()
                                            : (() { print('Using Image.file: ${artifact.path}'); return Image.file(
                                                File(artifact.path),
                                                fit: BoxFit.contain,
                                                width: double.infinity,
                                                height: double.infinity,
                                                errorBuilder: (context, error, stackTrace) => const Center(
                                                  child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                                ),
                                              ); })(),
                                    Positioned.fill(
                                      child: DrawingCanvas(
                                        key: canvasKey,
                                        artifactId: artifact.id,
                                        initialPoints: initialPoints,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              key: const ValueKey('scroll'),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[100],
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    children: [
                                      artifact.path.startsWith('assets/')
                                          ? (() { print('Using Image.asset: ${artifact.path}'); return Image.asset(
                                              artifact.path,
                                              fit: BoxFit.contain,
                                              width: double.infinity,
                                            ); })()
                                          : artifact.path.startsWith('http')
                                              ? (() { print('Using Image.network: ${artifact.path}'); return Image.network(
                                                  artifact.path,
                                                  fit: BoxFit.contain,
                                                  width: double.infinity,
                                                  errorBuilder: (context, error, stackTrace) => const Center(
                                                    child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                                  ),
                                                ); })()
                                              : (() { print('Using Image.file: ${artifact.path}'); return Image.file(
                                                  File(artifact.path),
                                                  fit: BoxFit.contain,
                                                  width: double.infinity,
                                                  errorBuilder: (context, error, stackTrace) => const Center(
                                                    child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                                  ),
                                                ); })(),
                                      Positioned.fill(
                                        child: DrawingCanvas(
                                          key: canvasKey,
                                          artifactId: artifact.id,
                                          initialPoints: initialPoints,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                    // Toggle button with fade background
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                setState(() {
                                  _isFullView = !_isFullView;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isFullView ? 'Full View' : 'Scroll View',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _isFullView ? Icons.fullscreen_exit : Icons.fullscreen,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Toolbar overlay at the bottom
                    if (_showToolbar)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 32,
                                  child: DrawingToolbar(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                                tooltip: 'Hide Toolbar',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: () {
                                  setState(() {
                                    _showToolbar = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!_showToolbar)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 8,
                        child: Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showToolbar = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.brush, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('Show Toolbar', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  SizedBox(width: 2),
                                  Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Eraser slider popup (above toolbar, centered)
                    if (_showToolbar)
                      Consumer(
                        builder: (context, ref, _) {
                          final settings = ref.watch(drawingSettingsProvider);
                          if (!settings.isEraser) return const SizedBox.shrink();
                          return Positioned(
                            left: 12,
                            bottom: 54,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Eraser size indicator
                                Container(
                                  width: settings.strokeWidth,
                                  height: settings.strokeWidth,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Slider
                                Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    width: 140,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.18),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Consumer(
                                      builder: (context, ref, _) {
                                        final settings = ref.watch(drawingSettingsProvider);
                                        final notifier = ref.read(drawingSettingsProvider.notifier);
                                        return Slider(
                                          value: settings.strokeWidth,
                                          min: 8.0,
                                          max: 40.0,
                                          divisions: 16,
                                          onChanged: (value) => notifier.setStrokeWidth(value),
                                          activeColor: Colors.white,
                                          inactiveColor: Colors.white24,
                                          thumbColor: Colors.white,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                );
              case ArtifactType.document:
                final isAsset = artifact.path.startsWith('assets/');
                final pdfWidget = isAsset
                    ? SfPdfViewer.asset(
                        artifact.path,
                        key: ValueKey(artifact.path),
                        canShowScrollHead: false,
                        canShowScrollStatus: false,
                        enableDoubleTapZooming: false,
                        pageLayoutMode: PdfPageLayoutMode.single,
                        scrollDirection: PdfScrollDirection.vertical,
                      )
                    : SfPdfViewer.file(
                        File(artifact.path),
                        key: ValueKey(artifact.path),
                        canShowScrollHead: false,
                        canShowScrollStatus: false,
                        enableDoubleTapZooming: false,
                        pageLayoutMode: PdfPageLayoutMode.single,
                        scrollDirection: PdfScrollDirection.vertical,
                      );
                final settings = ref.watch(drawingSettingsProvider);
                final drawingModeActive = settings.isEraser || settings.color != null; // true if pen or eraser is active
                return SizedBox(
                  height: 420,
                  child: Stack(
                    children: [
                      pdfWidget,
                      IgnorePointer(
                        ignoring: !drawingModeActive, // Only allow drawing when a tool is active
                        child: ClipRect(
                          child: SizedBox.expand(
                            child: DrawingCanvas(
                              key: canvasKey,
                              artifactId: artifact.id,
                              initialPoints: initialPoints,
                            ),
                          ),
                        ),
                      ),
                      // Toolbar overlays as before
                      if (_showToolbar)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 32,
                                    child: DrawingToolbar(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                                  tooltip: 'Hide Toolbar',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  onPressed: () {
                                    setState(() {
                                      _showToolbar = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (!_showToolbar)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 8,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showToolbar = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.brush, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text('Show Toolbar', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    SizedBox(width: 2),
                                    Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              case ArtifactType.video:
                return _buildVideoPreview(artifact);
              default:
                return _buildPlaceholder(artifact);
            }
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => _buildPlaceholder(artifact),
        );
      },
    );
  }

  Widget _buildVideoPreview(artifact) {
    return Container(
      color: AppTheme.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Removed icon
            const SizedBox(height: 16),
            Text(
              artifact.name.replaceAll(RegExp(r'\.[^\.]+$'), ''),
              style: AppTheme.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Video File',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(artifact) {
    return Container(
      color: AppTheme.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Removed icon
            const SizedBox(height: 16),
            Text(
              artifact.name.replaceAll(RegExp(r'\.[^\.]+$'), ''),
              style: AppTheme.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Image not available',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm(String artifactId) {
    return Consumer(
      builder: (context, ref, child) {
        final reviewAsync = ref.watch(reviewForArtifactProvider(artifactId));
        String? savedComment;
        reviewAsync.whenData((review) {
          savedComment = review?.comment;
        });
        if (_commentController == null || _lastArtifactId != artifactId) {
          _commentController?.dispose();
          _commentController = TextEditingController(text: savedComment ?? '');
          _lastArtifactId = artifactId;
        }
        return Column(
          children: [
            // Comment input
            TextField(
              controller: _commentController,
              decoration: AppTheme.inputDecoration.copyWith(
                hintText: 'Add your comment...',
                labelText: 'Comment',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            // (Removed old DrawingToolbar here)
            // Save as Edited Image button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () async {
                  // TODO: Render the image with drawing overlay and save as a new file
                  // TODO: Update the artifact to use the new image and mark as edited
                  // Show a snackbar for now
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Save : Not yet implemented')),
                  );
                },
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 8),
            // Reset Drawing button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: () async {
                  // TODO: Restore the original image and remove the edited tag
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reset Drawing: Not yet implemented')),
                  );
                },
                child: const Text('Reset Drawing'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildReviewFormWithSave(artifact) {
    final artifactId = artifact.id;
    final canvasKey = _getCanvasKey(artifactId); // <-- use same key as preview
    return Consumer(
      builder: (context, ref, child) {
        final reviewAsync = ref.watch(reviewForArtifactProvider(artifactId));
        String? savedComment;
        reviewAsync.whenData((review) {
          savedComment = review?.comment;
        });
        if (_commentController == null || _lastArtifactId != artifactId) {
          _commentController?.dispose();
          _commentController = TextEditingController(text: savedComment ?? '');
          _lastArtifactId = artifactId;
        }
        return Column(
          children: [
            // Comment input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: CustomPaint(
                painter: DashedBorderPainter(
                  color: Color(0xFFE0E0E0),
                  strokeWidth: 2.2,
                  gap: 7,
                  dashLength: 12,
                  radius: 8,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add your comment...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    maxLines: 2,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Post Comment button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF36383A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  try {
                    final comment = _commentController?.text ?? '';
                    print('DEBUG: Attempting to save comment: "$comment" for artifact: ${artifact.id}');
                    if (comment.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a comment.')),
                      );
                      return;
                    }
                    final review = Review.create(
                      artifactId: artifact.id,
                      comment: comment,
                      annotations: [], // Only comment, no drawing
                    );
                    final saveReviewUseCase = ref.read(saveReviewUseCaseProvider);
                    await saveReviewUseCase(review);
                    ref.invalidate(reviewForArtifactProvider(artifact.id));
                    ref.invalidate(reviewsForArtifactProvider(artifact.id));
                    _commentController?.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Comment posted!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Post Comment'),
              ),
            ),
            const SizedBox(height: 8),
            // Save Drawing button (only for images)
            if (artifact.type == ArtifactType.image)
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton(
                  onPressed: () async {
                    // Show custom animated loader
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => Center(
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LoadingAnimationWidget.staggeredDotsWave(
                                color: const Color(0xFF36383A),
                                size: 48,
                              ),
                              const SizedBox(height: 18),
                              const Text('Saving drawing...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                            ],
                          ),
                        ),
                      ),
                    );
                    try {
                      print('Save Drawing: using canvasKey=$canvasKey, currentState= [33m${canvasKey.currentState} [0m');
                      final points = canvasKey.currentState?.points ?? [];
                      final displaySize = canvasKey.currentState?.lastPaintSize;
                      print('Save Drawing: points=${points.length}, artifactId=$artifactId, displaySize=$displaySize, canvasKey=$canvasKey');
                      if (points.isEmpty) {
                        Navigator.of(context, rootNavigator: true).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No drawing to save.')),
                        );
                        return;
                      }
                      final newPath = await _renderAndSaveEditedImage(
                        baseImagePath: artifact.path,
                        points: points,
                        comment: '', // No comment
                        artifactId: artifact.id,
                        displaySize: displaySize, // <-- pass display size
                      );
                      // Save the review with only drawing/annotations
                      final review = Review.create(
                        artifactId: artifact.id,
                        comment: '',
                        annotations: points.whereType<DrawingPoint>().toList(),
                      );
                      final saveReviewUseCase = ref.read(saveReviewUseCaseProvider);
                      await saveReviewUseCase(review);
                      // Update the artifact path
                      final artifactRepository = ref.read(artifactRepositoryProvider);
                      await artifactRepository.updateArtifact(artifact.copyWith(path: newPath));
                      ref.read(refreshTriggerProvider.notifier).state++;
                      ref.invalidate(artifactsProvider);
                      ref.read(artifactExpansionProvider.notifier).expandArtifact(artifact.copyWith(path: newPath));
                      Navigator.of(context, rootNavigator: true).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Drawing saved!')),
                      );
                    } catch (e) {
                      Navigator.of(context, rootNavigator: true).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: const Text('Save Drawing'),
                ),
              ),
            const SizedBox(height: 8),
            // Reset Drawing button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: () async {
                  try {
                    // Find the original path (assets/)
                    final originalPath = artifact.path.startsWith('assets/')
                        ? artifact.path
                        : 'assets/images/${artifact.name}';
                    final artifactRepository = ref.read(artifactRepositoryProvider);
                    await artifactRepository.updateArtifact(artifact.copyWith(path: originalPath));
                    ref.read(refreshTriggerProvider.notifier).state++;
                    ref.invalidate(artifactsProvider);
                    ref.read(artifactExpansionProvider.notifier).expandArtifact(artifact.copyWith(path: originalPath));
                    // Clear the drawing canvas
                    print('Reset Drawing: using canvasKey=$canvasKey, currentState=${canvasKey.currentState}');
                    canvasKey.currentState?.clearCanvas();
                    // Clear the comment field
                    _commentController?.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Drawing reset to original image.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Reset Drawing'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

Future<String> _renderAndSaveEditedImage({
  required String baseImagePath,
  required List points,
  required String comment,
  required String artifactId,
  Size? displaySize, // <-- Add displaySize parameter
}) async {
  // Helper to convert custom paint to ui.Paint
  ui.StrokeCap _toUiStrokeCap(dynamic cap) {
    switch (cap?.index) {
      case 0:
        return ui.StrokeCap.butt;
      case 1:
        return ui.StrokeCap.round;
      case 2:
        return ui.StrokeCap.square;
      default:
        return ui.StrokeCap.round;
    }
  }
  ui.StrokeJoin _toUiStrokeJoin(dynamic join) {
    switch (join?.index) {
      case 0:
        return ui.StrokeJoin.miter;
      case 1:
        return ui.StrokeJoin.round;
      case 2:
        return ui.StrokeJoin.bevel;
      default:
        return ui.StrokeJoin.round;
    }
  }
  ui.Paint _toUiPaint(dynamic paint) {
    return ui.Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = paint.style?.index == 0 ? ui.PaintingStyle.fill : ui.PaintingStyle.stroke
      ..strokeCap = _toUiStrokeCap(paint.strokeCap)
      ..strokeJoin = _toUiStrokeJoin(paint.strokeJoin);
  }

  // Load the base image
  final bytes = await File(baseImagePath).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final baseImage = frame.image;

  // Set up canvas size
  final width = baseImage.width;
  final height = baseImage.height + 60; // Extra space for comment
  final scaleX = width / (displaySize?.width ?? width);
  final scaleY = height / (displaySize?.height ?? height);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

  // Draw the base image
  canvas.drawImage(baseImage, ui.Offset.zero, ui.Paint());

  // Draw the drawing points (convert to Offset and Paint)
  for (int i = 0; i < points.length - 1; i++) {
    final current = points[i];
    final next = points[i + 1];
    if (current == null || next == null) continue;
    final paint = _toUiPaint(current.paint);
    final p1 = current.point;
    final p2 = next.point;
    if (p1 != null && p2 != null) {
      final scaledP1 = Offset(p1.dx * scaleX, p1.dy * scaleY);
      final scaledP2 = Offset(p2.dx * scaleX, p2.dy * scaleY);
      canvas.drawLine(scaledP1, scaledP2, paint);
    }
  }

  // Draw the comment as a caption
  final textPainter = TextPainter(
    text: TextSpan(
      text: comment,
      style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  );
  textPainter.layout(maxWidth: width.toDouble());
  textPainter.paint(canvas, Offset(0, height - 50));

  // End recording and convert to image
  final picture = recorder.endRecording();
  final img = await picture.toImage(width, height);
  final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

  // Save to file
  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/artifact_${artifactId}_edited_${DateTime.now().millisecondsSinceEpoch}.png';
  final file = File(filePath);
  await file.writeAsBytes(pngBytes!.buffer.asUint8List());
  print('Saved edited image to: ' + filePath + ', exists: ' + (await file.exists()).toString() + ', size: ' + (await file.length()).toString());
  return filePath;
}

class _PreviousReviewsDialog extends ConsumerWidget {
  final String artifactId;
  const _PreviousReviewsDialog({required this.artifactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the proper provider from dependency injection
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        height: 480,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Previously Saved Comments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Review>>(
                  future: _fetchReviewsForArtifact(ref, artifactId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final reviews = snapshot.data ?? [];
                    if (reviews.isEmpty) {
                      return const Center(child: Text('No previous comments found.'));
                    }
                    return ListView.separated(
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.comment,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Saved: ${_formatDateTime(review.createdAt)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Review>> _fetchReviewsForArtifact(WidgetRef ref, String artifactId) async {
    // Use the proper provider from dependency injection
    final useCase = ref.read(getReviewsByArtifactUseCaseProvider);
    return await useCase(artifactId);
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
} 

// Add the Review Tab Section widget
class _ReviewTabSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artifactsAsync = ref.watch(artifactsProvider);
    return Container(
      width: double.infinity,
      color: Colors.black.withOpacity(0.10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review History',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          artifactsAsync.when(
            data: (artifacts) {
              if (artifacts.isEmpty) {
                return const Text('No artifacts found.', style: TextStyle(color: Colors.white70));
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: artifacts.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white24),
                itemBuilder: (context, index) {
                  final artifact = artifacts[index];
                  return _ArtifactReviewHistory(artifact: artifact);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => const Text('Error loading artifacts', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ArtifactReviewHistory extends ConsumerWidget {
  final dynamic artifact;
  const _ArtifactReviewHistory({required this.artifact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getReviewsByArtifact = ref.read(getReviewsByArtifactUseCaseProvider);
    return FutureBuilder<List<Review>>(
      future: getReviewsByArtifact(artifact.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          );
        }
        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return ListTile(
            title: Text(
              artifact.name.replaceAll(RegExp(r'\.[^\.]+$'), ''),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('No previous reviews.', style: TextStyle(color: Colors.white70)),
          );
        }
        return ExpansionTile(
          title: Text(
            artifact.name.replaceAll(RegExp(r'\.[^\.]+$'), ''),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${reviews.length} review(s)', style: const TextStyle(color: Colors.white70)),
          children: reviews.map((review) {
            return ListTile(
              title: Text(review.comment, style: const TextStyle(color: Colors.white)),
              subtitle: Text('Saved: ${_formatDateTime(review.createdAt)}', style: const TextStyle(color: Colors.white54)),
              // Optionally, show a thumbnail of the annotated version if available
            );
          }).toList(),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
} 

class _ArtifactCommentsFeed extends ConsumerWidget {
  final String artifactId;
  const _ArtifactCommentsFeed({required this.artifactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsForArtifactProvider(artifactId));
    return reviewsAsync.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => const SizedBox(
        height: 60,
        child: Center(child: Text('Error loading comments', style: TextStyle(color: Colors.red))),
      ),
      data: (reviews) {
        final filtered = reviews.where((review) => review.comment.trim().isNotEmpty).toList();
        print('DEBUG: Comments feed for artifact $artifactId: ${filtered.map((r) => r.comment).toList()}');
        if (filtered.isEmpty) {
          return const SizedBox(
            height: 60,
            child: Center(child: Text('No comments yet.', style: TextStyle(color: Colors.grey))),
          );
        }
        return SizedBox(
          height: 180,
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final review = filtered[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.comment,
                              style: const TextStyle(fontSize: 15, color: Colors.black87),
                            ),
                            Text(
                              _formatDateTime(review.createdAt),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
} 