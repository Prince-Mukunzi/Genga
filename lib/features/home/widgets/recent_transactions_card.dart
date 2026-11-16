import 'package:flutter/cupertino.dart';
import 'package:genga/shared/widgets/genga_sheets.dart';

import 'package:genga/shared/widgets/empty_activity.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/providers/database_provider.dart';
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/features/transactions/add_transaction_screen.dart';
import 'package:genga/features/transactions/widgets/transaction_detail_sheet.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/widgets/pressable.dart';
import 'package:genga/shared/widgets/transaction_tile.dart';

class RecentTransactionsCard extends ConsumerStatefulWidget {
  const RecentTransactionsCard({super.key});

  @override
  ConsumerState<RecentTransactionsCard> createState() =>
      _RecentTransactionsCardState();
}

class _RecentTransactionsCardState extends ConsumerState<RecentTransactionsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(recentTransactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: GengaTypography.callout.copyWith(
            fontWeight: FontWeight.w700,
            color: GengaColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: GengaColors.surface,
          ),
          child: recent.when(
            data: (txns) {
              if (txns.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: EmptyActivity(title: 'No transactions yet'),
                );
              }

              if (!_hasAnimated) {
                _hasAnimated = true;
                _staggerController.forward();
              }

              return Column(
                children: [
                  for (var i = 0; i < txns.length; i++) ...[
                    _StaggeredItem(
                      index: i,
                      total: txns.length,
                      controller: _staggerController,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Dismissible(
                          key: ValueKey(txns[i].transaction.id),
                          direction: DismissDirection.horizontal,
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            color: GengaColors.dynamicAccent(context),
                            child: const AppIcon(
                              AppIcons.pencil,
                              color: GengaColors.onOffWhite,
                              size: 20,
                            ),
                          ),
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: GengaColors.destructive,
                            child: const AppIcon(
                              AppIcons.trash,
                              color: GengaColors.onOffWhite,
                              size: 20,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            HapticFeedback.mediumImpact();
                            if (direction == DismissDirection.startToEnd) {
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  fullscreenDialog: true,
                                  builder: (_) =>
                                      AddTransactionScreen(editing: txns[i]),
                                ),
                              );
                              return false;
                            }
                            return await showGengaConfirm(
                              context,
                              title: 'Delete transaction',
                              message: 'This action cannot be undone.',
                              confirmLabel: 'Delete',
                              destructive: true,
                            );
                          },
                          onDismissed: (_) {
                            ref
                                .read(databaseProvider)
                                .deleteTransaction(txns[i].transaction.id);
                          },
                          child: TransactionTile(
                            data: txns[i],
                            onTap: () => showTransactionDetail(
                              context: context,
                              data: txns[i],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (i < txns.length - 1)
                      Container(
                        height: 0.5,
                        color: GengaColors.textPrimary.withValues(alpha: 0.06),
                      ),
                  ],
                  Container(
                    height: 0.5,
                    color: GengaColors.textPrimary.withValues(alpha: 0.06),
                  ),
                  _StaggeredItem(
                    index: txns.length,
                    total: txns.length + 1,
                    controller: _staggerController,
                    child: Pressable(
                      scale: 0.98,
                      haptic: true,
                      onTap: () => context.push('/transactions'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'All Transactions',
                                style: GengaTypography.callout.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const AppIcon(
                              AppIcons.chevronRight,
                              size: 14,
                              color: GengaColors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CupertinoActivityIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Text('Failed to load', style: GengaTypography.subhead),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        e.toString(),
                        style: GengaTypography.caption2.copyWith(
                          color: GengaColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StaggeredItem extends StatelessWidget {
  final int index;
  final int total;
  final AnimationController controller;
  final Widget child;

  const _StaggeredItem({
    required this.index,
    required this.total,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index / (total + 1)).clamp(0.0, 0.8);
    final end = ((index + 1.5) / (total + 1)).clamp(start + 0.1, 1.0);

    final opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
    final slideY = Tween<double>(begin: 10, end: 0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: GengaSprings.smooth),
      ),
    );
    final slideX = Tween<double>(begin: 8, end: 0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: GengaSprings.smooth),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(slideX.value, slideY.value),
          child: Opacity(opacity: opacity.value.clamp(0.0, 1.0), child: child),
        );
      },
    );
  }
}
