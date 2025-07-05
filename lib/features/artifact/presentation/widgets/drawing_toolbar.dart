import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/review_provider.dart';

typedef EraserPressedCallback = void Function();

class DrawingToolbar extends ConsumerWidget {
  final EraserPressedCallback? onEraserPressed;
  const DrawingToolbar({super.key, this.onEraserPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(drawingSettingsProvider);
    final notifier = ref.read(drawingSettingsProvider.notifier);
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Row(
          children: [
            // Eraser toggle
            Stack(
              alignment: Alignment.topCenter,
              children: [
                IconButton(
                  onPressed: () {
                    if (!settings.isEraser) {
                      // Switching to eraser
                      if (settings.strokeWidth < 8.0 || settings.strokeWidth > 40.0) {
                        notifier.setStrokeWidth(20.0);
                      }
                      notifier.setEraser(true);
                    } else {
                      // Switching to pen
                      if (settings.strokeWidth < 1.0 || settings.strokeWidth > 10.0) {
                        notifier.setStrokeWidth(3.0);
                      }
                      notifier.setEraser(false);
                    }
                  },
                  icon: Icon(
                    Icons.auto_fix_high,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Eraser',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  disabledColor: Colors.transparent,
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Color picker
            ...[
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.yellow,
              Colors.black,
            ].map((color) => GestureDetector(
                  onTap: () {
                    if (settings.strokeWidth < 1.0 || settings.strokeWidth > 10.0) {
                      notifier.setStrokeWidth(3.0);
                    }
                    notifier.setColor(color);
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: settings.color == color && !settings.isEraser
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                        width: settings.color == color && !settings.isEraser ? 2 : 1,
                      ),
                    ),
                  ),
                )),
            const SizedBox(width: 8),
            // Stroke width slider (only for pen)
            if (!settings.isEraser)
              Expanded(
                child: Slider(
                  value: settings.strokeWidth,
                  min: 1.0,
                  max: 10.0,
                  divisions: 9,
                  onChanged: (value) => notifier.setStrokeWidth(value),
                ),
              ),
            const SizedBox(width: 8),
            // Clear button
            IconButton(
              onPressed: () => ref.invalidate(drawingSettingsProvider), // This will reset settings
              icon: const Icon(Icons.clear, size: 20, color: Colors.white),
              tooltip: 'Reset Toolbar',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              disabledColor: Colors.transparent,
            ),
          ],
        ),
      ],
    );
  }
}

// Custom painter for downward arrow
class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.55)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 