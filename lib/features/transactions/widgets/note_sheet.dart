import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/shared/widgets/genga_bottom_sheet.dart';
import 'package:genga/shared/widgets/pressable.dart';
import 'package:genga/shared/widgets/sheet_parts.dart';

Future<String?> showNoteSheet({
  required BuildContext context,
  required String initial,
}) {
  return showGengaBottomSheet<String>(
    context: context,
    maxHeightFraction: 0.6,
    builder: (ctx) => _NoteSheetContent(initial: initial),
  );
}

class _NoteSheetContent extends StatefulWidget {
  final String initial;

  const _NoteSheetContent({required this.initial});

  @override
  State<_NoteSheetContent> createState() => _NoteSheetContentState();
}

class _NoteSheetContentState extends State<_NoteSheetContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _done() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final accent = GengaColors.dynamicAccent(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetTitle(
            'Note',
            trailing: Pressable(
              onTap: _done,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  'Done',
                  style: GengaTypography.callout.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
            child: CupertinoTextField.borderless(
              controller: _controller,
              autofocus: true,
              placeholder: 'What was this for?',
              placeholderStyle: GengaTypography.title3.copyWith(
                color: GengaColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
              style: GengaTypography.title3.copyWith(
                fontWeight: FontWeight.w400,
              ),
              minLines: 2,
              maxLines: 4,
              maxLength: 140,
              padding: EdgeInsets.zero,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _done(),
            ),
          ),
        ],
      ),
    );
  }
}
