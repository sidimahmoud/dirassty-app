import 'package:flutter/widgets.dart';

import '../../theme/dirassty_theme.dart';

/// Per-context access to the design-handoff type styles — Cairo for an
/// Arabic locale, Inter otherwise (same scale either way).
extension DirasstyContext on BuildContext {
  bool get isArabicLocale => Localizations.localeOf(this).languageCode == 'ar';

  DirasstyType get dirasstyType => DirasstyType(isArabicLocale);

  /// True when the OS asks for reduced motion — every animated design
  /// component checks this and skips/shortens its motion.
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;

  /// Two-up grids (stat tiles, subject cards) drop to one column on a
  /// narrow phone (< 360 dp) with large text, so nothing clips
  /// (DESIGN_SPEC §7 "Large text").
  bool get useSingleColumn =>
      MediaQuery.sizeOf(this).width < 360 &&
      MediaQuery.textScalerOf(this).scale(1) > 1.3;
}
