import 'package:flutter/cupertino.dart';
import 'package:genga/shared/constants/space_constants.dart';
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
import 'package:genga/core/providers/space_provider.dart';
import 'package:genga/shared/widgets/genga_toast.dart';
import 'package:genga/shared/widgets/pressable.dart';

import 'invite_sheet.dart';

class SpaceSettingsScreen extends ConsumerStatefulWidget {
  final Space space;
  const SpaceSettingsScreen({super.key, required this.space});

  @override
  ConsumerState<SpaceSettingsScreen> createState() =>
      _SpaceSettingsScreenState();
}

class _SpaceSettingsScreenState extends ConsumerState<SpaceSettingsScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.space.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members =
        ref.watch(spaceMembersProvider(widget.space.id)).valueOrNull ?? [];
    final currentMember = members.where((m) => m.isCurrentUser).firstOrNull;
    final isAdmin = currentMember?.role == 'admin';
    const spaceColor = kSpaceColor;
    final typeLabel = widget.space.type == 'family' ? 'Family' : 'Organization';
    final pendingMembers =
        ref.watch(pendingMembersProvider(widget.space.id)).valueOrNull ?? [];
    final activeMembers = members.where((m) => m.status == 'active').toList();
    final allSpaces = ref.watch(spacesProvider).valueOrNull ?? [];
    final canDeleteSpace = allSpaces.length > 1;

    return GengaScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  Pressable(
                    scale: 0.9,
                    onTap: () => context.pop(),
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
                    'Space Settings',
                    style: GengaTypography.headline.copyWith(
                      color: GengaColors.textPrimary,
                      fontWeight: FontWeight.w700,
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
                  // Space icon + name
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: spaceColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: AppIcon(
                          AppIcons.resolve(widget.space.iconKey),
                          size: 32,
                          color: GengaColors.onOffWhite,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: spaceColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        typeLabel,
                        style: GengaTypography.caption1.copyWith(
                          color: spaceColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name field (admin only)
                  if (isAdmin) ...[
                    GengaTextField(
                      controller: _nameController,
                      placeholder: 'Space name',
                      textAlign: TextAlign.center,
                      onEditingComplete: _saveName,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Invite button (admin only)
                  if (isAdmin) ...[
                    GengaButton(
                      label: 'Invite Members',
                      onTap: () => showInviteSheet(
                        context: context,
                        space: widget.space,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Pending members section
                  if (isAdmin && pendingMembers.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          'Pending Requests',
                          style: GengaTypography.title3.copyWith(
                            color: GengaColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemOrange.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${pendingMembers.length}',
                            style: GengaTypography.caption1.copyWith(
                              color: CupertinoColors.systemOrange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: GengaColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < pendingMembers.length; i++) ...[
                            _PendingMemberRow(
                              member: pendingMembers[i],
                              spaceColor: spaceColor,
                              onApprove: () =>
                                  _approveMember(pendingMembers[i]),
                              onReject: () => _rejectMember(pendingMembers[i]),
                            ),
                            if (i < pendingMembers.length - 1)
                              Padding(
                                padding: const EdgeInsets.only(left: 56),
                                child: Container(
                                  height: 0.5,
                                  color: GengaColors.textPrimary.withValues(
                                    alpha: 0.06,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Members section
                  Row(
                    children: [
                      Text(
                        'Members',
                        style: GengaTypography.title3.copyWith(
                          color: GengaColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${activeMembers.length}',
                        style: GengaTypography.callout.copyWith(
                          color: GengaColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: GengaColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < activeMembers.length; i++) ...[
                          _MemberRow(
                            member: activeMembers[i],
                            spaceColor: spaceColor,
                            isAdmin: isAdmin,
                            onRoleChange:
                                isAdmin && !activeMembers[i].isCurrentUser
                                ? () => _changeRole(activeMembers[i])
                                : null,
                            onRemove: isAdmin && !activeMembers[i].isCurrentUser
                                ? () => _removeMember(activeMembers[i])
                                : null,
                          ),
                          if (i < activeMembers.length - 1)
                            Padding(
                              padding: const EdgeInsets.only(left: 56),
                              child: Container(
                                height: 0.5,
                                color: GengaColors.textPrimary.withValues(
                                  alpha: 0.06,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),

                  // Danger zone (admin only)
                  if (isAdmin) ...[
                    const SizedBox(height: 32),
                    GengaButton.danger(
                      label: 'Delete Space Data',
                      onTap: _deleteSpaceData,
                    ),
                    if (canDeleteSpace) ...[
                      const SizedBox(height: 12),
                      GengaButton.danger(
                        label: 'Delete Space',
                        onTap: _deleteSpace,
                      ),
                    ],
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || name == widget.space.name) return;
    final db = ref.read(databaseProvider);
    await db.updateSpace(widget.space.copyWith(name: name));
  }

  void _changeRole(SpaceMember member) {
    final roles = ['admin', 'member', 'viewer'];

    showGengaActionSheet(
      context,
      title: 'Role for ${member.displayName}',
      actions: [
        for (final role in roles)
          SheetAction(
            label: role[0].toUpperCase() + role.substring(1),
            selected: role == member.role,
            onTap: () async {
              if (role == member.role) return;
              final db = ref.read(databaseProvider);
              await db.updateSpaceMember(member.copyWith(role: role));
            },
          ),
      ],
    );
  }

  Future<void> _removeMember(SpaceMember member) async {
    final ok = await showGengaConfirm(
      context,
      title: 'Remove member',
      message: 'Remove ${member.displayName} from this space?',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(databaseProvider).deleteSpaceMember(member.id);
  }

  Future<void> _approveMember(SpaceMember member) async {
    final db = ref.read(databaseProvider);
    await db.approveMember(member.id);
    if (mounted) {
      HapticFeedback.heavyImpact();
      showGengaToast(context, '${member.displayName} approved');
    }
  }

  Future<void> _rejectMember(SpaceMember member) async {
    final ok = await showGengaConfirm(
      context,
      title: 'Reject request',
      message: 'Reject ${member.displayName}\'s request to join?',
      confirmLabel: 'Reject',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(databaseProvider).rejectMember(member.id);
    if (mounted) showGengaToast(context, 'Request rejected');
  }

  Future<void> _deleteSpaceData() async {
    final ok = await showGengaConfirm(
      context,
      title: 'Delete space data',
      message: 'This will permanently delete all transactions in this space. The space itself will remain. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref
        .read(databaseProvider)
        .deleteTransactionsForSpace(widget.space.id);
    if (mounted) {
      HapticFeedback.mediumImpact();
      showGengaToast(context, 'Space data deleted');
    }
  }

  Future<void> _deleteSpace() async {
    final ok = await showGengaConfirm(
      context,
      title: 'Delete space',
      message: 'This will permanently delete this space and all its data. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(databaseProvider).deleteSpace(widget.space.id);
    if (mounted) {
      showGengaToast(context, 'Space deleted');
      context.pop();
    }
  }
}

class _MemberRow extends StatelessWidget {
  final SpaceMember member;
  final Color spaceColor;
  final bool isAdmin;
  final VoidCallback? onRoleChange;
  final VoidCallback? onRemove;

  const _MemberRow({
    required this.member,
    required this.spaceColor,
    required this.isAdmin,
    this.onRoleChange,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final initial = member.displayName.isNotEmpty
        ? member.displayName[0].toUpperCase()
        : '?';
    final roleLabel = member.role[0].toUpperCase() + member.role.substring(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: spaceColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: GengaTypography.callout.copyWith(
                  color: spaceColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.displayName,
                        style: GengaTypography.body.copyWith(
                          color: GengaColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (member.isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(You)',
                        style: GengaTypography.caption1.copyWith(
                          color: GengaColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (member.phone.isNotEmpty)
                  Text(
                    member.phone,
                    style: GengaTypography.caption1.copyWith(
                      color: GengaColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          Pressable(
            onTap: onRoleChange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: member.role == 'admin'
                    ? spaceColor.withValues(alpha: 0.15)
                    : GengaColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                roleLabel,
                style: GengaTypography.caption1.copyWith(
                  color: member.role == 'admin'
                      ? spaceColor
                      : GengaColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: const AppIcon(
                AppIcons.xmarkCircle,
                size: 18,
                color: GengaColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PendingMemberRow extends StatelessWidget {
  final SpaceMember member;
  final Color spaceColor;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingMemberRow({
    required this.member,
    required this.spaceColor,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final initial = member.displayName.isNotEmpty
        ? member.displayName[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CupertinoColors.systemOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: GengaTypography.callout.copyWith(
                  color: CupertinoColors.systemOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: GengaTypography.body.copyWith(
                    color: GengaColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (member.phone.isNotEmpty)
                  Text(
                    member.phone,
                    style: GengaTypography.caption1.copyWith(
                      color: GengaColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          Pressable(
            haptic: true,
            onTap: onApprove,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: GengaColors.offWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Approve',
                style: GengaTypography.caption1.copyWith(
                  color: GengaColors.onOffWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onReject,
            child: const AppIcon(
              AppIcons.xmarkCircle,
              size: 20,
              color: GengaColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
