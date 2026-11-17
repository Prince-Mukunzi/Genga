import 'dart:ui' show PathMetric;

import 'package:flutter/cupertino.dart';

class DashedBox extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color color;
  final Color? fill;

  const DashedBox({
    super.key,
    required this.child,
    this.radius = 22,
    this.color = const Color(0x40EDEAE4),
    this.fill,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedPainter(radius: radius, color: color),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  final double radius;
  final Color color;

  const _DashedPainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(0.5),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = color;
    for (final PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, (d + 6).clamp(0, m.length)), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter old) =>
      old.color != color || old.radius != radius;
}
