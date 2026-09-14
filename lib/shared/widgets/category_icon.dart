import 'package:flutter/widgets.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';

class CategoryIcon extends StatelessWidget {
  final String iconKey;
  final Color color;
  final double size;

  const CategoryIcon({
    super.key,
    required this.iconKey,
    required this.color,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: AppIcon(
          AppIcons.resolve(iconKey),
          color: color,
          size: size * 0.5,
        ),
      ),
    );
  }
}
