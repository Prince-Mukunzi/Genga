import 'package:drift/drift.dart' hide Column;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/providers/database_provider.dart';
import 'package:genga/core/providers/space_provider.dart';
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/core/services/analytics_service.dart';
import 'package:genga/core/services/currency_service.dart';
import 'package:genga/features/home/widgets/account_card_face.dart';
import 'package:genga/shared/animations/entrance_animation.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/brands/account_brand.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:genga/shared/widgets/amount_text.dart';
import 'package:genga/shared/widgets/dashed_box.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/genga_button.dart';
import 'package:genga/shared/widgets/genga_scaffold.dart';
import 'package:genga/shared/widgets/genga_text_field.dart';
import 'package:genga/shared/widgets/pressable.dart';
import 'package:genga/shared/widgets/sheet_parts.dart';

class _Draft {
  final AccountBrand brand;
  final String name;
  final String currency;
  final double balance;
  final bool primary;

  const _Draft({
    required this.brand,
    required this.name,
    required this.currency,
    required this.balance,
    required this.primary,
  });
}

class AddAccountFlow extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  final VoidCallback? onClose;

  const AddAccountFlow({super.key, required this.onDone, this.onClose});

  @override
  ConsumerState<AddAccountFlow> createState() => _AddAccountFlowState();
}

