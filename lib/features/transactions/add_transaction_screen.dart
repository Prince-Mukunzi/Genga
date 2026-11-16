import 'package:drift/drift.dart' hide Column;
import 'package:flutter/cupertino.dart';
import 'package:genga/shared/widgets/genga_sheets.dart';

import 'package:genga/shared/widgets/genga_button.dart';
import 'package:intl/intl.dart';
import 'package:genga/shared/widgets/currency_sheet.dart';
import 'package:genga/shared/widgets/genga_scaffold.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/models/enums.dart';
import 'package:genga/core/models/transaction_with_category.dart';
import 'package:genga/core/providers/database_provider.dart';
import 'package:genga/core/providers/momo_setup_provider.dart';
import 'package:genga/core/providers/preferences_provider.dart';
import 'package:genga/core/providers/space_provider.dart';
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/core/services/currency_service.dart';
import 'package:genga/core/services/analytics_service.dart';
import 'package:genga/core/services/widget_data_service.dart';
import 'package:genga/features/pay/contact_picker.dart';
import 'package:genga/shared/animations/entrance_animation.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/widgets/animated_amount.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/genga_toast.dart';
import 'package:genga/shared/widgets/pressable.dart';
import 'package:genga/core/services/mtn_fee_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:genga/shared/brands/account_brand.dart';

import 'widgets/account_picker.dart';
import 'widgets/amount_header.dart';
import 'widgets/category_chips.dart';

import 'package:genga/shared/widgets/amount_text.dart';
import 'package:genga/shared/widgets/morph_card.dart';

