import 'package:flutter/material.dart';

/// Dirassty brand and UI colors. Use only these in widgets.
abstract final class DirasstyColors {
  // Brand
  static const teal = Color(0xFF0E6B5C);
  static const tealDark = Color(0xFF0A5247);
  static const tealTint = Color(0xFFE3F0ED);
  static const ink = Color(0xFF10231F);
  static const gold = Color(0xFFF5B83D);
  static const goldStroke = Color(0xFFC98A12);
  static const goldTint = Color(0xFFFDF1D8);
  static const ivory = Color(0xFFF7F5EF);
  static const mint = Color(0xFF9FD3C7);

  // Surfaces & lines
  static const background = Color(0xFFFCFBF8);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFECE8DF);
  static const track = Color(0xFFF1EEE6);
  static const inactiveBar = Color(0xFFE3E0D7);
  static const neutralAvatar = Color(0xFFEDEEEC);
  static const disabledFill = Color(0xFFE4E7E5);
  static const skeleton = Color(0xFFEFECE4);
  static const skeletonLight = Color(0xFFF4F2EC);

  /// Idle outline — a not-started lesson ring, an off switch track.
  static const idle = Color(0xFFC9C4B8);

  // Text
  static const text = ink;
  static const textMuted = Color(0xFF5B6663); // 5.9:1 on background
  static const textOnDarkMuted = Color(0xFFC7D2CF);

  // Feedback
  static const error = Color(0xFFB3261E);
  static const errorDark = Color(0xFF8C1D18);
  static const errorTint = Color(0xFFFBEAE8);

  static const scrim = Color(0x7310231F); // ink @ 45 %
}
