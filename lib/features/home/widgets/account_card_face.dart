import 'package:flutter/cupertino.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/shared/brands/account_brand.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:genga/shared/widgets/pressable.dart';

String accountHeroTag(int accountId) => 'account-card-$accountId';

class AccountCardFace extends StatelessWidget {
  final Account account;
  final String balanceText;
  final Widget? corner;
  final VoidCallback? onCheckBalance;
  final String? spentText;
  final String? heroTag;
  final bool front;
  final bool large;

  const AccountCardFace({
    super.key,
    required this.account,
    required this.balanceText,
    this.corner,
    this.onCheckBalance,
    this.spentText,
    this.heroTag,
    this.front = true,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final brand = brandFor(account.accountType);

    final sheen = brand.isLightCard
        ? const Color(0x66FFFFFF)
        : const Color(0x33FFFFFF);

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: brand.isLightCard
              ? const Color(0x1F000000)
              : const Color(0x24FFFFFF),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 14,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BrandBackground(
          brand: brand,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.9, -1.1),
                      radius: 1.1,
                      colors: [sheen, const Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: brand.onCard,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.w400,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BrandLogo(brand: brand, height: 30 * brand.logoScale),
                          const Spacer(),
                          corner ??
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  brand.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: brand.onCardMuted,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (account.name != brand.name)
                                  Text(
                                    account.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: brand.onCardMuted,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    balanceText,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                      color: brand.onCard,
                                      decoration: TextDecoration.none,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                                if (spentText != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Spent $spentText this month',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: brand.onCardMuted,
                                      decoration: TextDecoration.none,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (onCheckBalance != null)
                            Pressable(
                              scale: 0.94,
                              haptic: true,
                              onTap: onCheckBalance,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: brand.onCard.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: brand.onCard.withValues(alpha: 0.25),
                                    width: 0.6,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppIcon(
                                      AppIcons.wallet04,
                                      size: 16,
                                      color: brand.onCard,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Balance',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: brand.onCard,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (heroTag == null) return card;
    return Hero(
      tag: heroTag!,
      flightShuttleBuilder: (context, animation, direction, from, to) =>
          DefaultTextStyle(
            style: const TextStyle(decoration: TextDecoration.none),
            child: to.widget,
          ),
      child: card,
    );
  }
}
