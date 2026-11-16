import 'package:flutter/cupertino.dart';
import 'package:genga/shared/constants/space_constants.dart';
import 'package:genga/shared/widgets/genga_button.dart';

import 'package:genga/shared/widgets/genga_text_field.dart';

import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/providers/database_provider.dart';
import 'package:genga/core/services/invite_link_service.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/genga_toast.dart';
import 'package:share_plus/share_plus.dart';

Future<void> showJoinSpaceSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Space space,
}) {
  const spaceColor = kSpaceColor;
  final typeLabel = space.type == 'family' ? 'Family' : 'Organization';

  return showGengaBottomSheet<void>(
    context: context,
    maxHeightFraction: 0.75,
    builder: (ctx) => _JoinSpaceContent(
      space: space,
      spaceColor: spaceColor,
      typeLabel: typeLabel,
      ref: ref,
    ),
  );
}

class _JoinSpaceContent extends StatefulWidget {
  final Space space;
  final Color spaceColor;
  final String typeLabel;
  final WidgetRef ref;

  const _JoinSpaceContent({
    required this.space,
    required this.spaceColor,
    required this.typeLabel,
    required this.ref,
  });

  @override
  State<_JoinSpaceContent> createState() => _JoinSpaceContentState();
}

class _JoinSpaceContentState extends State<_JoinSpaceContent> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_isValid || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final db = widget.ref.read(databaseProvider);

    await db.joinSpace(widget.space.id, displayName: name, phone: phone);

    if (!mounted) return;

    final requestLink = InviteLinkService.createJoinRequestLink(
      JoinRequestPayload(
        inviteCode: widget.space.inviteCode,
        spaceName: widget.space.name,
        memberName: name,
        memberPhone: phone,
      ),
    );

    Navigator.of(context).pop();
    HapticFeedback.heavyImpact();
    showGengaToast(context, 'Request sent to ${widget.space.name}');

    await Share.share(
      '$name wants to join ${widget.space.name} on Genga.\n$requestLink',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: widget.spaceColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppIcon(
                  AppIcons.resolve(widget.space.iconKey),
                  size: 28,
                  color: GengaColors.onOffWhite,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.space.name,
              style: GengaTypography.title2.copyWith(
                color: GengaColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: widget.spaceColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.typeLabel,
                style: GengaTypography.caption1.copyWith(
                  color: widget.spaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter your details to request to join this space. The admin will review and approve your request.',
              textAlign: TextAlign.center,
              style: GengaTypography.subhead.copyWith(
                color: GengaColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            GengaTextField(
              controller: _nameController,
              placeholder: 'Your name',
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            GengaTextField(
              controller: _phoneController,
              placeholder: 'Phone number',
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            GengaButton(
              label: 'Request to Join',
              onTap: _isValid && !_isSubmitting ? _submit : null,
              loading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}
