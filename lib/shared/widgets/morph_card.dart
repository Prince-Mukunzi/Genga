import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/shared/animations/springs.dart';

const _liquid = Cubic(0.2, 0.0, 0.0, 1.0);

Future<void> showMorphCard({
  required BuildContext context,
  required GlobalKey anchor,
  required WidgetBuilder builder,
  required double width,
  required double height,
}) {
  final box = anchor.currentContext?.findRenderObject() as RenderBox?;
  final screen = MediaQuery.of(context).size;
  final topLeft =
      box?.localToGlobal(Offset.zero) ?? Offset(screen.width - 52, 60);
  final size = box?.size ?? const Size(36, 36);
  final from = topLeft & size;
  final to = Rect.fromLTWH(from.right - width, from.top, width, height);

  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: const Color(0x4D000000),
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, animation, _) {
        final reduced = GengaMotion.reduced(ctx);
        final shape = CurvedAnimation(
          parent: animation,
          curve: reduced ? Curves.linear : _liquid,
          reverseCurve: const Cubic(0.5, 0.0, 0.2, 1.0),
        );
        final content = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
          reverseCurve: const Interval(0, 0.35, curve: Curves.easeIn),
        );

        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = shape.value;
            final rect = Rect.lerp(from, to, t) ?? to;
            final w = rect.width;
            final h = rect.height;
            final radius = lerpDouble(from.width / 2, 26, t.clamp(0.0, 1.0))!;

            return Stack(
              children: [
                Positioned(
                  left: rect.right - w,
                  top: rect.top,
                  width: w,
                  height: h,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: GengaColors.surfaceElevated.withValues(
                            alpha: 0.88,
                          ),
                          borderRadius: BorderRadius.circular(radius),
                          border: Border.all(
                            color: GengaColors.borderLight,
                            width: 0.5,
                          ),
                        ),
                        child: OverflowBox(
                          alignment: Alignment.topRight,
                          minWidth: width,
                          maxWidth: width,
                          minHeight: height,
                          maxHeight: height,
                          child: Opacity(
                            opacity: content.value.clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(0, 8 * (1 - content.value)),
                              child: builder(ctx),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      transitionsBuilder: (ctx, animation, _, child) => child,
    ),
  );
}
