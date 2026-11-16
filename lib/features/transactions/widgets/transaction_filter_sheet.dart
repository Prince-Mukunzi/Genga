import 'package:flutter/cupertino.dart';
import 'package:genga/shared/widgets/genga_button.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/genga_text_field.dart';
import 'package:genga/shared/widgets/pressable.dart';
import 'package:genga/shared/widgets/sheet_parts.dart';

enum TxnRange {
  all('Any time'),
  week('7 days'),
  month('This month'),
  last30('30 days');

  final String label;
  const TxnRange(this.label);
}

class TxnFilters {
  final int? accountId;
  final int? categoryId;
  final TxnRange range;
  final double? minAmount;
  final double? maxAmount;

  const TxnFilters({
    this.accountId,
    this.categoryId,
    this.range = TxnRange.all,
    this.minAmount,
    this.maxAmount,
  });

  static const empty = TxnFilters();

  int get activeCount =>
      (accountId != null ? 1 : 0) +
      (categoryId != null ? 1 : 0) +
      (range != TxnRange.all ? 1 : 0) +
      (minAmount != null || maxAmount != null ? 1 : 0);
}

Future<TxnFilters?> showTransactionFilterSheet(
  BuildContext context,
  TxnFilters initial,
) {
  return showGengaBottomSheet<TxnFilters>(
    context: context,
    maxHeightFraction: 0.9,
    builder: (_) => _FilterSheet(initial: initial),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  final TxnFilters initial;

  const _FilterSheet({required this.initial});

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  int? _account;
  int? _category;
  late TxnRange _range;
  late final TextEditingController _min;
  late final TextEditingController _max;

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _account = f.accountId;
    _category = f.categoryId;
    _range = f.range;
    _min = TextEditingController(text: f.minAmount?.toStringAsFixed(0) ?? '');
    _max = TextEditingController(text: f.maxAmount?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _account = null;
      _category = null;
      _range = TxnRange.all;
      _min.clear();
      _max.clear();
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      TxnFilters(
        accountId: _account,
        categoryId: _category,
        range: _range,
        minAmount: double.tryParse(_min.text.trim()),
        maxAmount: double.tryParse(_max.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(
            'Filters',
            trailing: Pressable(
              onTap: _reset,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text('Reset', style: GengaTypography.callout),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('Date'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in TxnRange.values)
                        _Choice(
                          label: r.label,
                          selected: _range == r,
                          onTap: () => setState(() => _range = r),
                        ),
                    ],
                  ),
                  if (accounts.length > 1) ...[
                    const _Label('Account'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Choice(
                          label: 'All',
                          selected: _account == null,
                          onTap: () => setState(() => _account = null),
                        ),
                        for (final a in accounts)
                          _Choice(
                            label: a.name,
                            selected: _account == a.id,
                            onTap: () => setState(() => _account = a.id),
                          ),
                      ],
                    ),
                  ],
                  const _Label('Amount'),
                  Row(
                    children: [
                      Expanded(
                        child: GengaTextField(
                          controller: _min,
                          placeholder: 'Min',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GengaTextField(
                          controller: _max,
                          placeholder: 'Max',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const _Label('Category'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Choice(
                        label: 'All',
                        selected: _category == null,
                        onTap: () => setState(() => _category = null),
                      ),
                      for (final c in categories)
                        _Choice(
                          label: c.name,
                          leading: AppIcon.key(
                            c.iconKey,
                            size: 14,
                            color: Color(c.color),
                          ),
                          selected: _category == c.id,
                          onTap: () => setState(() => _category = c.id),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: GengaButton(label: 'Show results', onTap: _apply),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Text(text, style: GengaTypography.footnote),
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      haptic: true,
      onTap: onTap,
      child: AnimatedContainer(
        duration: GengaSprings.quick,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: GengaColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? GengaColors.offWhite.withValues(alpha: 0.5)
                : GengaColors.borderLight,
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Text(
              label,
              style: GengaTypography.footnote.copyWith(
                color: selected
                    ? GengaColors.textPrimary
                    : GengaColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
