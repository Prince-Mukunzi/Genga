import 'package:flutter/cupertino.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/widgets/pressable.dart';

class SheetTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SheetTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
      child: Row(
        children: [
          Expanded(child: Text(text, style: GengaTypography.title3)),
          ?trailing,
        ],
      ),
    );
  }
}

class SheetOption extends StatelessWidget {
  final Widget? leading;
  final String label;
  final String? detail;
  final bool selected;
  final bool destructive;
  final VoidCallback onTap;

  const SheetOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.detail,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = GengaColors.dynamicAccent(context);

    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: const Color(0x00000000),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Text(
                label,
                style: GengaTypography.body.copyWith(
                  color: destructive
                      ? GengaColors.destructive
                      : selected
                      ? accent
                      : GengaColors.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (detail != null) Text(detail!, style: GengaTypography.subhead),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: GengaSprings.quick,
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accent : const Color(0x00000000),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
