import 'package:flutter/cupertino.dart';
import 'package:genga/shared/constants/space_constants.dart';
import 'package:genga/shared/widgets/genga_button.dart';

import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/services/invite_link_service.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/genga_toast.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

Future<void> showInviteSheet({
  required BuildContext context,
  required Space space,
}) {
  final inviteLink = InviteLinkService.createLink(
    SpaceInvitePayload(
      code: space.inviteCode,
      name: space.name,
      color: space.color,
      iconKey: space.iconKey,
      type: space.type,
    ),
  );
  const spaceColor = kSpaceColor;

  return showGengaBottomSheet<void>(
    context: context,
    maxHeightFraction: 0.65,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Invite to ${space.name}',
            style: GengaTypography.headline.copyWith(
              color: GengaColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share this QR code or link to invite members',
            style: GengaTypography.subhead.copyWith(
              color: GengaColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: QrImageView(
              data: inviteLink,
              version: QrVersions.auto,
              size: 180,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.circle,
                color: spaceColor,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Invite code display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: GengaColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    space.inviteCode,
                    style: GengaTypography.title3.copyWith(
                      color: GengaColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: space.inviteCode));
                      HapticFeedback.lightImpact();
                      showGengaToast(
                        ctx,
                        'Code copied',
                        icon: AppIcons.docOnClipboard,
                      );
                    },
                    child: const AppIcon(
                      AppIcons.docOnClipboard,
                      size: 18,
                      color: GengaColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: GengaButton.secondary(
                  label: 'Copy Link',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: inviteLink));
                    HapticFeedback.lightImpact();
                    showGengaToast(ctx, 'Link copied', icon: AppIcons.link);
                  },
                  icon: AppIcons.link,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GengaButton(
                  label: 'Share',
                  onTap: () {
                    Share.share(
                      'Join my ${space.type == 'family' ? 'family' : 'organization'} space "${space.name}" on Genga!\n\n$inviteLink',
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
