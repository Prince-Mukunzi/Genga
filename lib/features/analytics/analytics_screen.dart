import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:genga/shared/widgets/figure_row.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/models/enums.dart';
import 'package:genga/core/models/transaction_with_category.dart';
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/core/services/analytics_service.dart';
import 'package:genga/shared/animations/entrance_animation.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:genga/shared/widgets/amount_text.dart';
import 'package:genga/shared/widgets/genga_scaffold.dart';
import 'package:genga/shared/widgets/pressable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum _Period { week, month, year }

class _Bucket {
  final String label;
  double expense = 0;
  double income = 0;

  _Bucket(this.label);
}

class _Category {
  final String name;
  final Color color;
  final String? iconKey;
  double total = 0;

  _Category(this.name, this.color, this.iconKey);
}

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  _Period _period = _Period.week;
  int? _selected;

  DateTime get _start {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_period) {
      _Period.week => today.subtract(Duration(days: now.weekday - 1)),
      _Period.month => DateTime(now.year, now.month, 1),
      _Period.year => DateTime(now.year, 1, 1),
    };
  }

  String get _periodName => switch (_period) {
    _Period.week => 'this week',
    _Period.month => 'this month',
    _Period.year => 'this year',
  };

  String get _previousName => switch (_period) {
    _Period.week => 'last week',
    _Period.month => 'last month',
    _Period.year => 'last year',
  };

  void _setPeriod(_Period p) {
    if (p == _period) return;
    HapticFeedback.selectionClick();
    setState(() {
      _period = p;
      _selected = null;
    });
    ref.read(analyticsServiceProvider).trackEvent('analytics_viewed', {
      'preset': p.name,
    });
  }

  List<_Bucket> _buckets(Iterable<TransactionWithCategory> txns) {
    final start = _start;
    final buckets = switch (_period) {
      _Period.week => [
        for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S']) _Bucket(d),
      ],
      _Period.month => [
        for (var i = 0; i < (DateTime.now().day / 7).ceil().clamp(1, 5); i++)
          _Bucket('W${i + 1}'),
      ],
      _Period.year => [
        for (final m in [
          'J',
          'F',
          'M',
          'A',
          'M',
          'J',
          'J',
          'A',
          'S',
          'O',
          'N',
          'D',
        ])
          _Bucket(m),
      ],
    };

    for (final t in txns) {
      final d = t.transaction.date;
      final idx = switch (_period) {
        _Period.week => DateTime(
          d.year,
          d.month,
          d.day,
        ).difference(start).inDays,
        _Period.month => ((d.day - 1) / 7).floor(),
        _Period.year => d.month - 1,
      };
      if (idx < 0 || idx >= buckets.length) continue;
      final txn = t.transaction;
      if (txn.type == TransactionType.expense) {
        buckets[idx].expense += txn.amount + txn.momoFee;
      } else if (txn.type == TransactionType.income) {
        buckets[idx].income += txn.amount;
      }
    }
    return buckets;
  }

  Future<void> _export(List<TransactionWithCategory> all) async {
    final start = _start;
    final filtered = all.where((t) => !t.transaction.date.isBefore(start));

    final buffer = StringBuffer()
      ..writeln('Date,Type,Amount,Fee,Currency,Category,Account,Note');
    for (final t in filtered) {
      final txn = t.transaction;
      final note = txn.note.replaceAll('"', '""');
      buffer.writeln(
        '${DateFormat('yyyy-MM-dd').format(txn.date)},${txn.type.label},'
        '${txn.amount},${txn.momoFee},RWF,"${t.category?.name ?? ''}",'
        '"${t.account?.name ?? ''}","$note"',
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/genga-transactions-'
      '${DateFormat('yyyy-MM-dd').format(start)}-to-'
      '${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv',
    );
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)]);

    ref.read(analyticsServiceProvider).trackEvent('export_triggered', {
      'format': 'csv',
    });
  }

  @override
  Widget build(BuildContext context) {
    final txns = ref.watch(allTransactionsProvider);
    final all = txns.valueOrNull ?? const <TransactionWithCategory>[];

    return GengaScaffold(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  for (final p in _Period.values)
                    _PeriodLabel(
                      label: p.name[0].toUpperCase() + p.name.substring(1),
                      active: p == _period,
                      onTap: () => _setPeriod(p),
                    ),
                  const Spacer(),
                  Pressable(
                    haptic: true,
                    onTap: () => _export(all),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: AppIcon(
                        AppIcons.arrowDownDoc,
                        size: 20,
                        color: GengaColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: txns.when(
                data: _content,
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Could not load data',
                    style: GengaTypography.subhead,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(List<TransactionWithCategory> all) {
    final start = _start;
    final now = DateTime.now();
    final inPeriod = all
        .where((t) => !t.transaction.date.isBefore(start))
        .toList();

    double expense = 0, income = 0, fees = 0;
    final byCategory = <String, _Category>{};
    for (final t in inPeriod) {
      final txn = t.transaction;
      if (txn.momoFee > 0) fees += txn.momoFee;
      if (txn.type == TransactionType.income) {
        income += txn.amount;
      } else if (txn.type == TransactionType.expense) {
        final cost = txn.amount + txn.momoFee;
        expense += cost;
        final name = t.category?.name ?? 'Uncategorized';
        byCategory
                .putIfAbsent(
                  name,
                  () => _Category(
                    name,
                    t.category != null
                        ? Color(t.category!.color)
                        : GengaColors.textTertiary,
                    t.category?.iconKey,
                  ),
                )
                .total +=
            cost;
      }
    }
    final categories = byCategory.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final span = now.difference(start) + const Duration(days: 1);
    final prevStart = start.subtract(span);
    var prevExpense = 0.0;
    for (final t in all) {
      final d = t.transaction.date;
      if (t.transaction.type == TransactionType.expense &&
          !d.isBefore(prevStart) &&
          d.isBefore(start)) {
        prevExpense += t.transaction.amount + t.transaction.momoFee;
      }
    }

    final buckets = _buckets(inPeriod);
    final hasData = buckets.any((b) => b.expense > 0 || b.income > 0);

    if (!hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Nothing to report $_periodName.\nAdd a transaction and it shows up here.',
            textAlign: TextAlign.center,
            style: GengaTypography.subhead,
          ),
        ),
      );
    }

    final sel = _selected != null && _selected! < buckets.length
        ? buckets[_selected!]
        : null;
    final heroLabel = sel == null
        ? 'Spent $_periodName'
        : 'Spent ${_longLabel(_selected!)}';
    final heroValue = sel?.expense ?? expense;
    final delta = prevExpense > 0
        ? (expense - prevExpense) / prevExpense
        : null;
    final net = income - expense;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 140),
      children: [
        EntranceAnimation.stagger(
          index: 0,
          child: _Hero(
            label: heroLabel,
            value: heroValue,
            delta: sel == null ? delta : null,
            previous: _previousName,
          ),
        ),
        const SizedBox(height: 36),
        EntranceAnimation.stagger(
          index: 1,
          child: _BarChart(
            key: ValueKey(_period),
            buckets: buckets,
            selected: _selected,
            onSelect: (i) {
              if (i != _selected) HapticFeedback.selectionClick();
              setState(() => _selected = i);
            },
            onClear: () => setState(() => _selected = null),
          ),
        ),
        const SizedBox(height: 36),
        EntranceAnimation.stagger(
          index: 2,
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
                color: net < 0 ? GengaColors.expense : GengaColors.income,
                label: 'Net',
                value: '${net < 0 ? '-' : ''}${AmountText.plain(net.abs())}',
              ),
              if (fees > 0) ...[
                const FigureRule(),
                Figure(
                  icon: AppIcons.percent,
                  color: GengaColors.warning,
                  label: 'Fees',
                  value: AmountText.plain(fees),
                ),
              ],
            ],
          ),
        ),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 48),
          Text('Where it went', style: GengaTypography.footnote),
          const SizedBox(height: 16),
          _ShareBar(categories: categories, total: expense),
          const SizedBox(height: 8),
          for (final c in categories) _CategoryRow(category: c, total: expense),
        ],
      ],
    );
  }

  String _longLabel(int i) {
    final start = _start;
    return switch (_period) {
      _Period.week => DateFormat('EEEE').format(start.add(Duration(days: i))),
      _Period.month => 'week ${i + 1}',
      _Period.year => DateFormat('MMMM').format(DateTime(start.year, i + 1)),
    };
  }
}

