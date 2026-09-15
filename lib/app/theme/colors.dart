import 'dart:ui';

import 'package:flutter/cupertino.dart' show BuildContext;

abstract final class GengaColors {
  static Color dynamicAccent(BuildContext context) => offWhite;

  // ── Backgrounds ──
  static const Color background = Color(0xFF0C0C0E);
  static const Color surface = Color(0xFF161619);
  static const Color surfaceElevated = Color(0xFF1E1E22);

  // ── Accent ──
  static const Color accent = Color(0xFF34C759);
  static const Color accentDim = Color(0x1F34C759);

  // ── Buttons and active pills ──
  static const Color offWhite = Color(0xFFEDEAE4);
  static const Color onOffWhite = Color(0xFF17171A);

  // ── Text ──
  static const Color textPrimary = Color(0xFFE8E6E3);
  static const Color textSecondary = Color(0xFFA1A1A6);
  static const Color textTertiary = Color(0xFF86868B);

  // ── On-card (content drawn over account cards and the wallet pocket) ──
  static const Color onCard = Color(0xFFF6EDE3);
  static const Color onCardStrong = Color(0xFFFFFFFF);
  static const Color onCardMuted = Color(0xB3FFFFFF);
  static const Color onCardFaint = Color(0x80FFFFFF);
  static const Color onCardChip = Color(0x33FFFFFF);
  static const Color onCardChipSoft = Color(0x26FFFFFF);

  // ── Semantic ──
  static const Color expense = Color(0xFFFF453A);
  static const Color income = Color(0xFF30D158);
  static const Color transfer = Color(0xFF5AC8FA);

  // ── Borders ──
  static const Color border = Color(0x0FFFFFFF);
  static const Color borderLight = Color(0x1AFFFFFF);

  // ── System ──
  static const Color destructive = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFF9F0A);

  // ── Category palette ──
  static const List<Color> categoryPalette = [
    Color(0xFF5AC8FA), // blue
    Color(0xFFFF9F0A), // orange
    Color(0xFFFF375F), // pink
    Color(0xFF30D158), // green
    Color(0xFFAF52DE), // purple
    Color(0xFFFF453A), // red
    Color(0xFFFFD60A), // yellow
    Color(0xFF64D2FF), // cyan
    Color(0xFFBF5AF2), // violet
    Color(0xFFAC8E68), // brown
    Color(0xFF34C759), // emerald
    Color(0xFFFF6482), // coral
  ];
}
