import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:genga/shared/widgets/amount_text.dart';
import 'package:genga/shared/widgets/pressable.dart';

import 'package:genga/shared/brands/account_brand.dart';

import 'recurrence_picker.dart';

class AccountPill extends StatelessWidget {
  final Account? account;
  final double balance;
  final double? balanceAfter;
  final String currency;
  final VoidCallback onTap;

  const AccountPill({
    super.key,
    required this.account,
    required this.balance,
    required this.balanceAfter,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brand = brandFor(account?.accountType ?? 'cash');
    final name = account?.name ?? 'Account';
    final after = balanceAfter;

    return Pressable(
      haptic: true,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
        decoration: BoxDecoration(
          color: GengaColors.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: GengaColors.borderLight, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: brand.isLightCard
                      ? const Color(0x1F000000)
                      : const Color(0x24FFFFFF),
                  width: 0.6,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BrandBackground(
                  brand: brand,
                  child: Center(
                    child: brand.logoAsset == null
                        ? AppIcon(brand.icon, size: 14, color: brand.onCard)
                        : BrandLogo(brand: brand, height: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: GengaTypography.subhead.copyWith(
                color: GengaColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: GengaSprings.quick,
              child: Row(
                key: ValueKey(after != null),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AmountText.format(balance, currency: currency),
                    style: GengaTypography.footnote.copyWith(
                      decoration: after != null
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (after != null) ...[
                    const SizedBox(width: 6),
                    const AppIcon(
                      AppIcons.arrowRight,
                      size: 11,
                      color: GengaColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AmountText.format(after, currency: currency),
                      style: GengaTypography.footnote.copyWith(
                        color: GengaColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            const AppIcon(
              AppIcons.chevronDown,
              size: 12,
              color: GengaColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class CurrencyLabel extends StatelessWidget {
  final String currency;
  final VoidCallback onTap;

  const CurrencyLabel({super.key, required this.currency, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      haptic: true,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currency,
              style: GengaTypography.subhead.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(width: 4),
            const AppIcon(
              AppIcons.chevronDown,
              size: 11,
              color: GengaColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class DetailsSummary extends StatelessWidget {
  final DateTime date;
  final Recurrence recurrence;
  final String note;
  final Color tint;
  final VoidCallback onTap;

  const DetailsSummary({
    super.key,
    required this.date,
    required this.recurrence,
    required this.note,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final items = <(HugeIconData, String)>[
      if (!isToday) (AppIcons.calendar, DateFormat.MMMd().format(date)),
      if (recurrence != Recurrence.none)
        (AppIcons.arrow2Circlepath, recurrence.label),
      if (note.isNotEmpty)
        (
          AppIcons.pencil,
          note.length > 18 ? '${note.substring(0, 18)}...' : note,
        ),
    ];

    return AnimatedSize(
      duration: GengaSprings.medium,
      curve: GengaSprings.smooth,
      child: items.isEmpty
          ? const SizedBox(width: double.infinity)
          : Pressable(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    for (final (icon, text) in items)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(icon, size: 14, color: tint),
                          const SizedBox(width: 6),
                          Text(
                            text,
                            style: GengaTypography.footnote.copyWith(
                              color: GengaColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
