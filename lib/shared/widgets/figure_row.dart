import 'package:flutter/cupertino.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';
import 'package:genga/shared/icons/app_icon.dart';
import 'package:genga/shared/icons/app_icons.dart';

class Figure extends StatelessWidget {
  final HugeIconData icon;
  final Color color;
  final String label;
  final String value;

  const Figure({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(label, style: GengaTypography.caption1),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: GengaTypography.amountSmall.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class FigureRule extends StatelessWidget {
  const FigureRule({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: 44, color: GengaColors.borderLight);
}
