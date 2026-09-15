import 'package:drift/drift.dart' hide Column;
import 'package:flutter/cupertino.dart';
import 'package:genga/shared/widgets/genga_button.dart';

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
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/shared/widgets/genga_toast.dart';
import 'package:genga/shared/widgets/pressable.dart';
import 'package:genga/core/services/mtn_fee_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'contact_picker.dart';

enum _PayMode { send, save }

enum _MomoProvider { mtn, airtel }

class PayScreen extends ConsumerStatefulWidget {
  const PayScreen({super.key});

  @override
  ConsumerState<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends ConsumerState<PayScreen> {
  _PayMode _mode = _PayMode.send;
  _MomoProvider _provider = _MomoProvider.mtn;
  PickedRecipient? _recipient;
  Account? _selectedAccount;
  final _amountController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _cleanPhone(String phone) {
    var cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+250')) {
      cleaned = '0${cleaned.substring(4)}';
    } else if (cleaned.startsWith('250') && cleaned.length == 12) {
      cleaned = '0${cleaned.substring(3)}';
    }
    return cleaned;
  }

  String _generateUssd() {
    final amount = _amountController.text.trim();
    if (amount.isEmpty) return '';

    if (_mode == _PayMode.send) {
      if (_recipient != null) {
        final phone = _cleanPhone(_recipient!.phone);
        if (_provider == _MomoProvider.mtn) {
          return '*182*1*1*$phone*$amount#';
        } else {
          return '*181*1*$phone*$amount#';
        }
      }
      return '';
    } else if (_mode == _PayMode.save) {
      if (_provider == _MomoProvider.mtn) {
        return '*182*2*1*$amount#';
      } else {
        return '*181*2*$amount#';
      }
    }
    return '';
  }

