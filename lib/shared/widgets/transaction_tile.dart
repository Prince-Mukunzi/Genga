import 'package:flutter/cupertino.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/models/enums.dart';
import 'package:genga/core/models/transaction_with_category.dart';
import 'package:genga/core/providers/preferences_provider.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/widgets/pressable.dart';

import 'amount_text.dart';
import 'category_icon.dart';

class TransactionTile extends ConsumerStatefulWidget {
  final TransactionWithCategory data;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.data, this.onTap});

  @override
  ConsumerState<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends ConsumerState<TransactionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _iconScale;
  late final Animation<Offset> _amountSlide;
  late final Animation<double> _amountOpacity;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.7, curve: Cubic(0.34, 1.56, 0.64, 1)),
      ),
    );
    _amountSlide = Tween<Offset>(begin: const Offset(12, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.2, 1.0, curve: GengaSprings.smooth),
          ),
        );
    _amountOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txn = widget.data.transaction;
    final cat = widget.data.category;
    final dateStr = _formatDate(txn.date);
    final isTransfer = txn.type == TransactionType.transfer;
    final prefs = ref.watch(preferencesProvider);

    final displayAmount = (txn.amount + txn.momoFee) * prefs.currencyRate;

    String subtitle;
    if (isTransfer && widget.data.account != null) {
      subtitle =
          '${widget.data.account!.name} → ${widget.data.toAccount?.name ?? '?'}';
    } else if (txn.note.isNotEmpty) {
      subtitle = txn.note;
    } else {
      subtitle = dateStr;
    }

    return Pressable(
      scale: 0.98,
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                return Transform.scale(scale: _iconScale.value, child: child);
              },
              child: cat != null
                  ? CategoryIcon(iconKey: cat.iconKey, color: Color(cat.color))
                  : _UncategorizedIcon(type: txn.type),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat?.name ?? txn.type.label,
                    style: GengaTypography.callout.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GengaTypography.caption1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                return Transform.translate(
                  offset: _amountSlide.value,
                  child: Opacity(
                    opacity: _amountOpacity.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: AmountText(
                amount: displayAmount,
                type: txn.type,
                currency: prefs.currency,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txnDay = DateTime(date.year, date.month, date.day);

    if (txnDay == today) return 'Today';
    if (txnDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (now.difference(date).inDays < 7) return DateFormat.EEEE().format(date);
    return DateFormat.MMMd().format(date);
  }
}

/// Fallback icon when no category is assigned. Shows icon/color based on
/// the transaction type so uncategorised items look correct.
class _UncategorizedIcon extends StatelessWidget {
  final TransactionType type;
  const _UncategorizedIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (Color color, HugeIconData icon) = switch (type) {
      TransactionType.income => (GengaColors.income, AppIcons.arrowDownLeft),
      TransactionType.expense => (GengaColors.expense, AppIcons.arrowUpRight),
      TransactionType.transfer => (
        GengaColors.transfer,
        AppIcons.arrowRightArrowLeft,
      ),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(child: AppIcon(icon, color: color, size: 20)),
    );
  }
}
