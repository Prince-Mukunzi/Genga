import 'package:flutter/cupertino.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';
import 'package:genga/shared/widgets/pressable.dart';

class GengaTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String placeholder;
  final HugeIconData? icon;
  final String? prefixText;
  final bool autofocus;
  final bool clearable;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;

  const GengaTextField({
    super.key,
    this.controller,
    this.focusNode,
    required this.placeholder,
    this.icon,
    this.prefixText,
    this.autofocus = false,
    this.clearable = false,
    this.textAlign = TextAlign.start,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
  });

  @override
  State<GengaTextField> createState() => _GengaTextFieldState();
}

class _GengaTextFieldState extends State<GengaTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  late final bool _ownsController;
  late final bool _ownsFocus;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ownsFocus = widget.focusNode == null;
    _controller = widget.controller ?? TextEditingController();
    _focus = widget.focusNode ?? FocusNode();
    _focus.addListener(_refresh);
    _controller.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_refresh);
    _controller.removeListener(_refresh);
    if (_ownsFocus) _focus.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final showClear = widget.clearable && _controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: GengaSprings.quick,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: GengaColors.surfaceElevated,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: focused
              ? GengaColors.offWhite.withValues(alpha: 0.4)
              : GengaColors.borderLight,
          width: focused ? 1 : 0.5,
        ),
      ),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            AppIcon(widget.icon!, size: 18, color: GengaColors.textTertiary),
            const SizedBox(width: 12),
          ],
          if (widget.prefixText != null) ...[
            Text(
              widget.prefixText!,
              style: GengaTypography.body.copyWith(
                color: GengaColors.textTertiary,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: CupertinoTextField.borderless(
              controller: _controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              placeholder: widget.placeholder,
              placeholderStyle: GengaTypography.body.copyWith(
                color: GengaColors.textTertiary,
              ),
              style: GengaTypography.body.copyWith(
                color: GengaColors.textPrimary,
              ),
              textAlign: widget.textAlign,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              padding: EdgeInsets.zero,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              onEditingComplete: widget.onEditingComplete,
            ),
          ),
          if (showClear)
            Pressable(
              scale: 0.85,
              onTap: () {
                _controller.clear();
                widget.onChanged?.call('');
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: AppIcon(
                  AppIcons.xmarkCircle,
                  size: 18,
                  color: GengaColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
