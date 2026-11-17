import 'package:genga/shared/animations/entrance_animation.dart';

import 'package:flutter/cupertino.dart';
import 'package:genga/shared/widgets/genga_button.dart';

import 'package:genga/shared/widgets/genga_text_field.dart';

import 'package:genga/features/settings/add_account_flow.dart';
import 'package:genga/shared/widgets/genga_scaffold.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/providers/database_provider.dart';
import 'package:genga/core/providers/preferences_provider.dart';
import 'package:genga/core/providers/space_provider.dart';
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/core/services/widget_data_service.dart';
import 'package:genga/shared/widgets/amount_text.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/brands/account_brand.dart';
import 'package:genga/features/home/widgets/account_card_face.dart';
import 'package:genga/shared/widgets/dashed_box.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/core/services/ussd_service.dart';
import 'package:genga/features/settings/edit_account_screen.dart';
import 'package:genga/shared/widgets/pressable.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  bool _expanded = false;

  void _add(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => AddAccountFlow(
          onDone: () => Navigator.of(ctx).pop(),
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final canAdd =
        !ref.watch(isSharedSpaceProvider) || ref.watch(isSpaceAdminProvider);
    final prefs = ref.watch(preferencesProvider);
    final spaceName = ref.watch(activeSpaceProvider).valueOrNull?.name;
    final list = accounts.valueOrNull ?? const <Account>[];
    var total = 0.0;
    for (final a in list) {
      total += ref.watch(accountBalanceProvider(a.id));
    }

    return GengaScaffold(
      child: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Pressable(
                scale: 0.9,
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: GengaColors.surface,
                  ),
                  child: const Center(
                    child: AppIcon(
                      AppIcons.back,
                      color: GengaColors.textPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 8, 20),
              child: Text('Accounts', style: GengaTypography.title1),
            ),
            if (list.isNotEmpty)
              EntranceAnimation.stagger(
                index: 0,
                child: _TotalSummary(
                  count: list.length,
                  total: total * prefs.currencyRate,
                  currency: prefs.currency,
                  brandShares: [
                    for (final a in list)
                      (
                        brandFor(a.accountType).base,
                        ref.watch(accountBalanceProvider(a.id)),
                      ),
                  ],
                ),
              ),
            if (accounts.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CupertinoActivityIndicator()),
              ),
            if (list.isNotEmpty)
              _AccountsDeck(
                accounts: list,
                expanded: _expanded || list.length <= 2,
                canAdd: canAdd,
                onExpand: () {
                  HapticFeedback.selectionClick();
                  setState(() => _expanded = true);
                },
                onAdd: () => _add(context),
              )
            else if (canAdd)
              SizedBox(
                height: _kDeckCard,
                child: _AddCard(onTap: () => _add(context)),
              ),
            if (_expanded && list.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Center(
                  child: Pressable(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _expanded = false);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        'Stack cards',
                        style: GengaTypography.footnote.copyWith(
                          color: GengaColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!canAdd)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                child: Text(
                  'Only admins can add accounts to ${spaceName ?? 'this space'}. You are a member here.',
                  style: GengaTypography.footnote,
                ),
              ),
            if (list.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 18, 8, 0),
                child: Text(
                  'Tap a card to edit it. Press and hold to correct its balance.',
                  style: GengaTypography.caption1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: DashedBox(
        radius: 24,
        fill: const Color(0x08FFFFFF),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon(
                  AppIcons.add,
                  size: 18,
                  color: GengaColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add account',
                  style: GengaTypography.callout.copyWith(
                    color: GengaColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalSummary extends StatelessWidget {
  final int count;
  final double total;
  final String currency;
  final List<(Color, double)> brandShares;

  const _TotalSummary({
    required this.count,
    required this.total,
    required this.currency,
    required this.brandShares,
  });

  @override
  Widget build(BuildContext context) {
    final positive = brandShares.where((e) => e.$2 > 0).toList();
    final sum = positive.fold<double>(0, (m, e) => m + e.$2);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total across $count ${count == 1 ? 'account' : 'accounts'}',
            style: GengaTypography.footnote,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AmountText.withSymbol(total, currency),
              style: GengaTypography.largeTitle.copyWith(
                color: GengaColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (sum > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    for (var i = 0; i < positive.length; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      Expanded(
                        flex: (positive[i].$2 / sum * 1000).round().clamp(
                          8,
                          1000,
                        ),
                        child: ColoredBox(color: positive[i].$1),
                      ),
                    ],
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

const double _kDeckCard = 170;
const double _kDeckPeek = 74;
const double _kDeckGap = 14;

class _AccountsDeck extends StatelessWidget {
  final List<Account> accounts;
  final bool expanded;
  final bool canAdd;
  final VoidCallback onExpand;
  final VoidCallback onAdd;

  const _AccountsDeck({
    required this.accounts,
    required this.expanded,
    required this.canAdd,
    required this.onExpand,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final n = accounts.length;
    final step = expanded ? _kDeckCard + _kDeckGap : _kDeckPeek;
    final deckHeight = (n - 1) * step + _kDeckCard;
    final addTop = deckHeight + (expanded ? _kDeckGap : 18);
    final addHeight = expanded ? _kDeckCard : 76.0;
    final total = canAdd ? addTop + addHeight : deckHeight;

    return AnimatedContainer(
      duration: GengaSprings.slow,
      curve: GengaSprings.smooth,
      height: total,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < n; i++)
            AnimatedPositioned(
              key: ValueKey(accounts[i].id),
              duration: GengaSprings.slow,
              curve: GengaSprings.smooth,
              top: i * step,
              left: 0,
              right: 0,
              height: _kDeckCard,
              child: _AccountRow(
                account: accounts[i],
                expanded: expanded,
                onExpand: onExpand,
              ),
            ),
          if (canAdd)
            AnimatedPositioned(
              duration: GengaSprings.slow,
              curve: GengaSprings.smooth,
              top: addTop,
              left: 0,
              right: 0,
              height: addHeight,
              child: _AddCard(onTap: onAdd),
            ),
        ],
      ),
    );
  }
}

class _AccountRow extends ConsumerWidget {
  final Account account;
  final bool expanded;
  final VoidCallback onExpand;

  const _AccountRow({
    required this.account,
    required this.expanded,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(accountBalanceProvider(account.id));
    final prefs = ref.watch(preferencesProvider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: expanded
          ? () {
              HapticFeedback.mediumImpact();
              _showAdjustBalance(context, ref, account, balance);
            }
          : null,
      child: Pressable(
        scale: 0.98,
        onTap: expanded
            ? () => Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => EditAccountScreen(account: account),
                ),
              )
            : onExpand,
        child: SizedBox(
          height: _kDeckCard,
          child: AccountCardFace(
            account: account,
            large: true,
            balanceText: AmountText.withSymbol(
              balance * prefs.currencyRate,
              prefs.currency,
            ),
            spentText: AmountText.plain(
              ref.watch(accountSpentThisMonthProvider(account.id)) *
                  prefs.currencyRate,
            ),
            onCheckBalance: expanded ? balanceDialerFor(account) : null,
          ),
        ),
      ),
    );
  }

  void _showAdjustBalance(
    BuildContext context,
    WidgetRef ref,
    Account account,
    double currentBalance,
  ) {
    final controller = TextEditingController();

    showGengaBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Adjust Balance',
              style: GengaTypography.headline.copyWith(
                color: GengaColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current: ${AmountText.format(currentBalance)}',
              style: GengaTypography.footnote.copyWith(
                color: GengaColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            GengaTextField(
              controller: controller,
              placeholder: 'New balance',
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              prefixText: 'RWF',
            ),
            const SizedBox(height: 16),
            GengaButton(
              label: 'Adjust',
              onTap: () async {
                final newBalance = double.tryParse(controller.text.trim());
                if (newBalance == null) return;
                final diff = newBalance - currentBalance;
                if (diff == 0) {
                  Navigator.of(ctx).pop();
                  return;
                }
                // Adjust by updating the account's initialBalance directly
                // instead of creating a phantom transaction. This avoids
                // polluting the transaction list and inflating income/expense
                // totals.
                final db = ref.read(databaseProvider);
                final updatedAccount = account.copyWith(
                  initialBalance: account.initialBalance + diff,
                );
                await db.updateAccount(updatedAccount);
                // Sync widget data after adjustment.
                ref.read(widgetDataServiceProvider).updateWidgetData();
                if (ctx.mounted) {
                  HapticFeedback.mediumImpact();
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
