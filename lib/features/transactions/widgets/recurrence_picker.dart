import 'package:flutter/cupertino.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/sheet_parts.dart';

enum Recurrence {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  String get label => switch (this) {
    none => 'Does not repeat',
    daily => 'Daily',
    weekly => 'Weekly',
    monthly => 'Monthly',
    yearly => 'Yearly',
  };

  HugeIconData get icon => switch (this) {
    none => AppIcons.xmark,
    daily => AppIcons.sunMaxFill,
    weekly => AppIcons.calendar,
    monthly => AppIcons.calendarBadgePlus,
    yearly => AppIcons.arrow2Circlepath,
  };
}

Future<Recurrence?> showRecurrencePicker({
  required BuildContext context,
  Recurrence current = Recurrence.none,
}) {
  return showGengaBottomSheet<Recurrence>(
    context: context,
    maxHeightFraction: 0.6,
    builder: (ctx) => _RecurrencePickerContent(current: current),
  );
}

class _RecurrencePickerContent extends StatelessWidget {
  final Recurrence current;

  const _RecurrencePickerContent({required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetTitle('Repeat'),
          for (final r in Recurrence.values)
            SheetOption(
              label: r.label,
              selected: r == current,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop(r);
              },
            ),
        ],
      ),
    );
  }
}
