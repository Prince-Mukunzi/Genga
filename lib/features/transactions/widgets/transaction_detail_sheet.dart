import 'package:flutter/cupertino.dart';
import 'package:genga/shared/widgets/genga_sheets.dart';

import 'package:genga/shared/widgets/genga_button.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/models/enums.dart';
import 'package:genga/core/models/transaction_with_category.dart';
import 'package:genga/core/providers/database_provider.dart';
import 'package:genga/core/providers/space_provider.dart';
import 'package:genga/features/transactions/add_transaction_screen.dart';
import 'package:genga/shared/widgets/amount_text.dart';
import 'package:genga/shared/widgets/category_icon.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/pressable.dart';

void showTransactionDetail({
  required BuildContext context,
  required TransactionWithCategory data,
}) {
  showGengaBottomSheet<void>(
    context: context,
    maxHeightFraction: 0.7,
    builder: (ctx) => _DetailContent(data: data),
  );
}

class _DetailContent extends ConsumerWidget {
  final TransactionWithCategory data;

  const _DetailContent({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txn = data.transaction;
    final cat = data.category;
    final account = data.account;
    final isTransfer = txn.type == TransactionType.transfer;
    final isRecurring = txn.recurrence != 'none' && txn.recurrence.isNotEmpty;
    final canDelete =
        !ref.watch(isSharedSpaceProvider) || ref.watch(isSpaceAdminProvider);
    final accent = switch (txn.type) {
      TransactionType.expense => GengaColors.expense,
      TransactionType.income => GengaColors.income,
      TransactionType.transfer => GengaColors.transfer,
    };
    final title = cat?.name ?? txn.type.label;
    final where = isTransfer
        ? '${account?.name ?? '?'} to ${data.toAccount?.name ?? '?'}'
        : account?.name;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (cat != null)
                CategoryIcon(
                  iconKey: cat.iconKey,
                  color: Color(cat.color),
                  size: 44,
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AppIcon(
                      AppIcons.arrowRightArrowLeft,
                      color: accent,
                      size: 20,
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GengaTypography.headline,
                    ),
                    Text(
                      DateFormat('EEEE, MMM d, y').format(txn.date),
                      style: GengaTypography.footnote,
                    ),
                  ],
                ),
              ),
              if (canDelete)
                Pressable(
                  scale: 0.9,
                  haptic: true,
                  onTap: () => _confirmDelete(context, ref),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: GengaColors.surfaceElevated,
                    ),
                    child: const Center(
                      child: AppIcon(
                        AppIcons.trash,
                        size: 18,
                        color: GengaColors.destructive,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AmountText(
                amount: txn.amount + txn.momoFee,
                type: txn.type,
                showSign: true,
                style: GengaTypography.amountLarge.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (txn.momoFee > 0) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Includes RWF ${txn.momoFee.toStringAsFixed(0)} MoMo fee',
                style: GengaTypography.footnote,
              ),
            ),
          ],
          const SizedBox(height: 22),
          Container(height: 0.5, color: GengaColors.borderLight),
          if (where != null)
            _Line(
              icon: AppIcons.building2Fill,
              label: isTransfer ? 'Transfer' : 'Account',
              value: where,
            ),
          if (isRecurring)
            _Line(
              icon: AppIcons.arrow2Circlepath,
              label: 'Repeats',
              value:
                  txn.recurrence[0].toUpperCase() + txn.recurrence.substring(1),
            ),
          if (txn.note.isNotEmpty)
            _Line(icon: AppIcons.pencil, label: 'Note', value: txn.note),
          if (ref.watch(isSharedSpaceProvider) && txn.createdBy.isNotEmpty)
            _Line(
              icon: AppIcons.personFill,
              label: 'Added by',
              value: txn.createdBy,
            ),
          if (ref.watch(isSharedSpaceProvider) && txn.updatedBy.isNotEmpty)
            _Line(
              icon: AppIcons.pencil,
              label: 'Edited by',
              value: txn.updatedBy,
            ),
          const SizedBox(height: 18),
          GengaButton(
            label: 'Edit',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                CupertinoPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => AddTransactionScreen(editing: data),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showGengaConfirm(
      context,
      title: 'Delete transaction',
      message: 'This can\'t be undone. The amount will be reversed on the account it affected.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    HapticFeedback.mediumImpact();
    ref.read(databaseProvider).deleteTransaction(data.transaction.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _Line extends StatelessWidget {
  final HugeIconData icon;
  final String label;
  final String value;

  const _Line({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: GengaColors.border, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, size: 16, color: GengaColors.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: GengaTypography.subhead),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GengaTypography.body,
            ),
          ),
        ],
      ),
    );
  }
}
