import 'package:flutter/cupertino.dart';
import 'package:genga/shared/widgets/figure_row.dart';
import 'package:genga/core/services/ussd_service.dart';
import 'package:genga/shared/widgets/empty_activity.dart';
import 'package:genga/shared/widgets/genga_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/providers/preferences_provider.dart';
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/features/settings/edit_account_screen.dart';
import 'package:genga/features/transactions/widgets/transaction_detail_sheet.dart';
import 'package:genga/shared/animations/entrance_animation.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:genga/shared/widgets/amount_text.dart';
import 'package:genga/shared/widgets/pressable.dart';
import 'package:genga/shared/widgets/transaction_tile.dart';

import 'widgets/account_card_face.dart';

class AccountDetailScreen extends ConsumerWidget {
  final int accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref
        .watch(accountsProvider)
        .valueOrNull
        ?.where((a) => a.id == accountId)
        .firstOrNull;
    final prefs = ref.watch(preferencesProvider);
    final txns = (ref.watch(allTransactionsProvider).valueOrNull ?? []).where(
      (t) =>
          t.transaction.accountId == accountId ||
          t.transaction.toAccountId == accountId,
    );
    final topPadding = MediaQuery.of(context).padding.top;

    if (account == null) {
      return GengaScaffold(child: SizedBox.shrink());
    }

    final balance =
        ref.watch(accountBalanceProvider(accountId)) * prefs.currencyRate;
    final income =
        ref.watch(accountIncomeThisMonthProvider(accountId)) *
        prefs.currencyRate;
    final spent =
        ref.watch(accountSpentThisMonthProvider(accountId)) *
        prefs.currencyRate;
    final list = txns.toList();

    return GengaScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Row(
                    children: [
                      _RoundButton(
                        icon: AppIcons.back,
                        onTap: () => context.pop(),
                      ),
                      const Spacer(),
                      Text(
                        'Account',
                        style: GengaTypography.headline.copyWith(
                          color: GengaColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      _RoundButton(
                        icon: AppIcons.pencil,
                        onTap: () => Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                            builder: (_) => EditAccountScreen(account: account),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: AccountCardFace(
                      account: account,
                      heroTag: accountHeroTag(account.id),
                      balanceText: AmountText.format(
                        balance,
                        currency: prefs.currency,
                      ),
                      large: true,
                      onCheckBalance: balanceDialerFor(account),
                    ),
                  ),
                  const SizedBox(height: 22),
                  EntranceAnimation.stagger(
                    index: 1,
                    child: Row(
                      children: [
                        Figure(
                          icon: AppIcons.arrowDownLeft,
                          color: GengaColors.income,
                          label: 'Income',
                          value: AmountText.plain(income),
                        ),
                        const FigureRule(),
                        Figure(
                          icon: AppIcons.arrowUpRight,
                          color: GengaColors.expense,
                          label: 'Spent',
                          value: AmountText.plain(spent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Transactions',
                      style: GengaTypography.headline.copyWith(
                        color: GengaColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          if (list.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: EmptyActivity(
                  title: 'No transactions yet',
                  hint: 'Spending from this account will show up here',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: list.length,
                itemBuilder: (context, i) => EntranceAnimation.stagger(
                  index: (i + 2).clamp(0, 10),
                  slideOffset: 14,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TransactionTile(
                      data: list[i],
                      onTap: () => showTransactionDetail(
                        context: context,
                        data: list[i],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final HugeIconData icon;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.9,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: GengaColors.surfaceElevated,
        ),
        child: Center(
          child: AppIcon(icon, size: 20, color: GengaColors.textPrimary),
        ),
      ),
    );
  }
}
