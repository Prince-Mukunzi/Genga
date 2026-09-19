import 'package:flutter/cupertino.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/shared/animations/springs.dart';

Future<T?> showGengaBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxHeightFraction = 0.85,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (ctx) => _SheetWrapper(
      maxHeightFraction: maxHeightFraction,
      child: builder(ctx),
    ),
  );
}

class _SheetWrapper extends StatefulWidget {
  final double maxHeightFraction;
  final Widget child;

  const _SheetWrapper({required this.maxHeightFraction, required this.child});

  @override
  State<_SheetWrapper> createState() => _SheetWrapperState();
}

class _SheetWrapperState extends State<_SheetWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _back;
  double _dy = 0;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _back = AnimationController(vsync: this, duration: GengaSprings.medium)
      ..addListener(
        () => setState(
          () => _dy = _from * (1 - Curves.easeOutCubic.transform(_back.value)),
        ),
      );
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _update(DragUpdateDetails d) {
    _back.stop();
    setState(() => _dy = (_dy + d.delta.dy).clamp(0.0, double.infinity));
  }

  void _end(DragEndDetails d) {
    if (_dy > 110 || d.velocity.pixelsPerSecond.dy > 800) {
      Navigator.of(context).maybePop();
      return;
    }
    _from = _dy;
    _back.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _dy),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: _update,
        onVerticalDragEnd: _end,
        child: Container(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * widget.maxHeightFraction,
          ),
          decoration: const BoxDecoration(
            color: GengaColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _AnimatedHandle(),
                Flexible(child: widget.child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated grab handle that pulses width on mount to hint at draggability.
class _AnimatedHandle extends StatefulWidget {
  const _AnimatedHandle();

  @override
  State<_AnimatedHandle> createState() => _AnimatedHandleState();
}

class _AnimatedHandleState extends State<_AnimatedHandle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _width;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _width = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 32, end: 44), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 44, end: 36), weight: 60),
      ],
    ).animate(CurvedAnimation(parent: _controller, curve: GengaSprings.gentle));

    // Start after a short delay to play after sheet settles
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Container(
              width: _controller.isAnimating ? _width.value : 36,
              height: 4,
              decoration: BoxDecoration(
                color: GengaColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
      ),
    );
  }
}
