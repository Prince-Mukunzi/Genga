import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/genga_button.dart';
import 'package:genga/shared/widgets/sheet_parts.dart';

class SheetAction {
  final String label;
  final VoidCallback onTap;
  final HugeIconData? icon;
  final Widget? leading;
  final String? detail;
  final bool selected;
  final bool destructive;

  const SheetAction({
    required this.label,
    required this.onTap,
    this.icon,
    this.leading,
    this.detail,
    this.selected = false,
    this.destructive = false,
  });
}

Future<void> showGengaActionSheet(
  BuildContext context, {
  required String title,
  String? message,
  required List<SheetAction> actions,
}) {
  return showGengaBottomSheet<void>(
    context: context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetTitle(title),
        if (message != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(message, style: GengaTypography.footnote),
          ),
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                for (final a in actions)
                  SheetOption(
                    label: a.label,
                    detail: a.detail,
                    selected: a.selected,
                    destructive: a.destructive,
                    leading:
                        a.leading ??
                        (a.icon == null
                            ? null
                            : AppIcon(
                                a.icon!,
                                size: 20,
                                color: a.destructive
                                    ? GengaColors.destructive
                                    : GengaColors.textSecondary,
                              )),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(ctx).pop();
                      a.onTap();
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Future<bool> showGengaConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showGengaBottomSheet<bool>(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetTitle(title),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Text(message, style: GengaTypography.subhead),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                if (destructive)
                  GengaButton.danger(
                    label: confirmLabel,
                    onTap: () => Navigator.of(ctx).pop(true),
                  )
                else
                  GengaButton(
                    label: confirmLabel,
                    onTap: () => Navigator.of(ctx).pop(true),
                  ),
                const SizedBox(height: 10),
                GengaButton.secondary(
                  label: cancelLabel,
                  onTap: () => Navigator.of(ctx).pop(false),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
