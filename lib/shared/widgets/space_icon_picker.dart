import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/shared/animations/springs.dart';
import 'package:genga/shared/constants/space_constants.dart';
import 'package:genga/shared/icons/app_icon.dart';

class SpaceIconPicker extends StatelessWidget {
  final String type;
  final String selected;
  final ValueChanged<String> onChanged;

  const SpaceIconPicker({
    super.key,
    required this.type,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final icons = spaceIconsFor(type);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final key in icons)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(key);
            },
            child: AnimatedContainer(
              duration: GengaSprings.quick,
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected == key
                    ? kSpaceColor
                    : GengaColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppIcon.key(
                  key,
                  size: 20,
                  color: selected == key
                      ? GengaColors.onOffWhite
                      : GengaColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
