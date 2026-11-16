import 'package:flutter/cupertino.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:genga/shared/widgets/pressable.dart';

enum GengaButtonStyle { primary, secondary, danger }

class GengaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final GengaButtonStyle style;
  final HugeIconData? icon;
  final bool loading;

  const GengaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.style = GengaButtonStyle.primary,
    this.icon,
    this.loading = false,
  });

  const GengaButton.secondary({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
  }) : style = GengaButtonStyle.secondary;

  const GengaButton.danger({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
  }) : style = GengaButtonStyle.danger;

  static const double height = 54;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    final (fill, fg, border) = switch (style) {
      GengaButtonStyle.primary => (
        GengaColors.offWhite,
        GengaColors.onOffWhite,
        null,
      ),
      GengaButtonStyle.secondary => (
        GengaColors.surfaceElevated,
        GengaColors.textPrimary,
        GengaColors.borderLight,
      ),
      GengaButtonStyle.danger => (
        const Color(0x1AFF453A),
        GengaColors.destructive,
        const Color(0x4DFF453A),
      ),
    };

    return Pressable(
      haptic: true,
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.45 : 1,
        duration: GengaSprings.releaseDuration,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(height / 2),
            border: border == null
                ? null
                : Border.all(color: border, width: 0.5),
          ),
          child: Center(
            child: loading
                ? CupertinoActivityIndicator(color: fg)
                : AnimatedSwitcher(
                    duration: GengaSprings.quick,
                    child: Row(
                      key: ValueKey(label),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          AppIcon(icon!, size: 17, color: fg),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GengaTypography.callout.copyWith(
                              color: fg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
