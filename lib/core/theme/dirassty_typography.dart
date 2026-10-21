import 'package:flutter/material.dart';
import 'dirassty_colors.dart';

/// Type scale 11/12/14/16/18/20/24/32 — Inter (Latin) or Cairo (Arabic).
class DirasstyType {
  DirasstyType(this.isArabic);
  final bool isArabic;

  /// Re-fonts any [TextStyle] for Arabic content regardless of the app's
  /// locale — a French-locale screen still needs Cairo for an Arabic
  /// subject name.
  static TextStyle arabicFont(TextStyle? style) => (style ?? const TextStyle())
      .copyWith(fontFamily: 'Cairo', letterSpacing: 0);

  String get family => isArabic ? 'Cairo' : 'Inter';
  double get _lh => isArabic ? 1.5 : 1.4;

  TextStyle _s(
    double size,
    FontWeight w, {
    Color color = DirasstyColors.text,
    double? ls,
  }) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: w,
        height: _lh,
        color: color,
        letterSpacing: isArabic ? 0 : (ls ?? 0),
      );

  TextStyle get display => _s(32, FontWeight.w800, ls: -0.64);
  TextStyle get title => _s(24, FontWeight.w800);
  TextStyle get titleSmall => _s(20, FontWeight.w800);
  TextStyle get heading => _s(18, FontWeight.w700);
  TextStyle get subheading => _s(16, FontWeight.w700);
  TextStyle get body => _s(16, FontWeight.w400);
  TextStyle get bodySmall =>
      _s(14, FontWeight.w400, color: DirasstyColors.textMuted);
  TextStyle get label =>
      _s(12, FontWeight.w600, color: DirasstyColors.textMuted);
  TextStyle get tab => _s(isArabic ? 12 : 11, FontWeight.w600);
  TextStyle get button => _s(16, FontWeight.w700);
  TextStyle get statValue => _s(24, FontWeight.w800);

  /// Maps onto Material's TextTheme so standard widgets pick the brand styles.
  TextTheme get textTheme => TextTheme(
        displaySmall: display,
        headlineSmall: title,
        titleLarge: titleSmall,
        titleMedium: heading,
        titleSmall: subheading,
        bodyLarge: body,
        bodyMedium: _s(14, FontWeight.w400),
        bodySmall: bodySmall,
        labelLarge: button,
        labelMedium: _s(12, FontWeight.w600),
        labelSmall: tab,
      );
}
