import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:genga/shared/animations/springs.dart';

/// A pressable wrapper that responds to touch with a spring-based
/// scale and opacity animation, giving every tappable element a
/// physical, alive feel.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
    this.haptic = false,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this, value: 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateScale(double target) {
    if (GengaMotion.reduced(context)) {
      _controller.value = 1.0;
      return;
    }
    final simulation = SpringSimulation(
      GengaSprings.snappySpring,
      _controller.value,
      target,
      0, // zero velocity
    );
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled
          ? (_) {
              setState(() => _pressed = true);
              _animateScale(widget.scale);
            }
          : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              _animateScale(1.0);
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () {
        setState(() => _pressed = false);
        _animateScale(1.0);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _controller.value,
            child: AnimatedOpacity(
              opacity: _pressed ? 0.7 : 1.0,
              duration: _pressed
                  ? GengaSprings.pressDuration
                  : GengaSprings.releaseDuration,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
