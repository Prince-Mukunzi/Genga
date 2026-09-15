import 'package:flutter/cupertino.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/shared/animations/springs.dart';

/// Animated amount display that scales & fades on change, with
/// direction-aware vertical slide (up when increasing, down when decreasing).
class AnimatedAmount extends StatefulWidget {
  final String displayText;
  final TextStyle? style;

  const AnimatedAmount({super.key, required this.displayText, this.style});

  @override
  State<AnimatedAmount> createState() => _AnimatedAmountState();
}

class _AnimatedAmountState extends State<AnimatedAmount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;
  String _prevText = '';
  double _prevNumeric = 0;

  @override
  void initState() {
    super.initState();
    _prevText = widget.displayText;
    _prevNumeric = _parseAmount(widget.displayText);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _buildAnimations(slideUp: true);
    _controller.forward();
  }

  void _buildAnimations({required bool slideUp}) {
    _scaleAnim = Tween<double>(
      begin: 1.06,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: GengaSprings.snappy));
    _opacityAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    // Direction-aware: amount slides up when increasing, down when decreasing
    final yOffset = slideUp ? 6.0 : -6.0;
    _slideAnim = Tween<Offset>(
      begin: Offset(0, yOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: GengaSprings.smooth));
  }

  double _parseAmount(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  @override
  void didUpdateWidget(AnimatedAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.displayText != _prevText) {
      final newNumeric = _parseAmount(widget.displayText);
      final isIncreasing = newNumeric >= _prevNumeric;
      _prevText = widget.displayText;
      _prevNumeric = newNumeric;
      _buildAnimations(slideUp: isIncreasing);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: Opacity(
              opacity: _opacityAnim.value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          widget.displayText,
          style: widget.style ?? GengaTypography.amountLarge,
        ),
      ),
    );
  }
}
