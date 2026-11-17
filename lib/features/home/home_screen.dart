import 'package:flutter/cupertino.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/core/services/ussd_service.dart';
import 'package:genga/core/providers/immersive_provider.dart';
import 'package:genga/shared/constants/space_constants.dart';
import 'package:genga/shared/widgets/genga_button.dart';

import 'package:genga/shared/widgets/genga_scaffold.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/providers/database_provider.dart';
import 'package:genga/core/providers/preferences_provider.dart';
import 'package:genga/core/providers/space_provider.dart';
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/core/services/widget_data_service.dart';
import 'package:genga/core/services/currency_service.dart';
import 'package:genga/shared/animations/entrance_animation.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/pressable.dart';

import 'package:genga/features/settings/create_space_sheet.dart';

import 'widgets/wallet_view.dart';
import 'widgets/recent_transactions_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hidden = false;
  int? _selectedAccountId;
  bool _checkedOnboarding = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(widgetDataServiceProvider).updateWidgetData(),
    );
  }

  void _showSpaceSwitcher() {
    final allSpaces = ref.read(spacesProvider).valueOrNull ?? [];
    final activeSpace = ref.read(activeSpaceProvider).valueOrNull;

    showGengaBottomSheet<void>(
      context: context,
      maxHeightFraction: 0.5,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Spaces',
              style: GengaTypography.headline.copyWith(
                color: GengaColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Separate your personal, family, or work finances.',
              textAlign: TextAlign.center,
              style: GengaTypography.caption1.copyWith(
                color: GengaColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: GengaColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < allSpaces.length; i++) ...[
                    Pressable(
                      scale: 0.98,
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        await ref
                            .read(databaseProvider)
                            .setActiveSpace(allSpaces[i].id);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: kSpaceColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: AppIcon(
                                  AppIcons.resolve(allSpaces[i].iconKey),
                                  size: 14,
                                  color: GengaColors.onOffWhite,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    allSpaces[i].name,
                                    style: GengaTypography.body.copyWith(
                                      color: GengaColors.textPrimary,
                                    ),
                                  ),
                                  if (allSpaces[i].type != 'personal')
                                    Text(
                                      allSpaces[i].type == 'family'
                                          ? 'Family'
                                          : 'Organization',
                                      style: GengaTypography.caption2.copyWith(
                                        color: GengaColors.textTertiary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (allSpaces[i].type != 'personal')
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(ctx).pop();
                                    context.push(
                                      '/space-settings',
                                      extra: allSpaces[i],
                                    );
                                  },
                                  child: const AppIcon(
                                    AppIcons.gear,
                                    color: GengaColors.textTertiary,
                                    size: 18,
                                  ),
                                ),
                              ),
                            if (allSpaces[i].id == activeSpace?.id)
                              AppIcon(
                                AppIcons.checkmarkAlt,
                                color: GengaColors.dynamicAccent(context),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (i < allSpaces.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 56),
                        child: Container(
                          height: 0.5,
                          color: GengaColors.border,
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            GengaButton.secondary(
              label: 'New space',
              onTap: () {
                Navigator.of(ctx).pop();
                showCreateSpaceSheet(context, ref);
              },
              icon: AppIcons.add,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);

    if (!_checkedOnboarding && accounts.hasValue) {
      _checkedOnboarding = true;
      if (accounts.value!.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/onboarding');
        });
      }
    }

    final list = accounts.valueOrNull ?? const <Account>[];
    if (list.isNotEmpty && !list.any((a) => a.id == _selectedAccountId)) {
      _selectedAccountId =
          (list.where((a) => a.isPrimary).firstOrNull ?? list.first).id;
    }

    final prefs = ref.watch(preferencesProvider);
    ref.watch(currencyRatesProvider);
    final immersive = ref.watch(immersiveProvider);

    final selected = list.where((a) => a.id == _selectedAccountId).firstOrNull;
    final glow = selected != null
        ? kSpaceColor
        : CupertinoTheme.of(context).primaryColor;
    final topPadding = MediaQuery.of(context).padding.top;

    return GengaScaffold(
      glow: glow,
      intensity: 0.22,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  AnimatedOpacity(
                    duration: GengaSprings.quick,
                    opacity: immersive ? 0.15 : 1,
                    child: _TopBar(
                      onSpaceTap: _showSpaceSwitcher,
                      onCheckBalance: mtnBalanceDialer(list),
                    ),
                  ),
                  const SizedBox(height: 28),
                  EntranceAnimation.stagger(
                    index: 2,
                    slideOffset: 40,
                    initialScale: 0.96,
                    child: WalletView(
                      accounts: list,
                      selectedId: _selectedAccountId,
                      onSelect: (id) => setState(() => _selectedAccountId = id),
                      onOpen: (id) => context.push('/account/$id'),
                      hidden: _hidden,
                      onToggleHidden: () => setState(() => _hidden = !_hidden),
                      currency: prefs.currency,
                      rate: prefs.currencyRate,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            sliver: SliverToBoxAdapter(
              child: AnimatedOpacity(
                duration: GengaSprings.quick,
                opacity: immersive ? 0.15 : 1,
                child: EntranceAnimation(
                  delay: const Duration(milliseconds: 250),
                  slideOffset: 20,
                  child: const RecentTransactionsCard(),
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final VoidCallback onSpaceTap;
  final VoidCallback? onCheckBalance;

  const _TopBar({required this.onSpaceTap, required this.onCheckBalance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = CupertinoTheme.of(context).primaryColor;
    final space = ref.watch(activeSpaceProvider).valueOrNull;
    final spaceName = space?.name ?? 'Personal';
    final spaceIcon = space != null
        ? AppIcons.resolve(space.iconKey)
        : AppIcons.personFill;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        EntranceAnimation.stagger(
          index: 0,
          slideOffset: 12,
          from: EntranceFrom.left,
          child: Pressable(
            onTap: onSpaceTap,
            haptic: true,
            child: Container(
              height: 46,
              padding: const EdgeInsets.fromLTRB(6, 0, 16, 0),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                    ),
                    child: Center(
                      child: AppIcon(
                        spaceIcon,
                        size: 16,
                        color: GengaColors.onOffWhite,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      spaceName,
                      style: GengaTypography.subhead.copyWith(
                        color: GengaColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const AppIcon(
                    AppIcons.chevronDown,
                    size: 12,
                    color: GengaColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: GengaSprings.medium,
          switchInCurve: GengaSprings.smooth,
          child: onCheckBalance == null
              ? const SizedBox(key: ValueKey('none'), height: 46)
              : Pressable(
                  key: const ValueKey('balance'),
                  onTap: onCheckBalance,
                  haptic: true,
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.fromLTRB(6, 0, 18, 0),
                    decoration: BoxDecoration(
                      color: CupertinoTheme.of(context).primaryColor
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CupertinoTheme.of(context).primaryColor,
                          ),
                          child: const Center(
                            child: AppIcon(
                              AppIcons.wallet04,
                              size: 16,
                              color: GengaColors.onOffWhite,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Balance',
                          style: GengaTypography.subhead.copyWith(
                            color: GengaColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
