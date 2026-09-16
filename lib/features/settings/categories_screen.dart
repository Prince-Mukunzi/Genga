import 'package:genga/shared/animations/entrance_animation.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/cupertino.dart';
import 'package:genga/shared/widgets/genga_sheets.dart';

import 'package:genga/shared/widgets/genga_button.dart';

import 'package:genga/shared/widgets/genga_text_field.dart';

import 'package:genga/shared/widgets/genga_scaffold.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/providers/database_provider.dart';
import 'package:genga/core/services/analytics_service.dart';
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/shared/widgets/category_icon.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/features/settings/edit_category_screen.dart';
import 'package:genga/shared/widgets/pressable.dart';

import 'category_constants.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);

    return GengaScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
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
                    'Categories',
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
              child: cats.when(
                data: (list) => _buildGroupedList(context, ref, list),
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (_, _) =>
                    const Center(child: Text('Failed to load categories')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    WidgetRef ref,
    List<Category> allCats,
  ) {
    final grouped = <String, List<Category>>{};
    for (final cat in allCats) {
      grouped.putIfAbsent(cat.groupName, () => []).add(cat);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final ai = categoryGroupOrder.indexOf(a);
        final bi = categoryGroupOrder.indexOf(b);
        return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
      });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final group in sortedKeys) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              group,
              style: GengaTypography.footnote.copyWith(
                color: GengaColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          EntranceAnimation.stagger(
            index: sortedKeys.indexOf(group).clamp(0, 8),
            slideOffset: 14,
            child: Container(
              decoration: BoxDecoration(
                color: GengaColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < grouped[group]!.length; i++) ...[
                    _CategoryRow(category: grouped[group]![i]),
                    if (i < grouped[group]!.length - 1)
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
          ),
          const SizedBox(height: 16),
        ],
        GengaButton.secondary(
          label: 'Create Category',
          onTap: () => _showCreateCategory(context, ref),
          icon: AppIcons.add,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  void _showCreateCategory(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedGroup = 'Other';
    String selectedType = 'expense';
    int selectedColorIdx = 0;
    int selectedIconIdx = 17; // tag_fill

    showGengaBottomSheet<void>(
      context: context,
      maxHeightFraction: 0.85,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final color =
              GengaColors.categoryPalette[selectedColorIdx %
                  GengaColors.categoryPalette.length];
          final icon = categoryIconOptions[selectedIconIdx];

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Category',
                  style: GengaTypography.headline.copyWith(
                    color: GengaColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                // Preview icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AppIcon.key(icon, color: color, size: 28),
                  ),
                ),
                const SizedBox(height: 16),
                // Name input
                GengaTextField(
                  controller: nameController,
                  placeholder: 'Category name',
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                // Type switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: GengaColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      for (final type in ['expense', 'income'])
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setSheetState(() => selectedType = type),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedType == type
                                    ? GengaColors.surface
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  type == 'expense' ? 'Expense' : 'Income',
                                  style: GengaTypography.subhead.copyWith(
                                    color: selectedType == type
                                        ? GengaColors.textPrimary
                                        : GengaColors.textTertiary,
                                    fontWeight: selectedType == type
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Color palette
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 0; i < 8; i++)
                      GestureDetector(
                        onTap: () => setSheetState(() => selectedColorIdx = i),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: GengaColors.categoryPalette[i],
                            shape: BoxShape.circle,
                            border: selectedColorIdx == i
                                ? Border.all(
                                    color: GengaColors.textPrimary,
                                    width: 2.5,
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Icon grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 0; i < categoryIconOptions.length; i++)
                      GestureDetector(
                        onTap: () => setSheetState(() => selectedIconIdx = i),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selectedIconIdx == i
                                ? color.withValues(alpha: 0.15)
                                : GengaColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: selectedIconIdx == i
                                ? Border.all(color: color, width: 1.5)
                                : null,
                          ),
                          child: Center(
                            child: AppIcon.key(
                              categoryIconOptions[i],
                              size: 18,
                              color: selectedIconIdx == i
                                  ? color
                                  : GengaColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Group picker
                Pressable(
                  onTap: () async {
                    showGengaActionSheet(
                      ctx,
                      title: 'Group',
                      actions: [
                        for (final group in categoryGroupOrder)
                          SheetAction(
                            label: group,
                            selected: selectedGroup == group,
                            onTap: () =>
                                setSheetState(() => selectedGroup = group),
                          ),
                      ],
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: GengaColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Group',
                          style: GengaTypography.body.copyWith(
                            color: GengaColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          selectedGroup,
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
                const SizedBox(height: 16),
                // Create button
                GengaButton(
                  label: 'Create Category',
                  onTap: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    ref
                        .read(databaseProvider)
                        .insertCategory(
                          CategoriesCompanion.insert(
                            name: name,
                            iconKey: icon,
                            color: color.toARGB32(),
                            groupName: Value(selectedGroup),
                            type: Value(selectedType),
                          ),
                        );
                    ref.read(analyticsServiceProvider).trackEvent(
                      'category_created',
                      {'type': selectedType},
                    );
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final Category category;
  const _CategoryRow({required this.category});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => EditCategoryScreen(category: category),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CategoryIcon(
              iconKey: category.iconKey,
              color: Color(category.color),
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                style: GengaTypography.body.copyWith(
                  color: GengaColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
