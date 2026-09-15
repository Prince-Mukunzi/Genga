import 'package:genga/shared/animations/entrance_animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:genga/core/utils/recurrence.dart';
import 'package:genga/shared/widgets/genga_scaffold.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/models/transaction_with_category.dart';
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/features/transactions/add_transaction_screen.dart';
import 'package:genga/shared/widgets/amount_text.dart';
import 'package:genga/shared/widgets/category_icon.dart';
import 'package:genga/shared/widgets/pressable.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurrings = ref.watch(recurringTransactionsProvider);

    return GengaScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  Pressable(
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
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Recurrings',
                    style: GengaTypography.headline.copyWith(
                      color: GengaColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: recurrings.when(
                data: (list) {
                  if (list.isEmpty) {
                    return _buildEmpty();
                  }
                  return _buildList(context, list);
                },
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (_, _) => const Center(child: Text('Failed to load')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(
            AppIcons.arrow2Circlepath,
            size: 48,
            color: GengaColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'No recurring transactions',
            style: GengaTypography.headline.copyWith(
              color: GengaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Set a transaction to repeat when adding it',
            style: GengaTypography.subhead.copyWith(
              color: GengaColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<TransactionWithCategory> list) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final data = list[index];
        final txn = data.transaction;
        final cat = data.category;

        return EntranceAnimation.stagger(
          index: index.clamp(0, 8),
          slideOffset: 14,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Pressable(
              scale: 0.98,
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => AddTransactionScreen(editing: data),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: GengaColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    if (cat != null)
                      CategoryIcon(
                        iconKey: cat.iconKey,
                        color: Color(cat.color),
                      )
                    else
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: GengaColors.transfer.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: AppIcon(
                            AppIcons.arrowRightArrowLeft,
                            color: GengaColors.transfer,
                            size: 20,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat?.name ?? 'Transfer',
                            style: GengaTypography.callout.copyWith(
                              fontWeight: FontWeight.w600,
                              color: GengaColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: GengaColors.dynamicAccent(context)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _recurrenceShort(txn.recurrence),
                                  style: GengaTypography.caption2.copyWith(
                                    color: GengaColors.dynamicAccent(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Next ${DateFormat.MMMd().format(nextOccurrence(txn.date, txn.recurrence))}',
                                  style: GengaTypography.caption1.copyWith(
                                    color: GengaColors.textTertiary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      flex: 0,
                      child: AmountText(amount: txn.amount, type: txn.type),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _recurrenceShort(String recurrence) => switch (recurrence) {
    'daily' => 'D',
    'weekly' => 'W',
    'monthly' => 'M',
    'yearly' => 'Y',
    _ => recurrence,
  };
}
