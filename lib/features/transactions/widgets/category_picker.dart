import 'package:flutter/cupertino.dart';
import 'package:genga/features/settings/category_constants.dart';
import 'package:genga/shared/widgets/genga_text_field.dart';

import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/shared/widgets/category_icon.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/pressable.dart';

Future<Category?> showCategoryPicker({
  required BuildContext context,
  int? selectedId,
  String? transactionType,
}) {
  return showGengaBottomSheet<Category>(
    context: context,
    builder: (ctx) => _CategoryPickerContent(
      selectedId: selectedId,
      transactionType: transactionType,
    ),
  );
}

class _CategoryPickerContent extends ConsumerStatefulWidget {
  final int? selectedId;
  final String? transactionType;

  const _CategoryPickerContent({this.selectedId, this.transactionType});

  @override
  ConsumerState<_CategoryPickerContent> createState() =>
      _CategoryPickerContentState();
}

class _CategoryPickerContentState
    extends ConsumerState<_CategoryPickerContent> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              const Spacer(),
              Text(
                'Category',
                style: GengaTypography.headline.copyWith(
                  color: GengaColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: GengaTextField(
            icon: AppIcons.search,
            placeholder: 'Search',
            clearable: true,
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Flexible(
          child: cats.when(
            data: (list) => _buildGroupedList(list),
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (_, _) =>
                const Center(child: Text('Failed to load categories')),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedList(List<Category> allCats) {
    var baseList = allCats;
    if (widget.transactionType != null) {
      baseList = allCats
          .where((c) => c.type == widget.transactionType)
          .toList();
    }
    final filtered = _search.isEmpty
        ? baseList
        : baseList
              .where(
                (c) => c.name.toLowerCase().contains(_search.toLowerCase()),
              )
              .toList();

    final grouped = <String, List<Category>>{};
    for (final cat in filtered) {
      grouped.putIfAbsent(cat.groupName, () => []).add(cat);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final ai = categoryGroupOrder.indexOf(a);
        final bi = categoryGroupOrder.indexOf(b);
        return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      shrinkWrap: true,
      children: [
        for (final group in sortedKeys) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text(
              group,
              style: GengaTypography.footnote.copyWith(
                color: GengaColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: GengaColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                for (var i = 0; i < grouped[group]!.length; i++) ...[
                  _CategoryRow(
                    category: grouped[group]![i],
                    isSelected: grouped[group]![i].id == widget.selectedId,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop(grouped[group]![i]);
                    },
                  ),
                  if (i < grouped[group]!.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: Container(height: 0.5, color: GengaColors.border),
                    ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      onTap: onTap,
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
            if (isSelected)
              AppIcon(
                AppIcons.checkmarkAlt,
                color: GengaColors.dynamicAccent(context),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
