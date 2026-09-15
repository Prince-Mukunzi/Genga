import 'package:flutter/cupertino.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:intl/intl.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/models/enums.dart';
import 'package:genga/core/services/currency_service.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/widgets/category_icon.dart';
import 'package:genga/shared/widgets/pressable.dart';

import 'recurrence_picker.dart';

String formatAmountDisplay(String raw) {
  final parts = raw.split('.');
  final intPart = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
    buffer.write(intPart[i]);
  }
  if (parts.length > 1) buffer.write('.${parts[1]}');
  return buffer.toString();
}

String handleAmountKey(String current, String key) {
  switch (key) {
    case '⌫':
      if (current.length > 1) {
        return current.substring(0, current.length - 1);
      } else {
        return '0';
      }
    case '.':
      if (!current.contains('.')) return '$current.';
      return current;
    default:
      if (current == '0') {
        return key;
      } else if (current.length < 12) {
        return current + key;
      }
      return current;
  }
}

class TransactionAccountRow extends StatelessWidget {
  final Account? account;
  final double balance;
  final VoidCallback? onTap;
  final String displayCurrency;
  final VoidCallback? onCurrencyTap;

  const TransactionAccountRow({
    super.key,
    this.account,
    this.balance = 0,
    this.onTap,
    this.displayCurrency = 'RWF',
    this.onCurrencyTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = account?.name ?? 'Cash';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';
    final color = account != null
        ? Color(account!.color)
        : const Color(0xFF3478F6);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Pressable(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            decoration: BoxDecoration(
              color: GengaColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: GengaColors.borderLight, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GengaTypography.caption1.copyWith(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: GengaTypography.caption1.copyWith(
                        color: GengaColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'RWF ${_formatBalance(balance)}',
                      style: GengaTypography.caption2.copyWith(
                        color: GengaColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: onCurrencyTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: GengaColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GengaColors.borderLight, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currencyFlagForCode(displayCurrency),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  displayCurrency,
                  style: GengaTypography.subhead.copyWith(
                    color: GengaColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatBalance(double amount) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: 'en_US',
      decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
    );
    return formatter.format(amount);
  }
}

class TransactionControlsRow extends StatelessWidget {
  final DateTime date;
  final Category? category;
  final TransactionType type;
  final Recurrence recurrence;
  final String note;
  final VoidCallback onDateTap;
  final VoidCallback onCategoryTap;
  final VoidCallback onNoteTap;
  final VoidCallback onRecurrenceTap;
  final bool showCategory;

  const TransactionControlsRow({
    super.key,
    this.showCategory = true,
    required this.date,
    required this.category,
    required this.type,
    required this.recurrence,
    required this.note,
    required this.onDateTap,
    required this.onCategoryTap,
    required this.onNoteTap,
    required this.onRecurrenceTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return Row(
      children: [
        TransactionChipButton(
          icon: AppIcons.calendar,
          label: isToday ? 'Today' : DateFormat.MMMd().format(date),
          onTap: onDateTap,
        ),
        const SizedBox(width: 6),
        TransactionIconChip(
          icon: AppIcons.arrow2Circlepath,
          isActive: recurrence != Recurrence.none,
          onTap: onRecurrenceTap,
        ),
        const SizedBox(width: 6),
        if (showCategory && type != TransactionType.transfer)
          TransactionCategoryChip(category: category, onTap: onCategoryTap),
        const Spacer(),
        _AnimatedNoteChip(hasNote: note.isNotEmpty, onTap: onNoteTap),
      ],
    );
  }
}

class TransactionChipButton extends StatelessWidget {
  final HugeIconData icon;
  final String label;
  final VoidCallback onTap;

  const TransactionChipButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: GengaColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 14, color: GengaColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GengaTypography.footnote.copyWith(
                color: GengaColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Note chip with animated icon rotation when toggling between states.
class _AnimatedNoteChip extends StatefulWidget {
  final bool hasNote;
  final VoidCallback onTap;

  const _AnimatedNoteChip({required this.hasNote, required this.onTap});

  @override
  State<_AnimatedNoteChip> createState() => _AnimatedNoteChipState();
}

class _AnimatedNoteChipState extends State<_AnimatedNoteChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotateController;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _rotateController, curve: GengaSprings.snappy),
    );
  }

  @override
  void didUpdateWidget(_AnimatedNoteChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasNote != oldWidget.hasNote) {
      _rotateController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.9,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: GengaSprings.quick,
        curve: GengaSprings.smooth,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.hasNote
              ? GengaColors.dynamicAccent(context).withValues(alpha: 0.15)
              : GengaColors.surface,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateController.isAnimating
                    ? _rotation.value * 3.14159
                    : 0,
                child: child,
              );
            },
            child: AnimatedSwitcher(
              duration: GengaSprings.quick,
              child: AppIcon(
                widget.hasNote
                    ? AppIcons.squarePencilFill
                    : AppIcons.squarePencil,
                key: ValueKey(widget.hasNote),
                size: 16,
                color: widget.hasNote
                    ? GengaColors.dynamicAccent(context)
                    : GengaColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TransactionIconChip extends StatelessWidget {
  final HugeIconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const TransactionIconChip({
    super.key,
    required this.icon,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.9,
      onTap: onTap,
      child: AnimatedContainer(
        duration: GengaSprings.quick,
        curve: GengaSprings.smooth,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? GengaColors.dynamicAccent(context).withValues(alpha: 0.15)
              : GengaColors.surface,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: GengaSprings.quick,
            child: AppIcon(
              icon,
              key: ValueKey('$icon$isActive'),
              size: 16,
              color: isActive
                  ? GengaColors.dynamicAccent(context)
                  : GengaColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Category chip that animates between text-only and icon+text states.
class TransactionCategoryChip extends StatelessWidget {
  final Category? category;
  final VoidCallback onTap;

  const TransactionCategoryChip({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cat = category;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: GengaSprings.quick,
        curve: GengaSprings.smooth,
        padding: EdgeInsets.fromLTRB(
          cat != null ? 4 : 12,
          cat != null ? 4 : 8,
          12,
          cat != null ? 4 : 8,
        ),
        decoration: BoxDecoration(
          color: GengaColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedSwitcher(
          duration: GengaSprings.quick,
          transitionBuilder: (child, anim) {
            return FadeTransition(
              opacity: anim,
              child: SizeTransition(
                sizeFactor: anim,
                axis: Axis.horizontal,
                child: child,
              ),
            );
          },
          child: cat != null
              ? Row(
                  key: ValueKey(cat.id),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CategoryIcon(
                      iconKey: cat.iconKey,
                      color: Color(cat.color),
                      size: 28,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.name,
                      style: GengaTypography.footnote.copyWith(
                        color: GengaColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Category',
                  key: const ValueKey('empty'),
                  style: GengaTypography.footnote.copyWith(
                    color: GengaColors.textTertiary,
                  ),
                ),
        ),
      ),
    );
  }
}

class TransactionNoteField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onDone;

  const TransactionNoteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: GengaColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField.borderless(
              controller: controller,
              focusNode: focusNode,
              placeholder: 'Add a note',
              placeholderStyle: GengaTypography.callout.copyWith(
                color: GengaColors.textTertiary,
              ),
              style: GengaTypography.callout.copyWith(
                color: GengaColors.textPrimary,
              ),
              maxLines: 2,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 8),
          Pressable(
            scale: 0.9,
            onTap: onDone,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: GengaColors.textPrimary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: AppIcon(
                  AppIcons.checkmark,
                  size: 14,
                  color: GengaColors.background,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A dark rounded card for transfer mode, showing an account pill at the top
/// and a large centered amount display.
class TransferAccountCard extends StatelessWidget {
  final Account? account;
  final double? balance;
  final String amountDisplay;
  final String fallbackLabel;
  final bool dimAmount;
  final VoidCallback onAccountTap;

  const TransferAccountCard({
    super.key,
    required this.account,
    this.balance,
    required this.amountDisplay,
    required this.fallbackLabel,
    this.dimAmount = false,
    required this.onAccountTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = account?.name ?? fallbackLabel;
    final initial = account != null && account!.name.isNotEmpty
        ? account!.name[0].toUpperCase()
        : '?';
    final color = account != null
        ? Color(account!.color)
        : GengaColors.textTertiary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GengaColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account pill
          Pressable(
            onTap: onAccountTap,
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              decoration: BoxDecoration(
                color: GengaColors.surfaceElevated,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: GengaTypography.caption1.copyWith(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: GengaTypography.subhead.copyWith(
                          color: GengaColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (balance != null)
                        Text(
                          'RWF ${_formatBalance(balance!)}',
                          style: GengaTypography.caption1.copyWith(
                            color: GengaColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Centered amount
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    amountDisplay,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: dimAmount
                          ? GengaColors.textSecondary
                          : GengaColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBalance(double amount) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: 'en_US',
      decimalDigits: amount == amount.roundToDouble() ? 0 : 2,
    );
    return formatter.format(amount);
  }
}

/// Animated circular divider with a down-arrow icon and gentle bounce.
class TransferDividerArrow extends StatefulWidget {
  const TransferDividerArrow({super.key});

  @override
  State<TransferDividerArrow> createState() => _TransferDividerArrowState();
}

class _TransferDividerArrowState extends State<TransferDividerArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounce.value),
          child: child,
        );
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: GengaColors.surfaceElevated,
          shape: BoxShape.circle,
          border: Border.all(color: GengaColors.background, width: 3),
        ),
        child: const Center(
          child: AppIcon(
            AppIcons.arrowDown,
            size: 14,
            color: GengaColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
