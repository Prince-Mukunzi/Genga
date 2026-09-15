import 'package:flutter/cupertino.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/models/enums.dart';
import 'package:genga/shared/animations/springs.dart';

class TypeSwitcher extends StatefulWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;
  final bool showTransfer;

  const TypeSwitcher({
    super.key,
    required this.selected,
    required this.onChanged,
    this.showTransfer = true,
  });

  @override
  State<TypeSwitcher> createState() => _TypeSwitcherState();
}

class _TypeSwitcherState extends State<TypeSwitcher>
    with TickerProviderStateMixin {
  late final AnimationController _iconRotation;

  List<TransactionType> get _types => widget.showTransfer
      ? TransactionType.values
      : [TransactionType.expense, TransactionType.income];

  HugeIconData _iconFor(TransactionType type) => switch (type) {
    TransactionType.expense => AppIcons.arrowUpRight,
    TransactionType.income => AppIcons.arrowDownLeft,
    TransactionType.transfer => AppIcons.arrowRightArrowLeft,
  };

  Color _colorFor(TransactionType type) => switch (type) {
    TransactionType.expense => GengaColors.expense,
    TransactionType.income => GengaColors.income,
    TransactionType.transfer => GengaColors.transfer,
  };

  @override
  void initState() {
    super.initState();
    _iconRotation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(TypeSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      _iconRotation.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _iconRotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: GengaColors.surface,
        borderRadius: BorderRadius.circular(54),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in _types)
            type == widget.selected
                ? _ActivePill(
                    type: type,
                    icon: _iconFor(type),
                    color: _colorFor(type),
                    rotationController: _iconRotation,
                  )
                : _InactiveButton(
                    icon: _iconFor(type),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onChanged(type);
                    },
                  ),
        ],
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  final TransactionType type;
  final HugeIconData icon;
  final Color color;
  final AnimationController rotationController;

  const _ActivePill({
    required this.type,
    required this.icon,
    required this.color,
    required this.rotationController,
  });

  @override
  Widget build(BuildContext context) {
    final rotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: rotationController, curve: GengaSprings.snappy),
    );
    final pillScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: rotationController, curve: GengaSprings.snappy),
    );

    return AnimatedBuilder(
      animation: rotationController,
      builder: (context, child) {
        return Transform.scale(
          scale: rotationController.isAnimating ? pillScale.value : 1.0,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: GengaSprings.quick,
        curve: GengaSprings.snappy,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: GengaColors.surfaceElevated,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: rotationController.isAnimating
                      ? rotation.value * 3.14159
                      : 0,
                  child: child,
                );
              },
              child: AnimatedContainer(
                duration: GengaSprings.quick,
                curve: GengaSprings.smooth,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: GengaSprings.quick,
                    child: AppIcon(
                      icon,
                      key: ValueKey(icon),
                      size: 12,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: GengaSprings.quick,
              transitionBuilder: (child, anim) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                );
              },
              child: Text(
                type.label,
                key: ValueKey(type.label),
                style: GengaTypography.subhead.copyWith(
                  color: GengaColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InactiveButton extends StatefulWidget {
  final HugeIconData icon;
  final VoidCallback onTap;

  const _InactiveButton({required this.icon, required this.onTap});

  @override
  State<_InactiveButton> createState() => _InactiveButtonState();
}

class _InactiveButtonState extends State<_InactiveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: Duration(milliseconds: _pressed ? 60 : 150),
        curve: GengaSprings.snappy,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.5 : 0.7,
          duration: Duration(milliseconds: _pressed ? 60 : 150),
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Center(
              child: AppIcon(
                widget.icon,
                size: 16,
                color: GengaColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
