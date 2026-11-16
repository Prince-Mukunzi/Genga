import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/shared/brands/account_brand.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:genga/shared/widgets/pressable.dart';

class DetailsCard extends StatelessWidget {
  final Account? account;
  final String balanceLabel;
  final String dateLabel;
  final String repeatLabel;
  final String noteLabel;
  final bool calcOn;
  final VoidCallback onAccount;
  final VoidCallback onDate;
  final VoidCallback onRepeat;
  final VoidCallback onNote;
  final ValueChanged<bool> onCalc;
  final VoidCallback? onDelete;

  const DetailsCard({
    super.key,
    required this.account,
    required this.balanceLabel,
    required this.dateLabel,
    required this.repeatLabel,
    required this.noteLabel,
    required this.calcOn,
    required this.onAccount,
    required this.onDate,
    required this.onRepeat,
    required this.onNote,
    required this.onCalc,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final brand = brandFor(account?.accountType ?? 'cash');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pressable(
            scale: 0.98,
            onTap: onAccount,
            child: Container(
              height: 64,
              color: const Color(0x00000000),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: brand.isLightCard
                            ? const Color(0x1F000000)
                            : const Color(0x24FFFFFF),
                        width: 0.6,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: BrandBackground(
                        brand: brand,
                        child: Center(
                          child: brand.logoAsset == null
                              ? AppIcon(
                                  brand.icon,
                                  size: 15,
                                  color: brand.onCard,
                                )
                              : BrandLogo(brand: brand, height: 17),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account?.name ?? 'Account',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GengaTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(balanceLabel, style: GengaTypography.footnote),
                      ],
                    ),
                  ),
                  const AppIcon(
                    AppIcons.chevronRight,
                    size: 12,
                    color: GengaColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          const _Rule(),
          _Row(
            icon: AppIcons.calendar,
            label: 'Date',
            value: dateLabel,
            onTap: onDate,
          ),
          const _Rule(),
          _Row(
            icon: AppIcons.arrow2Circlepath,
            label: 'Repeat',
            value: repeatLabel,
            onTap: onRepeat,
          ),
          const _Rule(),
          _Row(
            icon: AppIcons.pencil,
            label: 'Note',
            value: noteLabel,
            onTap: onNote,
          ),
          const _Rule(),
          SizedBox(
            height: 52,
            child: Row(
              children: [
                const AppIcon(
                  AppIcons.calculator,
                  size: 18,
                  color: GengaColors.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Calculator', style: GengaTypography.body),
                ),
                CupertinoSwitch(
                  value: calcOn,
                  activeTrackColor: GengaColors.offWhite,
                  thumbColor: calcOn
                      ? GengaColors.onOffWhite
                      : CupertinoColors.white,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    onCalc(v);
                  },
                ),
              ],
            ),
          ),
          if (onDelete != null) ...[
            const _Rule(),
            Pressable(
              scale: 0.98,
              onTap: onDelete,
              child: Container(
                height: 52,
                color: const Color(0x00000000),
                child: Row(
                  children: [
                    const AppIcon(
                      AppIcons.trash,
                      size: 18,
                      color: GengaColors.destructive,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Delete transaction',
                      style: GengaTypography.body.copyWith(
                        color: GengaColors.destructive,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      Container(height: 0.5, color: GengaColors.border);
}

class _Row extends StatelessWidget {
  final HugeIconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        height: 52,
        color: const Color(0x00000000),
        child: Row(
          children: [
            AppIcon(icon, size: 18, color: GengaColors.textSecondary),
            const SizedBox(width: 14),
            Text(label, style: GengaTypography.body),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: GengaTypography.body.copyWith(
                  color: GengaColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const AppIcon(
              AppIcons.chevronRight,
              size: 12,
              color: GengaColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
