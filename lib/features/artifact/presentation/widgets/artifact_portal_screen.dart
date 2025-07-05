import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/artifact_model.dart';
import '../providers/artifact_provider.dart';
import '../../../../di/dependency_injection.dart';
import 'artifact_grid.dart';
import 'modern_navbar.dart';
import 'modern_sidebar.dart';
import 'drawing_canvas.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'drawing_toolbar.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/review.dart';
import '../providers/review_provider.dart';

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
  bool _isSidebarOpen = false;
  int _selectedNavIndex = 1; // Artifacts is selected by default

  TextEditingController? _commentController;
  String? _lastArtifactId;

  // Add a GlobalKey for DrawingCanvasState
  final GlobalKey<DrawingCanvasState> _drawingCanvasKey = GlobalKey<DrawingCanvasState>();

  // Toggle for image full view vs scroll view
  bool _isFullView = false;

  // Add toolbar visibility state
  bool _showToolbar = true;
  bool _showReviewSection = false;

  @override
  void dispose() {
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
              ModernSidebar(
                isOpen: _isSidebarOpen,
                onClose: () => setState(() => _isSidebarOpen = false),
                selectedIndex: _selectedNavIndex,
                onItemSelected: (index) {
                  setState(() {
                    _selectedNavIndex = index;
                    if (index != 1) {
                      // Close expanded artifact when navigating away
                      ref.read(artifactExpansionProvider.notifier).collapseArtifact();
                    }
                  });
                },
              ),
              // Main content
              Expanded(
                child: Column(
                  children: [
                    // Navbar
                    ModernNavbar(
                      title: AppConstants.appName,
                      onMenuPressed: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
                      onSearchPressed: () {
                        // TODO: Implement search
                      },
                      onSettingsPressed: () {
                        // TODO: Implement settings
                      },
                    ),
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
          if (expansionState.isExpanded && expansionState.selectedArtifact != null)
            Consumer(
              builder: (context, ref, _) {
                final artifactsAsync = ref.watch(artifactsProvider);
                return artifactsAsync.when(
                  data: (artifacts) {
                    final artifact = artifacts.firstWhere(
                      (a) => a.id == expansionState.selectedArtifact!.id,
                      orElse: () => expansionState.selectedArtifact!,
                    );
                    return Positioned.fill(
                      child: GestureDetector(
                        onTap: () => ref.read(artifactExpansionProvider.notifier).collapseArtifact(),
                        child: Container(
                          color: Colors.black.withOpacity(0.7),
                          child: Center(
                            child: GestureDetector(
                              onTap: () {}, // Prevent tap from propagating to background
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
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
                                    child: Stack(
                                      children: [
                                        SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Artifact preview - fixed max height
                                              SizedBox(
                                                height: 420,
                                                child: _buildArtifactPreviewWithKey(artifact),
                                              ),
                                              const SizedBox(height: 16),
                                              // Review section
                                              _buildReviewFormWithSave(artifact),
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                width: double.infinity,
                                                child: OutlinedButton.icon(
                                                  icon: const Icon(Icons.history),
                                                  label: const Text('Previously Saved Comments'),
                                                  onPressed: () async {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) {
                                                        return _PreviousReviewsDialog(artifactId: artifact.id);
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(height: 16), // Extra bottom padding
                                            ],
                                          ),
                                        ),
                                        // Close button
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close_rounded, size: 28),
                                            color: Colors.grey.shade700,
                                            onPressed: () => ref.read(artifactExpansionProvider.notifier).collapseArtifact(),
                                            tooltip: 'Close',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => const SizedBox.shrink(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildArtifactPreview(artifact) {
    return Consumer(
      builder: (context, ref, _) {
        final reviewAsync = ref.watch(reviewForArtifactProvider(artifact.id));
        return reviewAsync.when(
          data: (review) {
            final initialPoints = review?.annotations;
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
                        Positioned.fill(
                          child: DrawingCanvas(
                            artifactId: artifact.id,
                            initialPoints: initialPoints,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              case ArtifactType.document:
                return _buildDocumentPreview(artifact, initialPoints);
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
    return Consumer(
      builder: (context, ref, _) {
        final reviewAsync = ref.watch(reviewForArtifactProvider(artifact.id));
        return reviewAsync.when(
          data: (review) {
            final initialPoints = review?.annotations;
            switch (artifact.type) {
              case ArtifactType.image:
                // Debug print for which path is being used
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
                                        key: _drawingCanvasKey,
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
                                          key: _drawingCanvasKey,
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
                return _buildDocumentPreviewWithKey(artifact, initialPoints);
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

  Widget _buildDocumentPreview(artifact, initialPoints) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            SfPdfViewer.asset(
              artifact.path,
              key: ValueKey(artifact.path),
              enableDoubleTapZooming: true,
              enableTextSelection: false,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              pageSpacing: 4,
              pageLayoutMode: PdfPageLayoutMode.single,
              scrollDirection: PdfScrollDirection.vertical,
            ),
            Positioned.fill(
              child: DrawingCanvas(
                artifactId: artifact.id,
                initialPoints: initialPoints,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPreviewWithKey(artifact, initialPoints) {
    return Stack(
      children: [
        SfPdfViewer.asset(
          artifact.path,
          key: ValueKey(artifact.path),
          enableDoubleTapZooming: true,
          enableTextSelection: false,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          pageSpacing: 4,
          pageLayoutMode: PdfPageLayoutMode.single,
          scrollDirection: PdfScrollDirection.vertical,
        ),
        Positioned.fill(
          child: DrawingCanvas(
            key: _drawingCanvasKey,
            artifactId: artifact.id,
            initialPoints: initialPoints,
          ),
        ),
        // Toolbar overlay at the bottom
        if (_showToolbar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(child: DrawingToolbar()),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    tooltip: 'Hide Toolbar',
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.brush, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('Show Toolbar', style: TextStyle(color: Colors.white, fontSize: 13)),
                      SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
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
                    const SnackBar(content: Text('Save as Edited Image: Not yet implemented')),
                  );
                },
                child: const Text('Save as Edited Image'),
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
            // (Removed old DrawingToolbar here)
            // Save as Edited Image button
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
                    final points = _drawingCanvasKey.currentState?.points ?? [];
                    final comment = _commentController?.text ?? '';
                    final newPath = await _renderAndSaveEditedImage(
                      baseImagePath: artifact.path,
                      points: points,
                      comment: comment,
                      artifactId: artifact.id,
                    );
                    
                    // Save the review to the database
                    final review = Review.create(
                      artifactId: artifact.id,
                      comment: comment,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Artifact updated with edited image')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Save as Edited Image'),
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
                        : 'assets/images/${artifact.name}'; // keep for path, not for display
                    final artifactRepository = ref.read(artifactRepositoryProvider);
                    await artifactRepository.updateArtifact(artifact.copyWith(path: originalPath));
                    ref.read(refreshTriggerProvider.notifier).state++;
                    ref.invalidate(artifactsProvider);
                    ref.read(artifactExpansionProvider.notifier).expandArtifact(artifact.copyWith(path: originalPath));
                    // Clear the drawing canvas
                    _drawingCanvasKey.currentState?.clearCanvas();
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
      canvas.drawLine(p1, p2, paint);
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