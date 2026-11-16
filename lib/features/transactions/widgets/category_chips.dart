import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:genga/shared/widgets/category_icon.dart';
import 'package:genga/shared/widgets/pressable.dart';

class QuickCategoryChips extends ConsumerWidget {
  final String type;
  final Category? selected;
  final Color tint;
  final ValueChanged<Category?> onSelect;
  final VoidCallback onMore;

  const QuickCategoryChips({
    super.key,
    required this.type,
    required this.selected,
    required this.tint,
    required this.onSelect,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final txns = ref.watch(allTransactionsProvider).valueOrNull ?? const [];

    final usage = <int, int>{};
    for (final t in txns) {
      final id = t.transaction.categoryId;
      if (id != null) usage[id] = (usage[id] ?? 0) + 1;
    }

    final ranked = cats.where((c) => c.type == type).toList()
      ..sort((a, b) => (usage[b.id] ?? 0).compareTo(usage[a.id] ?? 0));
    final shown = ranked.take(8).toList();
    if (selected != null && !shown.any((c) => c.id == selected!.id)) {
      shown.insert(0, selected!);
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final c in shown)
            _CategoryChip(
              category: c,
              active: selected?.id == c.id,
              tint: tint,
              onTap: () => onSelect(selected?.id == c.id ? null : c),
            ),
          Pressable(
            haptic: true,
            onTap: onMore,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: GengaColors.borderLight, width: 0.5),
              ),
              child: Row(
                children: [
                  const AppIcon(
                    AppIcons.ellipsis,
                    size: 16,
                    color: GengaColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text('More', style: GengaTypography.footnote),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final Category category;
  final bool active;
  final Color tint;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.active,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        haptic: true,
        onTap: onTap,
        child: AnimatedContainer(
          duration: GengaSprings.quick,
          curve: GengaSprings.smooth,
          padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: GengaColors.surface,
            border: Border.all(
              color: active
                  ? GengaColors.offWhite.withValues(alpha: 0.4)
                  : GengaColors.border,
              width: active ? 1 : 0.5,
            ),
          ),
          child: Row(
            children: [
              CategoryIcon(
                iconKey: category.iconKey,
                color: Color(category.color),
                size: 32,
              ),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: GengaTypography.footnote.copyWith(
                  color: GengaColors.textPrimary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
