import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/core/database/database.dart';
import 'package:genga/core/providers/transactions_provider.dart';
import 'package:genga/shared/widgets/amount_text.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/sheet_parts.dart';

Future<Account?> showAccountPicker({
  required BuildContext context,
  int? selectedId,
  int? excludeId,
  String title = 'Account',
}) {
  return showGengaBottomSheet<Account>(
    context: context,
    maxHeightFraction: 0.5,
    builder: (ctx) => _AccountPickerContent(
      selectedId: selectedId,
      excludeId: excludeId,
      title: title,
    ),
  );
}

class _AccountPickerContent extends ConsumerWidget {
  final int? selectedId;
  final int? excludeId;
  final String title;

  const _AccountPickerContent({
    this.selectedId,
    this.excludeId,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetTitle(title),
          accounts.when(
            data: (list) {
              final filtered = excludeId != null
                  ? list.where((a) => a.id != excludeId).toList()
                  : list;

              return Column(
                children: [
                  for (final a in filtered)
                    SheetOption(
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(a.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      label: a.name,
                      detail: AmountText.format(
                        ref.watch(accountBalanceProvider(a.id)),
                      ),
                      selected: a.id == selectedId,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop(a);
                      },
                    ),
                ],
              );
            },
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
