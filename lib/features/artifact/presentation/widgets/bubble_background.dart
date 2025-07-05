import 'package:flutter/material.dart';

class BubbleBackground extends StatelessWidget {
  final Widget child;
  const BubbleBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark grey base
        Container(color: const Color(0xFF232526)),
        // Bubbles (glass effect: white to grey gradients, more bubbles)
        Positioned(
          top: -60, left: -40,
          child: _bubble(220, 0.18, Colors.white, Colors.grey.shade800),
        ),
        Positioned(
          top: 120, left: 60,
          child: _bubble(180, 0.10, Colors.white, Colors.grey.shade700),
        ),
        Positioned(
          bottom: -40, right: -60,
          child: _bubble(260, 0.14, Colors.white, Colors.grey.shade900),
        ),
        Positioned(
          top: 60, right: 10,
          child: _bubble(120, 0.12, Colors.white, Colors.grey.shade600),
        ),
        Positioned(
          bottom: 80, left: 30,
          child: _bubble(90, 0.09, Colors.white, Colors.grey.shade700),
        ),
        Positioned(
          bottom: 180, right: 80,
          child: _bubble(70, 0.13, Colors.white, Colors.grey.shade800),
        ),
        // Content
        child,
      ],
    );
  }

  Widget _bubble(double size, double opacity, Color color1, Color color2) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          color1.withOpacity(opacity),
          color2.withOpacity(opacity * 0.7),
          Colors.transparent,
        ],
        stops: [0.0, 0.7, 1.0],
        radius: 0.95,
      ),
      border: Border.all(
        color: Colors.white.withOpacity(0.18),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.white.withOpacity(0.10),
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ],
    ),
  );
} 