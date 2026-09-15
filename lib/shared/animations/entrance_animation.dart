import 'package:flutter/cupertino.dart';

import 'springs.dart';

/// The direction from which an element enters.
enum EntranceFrom { bottom, top, left, right }

/// A reusable widget that wraps any child with a slide + fade + optional
/// scale entrance animation.
///
/// Use [delay] to create staggered sequences:
/// ```dart
/// EntranceAnimation(delay: GengaSprings.staggerDelay(0), child: ...),
/// EntranceAnimation(delay: GengaSprings.staggerDelay(1), child: ...),
/// EntranceAnimation(delay: GengaSprings.staggerDelay(2), child: ...),
/// ```
class EntranceAnimation extends StatefulWidget {
  final Widget child;

  /// Delay before the entrance starts — use [GengaSprings.staggerDelay].
  final Duration delay;

  /// Total animation duration (after the delay).
  final Duration duration;

  /// Slide offset in logical pixels.
  final double slideOffset;

  /// Direction the element slides from.
  final EntranceFrom from;

  /// Optional scale animation (1.0 = no scale).
  final double initialScale;

  /// Curve for the entrance animation.
  final Curve curve;

  const EntranceAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.slideOffset = 16.0,
    this.from = EntranceFrom.bottom,
    this.initialScale = 1.0,
    this.curve = GengaSprings.smooth,
  });

  /// Quick factory for bottom-up entrances with index-based stagger.
  factory EntranceAnimation.stagger({
    Key? key,
    required int index,
    required Widget child,
    double slideOffset = 16.0,
    EntranceFrom from = EntranceFrom.bottom,
    double initialScale = 1.0,
  }) {
    return EntranceAnimation(
      key: key,
      delay: GengaSprings.staggerDelay(index),
      slideOffset: slideOffset,
      from: from,
      initialScale: initialScale,
      child: child,
    );
  }

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    final offset = _offsetFor(widget.from, widget.slideOffset);
    _slide = Tween<Offset>(begin: offset, end: Offset.zero).animate(curved);

    _scale = Tween<double>(
      begin: widget.initialScale,
      end: 1.0,
    ).animate(curved);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  Offset _offsetFor(EntranceFrom from, double distance) {
    return switch (from) {
      EntranceFrom.bottom => Offset(0, distance),
      EntranceFrom.top => Offset(0, -distance),
      EntranceFrom.left => Offset(-distance, 0),
      EntranceFrom.right => Offset(distance, 0),
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (GengaMotion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slide.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _opacity.value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
