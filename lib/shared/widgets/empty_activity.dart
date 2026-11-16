import 'package:flutter/cupertino.dart';
import 'package:genga/app/theme/colors.dart';
import 'package:genga/app/theme/typography.dart';

class EmptyActivity extends StatelessWidget {
  final String title;
  final String hint;
  final int ghostRows;

  const EmptyActivity({
    super.key,
    this.title = 'Nothing here yet',
    this.hint = 'Tap + to log your first transaction',
    this.ghostRows = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < ghostRows; i++)
          Opacity(opacity: 0.55 - i * 0.17, child: const _GhostRow()),
        const SizedBox(height: 18),
        Text(
          title,
          style: GengaTypography.headline.copyWith(
            color: GengaColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(hint, style: GengaTypography.footnote),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _GhostRow extends StatelessWidget {
  const _GhostRow();

  @override
  Widget build(BuildContext context) {
    const fill = Color(0x14FFFFFF);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 10,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 70,
                  height: 8,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 10,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}
