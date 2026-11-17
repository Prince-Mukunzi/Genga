import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:genga/shared/animations/springs.dart';

enum SwipeDismissAxis { down, right }

class SwipeDismiss extends StatefulWidget {
  final SwipeDismissAxis axis;
  final Widget child;

  const SwipeDismiss({super.key, required this.axis, required this.child});

  @override
  State<SwipeDismiss> createState() => _SwipeDismissState();
}

class _SwipeDismissState extends State<SwipeDismiss>
    with SingleTickerProviderStateMixin {
  late final AnimationController _back;
  double _offset = 0;

  bool get _down => widget.axis == SwipeDismissAxis.down;

  @override
  void initState() {
    super.initState();
    _back = AnimationController(vsync: this, duration: GengaSprings.medium)
      ..addListener(() => setState(() => _offset = _from * (1 - _eased)));
  }

  double _from = 0;
  double get _eased => Curves.easeOutCubic.transform(_back.value);

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _update(DragUpdateDetails d) {
    _back.stop();
    setState(() {
      _offset = (_offset + (_down ? d.delta.dy : d.delta.dx)).clamp(
        0.0,
        double.infinity,
      );
    });
  }

  void _end(DragEndDetails d) {
    final velocity = (_down
        ? d.velocity.pixelsPerSecond.dy
        : d.velocity.pixelsPerSecond.dx);
    final size = MediaQuery.of(context).size;
    final limit = (_down ? size.height : size.width) * 0.22;
    if (_offset > limit || velocity > 900) {
      HapticFeedback.selectionClick();
      Navigator.of(context).maybePop();
      return;
    }
    _from = _offset;
    _back.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final detector = _down
        ? GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: _update,
            onVerticalDragEnd: _end,
          )
        : GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: _update,
            onHorizontalDragEnd: _end,
          );

    return Stack(
      children: [
        Transform.translate(
          offset: _down ? Offset(0, _offset) : Offset(_offset, 0),
          child: widget.child,
        ),
        if (_down)
          Positioned(top: 0, left: 0, right: 0, height: 120, child: detector)
        else
          Positioned(top: 0, bottom: 0, left: 0, width: 24, child: detector),
      ],
    );
  }
}
