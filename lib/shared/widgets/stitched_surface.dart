import 'package:flutter/cupertino.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/shared/animations/springs.dart';

class StitchedSurface extends StatelessWidget {
  final Color tint;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Widget child;

  const StitchedSurface({
    super.key,
    required this.tint,
    required this.child,
    this.radius = 28,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: GengaSprings.slow,
      curve: GengaSprings.smooth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Color.alphaBlend(
          tint.withValues(alpha: 0.07),
          GengaColors.surface,
        ),
        border: Border.all(color: GengaColors.borderLight, width: 0.5),
      ),
      child: CustomPaint(
        painter: _StitchPainter(tint.withValues(alpha: 0.35), radius - 6),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _StitchPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _StitchPainter(this.color, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(7, 7, size.width - 14, size.height - 14);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_StitchPainter old) =>
      old.color != color || old.radius != radius;
}
