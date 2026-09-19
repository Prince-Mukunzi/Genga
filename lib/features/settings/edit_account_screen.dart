import 'package:drift/drift.dart' hide Column;
import 'package:flutter/cupertino.dart';
import 'package:genga/shared/widgets/genga_sheets.dart';

import 'package:genga/shared/widgets/genga_button.dart';

import 'package:genga/shared/widgets/genga_text_field.dart';

import 'package:genga/shared/widgets/genga_scaffold.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/models/enums.dart';
import 'package:genga/core/providers/database_provider.dart';
import 'package:genga/core/providers/space_provider.dart';
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/core/services/currency_service.dart';
import 'package:genga/core/services/widget_data_service.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/genga_toast.dart';
import 'package:genga/shared/brands/account_brand.dart';
import 'package:genga/shared/widgets/pressable.dart';

class EditAccountScreen extends ConsumerStatefulWidget {
  final Account account;

  const EditAccountScreen({super.key, required this.account});

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  late final TextEditingController _nameController;
  late String _accountType;
  late String _currency;
  late bool _isPrimary;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _accountType = widget.account.accountType;
    _currency = widget.account.currency;
    _isPrimary = widget.account.isPrimary;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(accountBalanceProvider(widget.account.id));

    return GengaScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
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
                    'Edit Account',
                    style: GengaTypography.headline.copyWith(
                      color: GengaColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (!ref.watch(isSharedSpaceProvider) ||
                      ref.watch(isSpaceAdminProvider))
                    Pressable(
                      scale: 0.9,
                      onTap: () => _confirmDelete(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: GengaColors.surface,
                        ),
                        child: const Center(
                          child: AppIcon(
                            AppIcons.trash,
                            size: 16,
                            color: GengaColors.destructive,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                children: [
                  // Name
                  GengaTextField(
                    controller: _nameController,
                    placeholder: 'Account name',
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  // Type
                  Container(
                    decoration: BoxDecoration(
                      color: GengaColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Pressable(
                          scale: 0.98,
                          onTap: null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Type',
                                  style: GengaTypography.body.copyWith(
                                    color: GengaColors.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  brandFor(_accountType).name,
                                  style: GengaTypography.body.copyWith(
                                    color: GengaColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const AppIcon(
                                  AppIcons.chevronRight,
                                  size: 14,
                                  color: GengaColors.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Container(
                            height: 0.5,
                            color: GengaColors.border,
                          ),
                        ),
                        Pressable(
                          scale: 0.98,
                          onTap: _pickCurrency,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Currency',
                                  style: GengaTypography.body.copyWith(
                                    color: GengaColors.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  currencyFlag(_currency),
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _currency,
                                  style: GengaTypography.body.copyWith(
                                    color: GengaColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const AppIcon(
                                  AppIcons.chevronRight,
                                  size: 14,
                                  color: GengaColors.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Container(
                            height: 0.5,
                            color: GengaColors.border,
                          ),
                        ),
                        // Balance (tappable to adjust)
                        Pressable(
                          scale: 0.98,
                          onTap: () => _showAdjustBalance(balance),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Balance',
                                  style: GengaTypography.body.copyWith(
                                    color: GengaColors.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$_currency ${_formatNum(balance)}',
                                  style: GengaTypography.body.copyWith(
                                    color: GengaColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const AppIcon(
                                  AppIcons.chevronRight,
                                  size: 14,
                                  color: GengaColors.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Container(
                            height: 0.5,
                            color: GengaColors.border,
                          ),
                        ),
                        // Primary toggle
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Set as Primary',
                                style: GengaTypography.body.copyWith(
                                  color: GengaColors.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              CupertinoSwitch(
                                value: _isPrimary,
                                activeTrackColor: GengaColors.offWhite,
                                thumbColor: _isPrimary
                                    ? GengaColors.onOffWhite
                                    : CupertinoColors.white,
                                onChanged: (v) =>
                                    setState(() => _isPrimary = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Save
                  GengaButton(
                    label: _saving ? 'Saving...' : 'Save Changes',
                    onTap: _nameController.text.trim().isNotEmpty && !_saving
                        ? _save
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  Future<void> _pickCurrency() async {
    final rates = ref.read(currencyRatesProvider).valueOrNull;
    final currencies = rates ?? _fallbackCurrencyList();

    await showGengaBottomSheet<void>(
      context: context,
      maxHeightFraction: 0.6,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Currency',
              style: GengaTypography.headline.copyWith(
                color: GengaColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: currencies.length,
              itemBuilder: (ctx, i) {
                final c = currencies[i];
                final isSelected = c.code == _currency;
                return Pressable(
                  scale: 0.98,
                  onTap: () {
                    setState(() => _currency = c.code);
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GengaColors.dynamicAccent(context)
                                .withValues(alpha: 0.1)
                          : null,
                      border: Border(
                        bottom: BorderSide(
                          color: GengaColors.textPrimary.withValues(
                            alpha: 0.06,
                          ),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(c.flag, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.code,
                                style: GengaTypography.body.copyWith(
                                  color: GengaColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                c.name,
                                style: GengaTypography.caption1.copyWith(
                                  color: GengaColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          AppIcon(
                            AppIcons.checkmarkCircleFill,
                            size: 20,
                            color: GengaColors.dynamicAccent(context),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<CurrencyRate> _fallbackCurrencyList() {
    const codes = ['RWF', 'USD', 'EUR', 'GBP', 'KES', 'UGX', 'TZS', 'BIF'];
    return codes
        .map(
          (c) => CurrencyRate(
            code: c,
            name: currencyName(c),
            flag: currencyFlag(c),
            rateFromRwf: c == 'RWF' ? 1.0 : 0,
          ),
        )
        .toList();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final db = ref.read(databaseProvider);
      final updated = widget.account.copyWith(
        name: name,
        currency: _currency,
        isPrimary: _isPrimary,
      );

      await db.updateAccount(updated);

      if (_isPrimary) {
        await db.setPrimaryAccount(widget.account.id);
      }

      if (mounted) {
        showGengaToast(
          context,
          'Account saved',
          icon: AppIcons.checkmarkCircle,
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showAdjustBalance(double currentBalance) {
    final controller = TextEditingController();

    showGengaBottomSheet<void>(
      context: context,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
              'Current: $_currency ${_formatNum(currentBalance)}',
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
              prefixText: _currency,
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
                final db = ref.read(databaseProvider);
                final updatedAccount = widget.account.copyWith(
                  initialBalance: widget.account.initialBalance + diff,
                );
                await db.updateAccount(updatedAccount);
                await db.insertTransaction(
                  TransactionsCompanion.insert(
                    accountId: widget.account.id,
                    amount: diff.abs(),
                    type: diff > 0
                        ? TransactionType.income
                        : TransactionType.expense,
                    date: DateTime.now(),
                    note: const Value('Balance correction'),
                    recurrence: const Value('none'),
                  ),
                );
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

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showGengaConfirm(
      context,
      title: 'Delete account',
      message: 'This will permanently delete this account. Transactions linked to it will remain.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    HapticFeedback.mediumImpact();
    await ref.read(databaseProvider).deleteAccount(widget.account.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}
