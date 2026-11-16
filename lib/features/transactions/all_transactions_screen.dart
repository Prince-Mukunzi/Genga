import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:genga/shared/widgets/genga_sheets.dart';

import 'package:genga/features/transactions/widgets/transaction_filter_sheet.dart';
import 'package:genga/shared/animations/entrance_animation.dart';
import 'package:genga/shared/widgets/empty_activity.dart';
import 'package:genga/shared/widgets/genga_scaffold.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/models/enums.dart';
import 'package:genga/core/models/transaction_with_category.dart';
import 'package:genga/core/providers/database_provider.dart';
import 'package:genga/core/providers/preferences_provider.dart';
import 'package:genga/shared/widgets/genga_text_field.dart';
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/features/transactions/add_transaction_screen.dart';
import 'package:genga/features/transactions/widgets/transaction_detail_sheet.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/widgets/amount_text.dart';
import 'package:genga/shared/widgets/filter_chip.dart';
import 'package:genga/shared/widgets/pressable.dart';
import 'package:genga/shared/widgets/transaction_tile.dart';

class AllTransactionsScreen extends ConsumerStatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  ConsumerState<AllTransactionsScreen> createState() =>
      _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends ConsumerState<AllTransactionsScreen> {
  String _search = '';
  TransactionType? _typeFilter;
  TxnFilters _filters = TxnFilters.empty;
  bool _searching = false;

  List<TransactionWithCategory> _apply(List<TransactionWithCategory> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = switch (_filters.range) {
      TxnRange.all => null,
      TxnRange.week => today.subtract(const Duration(days: 6)),
      TxnRange.month => DateTime(now.year, now.month, 1),
      TxnRange.last30 => today.subtract(const Duration(days: 29)),
    };
    final q = _search.toLowerCase();

    return list.where((t) {
      final tx = t.transaction;
      if (q.isNotEmpty) {
        final cat = t.category?.name.toLowerCase() ?? '';
        if (!cat.contains(q) && !tx.note.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_typeFilter != null && tx.type != _typeFilter) return false;
      if (_filters.categoryId != null &&
          t.category?.id != _filters.categoryId) {
        return false;
      }
      if (_filters.accountId != null && tx.accountId != _filters.accountId) {
        return false;
      }
      if (from != null && tx.date.isBefore(from)) return false;
      final min = _filters.minAmount;
      if (min != null && tx.amount < min) return false;
      final max = _filters.maxAmount;
      if (max != null && tx.amount > max) return false;
      return true;
    }).toList();
  }

  Future<void> _openFilters() async {
    final result = await showTransactionFilterSheet(context, _filters);
    if (result != null && mounted) setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    final txns = ref.watch(allTransactionsProvider);
    final all = txns.valueOrNull ?? const <TransactionWithCategory>[];

    return GengaScaffold(
      child: Stack(
        children: [
          SafeArea(
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
                        'Transactions',
                        style: GengaTypography.headline.copyWith(
                          color: GengaColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Pressable(
                        scale: 0.9,
                        haptic: true,
                        onTap: () => setState(() => _searching = true),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: GengaColors.surface,
                          ),
                          child: const Center(
                            child: AppIcon(
                              AppIcons.search,
                              color: GengaColors.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: txns.when(
                    data: (list) {
                      final filtered = _apply(list);
                      final body = filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: list.isEmpty
                                    ? const EmptyActivity(
                                        title: 'No transactions yet',
                                        hint: 'Tap + on Home to add one',
                                      )
                                    : const EmptyActivity(
                                        title: 'No results',
                                        hint: 'Try a different filter',
                                        ghostRows: 0,
                                      ),
                              ),
                            )
                          : _buildGroupedList(_groupByDate(filtered));

                      return Column(
                        children: [
                          _Summary(transactions: list),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                            child: _FilterBar(
                              typeFilter: _typeFilter,
                              onTypeChanged: (t) => setState(
                                () => _typeFilter = t == _typeFilter ? null : t,
                              ),
                              onClearType: () =>
                                  setState(() => _typeFilter = null),
                              query: _search,
                              onClearQuery: () => setState(() => _search = ''),
                              activeFilters: _filters.activeCount,
                              onOpenFilters: _openFilters,
                            ),
                          ),
                          Expanded(child: body),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CupertinoActivityIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        'Error loading transactions',
                        style: GengaTypography.subhead,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: GengaSprings.quick,
            child: _searching
                ? _SearchOverlay(
                    key: const ValueKey('search'),
                    initial: _search,
                    results: _apply(all),
                    onChanged: (v) => setState(() => _search = v),
                    onClose: () => setState(() => _searching = false),
                  )
                : const SizedBox.shrink(key: ValueKey('none')),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(
    Map<DateTime, List<TransactionWithCategory>> grouped,
  ) {
    return CustomScrollView(
      slivers: [
        for (final entry in grouped.entries) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _DateHeader(date: entry.key, transactions: entry.value),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: GengaColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < entry.value.length; i++) ...[
                      ClipRRect(
                        borderRadius: i == 0 && entry.value.length == 1
                            ? BorderRadius.circular(12)
                            : i == 0
                            ? const BorderRadius.vertical(
                                top: Radius.circular(12),
                              )
                            : i == entry.value.length - 1
                            ? const BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              )
                            : BorderRadius.zero,
                        child: Dismissible(
                          key: ValueKey(entry.value[i].transaction.id),
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
                                  builder: (_) => AddTransactionScreen(
                                    editing: entry.value[i],
                                  ),
                                ),
                              );
                              return false;
                            }
                            return _confirmDelete(context);
                          },
                          onDismissed: (_) {
                            ref
                                .read(databaseProvider)
                                .deleteTransaction(
                                  entry.value[i].transaction.id,
                                );
                          },
                          child: TransactionTile(
                            data: entry.value[i],
                            onTap: () => showTransactionDetail(
                              context: context,
                              data: entry.value[i],
                            ),
                          ),
                        ),
                      ),
                      if (i < entry.value.length - 1)
                        Container(
                          height: 0.5,
                          color: GengaColors.textPrimary.withValues(
                            alpha: 0.06,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  Map<DateTime, List<TransactionWithCategory>> _groupByDate(
    List<TransactionWithCategory> list,
  ) {
    final map = <DateTime, List<TransactionWithCategory>>{};
    for (final txn in list) {
      final d = txn.transaction.date;
      final key = DateTime(d.year, d.month, d.day);
      (map[key] ??= []).add(txn);
    }
    return map;
  }

  Future<bool> _confirmDelete(BuildContext context) {
    return showGengaConfirm(
      context,
      title: 'Delete transaction',
      message: 'This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final List<TransactionWithCategory> transactions;

  const _DateHeader({required this.date, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String label;
    if (date == today) {
      label = 'Today';
    } else if (date == yesterday) {
      label = 'Yesterday';
    } else if (now.year == date.year) {
      label = DateFormat('EEEE, MMM d').format(date);
    } else {
      label = DateFormat('MMM d, yyyy').format(date);
    }

    double dayTotal = 0;
    for (final t in transactions) {
      if (t.transaction.type == TransactionType.expense) {
        dayTotal -= (t.transaction.amount + t.transaction.momoFee);
      } else if (t.transaction.type == TransactionType.income) {
        dayTotal += t.transaction.amount;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: GengaTypography.footnote,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${dayTotal >= 0 ? '+' : '-'} ${AmountText.format(dayTotal.abs())}',
          style: GengaTypography.footnote.copyWith(
            color: dayTotal >= 0 ? GengaColors.income : GengaColors.expense,
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TransactionType? typeFilter;
  final ValueChanged<TransactionType> onTypeChanged;
  final VoidCallback onClearType;
  final String query;
  final VoidCallback onClearQuery;
  final int activeFilters;
  final VoidCallback onOpenFilters;

  const _FilterBar({
    required this.typeFilter,
    required this.onTypeChanged,
    required this.onClearType,
    required this.query,
    required this.onClearQuery,
    required this.activeFilters,
    required this.onOpenFilters,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (query.isNotEmpty) ...[
                  Pressable(
                    haptic: true,
                    onTap: onClearQuery,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: GengaColors.offWhite,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const AppIcon(
                            AppIcons.search,
                            size: 14,
                            color: GengaColors.onOffWhite,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            query,
                            style: GengaTypography.caption1.copyWith(
                              color: GengaColors.onOffWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const AppIcon(
                            AppIcons.xmark,
                            size: 12,
                            color: GengaColors.onOffWhite,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                GengaFilterChip(
                  label: 'All',
                  icon: AppIcons.squareGrid2x2,
                  isActive: typeFilter == null,
                  onTap: onClearType,
                ),
                const SizedBox(width: 6),
                GengaFilterChip(
                  label: 'Expense',
                  icon: AppIcons.arrowUpRight,
                  isActive: typeFilter == TransactionType.expense,
                  onTap: () => onTypeChanged(TransactionType.expense),
                ),
                const SizedBox(width: 6),
                GengaFilterChip(
                  label: 'Income',
                  icon: AppIcons.arrowDownLeft,
                  isActive: typeFilter == TransactionType.income,
                  onTap: () => onTypeChanged(TransactionType.income),
                ),
                const SizedBox(width: 6),
                GengaFilterChip(
                  label: 'Transfer',
                  icon: AppIcons.arrowRightArrowLeft,
                  isActive: typeFilter == TransactionType.transfer,
                  onTap: () => onTypeChanged(TransactionType.transfer),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Pressable(
            scale: 0.9,
            haptic: true,
            onTap: onOpenFilters,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeFilters > 0
                    ? GengaColors.offWhite
                    : GengaColors.surface,
                border: Border.all(color: GengaColors.border, width: 0.5),
              ),
              child: Center(
                child: activeFilters > 0
                    ? Text(
                        '$activeFilters',
                        style: GengaTypography.footnote.copyWith(
                          color: GengaColors.onOffWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : const AppIcon(
                        AppIcons.sliders,
                        size: 17,
                        color: GengaColors.textPrimary,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchOverlay extends StatefulWidget {
  final String initial;
  final List<TransactionWithCategory> results;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchOverlay({
    super.key,
    required this.initial,
    required this.results,
    required this.onChanged,
    required this.onClose,
  });

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final query = _controller.text.trim();
    final shown = widget.results.take(6).toList();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: GengaSprings.medium,
              curve: GengaSprings.smooth,
              builder: (context, t, _) => BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16 * t, sigmaY: 16 * t),
                child: ColoredBox(color: Color.fromRGBO(12, 12, 14, 0.5 * t)),
              ),
            ),
          ),
        ),
        Positioned(
          top: top + 10,
          left: 16,
          right: 16,
          child: EntranceAnimation(
            slideOffset: -16,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GengaTextField(
                        controller: _controller,
                        icon: AppIcons.search,
                        placeholder: 'Search category or note',
                        autofocus: true,
                        clearable: true,
                        textInputAction: TextInputAction.search,
                        onChanged: (v) {
                          widget.onChanged(v);
                          setState(() {});
                        },
                        onSubmitted: (_) => widget.onClose(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Pressable(
                      onTap: widget.onClose,
                      child: Text(
                        'Done',
                        style: GengaTypography.callout.copyWith(
                          color: GengaColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (query.isNotEmpty && shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      'Nothing matches "$query"',
                      style: GengaTypography.subhead,
                    ),
                  ),
                if (query.isNotEmpty && shown.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: GengaColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: GengaColors.borderLight,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < shown.length; i++) ...[
                          TransactionTile(
                            data: shown[i],
                            onTap: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              showTransactionDetail(
                                context: context,
                                data: shown[i],
                              );
                            },
                          ),
                          if (i < shown.length - 1)
                            Container(
                              height: 0.5,
                              color: GengaColors.textPrimary.withValues(
                                alpha: 0.06,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                if (widget.results.length > shown.length && query.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Pressable(
                      onTap: widget.onClose,
                      child: Text(
                        'Show all ${widget.results.length} results',
                        style: GengaTypography.footnote.copyWith(
                          color: GengaColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Summary extends ConsumerWidget {
  final List<TransactionWithCategory> transactions;

  const _Summary({required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var monthTotal = 0.0;
    final perDay = List<double>.filled(7, 0);
    for (final t in transactions) {
      if (t.transaction.type != TransactionType.expense) continue;
      final spent = t.transaction.amount + t.transaction.momoFee;
      final d = t.transaction.date;
      if (d.year == now.year && d.month == now.month) monthTotal += spent;
      final day = DateTime(d.year, d.month, d.day);
      final ago = today.difference(day).inDays;
      if (ago >= 0 && ago < 7) perDay[6 - ago] += spent;
    }
    final peak = perDay.fold<double>(0, (m, v) => v > m ? v : m);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
      child: Column(
        children: [
          Text(
            'Spent in ${DateFormat('MMMM').format(now)}',
            style: GengaTypography.footnote,
          ),
          const SizedBox(height: 4),
          Text(
            AmountText.withSymbol(
              monthTotal * prefs.currencyRate,
              prefs.currency,
            ),
            style: GengaTypography.largeTitle.copyWith(
              color: GengaColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  AnimatedContainer(
                    duration: GengaSprings.medium,
                    curve: GengaSprings.smooth,
                    width: 8,
                    height: peak == 0 ? 4 : 4 + 26 * (perDay[i] / peak),
                    decoration: BoxDecoration(
                      color: i == 6
                          ? GengaColors.offWhite
                          : const Color(0xFF3A3A3F),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
