import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';

class NavPillDestination {
  final HugeIconData icon;
  final String label;
  final String path;

  const NavPillDestination(this.icon, this.label, this.path);
}

const navPillDestinations = [
  NavPillDestination(AppIcons.cog, 'Settings', '/settings'),
  NavPillDestination(AppIcons.pieChart, 'Reports', '/analytics'),
  NavPillDestination(AppIcons.houseFill, 'Home', '/'),
];

class NavPill extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const NavPill({super.key, required this.index, required this.onSelect});

  static const double _height = 56;
  static const double _inactiveWidth = 48;
  static const double _activePadding = 16;
  static const double _iconSize = 22;
  static const double _gap = 8;

  double _labelWidth(String label) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: GengaTypography.subhead.copyWith(fontWeight: FontWeight.w700),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final widths = [
      for (var i = 0; i < navPillDestinations.length; i++)
        i == index
            ? _activePadding * 2 +
                  _iconSize +
                  _gap +
                  _labelWidth(navPillDestinations[i].label) +
                  2
            : _inactiveWidth,
    ];
    var left = 0.0;
    for (var i = 0; i < index; i++) {
      left += widths[i];
    }
    final total = widths.fold<double>(0, (a, b) => a + b);
    const curve = Curves.easeOutCubic;
    const duration = GengaSprings.medium;

    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: GengaColors.surfaceElevated.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: GengaColors.borderLight, width: 0.5),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (d) {
              final count = navPillDestinations.length;
              final slot = (d.localPosition.dx / (total / count)).floor();
              final i = slot.clamp(0, count - 1);
              if (i == index) return;
              HapticFeedback.selectionClick();
              onSelect(i);
            },
            child: AnimatedContainer(
              duration: duration,
              curve: curve,
              width: total,
              height: _height,
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: duration,
                    curve: curve,
                    left: left,
                    width: widths[index],
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: GengaColors.offWhite,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < navPillDestinations.length; i++)
                        _PillItem(
                          destination: navPillDestinations[i],
                          active: i == index,
                          width: widths[i],
                          onTap: () {
                            if (i == index) return;
                            HapticFeedback.selectionClick();
                            onSelect(i);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  final NavPillDestination destination;
  final bool active;
  final double width;
  final VoidCallback onTap;

  const _PillItem({
    required this.destination,
    required this.active,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: GengaSprings.medium,
        curve: Curves.easeOutCubic,
        width: width,
        height: NavPill._height,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                destination.icon,
                size: NavPill._iconSize,
                color: active
                    ? GengaColors.onOffWhite
                    : GengaColors.textSecondary,
              ),
              if (active) ...[
                const SizedBox(width: NavPill._gap),
                Flexible(
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: GengaTypography.subhead.copyWith(
                      color: GengaColors.onOffWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
