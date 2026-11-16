import 'package:flutter/cupertino.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:genga/shared/widgets/pressable.dart';

class GengaFilterChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final HugeIconData? icon;

  const GengaFilterChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.icon,
  });

  @override
  State<GengaFilterChip> createState() => _GengaFilterChipState();
}

class _GengaFilterChipState extends State<GengaFilterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceScale;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 60),
        ]).animate(
          CurvedAnimation(
            parent: _bounceController,
            curve: GengaSprings.gentle,
          ),
        );
  }

  @override
  void didUpdateWidget(GengaFilterChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = GengaColors.dynamicAccent(context);
    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceController.isAnimating ? _bounceScale.value : 1.0,
          child: child,
        );
      },
      child: Pressable(
        haptic: true,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: GengaSprings.quick,
          curve: GengaSprings.smooth,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: GengaColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isActive
                  ? accent.withValues(alpha: 0.4)
                  : GengaColors.border,
              width: widget.isActive ? 1 : 0.5,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: GengaSprings.quick,
            style: GengaTypography.caption1.copyWith(
              color: widget.isActive ? accent : GengaColors.textSecondary,
              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  AppIcon(
                    widget.icon!,
                    size: 14,
                    color: widget.isActive ? accent : GengaColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(widget.label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
