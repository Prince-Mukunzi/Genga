import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/features/transactions/calc_expression.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/shared/animations/springs.dart';

class CalculatorKeypad extends StatefulWidget {
  final ValueChanged<String> onKeyPressed;
  final bool calcMode;

  const CalculatorKeypad({
    super.key,
    required this.onKeyPressed,
    this.calcMode = false,
  });

  static const _plainKeys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  static const _calcKeys = [
    ['1', '2', '3', '÷'],
    ['4', '5', '6', '×'],
    ['7', '8', '9', '−'],
    ['.', '0', '⌫', '+'],
  ];

  @override
  State<CalculatorKeypad> createState() => _CalculatorKeypadState();
}

class _CalculatorKeypadState extends State<CalculatorKeypad>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keys = widget.calcMode
        ? CalculatorKeypad._calcKeys
        : CalculatorKeypad._plainKeys;
    int flatIndex = 0;
    final totalKeys = widget.calcMode ? 16 : 12;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var rowIdx = 0; rowIdx < keys.length; rowIdx++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                for (
                  var colIdx = 0;
                  colIdx < keys[rowIdx].length;
                  colIdx++
                ) ...[
                  if (colIdx > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _StaggeredKey(
                      index: flatIndex++,
                      totalKeys: totalKeys,
                      staggerController: _staggerController,
                      label: keys[rowIdx][colIdx],
                      onTap: widget.onKeyPressed,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Wraps a key with staggered entrance animation.
class _StaggeredKey extends StatelessWidget {
  final int index;
  final int totalKeys;
  final AnimationController staggerController;
  final String label;
  final ValueChanged<String> onTap;

  const _StaggeredKey({
    required this.index,
    required this.totalKeys,
    required this.staggerController,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index / (totalKeys + 2)).clamp(0.0, 0.7);
    final end = ((index + 3) / (totalKeys + 2)).clamp(start + 0.15, 1.0);

    final opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: staggerController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
    final scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: staggerController,
        curve: Interval(start, end, curve: GengaSprings.snappy),
      ),
    );

    return AnimatedBuilder(
      animation: staggerController,
      builder: (context, child) {
        return Transform.scale(
          scale: scale.value,
          child: Opacity(opacity: opacity.value.clamp(0.0, 1.0), child: child),
        );
      },
      child: _Key(label: label, onTap: onTap),
    );
  }
}

class _Key extends StatefulWidget {
  final String label;
  final ValueChanged<String> onTap;

  const _Key({required this.label, required this.onTap});

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool get _isBackspace => widget.label == '⌫';

  late final AnimationController _flashController;
  late final Animation<Color?> _bgColor;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _bgColor = ColorTween(
      begin: const Color(0x00000000),
      end: GengaColors.surfaceElevated,
    ).animate(CurvedAnimation(parent: _flashController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap(widget.label);
    // Background color flash
    _flashController.forward().then((_) {
      if (mounted) _flashController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _handleTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: Duration(milliseconds: _pressed ? 60 : 150),
        curve: GengaSprings.snappy,
        child: AnimatedBuilder(
          animation: _flashController,
          builder: (context, child) {
            return Container(
              height: 54,
              decoration: BoxDecoration(
                color: _bgColor.value ?? const Color(0x00000000),
                borderRadius: BorderRadius.circular(16),
              ),
              child: child,
            );
          },
          child: Center(
            child: _isBackspace
                ? const CustomPaint(
                    size: Size(28, 22),
                    painter: _BackspacePainter(GengaColors.textPrimary),
                  )
                : Text(
                    widget.label,
                    style: GengaTypography.keypad.copyWith(
                      fontSize: 30,
                      color: isCalcOperator(widget.label)
                          ? GengaColors.dynamicAccent(context)
                          : GengaColors.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _BackspacePainter extends CustomPainter {
  final Color color;

  const _BackspacePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final body = Path()
      ..moveTo(w * 0.30, 1)
      ..lineTo(w - 3, 1)
      ..quadraticBezierTo(w - 1, 1, w - 1, 3)
      ..lineTo(w - 1, h - 3)
      ..quadraticBezierTo(w - 1, h - 1, w - 3, h - 1)
      ..lineTo(w * 0.30, h - 1)
      ..lineTo(1, h / 2)
      ..close();
    canvas.drawPath(body, stroke);

    final cx = w * 0.64;
    final cy = h / 2;
    const r = 3.6;
    canvas.drawLine(Offset(cx - r, cy - r), Offset(cx + r, cy + r), stroke);
    canvas.drawLine(Offset(cx + r, cy - r), Offset(cx - r, cy + r), stroke);
  }

  @override
  bool shouldRepaint(_BackspacePainter old) => old.color != color;
}
