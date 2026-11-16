import 'package:drift/drift.dart' hide Column;
import 'package:flutter/cupertino.dart';
import 'package:genga/shared/widgets/space_icon_picker.dart';
import 'package:genga/shared/widgets/genga_button.dart';

import 'package:genga/shared/widgets/genga_text_field.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/providers/database_provider.dart';
import 'package:genga/core/services/analytics_service.dart';
import 'package:genga/shared/constants/space_constants.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';

Future<void> showCreateSpaceSheet(BuildContext context, WidgetRef ref) {
  return _show(context, ref);
}

Future<void> _show(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController();
  var selectedIcon = defaultSpaceIcon('personal');
  String selectedType = 'personal';

  final typeOptions = [
    ('personal', 'Personal', AppIcons.personFill),
    ('family', 'Family', AppIcons.houseFill),
    ('organization', 'Organization', AppIcons.building2Fill),
  ];

  return showGengaBottomSheet<void>(
    context: context,
    maxHeightFraction: 0.7,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        const color = kSpaceColor;
        final icon = selectedIcon;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'New Space',
                style: GengaTypography.headline.copyWith(
                  color: GengaColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              // Type picker
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: GengaColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    for (final (type, label, _) in typeOptions)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() {
                            selectedType = type;
                            selectedIcon = defaultSpaceIcon(type);
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == type
                                  ? GengaColors.offWhite
                                  : const Color(0x00000000),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: GengaTypography.caption1.copyWith(
                                  color: selectedType == type
                                      ? GengaColors.onOffWhite
                                      : GengaColors.textSecondary,
                                  fontWeight: selectedType == type
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
                placeholder: selectedType == 'family'
                    ? 'e.g. The Smiths'
                    : selectedType == 'organization'
                    ? 'e.g. My Business'
                    : 'Space name',
                autofocus: true,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SpaceIconPicker(
                type: selectedType,
                selected: selectedIcon,
                onChanged: (k) => setSheetState(() => selectedIcon = k),
              ),
              const SizedBox(height: 20),
              GengaButton(
                label: 'Create Space',
                onTap: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final db = ref.read(databaseProvider);
                  final isShared = selectedType != 'personal';
                  final inviteCode = isShared
                      ? AppDatabase.generateInviteCode()
                      : '';
                  final spaceId = await db.insertSpace(
                    SpacesCompanion.insert(
                      name: name,
                      color: color.toARGB32(),
                      iconKey: icon,
                      type: Value(selectedType),
                      inviteCode: Value(inviteCode),
                    ),
                  );
                  await db.insertSpaceMember(
                    SpaceMembersCompanion.insert(
                      spaceId: spaceId,
                      displayName: await db.currentUserName(),
                      role: const Value('admin'),
                      isCurrentUser: const Value(true),
                    ),
                  );
                  ref.read(analyticsServiceProvider).trackEvent(
                    'space_created',
                    {'type': selectedType},
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}
