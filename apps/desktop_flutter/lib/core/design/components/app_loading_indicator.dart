import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = 40,
    this.strokeWidth = 4,
  });

  final double size;
  final double strokeWidth;

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'جاري التحميل',
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: RotationTransition(
            turns: _controller,
            child: CustomPaint(
              painter: _MulticolorRingPainter(
                strokeWidth: widget.strokeWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MulticolorRingPainter extends CustomPainter {
  const _MulticolorRingPainter({required this.strokeWidth});

  final double strokeWidth;

  static const _colors = <Color>[
    Color(0xFF4285F4),
    Color(0xFFEA4335),
    Color(0xFFFBBC05),
    Color(0xFF34A853),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const sweep = math.pi * 0.38;
    const gap = math.pi * 0.12;
    var start = -math.pi / 2;

    for (final color in _colors) {
      paint.color = color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_MulticolorRingPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth;
  }
}