  Future<void> _dialUssd() async {
    final ussd = _generateUssd();
    if (ussd.isEmpty) return;

    final encoded = Uri.encodeComponent(ussd);
    final uri = Uri.parse('tel:$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _recordAndDial() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final db = ref.read(databaseProvider);
      final accounts = ref.read(accountsProvider).valueOrNull ?? [];
      final account = _selectedAccount ?? accounts.firstOrNull;
      if (account == null) return;

      if (_mode == _PayMode.send) {
        final fee =
            _provider == _MomoProvider.mtn &&
                _recipient != null &&
                isPhoneRecipient(_recipient)
            ? getMtnFee(amount)
            : null;

        await db.insertTransaction(
          TransactionsCompanion.insert(
            amount: amount,
            type: TransactionType.expense,
            accountId: account.id,
            date: DateTime.now(),
            note: Value(
              _recipient != null ? 'Sent to ${_recipient!.name}' : 'Payment',
            ),
            recipientName: Value(_recipient?.name ?? ''),
            recipientPhone: Value(_recipient?.phone ?? ''),
            momoFee: Value(fee?.onNet.toDouble() ?? 0),
          ),
        );
      } else {
        final savingsAccount = accounts
            .where((a) => a.accountType == 'savings')
            .firstOrNull;
        if (savingsAccount != null) {
          await db.insertTransaction(
            TransactionsCompanion.insert(
              amount: amount,
              type: TransactionType.transfer,
              accountId: account.id,
              toAccountId: Value(savingsAccount.id),
              date: DateTime.now(),
              note: const Value('MoMo savings deposit'),
            ),
          );
        } else {
          await db.insertTransaction(
            TransactionsCompanion.insert(
              amount: amount,
              type: TransactionType.expense,
              accountId: account.id,
              date: DateTime.now(),
              note: const Value('Savings deposit'),
            ),
          );
        }
      }

      final ussd = _generateUssd();
      if (ussd.isNotEmpty) {
        await _dialUssd();
      }

      if (mounted) {
        showGengaToast(
          context,
          _mode == _PayMode.send ? 'Payment recorded' : 'Savings recorded',
          icon: AppIcons.checkmarkCircle,
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
    _selectedAccount ??= accounts.firstOrNull;

    final ussd = _generateUssd();

    return GengaScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // Header
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
                          AppIcons.xmark,
                          color: GengaColors.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Pay & Send',
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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),
                  // Mode switcher
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: GengaColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _ModeTab(
                          label: 'Send Money',
                          icon: AppIcons.arrowUpCircle,
                          active: _mode == _PayMode.send,
                          onTap: () => setState(() => _mode = _PayMode.send),
                        ),
                        _ModeTab(
                          label: 'Save',
                          icon: AppIcons.arrowDownCircle,
                          active: _mode == _PayMode.save,
                          onTap: () => setState(() => _mode = _PayMode.save),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Recipient (send mode only)
                  if (_mode == _PayMode.send) ...[
                    Text(
                      'Recipient',
                      style: GengaTypography.caption1.copyWith(
                        color: GengaColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Pressable(
                      onTap: () async {
                        final picked = await showContactPicker(context);
                        if (picked != null && mounted) {
                          setState(() => _recipient = picked);
                        }
                      },
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
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _recipient != null
                                    ? GengaColors.dynamicAccent(context)
                                          .withValues(alpha: 0.15)
                                    : GengaColors.surfaceElevated,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: _recipient != null
                                    ? Text(
                                        _recipient!.name[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: GengaColors.dynamicAccent(
                                            context,
                                          ),
                                        ),
                                      )
                                    : const AppIcon(
                                        AppIcons.personAdd,
                                        size: 18,
                                        color: GengaColors.textTertiary,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _recipient?.name ?? 'Choose contact',
                                    style: GengaTypography.body.copyWith(
                                      color: _recipient != null
                                          ? GengaColors.textPrimary
                                          : GengaColors.textTertiary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_recipient != null)
                                    Text(
                                      _recipient!.phone,
                                      style: GengaTypography.caption1.copyWith(
                                        color: GengaColors.textTertiary,
                                      ),
                                    ),
                                ],
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
                    const SizedBox(height: 20),
                  ],
                  // Amount
                  Text(
                    'Amount',
                    style: GengaTypography.caption1.copyWith(
                      color: GengaColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _amountController,
                    placeholder: '0',
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: GengaColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: GengaColors.textPrimary,
                    ),
                    placeholderStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: GengaColors.textTertiary,
                    ),
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        'RWF',
                        style: GengaTypography.body.copyWith(
                          color: GengaColors.textTertiary,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  // Provider picker
                  Text(
                    'Provider',
                    style: GengaTypography.caption1.copyWith(
                      color: GengaColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ProviderChip(
                          label: 'MTN MoMo',
                          emoji: '\u{1F7E1}',
                          active: _provider == _MomoProvider.mtn,
                          onTap: () =>
                              setState(() => _provider = _MomoProvider.mtn),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ProviderChip(
                          label: 'Airtel Money',
                          emoji: '\u{1F534}',
                          active: _provider == _MomoProvider.airtel,
                          onTap: () =>
                              setState(() => _provider = _MomoProvider.airtel),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Account picker
                  Text(
                    'From Account',
                    style: GengaTypography.caption1.copyWith(
                      color: GengaColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final acct in accounts) ...[
                          _AccountChipSmall(
                            name: acct.name,
                            color: Color(acct.color),
                            isSelected: _selectedAccount?.id == acct.id,
                            onTap: () =>
                                setState(() => _selectedAccount = acct),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  // MTN Fee display
                  Builder(
                    builder: (context) {
                      final amountVal = double.tryParse(
                        _amountController.text.trim(),
                      );
                      final showFee =
                          _mode == _PayMode.send &&
                          _provider == _MomoProvider.mtn &&
                          _recipient != null &&
                          isPhoneRecipient(_recipient) &&
                          amountVal != null &&
                          amountVal > 0;
                      if (!showFee) return const SizedBox.shrink();
                      final fee = getMtnFee(amountVal);
                      if (fee == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFCC00)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFFFCC00)
                                  .withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '\u{1F7E1}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'MTN MoMo Fee',
                                    style: GengaTypography.caption1.copyWith(
                                      color: GengaColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'On-Net',
                                          style: GengaTypography.caption1
                                              .copyWith(
                                                color: GengaColors.textTertiary,
                                              ),
                                        ),
                                        Text(
                                          'RWF ${fee.onNet}',
                                          style: GengaTypography.body.copyWith(
                                            color: GengaColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Off-Net',
                                          style: GengaTypography.caption1
                                              .copyWith(
                                                color: GengaColors.textTertiary,
                                              ),
                                        ),
                                        Text(
                                          'RWF ${fee.offNet}',
                                          style: GengaTypography.body.copyWith(
                                            color: GengaColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // USSD preview
                  if (ussd.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: GengaColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: GengaColors.borderLight,
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const AppIcon(
                                AppIcons.dial,
                                size: 14,
                                color: GengaColors.textTertiary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'USSD Code',
                                style: GengaTypography.caption1.copyWith(
                                  color: GengaColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ussd,
                                  style: GengaTypography.title3.copyWith(
                                    color: GengaColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: [
                                      const FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                              Pressable(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: ussd));
                                  HapticFeedback.lightImpact();
                                  showGengaToast(
                                    context,
                                    'Copied to clipboard',
                                    icon: AppIcons.docOnClipboard,
                                  );
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: GengaColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: AppIcon(
                                      AppIcons.docOnClipboard,
                                      size: 16,
                                      color: GengaColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Action buttons
                  Row(
                    children: [
                      if (ussd.isNotEmpty) ...[
                        Expanded(
                          child: GengaButton.secondary(
                            label: 'Dial Only',
                            onTap: _dialUssd,
                            icon: AppIcons.phone,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: GengaButton(
                          label: _saving
                              ? 'Processing...'
                              : _mode == _PayMode.send
                              ? (_recipient != null
                                    ? 'Send & Record'
                                    : 'Record')
                              : 'Save & Record',
                          onTap:
                              _amountController.text.trim().isNotEmpty &&
                                  !_saving
                              ? _recordAndDial
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final HugeIconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? GengaColors.surfaceElevated : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                icon,
                size: 16,
                color: active
                    ? GengaColors.textPrimary
                    : GengaColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GengaTypography.subhead.copyWith(
                  color: active
                      ? GengaColors.textPrimary
                      : GengaColors.textTertiary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool active;
  final VoidCallback onTap;

  const _ProviderChip({
    required this.label,
    required this.emoji,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? GengaColors.surfaceElevated : GengaColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: active
              ? Border.all(color: GengaColors.borderLight, width: 0.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GengaTypography.subhead.copyWith(
                color: active
                    ? GengaColors.textPrimary
                    : GengaColors.textSecondary,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountChipSmall extends StatelessWidget {
  final String name;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountChipSmall({
    required this.name,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? GengaColors.surfaceElevated : GengaColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? GengaColors.borderLight : GengaColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: GengaTypography.footnote.copyWith(
                color: isSelected
                    ? GengaColors.textPrimary
                    : GengaColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