import 'widgets/details_card.dart';
import 'widgets/note_sheet.dart';
import 'calc_expression.dart';
import 'widgets/calculator_keypad.dart';
import 'widgets/category_picker.dart';
import 'widgets/recurrence_picker.dart';
import 'widgets/transaction_form_widgets.dart';
import 'widgets/type_switcher.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.initialType,
    this.initialAmount,
    this.initialNote,
    this.momoBalance,
    this.fromShortcut = false,
    this.editing,
  });

  final TransactionType? initialType;
  final double? initialAmount;
  final String? initialNote;
  final double? momoBalance;
  final bool fromShortcut;
  final TransactionWithCategory? editing;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late TransactionType _type;
  String _amountStr = '0';
  Category? _category;
  DateTime _date = DateTime.now();
  String _note = '';
  Recurrence _recurrence = Recurrence.none;
  bool _saving = false;
  bool _calcMode = false;
  final _moreKey = GlobalKey();
  String _expr = '';
  Account? _selectedAccount;
  Account? _toAccount;
  double? _momoBalance;

  double get _amount => double.tryParse(_amountStr) ?? 0;

  // Opened from a genga://add link, this screen is the only route, so
  // popping it would leave a blank app.
  void _close() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      context.go('/');
    }
  }

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      final txn = e.transaction;
      _type = txn.type;
      _amountStr = txn.amount == txn.amount.roundToDouble()
          ? txn.amount.toInt().toString()
          : txn.amount.toString();
      _category = e.category;
      _date = txn.date;
      _note = txn.note;
      _selectedAccount = e.account;
      _recurrence = Recurrence.values.firstWhere(
        (r) => r.name == txn.recurrence,
        orElse: () => Recurrence.none,
      );
    } else {
      _type = widget.initialType ?? TransactionType.expense;
      final amount = widget.initialAmount;
      if (amount != null && amount > 0) {
        _amountStr = amount == amount.roundToDouble()
            ? amount.toInt().toString()
            : amount.toString();
      }
      _note = widget.initialNote ?? '';
      _momoBalance = widget.momoBalance;
      if (widget.fromShortcut) {
        ref.read(momoSetupProvider.notifier).markCaptured();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final toId = widget.editing?.transaction.toAccountId;
    if (toId != null && _toAccount == null) {
      final accounts = ref.read(accountsProvider).valueOrNull ?? [];
      final match = accounts.where((a) => a.id == toId).firstOrNull;
      if (match != null) _toAccount = match;
    }
  }

  @override
  void didUpdateWidget(covariant AddTransactionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialType != null &&
        widget.initialType != oldWidget.initialType) {
      setState(() {
        _type = widget.initialType!;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currencyRatesProvider);
    final accounts = ref.watch(accountsProvider);
    final allAccounts = accounts.valueOrNull ?? [];

    if (_momoBalance != null && _selectedAccount == null) {
      _selectedAccount = allAccounts.where(_isMtn).firstOrNull;
    }

    final account =
        _selectedAccount ??
        allAccounts.where((a) => a.isPrimary).firstOrNull ??
        allAccounts.firstOrNull;
    final accountBalance = account != null
        ? ref.watch(accountBalanceProvider(account.id))
        : 0.0;
    final toAccountBalance = _toAccount != null
        ? ref.watch(accountBalanceProvider(_toAccount!.id))
        : 0.0;
    final isTransfer = _type == TransactionType.transfer;
    final currency = ref.watch(preferencesProvider).currency;
    final formattedAmount = 'RWF ${formatAmountDisplay(_amountStr)}';

    final typeGlow = switch (_type) {
      TransactionType.expense => GengaColors.expense,
      TransactionType.income => GengaColors.income,
      TransactionType.transfer => GengaColors.transfer,
    };

    return GengaScaffold(
      glow: typeGlow,
      intensity: 0.2,
      child: SafeArea(
        child: Column(
          children: [
            // ── Top bar ── (stagger index 0)
            EntranceAnimation.stagger(
              index: 0,
              slideOffset: 12,
              from: EntranceFrom.top,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    _CloseButton(onTap: _close),
                    const Spacer(),
                    TypeSwitcher(
                      selected: _type,
                      onChanged: (t) => setState(() {
                        _type = t;
                        _category = null;
                      }),
                      showTransfer: allAccounts.length >= 2,
                    ),
                    const Spacer(),
                    KeyedSubtree(
                      key: _moreKey,
                      child: _MoreButton(
                        active:
                            _calcMode ||
                            _note.isNotEmpty ||
                            _recurrence != Recurrence.none,
                        onTap: _showDetails,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body: transfer vs expense/income ──
            if (isTransfer) ...[
              const SizedBox(height: 12),
              Expanded(
                child: EntranceAnimation.stagger(
                  index: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _TransferBody(
                      fromAccount: account,
                      toAccount: _toAccount,
                      fromBalance: accountBalance,
                      toBalance: toAccountBalance,
                      amountDisplay: formattedAmount,
                      onFromTap: () => _pickAccount(isTo: false),
                      onToTap: () => _pickAccount(isTo: true),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: EntranceAnimation.stagger(
                  index: 1,
                  initialScale: 0.94,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IgnorePointer(
                                child: Opacity(
                                  opacity: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 14,
                                      right: 6,
                                    ),
                                    child: CurrencyLabel(
                                      currency: currency,
                                      onTap: () {},
                                    ),
                                  ),
                                ),
                              ),
                              Flexible(
                                child: AnimatedAmount(
                                  displayText: formatAmountDisplay(_amountStr),
                                  style: GengaTypography.amountLarge.copyWith(
                                    fontSize: 76,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: CurrencyLabel(
                                  currency: currency,
                                  onTap: _showCurrencyPicker,
                                ),
                              ),
                            ],
                          ),
                          AnimatedOpacity(
                            duration: GengaSprings.quick,
                            opacity: _amount > 0 ? 1 : 0,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${AmountText.plain(_type == TransactionType.income ? accountBalance + _amount : accountBalance - _amount)} left in ${account?.name ?? 'account'}',
                                style: GengaTypography.footnote,
                              ),
                            ),
                          ),
                          AnimatedSize(
                            duration: GengaSprings.medium,
                            curve: GengaSprings.smooth,
                            child: _calcMode && _expr.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      spaceExpression(_expr),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GengaTypography.body.copyWith(
                                        color: GengaColors.textSecondary,
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: double.infinity),
                          ),
                          DetailsSummary(
                            date: _date,
                            recurrence: _recurrence,
                            note: _note,
                            tint: typeGlow,
                            onTap: _showDetails,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              EntranceAnimation.stagger(
                index: 2,
                slideOffset: 10,
                child: QuickCategoryChips(
                  type: _type == TransactionType.income ? 'income' : 'expense',
                  selected: _category,
                  tint: typeGlow,
                  onSelect: (c) => setState(() => _category = c),
                  onMore: _pickCategory,
                ),
              ),
            ],

            // ── Keypad ── hidden when note field is open (keyboard takes its place)
            ...[
              const SizedBox(height: 8),
              EntranceAnimation.stagger(
                index: 4,
                slideOffset: 20,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: CalculatorKeypad(
                    onKeyPressed: _handleKey,
                    calcMode: _calcMode,
                  ),
                ),
              ),
            ],

            // ── Bottom action ── (stagger index 5)
            EntranceAnimation.stagger(
              index: 5,
              slideOffset: 16,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  8 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: _BottomBar(
                  type: _type,
                  canSave: _amount > 0 && !_saving,
                  saving: _saving,
                  accountName: account?.name ?? 'account',
                  editing: widget.editing != null,
                  onSave: _save,
                  onPay: _handlePay,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _amountStr = '0';
      _expr = '';
      _category = null;
      _date = DateTime.now();
      _note = '';
      _recurrence = Recurrence.none;
      _toAccount = null;
    });
  }

  void _handleKey(String key) {
    if (!_calcMode) {
      setState(() => _amountStr = handleAmountKey(_amountStr, key));
      return;
    }
    setState(() {
      if (key == '⌫') {
        if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
      } else if (isCalcOperator(key)) {
        if (_expr.isEmpty) return;
        _expr = isCalcOperator(_expr[_expr.length - 1])
            ? _expr.substring(0, _expr.length - 1) + key
            : _expr + key;
      } else if (key == '.') {
        final segment = _expr.split(RegExp('[+−×÷]')).last;
        if (!segment.contains('.')) {
          _expr = segment.isEmpty ? '${_expr}0.' : '$_expr.';
        }
      } else if (_expr.length < 24) {
        _expr += key;
      }
      final result = evaluateExpression(_expr);
      _amountStr = result == null || result < 0
          ? '0'
          : formatCalcResult(result);
    });
  }

  Future<void> _confirmDelete() async {
    final editing = widget.editing;
    if (editing == null) return;
    final ok = await showGengaConfirm(
      context,
      title: 'Delete transaction',
      message: 'This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await ref.read(databaseProvider).deleteTransaction(editing.transaction.id);
    HapticFeedback.mediumImpact();
    ref.read(widgetDataServiceProvider).updateWidgetData();
    if (!mounted) return;
    showGengaToast(context, 'Transaction deleted', icon: AppIcons.trash);
    Navigator.of(context).pop(true);
  }

  void _showDetails() {
    HapticFeedback.selectionClick();
    showMorphCard(
      context: context,
      anchor: _moreKey,
      width: 300,
      height: widget.editing != null ? 328 : 276,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final accounts = ref.read(accountsProvider).valueOrNull ?? [];
          final account =
              _selectedAccount ??
              accounts.where((a) => a.isPrimary).firstOrNull ??
              accounts.firstOrNull;
          final balance = account != null
              ? ref.read(accountBalanceProvider(account.id))
              : 0.0;
          final now = DateTime.now();
          final isToday =
              _date.year == now.year &&
              _date.month == now.month &&
              _date.day == now.day;
          return DetailsCard(
            account: account,
            balanceLabel:
                '${AmountText.plain(balance)} ${ref.read(preferencesProvider).currency}',
            dateLabel: isToday ? 'Today' : DateFormat.MMMd().format(_date),
            repeatLabel: _recurrence.label,
            noteLabel: _note.isEmpty ? 'Add' : _note,
            calcOn: _calcMode,
            onAccount: () async {
              await _pickAccount(isTo: false);
              setSheet(() {});
            },
            onDate: () async {
              await _pickDate();
              setSheet(() {});
            },
            onRepeat: () async {
              await _pickRecurrence();
              setSheet(() {});
            },
            onNote: () async {
              await _toggleNote();
              setSheet(() {});
            },
            onCalc: (v) {
              if (v != _calcMode) _toggleCalc();
              setSheet(() {});
            },
            onDelete:
                widget.editing != null &&
                    (!ref.read(isSharedSpaceProvider) ||
                        ref.read(isSpaceAdminProvider))
                ? () {
                    Navigator.of(ctx).pop();
                    _confirmDelete();
                  }
                : null,
          );
        },
      ),
    );
  }

  void _toggleCalc() {
    HapticFeedback.selectionClick();
    setState(() {
      _calcMode = !_calcMode;
      _expr = _calcMode && _amountStr != '0' ? _amountStr : '';
    });
  }

  Future<void> _pickDate() async {
    await showGengaBottomSheet<void>(
      context: context,
      maxHeightFraction: 0.45,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            child: Row(
              children: [
                const Spacer(),
                Text(
                  'Date',
                  style: GengaTypography.headline.copyWith(
                    color: GengaColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(
                    'Done',
                    style: GengaTypography.callout.copyWith(
                      color: GengaColors.dynamicAccent(context),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _date,
              maximumDate: DateTime.now(),
              onDateTimeChanged: (d) => setState(() => _date = d),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleNote() async {
    final result = await showNoteSheet(context: context, initial: _note);
    if (result != null && mounted) setState(() => _note = result);
  }

  void _showCurrencyPicker() {
    showCurrencySheet(context, ref);
  }

  Future<void> _pickAccount({required bool isTo}) async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    final current = isTo
        ? _toAccount
        : (_selectedAccount ?? accounts.firstOrNull);
    final exclude = isTo
        ? (_selectedAccount ?? accounts.firstOrNull)?.id
        : null;

    final picked = await showAccountPicker(
      context: context,
      selectedId: current?.id,
      excludeId: exclude,
      title: isTo ? 'Transfer To' : 'Account',
    );
    if (picked != null) {
      setState(() {
        if (isTo) {
          _toAccount = picked;
        } else {
          _selectedAccount = picked;
        }
      });
    }
  }

  Future<void> _pickCategory() async {
    final picked = await showCategoryPicker(
      context: context,
      selectedId: _category?.id,
      transactionType: _type == TransactionType.income ? 'income' : 'expense',
    );
    if (picked != null) setState(() => _category = picked);
  }

  Future<void> _pickRecurrence() async {
    final picked = await showRecurrencePicker(
      context: context,
      current: _recurrence,
    );
    if (picked != null) setState(() => _recurrence = picked);
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

  String _generateUssd(PickedRecipient recipient, double amount) {
    final phone = _cleanPhone(recipient.phone);
    final amountStr = amount.toStringAsFixed(0);
    if (recipient.kind == RecipientKind.phone) {
      return '*182*1*1*$phone*$amountStr#';
    } else {
      return '*182*8*1*$phone*$amountStr#';
    }
  }

  Future<void> _dialUssd(String ussd) async {
    final encoded = Uri.encodeComponent(ussd);
    final uri = Uri.parse('tel:$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _handlePay() async {
    final amount = _amount;
    if (amount <= 0) return;

    final recipient = await showContactPicker(context);
    if (recipient == null || !mounted) return;

    setState(() => _saving = true);
    HapticFeedback.heavyImpact();

    final allAccounts0 = ref.read(accountsProvider).valueOrNull ?? [];
    final payAccount =
        _selectedAccount ??
        allAccounts0.where((a) => a.isPrimary).firstOrNull ??
        allAccounts0.firstOrNull;
    final brand = brandFor(payAccount?.accountType ?? 'cash');
    final usesMomoCodes = brand.automatedMomoPay || brand.ussdMenu == null;

    final fee = usesMomoCodes && isPhoneRecipient(recipient)
        ? getMtnFee(amount)
        : null;
    final feeAmount = fee?.onNet.toDouble() ?? 0;
    final ussd = usesMomoCodes
        ? _generateUssd(recipient, amount)
        : brand.ussdMenu!;

    try {
      final db = ref.read(databaseProvider);
      final allAccounts = ref.read(accountsProvider).valueOrNull ?? [];
      final account =
          _selectedAccount ??
          allAccounts.where((a) => a.isPrimary).firstOrNull ??
          (allAccounts.isNotEmpty ? allAccounts.first : null);

      if (account != null) {
        final createdBy = ref.read(currentUserNameProvider);
        final entry = TransactionsCompanion.insert(
          amount: amount,
          type: _type,
          categoryId: Value(_category?.id),
          accountId: account.id,
          toAccountId: Value(_toAccount?.id),
          date: _date,
          note: Value(_note.isNotEmpty ? _note : 'Sent to ${recipient.name}'),
          recurrence: Value(_recurrence.name),
          recipientName: Value(recipient.name),
          recipientPhone: Value(recipient.phone),
          momoFee: Value(feeAmount),
          createdBy: Value(createdBy),
        );

        await db.insertTransaction(entry);
        ref.read(widgetDataServiceProvider).updateWidgetData();
      }
    } catch (_) {
      // DB write may fail; still proceed to dial.
    }

    final analytics = ref.read(analyticsServiceProvider);
    final feeTier = amount < 5000
        ? 'low'
        : amount < 50000
        ? 'medium'
        : 'high';
    analytics.trackEvent('momo_pay_initiated', {'fee_tier': feeTier});
    analytics.incrementTransactionCount();

    await _dialUssd(ussd);

    if (mounted) {
      showGengaToast(
        context,
        usesMomoCodes
            ? 'Payment recorded'
            : 'Recorded. Finish the transfer in the ${brand.name} menu',
        icon: AppIcons.checkmarkCircle,
      );
      _resetForm();
    }

    if (mounted) setState(() => _saving = false);
  }

  /// Shows a native iOS alert asking whether to apply MoMo charges.
  /// Returns the fee amount (0 if user declines or fee is N/A).
  Future<double> _askMomoFee(double amount) async {
    final fee = getMtnFee(amount);
    if (fee == null) return 0;

    final apply = await showGengaConfirm(
      context,
      title: 'Apply MoMo charges?',
      message:
          'Include the MTN MoMo fee of RWF ${fee.onNet} for this transaction?',
      confirmLabel: 'Yes, apply',
      cancelLabel: 'No',
    );

    return apply ? fee.onNet.toDouble() : 0;
  }

  Future<void> _save() async {
    final amount = _amount;
    if (amount <= 0) return;

    // For expenses, ask if MoMo charges should be applied
    double feeAmount = 0;
    if (_type == TransactionType.expense) {
      feeAmount = await _askMomoFee(amount);
      if (!mounted) return;
    }

    setState(() => _saving = true);

    try {
      final db = ref.read(databaseProvider);
      final allAccounts = ref.read(accountsProvider).valueOrNull ?? [];
      if (allAccounts.isEmpty) return;

      final editing = widget.editing;
      if (editing != null) {
        final old = editing.transaction;
        final target =
            _selectedAccount ??
            allAccounts.where((a) => a.id == old.accountId).firstOrNull ??
            allAccounts.first;
        await db.updateTransaction(
          old.copyWith(
            amount: amount,
            type: _type,
            categoryId: Value(_category?.id),
            accountId: target.id,
            toAccountId: Value(_toAccount?.id),
            date: _date,
            note: _note,
            recurrence: _recurrence.name,
            momoFee: feeAmount,
            updatedBy: ref.read(currentUserNameProvider),
          ),
        );
        HapticFeedback.mediumImpact();
        ref.read(widgetDataServiceProvider).updateWidgetData();
        ref.read(analyticsServiceProvider).trackEvent('transaction_edited', {
          'type': _type.name,
        });
        if (mounted) {
          showGengaToast(
            context,
            'Transaction updated',
            icon: AppIcons.checkmarkCircle,
          );
          Navigator.of(context).pop(true);
        }
        return;
      }

      final account =
          _selectedAccount ??
          allAccounts.where((a) => a.isPrimary).firstOrNull ??
          allAccounts.first;

      final balanceBefore = ref.read(accountBalanceProvider(account.id));
      final createdBy = ref.read(currentUserNameProvider);
      final entry = TransactionsCompanion.insert(
        amount: amount,
        type: _type,
        categoryId: Value(_category?.id),
        accountId: account.id,
        toAccountId: Value(_toAccount?.id),
        date: _date,
        note: Value(_note),
        recurrence: Value(_recurrence.name),
        momoFee: Value(feeAmount),
        createdBy: Value(createdBy),
      );

      final savedId = await db.insertTransaction(entry);
      final savedNote = _note.trim();
      HapticFeedback.heavyImpact();
      ref.read(widgetDataServiceProvider).updateWidgetData();

      final analytics = ref.read(analyticsServiceProvider);
      analytics.trackEvent('transaction_created', {
        'type': _type.name,
        'category_name': _category?.isDefault == true
            ? _category?.name ?? 'uncategorized'
            : 'custom',
        'has_note': _note.isNotEmpty,
        'recurrence': _recurrence.name,
        'has_momo_fee': feeAmount > 0,
        'account_type': account.accountType,
        'hour_of_day': DateTime.now().hour,
      });
      analytics.incrementTransactionCount();

      if (mounted) {
        showGengaToast(
          context,
          'Transaction saved',
          icon: AppIcons.checkmarkCircle,
        );
        _resetForm();
      }

      final change = _type == TransactionType.income
          ? amount
          : -(amount + feeAmount);
      await _checkMomoBalance(
        account,
        balanceBefore + change,
        savedId: savedId,
        hasOwnNote: savedNote.isNotEmpty,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static bool _isMtn(Account a) => brandFor(a.accountType).id == 'mtn_momo';

  Future<void> _checkMomoBalance(
    Account account,
    double expected, {
    required int savedId,
    required bool hasOwnNote,
  }) async {
    final momo = _momoBalance;
    _momoBalance = null;
    if (momo == null || !_isMtn(account) || !mounted) return;
    if ((momo - expected).abs() < 1) return;

    final useMomo = await showGengaConfirm(
      context,
      title: "Balance doesn't match",
      message:
          'MoMo says your balance is ${AmountText.withSymbol(momo, 'RWF')}, '
          'but Genga shows ${AmountText.withSymbol(expected, 'RWF')} for '
          '${account.name}.',
      confirmLabel: 'Use MoMo balance',
      cancelLabel: "Keep Genga's",
    );
    if (!useMomo) return;

    final db = ref.read(databaseProvider);
    final fresh = (ref.read(accountsProvider).valueOrNull ?? [])
        .where((a) => a.id == account.id)
        .firstOrNull;
    final base = fresh ?? account;
    await db.updateAccount(
      base.copyWith(initialBalance: base.initialBalance + (momo - expected)),
    );
    if (!hasOwnNote) {
      final diff = momo - expected;
      final sign = diff > 0 ? '+' : '-';
      await db.setTransactionNote(
        savedId,
        'Balance synced with MoMo ($sign${AmountText.plain(diff.abs())})',
      );
    }
    ref.read(widgetDataServiceProvider).updateWidgetData();
    HapticFeedback.mediumImpact();
  }
}

class _MoreButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _MoreButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = GengaColors.dynamicAccent(context);
    return Pressable(
      scale: 0.9,
      onTap: onTap,
      child: AnimatedContainer(
        duration: GengaSprings.quick,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? accent.withValues(alpha: 0.2) : GengaColors.surface,
        ),
        child: Center(
          child: AppIcon(
            AppIcons.ellipsis,
            size: 18,
            color: active ? accent : GengaColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.9,
      onTap: onTap,
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
            size: 16,
            color: GengaColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Two vertically-stacked account cards with a divider arrow in between.
/// Used exclusively in transfer mode.
class _TransferBody extends StatelessWidget {
  final Account? fromAccount;
  final Account? toAccount;
  final double fromBalance;
  final double toBalance;
  final String amountDisplay;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;

  const _TransferBody({
    required this.fromAccount,
    required this.toAccount,
    required this.fromBalance,
    required this.toBalance,
    required this.amountDisplay,
    required this.onFromTap,
    required this.onToTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The two cards in a column
        Column(
          children: [
            Expanded(
              child: TransferAccountCard(
                account: fromAccount,
                balance: fromBalance,
                amountDisplay: amountDisplay,
                fallbackLabel: 'From',
                onAccountTap: onFromTap,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: TransferAccountCard(
                account: toAccount,
                balance: toBalance,
                amountDisplay: amountDisplay,
                fallbackLabel: 'To',
                dimAmount: true,
                onAccountTap: onToTap,
              ),
            ),
          ],
        ),

        // Floating divider arrow centered on the gap
        const Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(child: TransferDividerArrow()),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final TransactionType type;
  final bool canSave;
  final bool saving;
  final String accountName;
  final bool editing;
  final VoidCallback onSave;
  final VoidCallback onPay;

  const _BottomBar({
    required this.type,
    required this.canSave,
    required this.saving,
    required this.accountName,
    required this.editing,
    required this.onSave,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = type == TransactionType.expense && !editing;
    final label = saving
        ? 'Saving...'
        : editing
        ? 'Save changes'
        : 'Save to $accountName';
    if (!isExpense) {
      return GengaButton(label: label, onTap: canSave ? onSave : null);
    }
    final save = Pressable(
      haptic: true,
      onTap: canSave ? onSave : null,
      child: AnimatedOpacity(
        opacity: canSave ? 1 : 0.45,
        duration: GengaSprings.releaseDuration,
        child: SizedBox(
          height: 44,
          width: double.infinity,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GengaTypography.callout.copyWith(
                color: GengaColors.textPrimary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: GengaColors.textSecondary,
                decorationThickness: 1,
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GengaButton(
          label: saving ? 'Processing...' : 'Pay now',
          onTap: canSave ? onPay : null,
        ),
        const SizedBox(height: 2),
        save,
      ],
    );
  }
}
