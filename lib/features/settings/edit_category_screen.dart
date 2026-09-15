import 'package:drift/drift.dart' hide Column;
import 'package:flutter/cupertino.dart';
import 'package:genga/shared/widgets/genga_sheets.dart';

import 'package:genga/shared/widgets/genga_text_field.dart';

import 'package:genga/shared/widgets/genga_scaffold.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/providers/database_provider.dart';
import 'package:genga/shared/widgets/genga_toast.dart';
import 'package:genga/shared/widgets/pressable.dart';

import 'category_constants.dart';

class EditCategoryScreen extends ConsumerStatefulWidget {
  final Category category;

  const EditCategoryScreen({super.key, required this.category});

  @override
  ConsumerState<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends ConsumerState<EditCategoryScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _budgetController;
  late int _selectedColorIdx;
  late int _selectedIconIdx;
  late String _selectedGroup;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _budgetController = TextEditingController(
      text: widget.category.budgetLimit != null
          ? widget.category.budgetLimit!.toStringAsFixed(0)
          : '',
    );
    _selectedGroup = widget.category.groupName;
    _selectedType = widget.category.type;

    _selectedColorIdx = GengaColors.categoryPalette.indexWhere(
      (c) => c.toARGB32() == widget.category.color,
    );
    if (_selectedColorIdx < 0) _selectedColorIdx = 0;

    _selectedIconIdx = categoryIconOptions.indexWhere(
      (ic) => ic == widget.category.iconKey,
    );
    if (_selectedIconIdx < 0) _selectedIconIdx = categoryIconOptions.length - 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        GengaColors.categoryPalette[_selectedColorIdx %
            GengaColors.categoryPalette.length];
    final icon = categoryIconOptions[_selectedIconIdx];

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
                          AppIcons.back,
                          color: GengaColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Edit Category',
                    style: GengaTypography.headline.copyWith(
                      color: GengaColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Pressable(
                    scale: 0.9,
                    onTap: _save,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: GengaColors.surface,
                      ),
                      child: Center(
                        child: AppIcon(
                          AppIcons.checkmark,
                          color: GengaColors.dynamicAccent(context),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),
                  // Preview avatar
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: AppIcon.key(icon, color: color, size: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Name
                  GengaTextField(
                    controller: _nameController,
                    placeholder: 'Category name',
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  // Type switcher
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: GengaColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        for (final type in ['expense', 'income'])
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedType = type),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedType == type
                                      ? GengaColors.surfaceElevated
                                      : null,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    type == 'expense' ? 'Expense' : 'Income',
                                    style: GengaTypography.subhead.copyWith(
                                      color: _selectedType == type
                                          ? GengaColors.textPrimary
                                          : GengaColors.textTertiary,
                                      fontWeight: _selectedType == type
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
                  const SizedBox(height: 16),
                  // Color palette
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < 8; i++)
                        GestureDetector(
                          onTap: () => setState(() => _selectedColorIdx = i),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: GengaColors.categoryPalette[i],
                              shape: BoxShape.circle,
                              border: _selectedColorIdx == i
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
                  const SizedBox(height: 16),
                  // Icon grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < categoryIconOptions.length; i++)
                        GestureDetector(
                          onTap: () => setState(() => _selectedIconIdx = i),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _selectedIconIdx == i
                                  ? color.withValues(alpha: 0.15)
                                  : GengaColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: _selectedIconIdx == i
                                  ? Border.all(color: color, width: 1.5)
                                  : null,
                            ),
                            child: Center(
                              child: AppIcon.key(
                                categoryIconOptions[i],
                                size: 18,
                                color: _selectedIconIdx == i
                                    ? color
                                    : GengaColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Group picker
                  Pressable(
                    onTap: _pickGroup,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: GengaColors.surface,
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
                            _selectedGroup,
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
                  if (_selectedType == 'expense') ...[
                    const SizedBox(height: 16),
                    GengaTextField(
                      controller: _budgetController,
                      placeholder: 'Monthly budget limit (optional)',
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                      prefixText: 'RWF',
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Delete
                  if (!widget.category.isDefault)
                    Pressable(
                      onTap: _confirmDelete,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: GengaColors.destructive.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            'Delete Category',
                            style: GengaTypography.callout.copyWith(
                              color: GengaColors.destructive,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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

  void _pickGroup() {
    showGengaActionSheet(
      context,
      title: 'Group',
      actions: [
        for (final group in categoryGroupOrder)
          SheetAction(
            label: group,
            selected: _selectedGroup == group,
            onTap: () => setState(() => _selectedGroup = group),
          ),
      ],
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final color =
        GengaColors.categoryPalette[_selectedColorIdx %
            GengaColors.categoryPalette.length];
    final icon = categoryIconOptions[_selectedIconIdx];
    final budgetText = _budgetController.text.trim();
    final budgetLimit = budgetText.isNotEmpty
        ? double.tryParse(budgetText)
        : null;

    final updated = widget.category.copyWith(
      name: name,
      iconKey: icon,
      color: color.toARGB32(),
      groupName: _selectedGroup,
      type: _selectedType,
      budgetLimit: Value(budgetLimit),
    );

    ref.read(databaseProvider).updateCategory(updated);
    HapticFeedback.mediumImpact();
    showGengaToast(context, 'Category saved', icon: AppIcons.checkmarkCircle);
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final result = await showGengaConfirm(
      context,
      title: 'Delete category',
      message: 'Transactions using this category will become uncategorized.',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (result && mounted) {
      ref.read(databaseProvider).deleteCategory(widget.category.id);
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
    }
  }
}
