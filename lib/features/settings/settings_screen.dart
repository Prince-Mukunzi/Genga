import 'package:flutter/cupertino.dart';
import 'package:genga/shared/widgets/currency_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:genga/shared/widgets/genga_sheets.dart';

import 'package:genga/shared/widgets/genga_button.dart';

import 'package:genga/shared/widgets/genga_text_field.dart';

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
import 'package:genga/features/settings/create_space_sheet.dart';
import 'package:genga/features/settings/space_settings_screen.dart';
import 'package:genga/shared/animations/entrance_animation.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/widgets/pressable.dart';
import 'package:genga/shared/constants/space_constants.dart';
import 'package:genga/shared/widgets/space_icon_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:genga/core/services/notification_service.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/sheet_parts.dart';
import 'package:genga/core/services/contacts_access.dart';
import 'package:genga/core/services/widget_data_service.dart';
import 'package:genga/features/settings/momo_capture_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catCount = ref.watch(categoriesProvider).valueOrNull?.length ?? 0;
    final accountCount = ref.watch(accountsProvider).valueOrNull?.length ?? 0;
    final activeSpace = ref.watch(activeSpaceProvider).valueOrNull;
    final accent = GengaColors.dynamicAccent(context);

    final spaceName = activeSpace?.name ?? 'Personal';
    final spaceColor = activeSpace != null ? kSpaceColor : accent;

    final spaceIcon = activeSpace != null
        ? AppIcons.resolve(activeSpace.iconKey)
        : AppIcons.personFill;

    return GengaScaffold(
      glow: spaceColor,
      intensity: 0.16,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 20,
          16,
          140,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 18),
            child: Text('Settings', style: GengaTypography.title1),
          ),
          EntranceAnimation.stagger(
            index: 0,
            child: _SpaceBanner(
              name: spaceName,
              icon: spaceIcon,
              color: spaceColor,
              subtitle: activeSpace != null && activeSpace.type != 'personal'
                  ? 'Shared space'
                  : 'Personal space',
              onEdit: () => _showEditSpace(context, ref, activeSpace),
              onSwitch: () => _showSwitchSpace(context, ref),
              onNew: () => showCreateSpaceSheet(context, ref),
              onMembers: activeSpace != null && activeSpace.type != 'personal'
                  ? () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => SpaceSettingsScreen(space: activeSpace),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 26),
          const _SectionLabel('Manage'),
          EntranceAnimation.stagger(
            index: 2,
            child: _Group(
              children: [
                _IconRow(
                  icon: AppIcons.building2Fill,
                  color: const Color(0xFF3478F6),
                  label: 'Accounts',
                  value: '$accountCount',
                  onTap: () => context.push('/accounts'),
                ),
                _IconRow(
                  icon: AppIcons.squareGrid2x2,
                  color: const Color(0xFF8E8E93),
                  label: 'Categories',
                  value: '$catCount',
                  onTap: () => context.push('/categories'),
                ),
                _IconRow(
                  icon: AppIcons.arrow2Circlepath,
                  color: const Color(0xFFFF9F0A),
                  label: 'Recurring',
                  isLast: true,
                  onTap: () => context.push('/recurring'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const _SectionLabel('Preferences'),
          EntranceAnimation.stagger(index: 3, child: const _PreferencesGroup()),
          const SizedBox(height: 26),
          const _SectionLabel('Automation'),
          EntranceAnimation.stagger(
            index: 4,
            child: _Group(
              children: [
                _IconRow(
                  icon: AppIcons.boltFill,
                  color: const Color(0xFFFFCC00),
                  label: 'Auto-capture MoMo',
                  isLast: true,
                  onTap: () => showMomoCaptureSheet(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const _SectionLabel('Data'),
          EntranceAnimation.stagger(
            index: 5,
            child: _Group(
              children: [
                _IconRow(
                  icon: AppIcons.trash,
                  color: const Color(0xFFFF453A),
                  label: 'Delete all data',
                  isLast: true,
                  onTap: () => _confirmEraseAll(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const _SectionLabel('About'),
          EntranceAnimation.stagger(
            index: 6,
            child: _Group(
              children: [
                _IconRow(
                  icon: AppIcons.sparkles,
                  color: const Color(0xFF8E8E93),
                  label: "What's new",
                  onTap: () => _showWhatsNew(context),
                ),
                _IconRow(
                  icon: AppIcons.sent,
                  color: const Color(0xFF8E8E93),
                  label: 'Share Genga',
                  onTap: () => Share.share(
                    'Genga helps you track your money across MoMo, banks and cash, all on your phone.',
                  ),
                ),
                _IconRow(
                  icon: AppIcons.shieldFill,
                  color: const Color(0xFF8E8E93),
                  label: 'Help and privacy',
                  onTap: () => _showInfo(
                    context,
                    title: 'Help and privacy',
                    lines: const [
                      'Your accounts and transactions are stored on this phone only.',
                      'Anonymous analytics are off unless you turn them on in Preferences.',
                      'The Balance button dials your provider\'s USSD menu. Genga never reads your PIN.',
                      'Delete all data erases everything on this phone.',
                    ],
                  ),
                ),
                _IconRow(
                  icon: AppIcons.coffee,
                  color: _coffeeColor,
                  label: 'Tip the developer',
                  onTap: _openTip,
                ),
                _IconRow(
                  icon: AppIcons.personFill,
                  color: const Color(0xFF8E8E93),
                  label: 'About the developer',
                  isLast: true,
                  onTap: () => _showDeveloper(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          const _Footer(),
        ],
      ),
    );
  }

  void _showInfo(
    BuildContext context, {
    required String title,
    required List<String> lines,
  }) {
    showGengaBottomSheet<void>(
      context: context,
      maxHeightFraction: 0.7,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetTitle(title),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(line, style: GengaTypography.subhead),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GengaButton(
              label: 'Got it',
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeveloper(BuildContext context) {
    showGengaBottomSheet<void>(
      context: context,
      maxHeightFraction: 0.9,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
                stops: [0.82, 1],
              ).createShader(rect),
              child: Image.asset(
                'assets/images/developer.webp',
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Hi, I\'m Mukunzi', style: GengaTypography.title2),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'I live in Kigali, Rwanda. I genuinely enjoy building things, '
              'I care about pixel-perfect design, but I\'m now leaning toward '
              'performance optimization. Other than that, I\'m playing '
              'basketball (if you\'re reading this, there\'s a high chance '
              'you can\'t guard me), swimming, and golf sometimes. Most of '
              'all, Jesus is genuinely holding my life together.',
              textAlign: TextAlign.center,
              style: GengaTypography.subhead.copyWith(
                color: GengaColors.textSecondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
            child: GengaButton(
              label: 'Okay, nerd',
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GengaButton.secondary(
              label: 'Buy me a coffee',
              icon: AppIcons.coffee,
              onTap: _openTip,
            ),
          ),
        ],
      ),
    );
  }

  void _openTip() {
    launchUrl(Uri.parse(kTipUrl), mode: LaunchMode.externalApplication);
  }

  void _showWhatsNew(BuildContext context) {
    const items = [
      (
        icon: AppIcons.wallet04,
        title: 'A wallet you can hold',
        body: 'Hold the wallet on Home and slide to flick through your cards.',
      ),
      (
        icon: AppIcons.creditcardFill,
        title: 'Cards in your colours',
        body: 'Bank and mobile money cards, with a one-tap MoMo balance check.',
      ),
      (
        icon: AppIcons.tagFill,
        title: 'Rwanda-first categories',
        body: 'Bike, Moto taxi, AI subscriptions and more, ready to go.',
      ),
      (
        icon: AppIcons.chartBarFill,
        title: 'Reports',
        body: 'See your money by week, month or year.',
      ),
    ];

    showGengaBottomSheet<void>(
      context: context,
      maxHeightFraction: 0.8,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetTitle("What's new"),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: AppIcon(
                              item.icon,
                              size: 22,
                              color: GengaColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: GengaTypography.headline),
                                const SizedBox(height: 3),
                                Text(
                                  item.body,
                                  style: GengaTypography.subhead.copyWith(
                                    color: GengaColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GengaButton(
              label: 'Got it',
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSwitchSpace(BuildContext context, WidgetRef ref) async {
    final allSpaces = await ref.read(spacesProvider.future);
    final activeSpace = ref.read(activeSpaceProvider).valueOrNull;
    if (!context.mounted) return;

    showGengaActionSheet(
      context,
      title: 'Switch space',
      actions: [
        for (final space in allSpaces)
          SheetAction(
            label: space.name,
            selected: space.id == activeSpace?.id,
            leading: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: kSpaceColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppIcon(
                  AppIcons.resolve(space.iconKey),
                  size: 14,
                  color: GengaColors.onOffWhite,
                ),
              ),
            ),
            onTap: () => ref.read(databaseProvider).setActiveSpace(space.id),
          ),
      ],
    );
  }

  Future<void> _confirmEraseAll(BuildContext context, WidgetRef ref) async {
    final ok = await showGengaConfirm(
      context,
      title: 'Delete all data?',
      message:
          'Every account, transaction, category, space and setting on this '
          'phone will be erased, and Genga will start fresh.\n\n'
          'This cannot be undone.',
      confirmLabel: 'Delete everything',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    HapticFeedback.heavyImpact();
    await ref.read(databaseProvider).eraseEverything();
    await ref.read(preferencesProvider.notifier).resetAll();
    await ref.read(widgetDataServiceProvider).updateWidgetData();
    if (context.mounted) context.go('/onboarding');
  }

  void _showEditSpace(BuildContext context, WidgetRef ref, Space? activeSpace) {
    if (activeSpace == null) return;

    final nameController = TextEditingController(text: activeSpace.name);
    final canDeleteSpace =
        (ref.read(spacesProvider).valueOrNull?.length ?? 0) > 1;

    var selectedIcon = activeSpace.iconKey;

    showGengaBottomSheet<void>(
      context: context,
      maxHeightFraction: 0.92,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          const color = kSpaceColor;
          final icon = selectedIcon;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Space',
                  style: GengaTypography.headline.copyWith(
                    color: GengaColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AppIcon.key(
                      icon,
                      size: 28,
                      color: GengaColors.onOffWhite,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GengaTextField(
                  controller: nameController,
                  placeholder: 'Space name',
                  autofocus: true,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SpaceIconPicker(
                  type: activeSpace.type,
                  selected: selectedIcon,
                  onChanged: (k) => setSheetState(() => selectedIcon = k),
                ),
                const SizedBox(height: 20),
                GengaButton(
                  label: 'Save Changes',
                  onTap: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final db = ref.read(databaseProvider);
                    await db.updateSpace(
                      activeSpace.copyWith(
                        name: name,
                        color: color.toARGB32(),
                        iconKey: icon,
                      ),
                    );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                ),
                if (canDeleteSpace) ...[
                  const SizedBox(height: 12),
                  GengaButton.danger(
                    label: 'Delete Space',
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _confirmDeleteSpace(context, ref, activeSpace);
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteSpace(
    BuildContext context,
    WidgetRef ref,
    Space space,
  ) async {
    final ok = await showGengaConfirm(
      context,
      title: 'Delete space',
      message:
          'This will permanently delete "${space.name}" and all its data. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(databaseProvider).deleteSpace(space.id);
  }
}

Future<bool> _confirmAnalytics(BuildContext context) {
  return showGengaConfirm(
    context,
    title: 'Anonymous analytics',
    message:
        'Help improve Genga by sharing anonymous usage data.\n\n'
        'What we collect:\n'
        '• Which screens you visit\n'
        '• How often you open the app\n'
        '• Feature usage (categories, accounts)\n\n'
        'What we never collect:\n'
        '• Transaction amounts\n'
        '• Personal information\n'
        '• Notes or tags\n'
        '• Phone numbers or names',
    confirmLabel: 'Enable',
  );
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Text(title, style: GengaTypography.footnote),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: GengaColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GengaColors.border, width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class _IconChip extends StatelessWidget {
  final HugeIconData icon;
  final Color color;

  const _IconChip({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final destructive = color.toARGB32() == 0xFFFF453A;
    return SizedBox(
      width: 26,
      child: AppIcon(
        icon,
        size: 22,
        color: destructive
            ? GengaColors.destructive
            : GengaColors.textSecondary,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 44),
      color: GengaColors.border,
    );
  }
}

class _IconRow extends StatelessWidget {
  final HugeIconData icon;
  final Color color;
  final String label;
  final String? value;
  final bool isLast;
  final VoidCallback onTap;

  const _IconRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Pressable(
          scale: 0.98,
          onTap: onTap,
          child: Container(
            height: 52,
            color: const Color(0x00000000),
            child: Row(
              children: [
                _IconChip(icon: icon, color: color),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: GengaTypography.body)),
                if (value != null) ...[
                  Text(value!, style: GengaTypography.subhead),
                  const SizedBox(width: 8),
                ],
                const AppIcon(
                  AppIcons.chevronRight,
                  size: 12,
                  color: GengaColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
        if (!isLast) const _Divider(),
      ],
    );
  }
}

class _IconSwitchRow extends StatelessWidget {
  final HugeIconData icon;
  final Color color;
  final String label;
  final bool value;
  final bool isLast;
  final ValueChanged<bool> onChanged;
  final bool? expanded;
  final VoidCallback? onExpand;

  const _IconSwitchRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isLast = false,
    this.expanded,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onExpand == null
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          onExpand!();
                        },
                  child: Row(
                    children: [
                      _IconChip(icon: icon, color: color),
                      const SizedBox(width: 14),
                      Text(label, style: GengaTypography.body),
                      if (expanded != null) ...[
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: expanded! ? 0.5 : 0,
                          duration: GengaSprings.medium,
                          curve: GengaSprings.smooth,
                          child: const AppIcon(
                            AppIcons.chevronDown,
                            size: 14,
                            color: GengaColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              CupertinoSwitch(
                value: value,
                activeTrackColor: GengaColors.offWhite,
                thumbColor: value
                    ? GengaColors.onOffWhite
                    : CupertinoColors.white,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  onChanged(v);
                },
              ),
            ],
          ),
        ),
        if (!isLast) const _Divider(),
      ],
    );
  }
}

class _SubSwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? detail;
  final VoidCallback? onDetailTap;

  const _SubSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.detail,
    this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 46,
          child: Row(
            children: [
              const SizedBox(width: 44),
              Expanded(
                child: Text(
                  label,
                  style: GengaTypography.subhead.copyWith(
                    color: GengaColors.textPrimary,
                  ),
                ),
              ),
              if (detail != null)
                Pressable(
                  scale: 0.94,
                  haptic: true,
                  onTap: value ? onDetailTap : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: AnimatedOpacity(
                      duration: GengaSprings.quick,
                      opacity: value ? 1 : 0.35,
                      child: Text(
                        detail!,
                        style: GengaTypography.subhead.copyWith(
                          color: GengaColors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              CupertinoSwitch(
                value: value,
                activeTrackColor: GengaColors.offWhite,
                thumbColor: value
                    ? GengaColors.onOffWhite
                    : CupertinoColors.white,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  onChanged(v);
                },
              ),
            ],
          ),
        ),
        const _Divider(),
      ],
    );
  }
}

class _PreferencesGroup extends ConsumerStatefulWidget {
  const _PreferencesGroup();

  @override
  ConsumerState<_PreferencesGroup> createState() => _PreferencesGroupState();
}

class _PreferencesGroupState extends ConsumerState<_PreferencesGroup>
    with WidgetsBindingObserver {
  bool _systemBlocked = false;
  bool _remindersOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSystem();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.invalidate(contactsAccessProvider);
    _checkSystem();
  }

  Future<void> _checkSystem() async {
    final permitted = await ref.read(notificationServiceProvider).isPermitted();
    if (mounted) setState(() => _systemBlocked = !permitted);
  }

  Future<void> _openSystemSettings() => launchUrl(Uri.parse('app-settings:'));

  Future<void> _toggleNotifications(bool value) async {
    final granted = await ref
        .read(preferencesProvider.notifier)
        .setNotifications(value);
    await _checkSystem();
    if (granted || !mounted) return;
    final open = await showGengaConfirm(
      context,
      title: 'Notifications are off',
      message:
          'iOS is blocking notifications for Genga. Turn them on in '
          'Settings, then come back.',
      confirmLabel: 'Open Settings',
    );
    if (open) await _openSystemSettings();
  }

  Future<void> _pickTime(PreferencesState prefs) async {
    var picked = DateTime(2000, 1, 1, prefs.reminderHour, prefs.reminderMinute);
    final save = await showGengaBottomSheet<bool>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetTitle('Remind me at'),
          SizedBox(
            height: 200,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: picked,
              minuteInterval: 5,
              onDateTimeChanged: (d) => picked = d,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: GengaButton(
              label: 'Save',
              onTap: () => Navigator.of(ctx).pop(true),
            ),
          ),
        ],
      ),
    );
    if (save == true) {
      await ref
          .read(preferencesProvider.notifier)
          .setReminderTime(picked.hour, picked.minute);
    }
  }

  Future<void> _tapContacts(ContactsAccess access) async {
    if (access == ContactsAccess.notAsked) {
      await requestContactsAccess();
      ref.invalidate(contactsAccessProvider);
      return;
    }
    await _openSystemSettings();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);
    final contacts = ref.watch(contactsAccessProvider).valueOrNull;
    final on = prefs.notifications && !_systemBlocked;
    final time = DateFormat.jm().format(
      DateTime(2000, 1, 1, prefs.reminderHour, prefs.reminderMinute),
    );

    return _Group(
      children: [
        _IconRow(
          icon: AppIcons.moneyDollarCircleFill,
          color: const Color(0xFF8E8E93),
          label: 'Currency',
          value: prefs.currency,
          onTap: () => showCurrencySheet(context, ref),
        ),
        _IconSwitchRow(
          icon: AppIcons.bellFill,
          color: const Color(0xFFFF375F),
          label: 'Notifications',
          value: on,
          onChanged: _toggleNotifications,
          expanded: on ? _remindersOpen : null,
          onExpand: on
              ? () => setState(() => _remindersOpen = !_remindersOpen)
              : null,
        ),
        AnimatedSize(
          duration: GengaSprings.medium,
          curve: GengaSprings.smooth,
          alignment: Alignment.topCenter,
          child: on && _remindersOpen
              ? Column(
                  children: [
                    _SubSwitchRow(
                      label: 'Daily reminder',
                      value: prefs.dailyReminder,
                      detail: time,
                      onDetailTap: () => _pickTime(prefs),
                      onChanged: notifier.setDailyReminder,
                    ),
                    _SubSwitchRow(
                      label: 'Sunday summary',
                      value: prefs.weeklyReport,
                      onChanged: notifier.setWeeklyReport,
                    ),
                    _SubSwitchRow(
                      label: 'Recurring bills due',
                      value: prefs.dueAlerts,
                      onChanged: notifier.setDueAlerts,
                    ),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
        if (contacts != null && contacts != ContactsAccess.unsupported)
          _IconRow(
            icon: AppIcons.person2Fill,
            color: const Color(0xFF5AC8FA),
            label: 'Contacts',
            value: switch (contacts) {
              ContactsAccess.allowed => 'Allowed',
              ContactsAccess.denied => 'Off',
              _ => 'Allow',
            },
            onTap: () => _tapContacts(contacts),
          ),
        _IconSwitchRow(
          icon: AppIcons.graphCircleFill,
          color: const Color(0xFF8E8E93),
          label: 'Anonymous analytics',
          value: prefs.analyticsEnabled,
          isLast: true,
          onChanged: (v) async {
            if (v && !await _confirmAnalytics(context)) return;
            await notifier.setAnalyticsEnabled(v);
          },
        ),
      ],
    );
  }
}

class _SpaceBanner extends StatelessWidget {
  final String name;
  final String subtitle;
  final HugeIconData icon;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onSwitch;
  final VoidCallback onNew;
  final VoidCallback? onMembers;

  const _SpaceBanner({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onEdit,
    required this.onSwitch,
    required this.onNew,
    required this.onMembers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.55),
            color.withValues(alpha: 0.16),
            const Color(0xFF111114),
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -22,
              bottom: -30,
              child: AppIcon(
                icon,
                size: 150,
                color: CupertinoColors.white.withValues(alpha: 0.07),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x40FFFFFF),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: AppIcon(
                            icon,
                            size: 26,
                            color: GengaColors.onOffWhite,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GengaTypography.title2,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GengaTypography.footnote,
                            ),
                          ],
                        ),
                      ),
                      if (onMembers != null)
                        _BannerIcon(
                          icon: AppIcons.person2Fill,
                          onTap: onMembers!,
                        ),
                      _BannerIcon(icon: AppIcons.pencil, onTap: onEdit),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _BannerButton(
                          icon: AppIcons.arrowRightArrowLeft,
                          label: 'Switch',
                          onTap: onSwitch,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BannerButton(
                          icon: AppIcons.add,
                          label: 'New space',
                          onTap: onNew,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerIcon extends StatelessWidget {
  final HugeIconData icon;
  final VoidCallback onTap;

  const _BannerIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.88,
      haptic: true,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: AppIcon(icon, size: 19, color: GengaColors.textSecondary),
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  final HugeIconData icon;
  final String label;
  final VoidCallback onTap;

  const _BannerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.94,
      haptic: true,
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0x24FFFFFF),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(icon, size: 16, color: GengaColors.textPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GengaTypography.footnote.copyWith(
                color: GengaColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const String kAppVersion = '1.0.0';
const String kTipUrl = 'https://buymeacoffee.com/';
const Color _coffeeColor = Color(0xFFC8864A);
const String kAppBuild = '1';

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Made with', style: GengaTypography.caption1),
            const SizedBox(width: 5),
            const AppIcon(
              AppIcons.heartFill,
              size: 13,
              color: Color(0xFFFF453A),
            ),
            const SizedBox(width: 5),
            Text('in Rwanda', style: GengaTypography.caption1),
          ],
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/images/app_icon.png',
            width: 68,
            height: 68,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Genga',
          style: GengaTypography.headline.copyWith(
            color: GengaColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Version $kAppVersion ($kAppBuild)',
          style: GengaTypography.footnote,
        ),
      ],
    );
  }
}
