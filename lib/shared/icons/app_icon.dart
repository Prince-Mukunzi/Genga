import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

import 'app_icons.dart';

class AppIcon extends StatelessWidget {
  final HugeIconData icon;
  final double? size;
  final Color? color;

  const AppIcon(this.icon, {super.key, this.size, this.color});

  factory AppIcon.key(String iconKey, {Key? key, double? size, Color? color}) =>
      AppIcon(AppIcons.resolve(iconKey), key: key, size: size, color: color);

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    return HugeIcon(
      icon: icon,
      size: size ?? theme.size ?? 24,
      color: color ?? theme.color,
    );
  }
}