class _AddAccountFlowState extends ConsumerState<AddAccountFlow> {
  _Draft? _draft;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final b in kBrands) {
      final asset = b.logoAsset;
      if (asset != null) precacheImage(AssetImage(asset), context);
    }
  }

  bool get _isFirst => (ref.read(accountsProvider).valueOrNull ?? []).isEmpty;

  String _uniqueName(AccountBrand brand) {
    final existing = (ref.read(accountsProvider).valueOrNull ?? [])
        .map((a) => a.name)
        .toSet();
    if (!existing.contains(brand.name)) return brand.name;
    var i = 2;
    while (existing.contains('${brand.name} $i')) {
      i++;
    }
    return '${brand.name} $i';
  }

  Future<void> _editCard() async {
    HapticFeedback.selectionClick();
    final result = await showGengaBottomSheet<_Draft>(
      context: context,
      maxHeightFraction: 0.9,
      builder: (_) =>
          _CardSheet(initial: _draft, isFirst: _isFirst, nameFor: _uniqueName),
    );
    if (result != null && mounted) setState(() => _draft = result);
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || _saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final db = ref.read(databaseProvider);
      final space = ref.read(activeSpaceProvider).valueOrNull;
      final rates = await ref.read(currencyRatesProvider.future);
      final rate =
          rates
              .where((r) => r.code == draft.currency)
              .firstOrNull
              ?.rateFromRwf ??
          1;
      final inRwf = draft.currency == 'RWF' || rate == 0
          ? draft.balance
          : draft.balance / rate;

      final id = await db.insertAccount(
        AccountsCompanion.insert(
          name: draft.name,
          iconKey: 'creditcard',
          color: draft.brand.base.toARGB32(),
          accountType: Value(draft.brand.id),
          currency: Value(draft.currency),
          initialBalance: Value(inRwf),
          spaceId: Value(space?.id),
        ),
      );
      if (draft.primary || _isFirst) await db.setPrimaryAccount(id);

      ref.read(analyticsServiceProvider).trackEvent('account_created', {
        'account_type': draft.brand.id,
      });
      if (mounted) widget.onDone();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;

    return GengaScaffold(
      glow: draft?.brand.base,
      intensity: 0.2,
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            if (widget.onClose != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Pressable(
                  scale: 0.9,
                  onTap: widget.onClose,
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
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 18, 8, 4),
              child: Text('Add an account', style: GengaTypography.title1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 26),
              child: Text(
                draft == null
                    ? 'Tap the card to set it up.'
                    : 'Tap the card to change anything.',
                style: GengaTypography.subhead,
              ),
            ),
            EntranceAnimation(
              initialScale: 0.94,
              slideOffset: 20,
              child: Pressable(
                scale: 0.98,
                onTap: _editCard,
                child: SizedBox(
                  height: 190,
                  child: AnimatedSwitcher(
                    duration: GengaSprings.medium,
                    switchInCurve: GengaSprings.smooth,
                    child: draft == null
                        ? const _EmptyCard(key: ValueKey('empty'))
                        : AccountCardFace(
                            key: ValueKey(draft.brand.id),
                            account: Account(
                              id: -1,
                              name: draft.name,
                              iconKey: 'creditcard',
                              color: draft.brand.base.toARGB32(),
                              currency: draft.currency,
                              accountType: draft.brand.id,
                              isPrimary: draft.primary,
                              initialBalance: 0,
                              createdAt: DateTime.now(),
                            ),
                            large: true,
                            balanceText: AmountText.withSymbol(
                              draft.balance,
                              draft.currency,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            EntranceAnimation.stagger(
              index: 2,
              child: GengaButton(
                label: _saving ? 'Adding...' : 'Add account',
                onTap: draft == null || _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashedBox(
      radius: 24,
      fill: const Color(0x08FFFFFF),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x14FFFFFF),
              ),
              child: const Center(
                child: AppIcon(
                  AppIcons.add,
                  size: 22,
                  color: GengaColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add account',
              style: GengaTypography.callout.copyWith(
                color: GengaColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text('Mobile money, bank or cash', style: GengaTypography.footnote),
          ],
        ),
      ),
    );
  }
}

class _CardSheet extends ConsumerStatefulWidget {
  final _Draft? initial;
  final bool isFirst;
  final String Function(AccountBrand) nameFor;

  const _CardSheet({
    required this.initial,
    required this.isFirst,
    required this.nameFor,
  });

  @override
  ConsumerState<_CardSheet> createState() => _CardSheetState();
}

class _CardSheetState extends ConsumerState<_CardSheet> {
  AccountBrand? _brand;
  String _currency = 'RWF';
  bool _primary = false;
  late final TextEditingController _name;
  late final TextEditingController _balance;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _brand = d?.brand;
    _currency = d?.currency ?? 'RWF';
    _primary = d?.primary ?? widget.isFirst;
    _name = TextEditingController(text: d?.name ?? '');
    _balance = TextEditingController(
      text: d == null || d.balance == 0 ? '' : d.balance.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  void _choose(AccountBrand brand) {
    HapticFeedback.selectionClick();
    setState(() {
      _brand = brand;
      _name.text = widget.nameFor(brand);
    });
  }

  Future<void> _pickCurrency() async {
    final rates = await ref.read(currencyRatesProvider.future);
    if (rates.isEmpty || !mounted) return;
    final picked = await showGengaBottomSheet<String>(
      context: context,
      maxHeightFraction: 0.7,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetTitle('Currency'),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                for (final r in rates)
                  SheetOption(
                    label: r.code,
                    detail: r.name,
                    selected: r.code == _currency,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(ctx).pop(r.code);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked != null && mounted) setState(() => _currency = picked);
  }

  void _done() {
    final brand = _brand;
    if (brand == null) return;
    final name = _name.text.trim();
    Navigator.of(context).pop(
      _Draft(
        brand: brand,
        name: name.isEmpty ? widget.nameFor(brand) : name,
        currency: _currency,
        balance: double.tryParse(_balance.text.trim()) ?? 0,
        primary: _primary || widget.isFirst,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = _brand;
    return AnimatedSize(
      duration: GengaSprings.medium,
      curve: GengaSprings.smooth,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: GengaSprings.quick,
        child: brand == null
            ? _ProviderList(key: const ValueKey('list'), onChoose: _choose)
            : _DetailsForm(
                key: const ValueKey('details'),
                brand: brand,
                name: _name,
                balance: _balance,
                currency: _currency,
                primary: _primary || widget.isFirst,
                showPrimary: !widget.isFirst,
                onChangeProvider: () => setState(() => _brand = null),
                onCurrency: _pickCurrency,
                onPrimary: (v) => setState(() => _primary = v),
                onDone: _done,
              ),
      ),
    );
  }
}

class _ProviderList extends StatelessWidget {
  final ValueChanged<AccountBrand> onChoose;

  const _ProviderList({super.key, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    List<AccountBrand> of(BrandKind k) =>
        kBrands.where((b) => b.kind == k).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetTitle('Where is this money?'),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _Section('Mobile money', of(BrandKind.mobileMoney), onChoose),
              const SizedBox(height: 18),
              _Section('Banks', of(BrandKind.bank), onChoose),
              const SizedBox(height: 18),
              _Section('Other', of(BrandKind.other), onChoose),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<AccountBrand> brands;
  final ValueChanged<AccountBrand> onChoose;

  const _Section(this.title, this.brands, this.onChoose);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Text(title, style: GengaTypography.footnote),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: GengaColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              for (var i = 0; i < brands.length; i++) ...[
                Pressable(
                  scale: 0.98,
                  onTap: () => onChoose(brands[i]),
                  child: Container(
                    height: 62,
                    color: const Color(0x00000000),
                    child: Row(
                      children: [
                        _BrandTile(brand: brands[i]),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            brands[i].name,
                            style: GengaTypography.body,
                          ),
                        ),
                        const AppIcon(
                          AppIcons.chevronRight,
                          size: 12,
                          color: GengaColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (i < brands.length - 1)
                  Container(
                    height: 0.5,
                    margin: const EdgeInsets.only(left: 74),
                    color: GengaColors.border,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandTile extends StatelessWidget {
  final AccountBrand brand;

  const _BrandTile({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: brand.isLightCard
              ? const Color(0x1F000000)
              : const Color(0x24FFFFFF),
          width: 0.6,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: BrandBackground(
          brand: brand,
          child: Center(
            child: brand.logoAsset == null
                ? AppIcon(brand.icon, size: 18, color: brand.onCard)
                : BrandLogo(brand: brand, height: 20),
          ),
        ),
      ),
    );
  }
}

class _DetailsForm extends StatelessWidget {
  final AccountBrand brand;
  final TextEditingController name;
  final TextEditingController balance;
  final String currency;
  final bool primary;
  final bool showPrimary;
  final VoidCallback onChangeProvider;
  final VoidCallback onCurrency;
  final ValueChanged<bool> onPrimary;
  final VoidCallback onDone;

  const _DetailsForm({
    super.key,
    required this.brand,
    required this.name,
    required this.balance,
    required this.currency,
    required this.primary,
    required this.showPrimary,
    required this.onChangeProvider,
    required this.onCurrency,
    required this.onPrimary,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetTitle(
            brand.name,
            trailing: Pressable(
              onTap: onChangeProvider,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text('Change', style: GengaTypography.callout),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: Column(
                children: [
                  GengaTextField(
                    controller: name,
                    placeholder: 'Account name',
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: GengaTextField(
                          controller: balance,
                          placeholder: 'Balance',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Pressable(
                        scale: 0.96,
                        haptic: true,
                        onTap: onCurrency,
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: GengaColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: GengaColors.borderLight,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(currency, style: GengaTypography.body),
                              const SizedBox(width: 6),
                              const AppIcon(
                                AppIcons.chevronDown,
                                size: 12,
                                color: GengaColors.textTertiary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showPrimary) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Primary account',
                              style: GengaTypography.body,
                            ),
                          ),
                          CupertinoSwitch(
                            value: primary,
                            activeTrackColor: GengaColors.offWhite,
                            thumbColor: primary
                                ? GengaColors.onOffWhite
                                : CupertinoColors.white,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              onPrimary(v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: GengaButton(label: 'Done', onTap: onDone),
          ),
        ],
      ),
    );
  }
}