class _PeriodLabel extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PeriodLabel({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 22, top: 10, bottom: 10),
        child: AnimatedDefaultTextStyle(
          duration: GengaSprings.quick,
          style: GengaTypography.title3.copyWith(
            color: active ? GengaColors.textPrimary : GengaColors.textTertiary,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String label;
  final double value;
  final double? delta;
  final String previous;

  const _Hero({
    required this.label,
    required this.value,
    required this.delta,
    required this.previous,
  });

  @override
  Widget build(BuildContext context) {
    final d = delta;
    final pct = d == null ? 0 : (d.abs() * 100).round();
    final up = d != null && d > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: GengaSprings.quick,
          child: Text(
            label,
            key: ValueKey(label),
            style: GengaTypography.subhead,
          ),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: value),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AmountText.format(v.roundToDouble()),
              maxLines: 1,
              style: GengaTypography.amountLarge.copyWith(
                fontSize: 60,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (d != null && pct > 0) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              AppIcon(
                up ? AppIcons.arrowUpRight : AppIcons.arrowDownRight,
                size: 14,
                color: up ? GengaColors.expense : GengaColors.income,
              ),
              const SizedBox(width: 6),
              Text(
                '$pct% ${up ? 'more' : 'less'} than $previous',
                style: GengaTypography.subhead,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<_Bucket> buckets;
  final int? selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onClear;

  const _BarChart({
    super.key,
    required this.buckets,
    required this.selected,
    required this.onSelect,
    required this.onClear,
  });

  static const double _height = 170;

  @override
  Widget build(BuildContext context) {
    final accent = GengaColors.dynamicAccent(context);
    final maxValue = buckets.fold<double>(0, (m, b) => math.max(m, b.expense));

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        void pick(double dx) {
          final i = (dx / width * buckets.length).floor().clamp(
            0,
            buckets.length - 1,
          );
          onSelect(i);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => pick(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => pick(d.localPosition.dx),
          onDoubleTap: onClear,
          child: SizedBox(
            height: _height + 28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < buckets.length; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            end: maxValue == 0
                                ? 0
                                : buckets[i].expense / maxValue,
                          ),
                          duration: GengaSprings.slow,
                          curve: Curves.easeOutCubic,
                          builder: (context, f, _) {
                            final dim = selected != null && selected != i;
                            return AnimatedContainer(
                              duration: GengaSprings.quick,
                              width: buckets.length > 8 ? 9 : 12,
                              height: math.max(4, _height * f.clamp(0.0, 1.0)),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: buckets[i].expense == 0
                                    ? GengaColors.textTertiary.withValues(
                                        alpha: 0.35,
                                      )
                                    : dim
                                    ? accent.withValues(alpha: 0.3)
                                    : accent,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 18,
                          child: Text(
                            buckets[i].label,
                            style: GengaTypography.caption1.copyWith(
                              color: selected == i
                                  ? GengaColors.textPrimary
                                  : GengaColors.textTertiary,
                              fontWeight: selected == i
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShareBar extends StatelessWidget {
  final List<_Category> categories;
  final double total;

  const _ShareBar({required this.categories, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: GengaSprings.slow,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: t.clamp(0.0, 1.0),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  for (var i = 0; i < categories.length; i++)
                    Expanded(
                      flex: (categories[i].total / total * 1000).round().clamp(
                        1,
                        1000,
                      ),
                      child: Container(
                        margin: EdgeInsets.only(
                          right: i == categories.length - 1 ? 0 : 2,
                        ),
                        color: categories[i].color,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final _Category category;
  final double total;

  const _CategoryRow({required this.category, required this.total});

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (category.total / total * 100).round() : 0;

    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppIcon(
                category.iconKey != null
                    ? AppIcons.resolve(category.iconKey!)
                    : AppIcons.tag,
                size: 16,
                color: category.color,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: GengaTypography.body),
                Text('$percent%', style: GengaTypography.caption1),
              ],
            ),
          ),
          Text(
            AmountText.format(category.total),
            style: GengaTypography.body.copyWith(
              color: GengaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
