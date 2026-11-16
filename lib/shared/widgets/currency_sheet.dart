import 'package:flutter/cupertino.dart';
import 'package:genga/shared/widgets/genga_text_field.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/core/providers/preferences_provider.dart';
import 'package:genga/core/services/currency_service.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/sheet_parts.dart';

void showCurrencySheet(BuildContext context, WidgetRef ref) {
  showGengaBottomSheet<void>(
    context: context,
    maxHeightFraction: 0.75,
    builder: (ctx) => const _CurrencySheet(),
  );
}

class _CurrencySheet extends ConsumerStatefulWidget {
  const _CurrencySheet();

  @override
  ConsumerState<_CurrencySheet> createState() => _CurrencySheetState();
}

class _CurrencySheetState extends ConsumerState<_CurrencySheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final rates = ref.watch(currencyRatesProvider).valueOrNull ?? [];
    final current = ref.watch(preferencesProvider).currency;
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? rates
        : rates
              .where(
                (r) =>
                    r.code.toLowerCase().contains(q) ||
                    r.name.toLowerCase().contains(q),
              )
              .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetTitle('Display currency'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: GengaTextField(
              icon: AppIcons.search,
              placeholder: 'Search currencies',
              clearable: true,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                for (final r in shown)
                  SheetOption(
                    leading: Text(r.flag, style: const TextStyle(fontSize: 20)),
                    label: r.code,
                    detail: r.name,
                    selected: r.code == current,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(preferencesProvider.notifier)
                          .setCurrency(r.code, r.rateFromRwf);
                      Navigator.of(context).pop();
                    },
                  ),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text('No matches', style: GengaTypography.subhead),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
