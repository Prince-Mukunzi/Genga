import 'package:flutter/cupertino.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/widgets/swipe_dismiss.dart';

class GengaScaffold extends StatelessWidget {
  final Widget child;
  final Color? glow;
  final double intensity;

  const GengaScaffold({
    super.key,
    required this.child,
    this.glow,
    this.intensity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    final target = glow ?? CupertinoTheme.of(context).primaryColor;
    final route = ModalRoute.of(context);

    Widget body = _body(context, target);
    if (route is PageRoute && route.canPop) {
      if (route.fullscreenDialog) {
        body = SwipeDismiss(axis: SwipeDismissAxis.down, child: body);
      } else if (route is! CupertinoRouteTransitionMixin) {
        body = SwipeDismiss(axis: SwipeDismissAxis.right, child: body);
      }
    }
    return body;
  }

  Widget _body(BuildContext context, Color target) {
    return ColoredBox(
      color: GengaColors.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: target),
                duration: GengaSprings.slow,
                builder: (context, color, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.85),
                      radius: 1.0,
                      colors: [
                        (color ?? target).withValues(alpha: intensity),
                        const Color(0x00000000),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          CupertinoPageScaffold(
            backgroundColor: const Color(0x00000000),
            child: child,
          ),
        ],
      ),
    );
  }
}
