import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'dirassty_colors.dart';
import 'dirassty_tokens.dart';
import 'dirassty_page_transitions.dart';
import 'dirassty_typography.dart';

export 'dirassty_colors.dart';
export 'dirassty_tokens.dart';
export 'dirassty_typography.dart';

/// Usage: MaterialApp(theme: DirasstyTheme.light(locale), ...)
abstract final class DirasstyTheme {
  static ThemeData light(Locale locale) {
    final type = DirasstyType(locale.languageCode == 'ar');
    final scheme = ColorScheme.fromSeed(
      seedColor: DirasstyColors.teal,
      primary: DirasstyColors.teal,
      onPrimary: Colors.white,
      secondary: DirasstyColors.ink,
      onSecondary: Colors.white,
      tertiary: DirasstyColors.gold,
      onTertiary: DirasstyColors.ink,
      error: DirasstyColors.error,
      surface: DirasstyColors.surface,
      onSurface: DirasstyColors.text,
    );
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: DirasstyRadius.cardR,
          borderSide: BorderSide(color: c, width: 1.5),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: DirasstyColors.background,
      fontFamily: type.family,
      textTheme: type.textTheme,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: DirasstyPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: DirasstyColors.background,
        foregroundColor: DirasstyColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: type.subheading,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DirasstyColors.teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: DirasstyColors.disabledFill,
          disabledForegroundColor: DirasstyColors.textMuted,
          minimumSize: const Size.fromHeight(DirasstySize.button),
          shape: const RoundedRectangleBorder(borderRadius: DirasstyRadius.cardR),
          textStyle: type.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DirasstyColors.teal,
          minimumSize: const Size.fromHeight(DirasstySize.button),
          side: const BorderSide(color: DirasstyColors.teal, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: DirasstyRadius.cardR),
          textStyle: type.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DirasstyColors.teal,
          minimumSize: const Size(DirasstySize.minTouch, DirasstySize.minTouch),
          textStyle: type.subheading.copyWith(fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DirasstyColors.surface,
        contentPadding:
            const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 15),
        border: border(DirasstyColors.line),
        enabledBorder: border(DirasstyColors.line),
        focusedBorder: border(DirasstyColors.teal),
        errorBorder: border(DirasstyColors.error),
        focusedErrorBorder: border(DirasstyColors.error),
        labelStyle: type.label.copyWith(fontSize: 14, color: DirasstyColors.text),
        hintStyle: type.body.copyWith(color: DirasstyColors.textMuted),
        errorStyle: type.label.copyWith(color: DirasstyColors.error),
      ),
      cardTheme: const CardThemeData(
        color: DirasstyColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: DirasstyRadius.cardR,
          side: BorderSide(color: DirasstyColors.line),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(side: BorderSide(color: DirasstyColors.line)),
        backgroundColor: DirasstyColors.surface,
        selectedColor: DirasstyColors.ink,
        labelStyle: type.label
            .copyWith(color: DirasstyColors.text, fontWeight: FontWeight.w700),
        // Selected chips sit on ink (selectedColor) — without these the
        // label and check stay ink too and vanish. Not in the handoff's
        // original file; added here.
        secondaryLabelStyle: type.label
            .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        checkmarkColor: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: DirasstyColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: DirasstyRadius.dialogR),
        titleTextStyle: type.titleSmall,
        contentTextStyle: type.bodySmall,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: DirasstyColors.background,
        shape: RoundedRectangleBorder(borderRadius: DirasstyRadius.sheetR),
        showDragHandle: true,
        dragHandleColor: Color(0xFFD9D5CB),
        dragHandleSize: Size(40, 4),
        modalBarrierColor: DirasstyColors.scrim,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DirasstyColors.ink,
        contentTextStyle: type.bodySmall.copyWith(color: Colors.white),
        actionTextColor: DirasstyColors.mint,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: DirasstyRadius.cardR),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? DirasstyColors.teal
              : const Color(0xFFC9C4B8),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DirasstyColors.teal,
        linearTrackColor: DirasstyColors.track,
      ),
      dividerTheme: const DividerThemeData(
          color: DirasstyColors.track, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DirasstyColors.surface,
        indicatorColor: DirasstyColors.tealTint,
        labelTextStyle: WidgetStatePropertyAll(type.tab),
        height: 64,
      ),
    );
  }
}
