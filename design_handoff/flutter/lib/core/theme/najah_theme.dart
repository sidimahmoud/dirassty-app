import 'package:flutter/material.dart';
import 'najah_colors.dart';
import 'najah_tokens.dart';
import 'najah_typography.dart';

export 'najah_colors.dart';
export 'najah_tokens.dart';
export 'najah_typography.dart';

/// Usage: MaterialApp(theme: NajahTheme.light(locale), ...)
abstract final class NajahTheme {
  static ThemeData light(Locale locale) {
    final type = NajahType(locale.languageCode == 'ar');
    final scheme = ColorScheme.fromSeed(
      seedColor: NajahColors.teal,
      primary: NajahColors.teal,
      onPrimary: Colors.white,
      secondary: NajahColors.ink,
      onSecondary: Colors.white,
      tertiary: NajahColors.gold,
      onTertiary: NajahColors.ink,
      error: NajahColors.error,
      surface: NajahColors.surface,
      onSurface: NajahColors.text,
    );
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: NajahRadius.cardR,
          borderSide: BorderSide(color: c, width: 1.5),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: NajahColors.background,
      fontFamily: type.family,
      textTheme: type.textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: NajahColors.background,
        foregroundColor: NajahColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: type.subheading,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: NajahColors.teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: NajahColors.disabledFill,
          disabledForegroundColor: NajahColors.textMuted,
          minimumSize: const Size.fromHeight(NajahSize.button),
          shape: const RoundedRectangleBorder(borderRadius: NajahRadius.cardR),
          textStyle: type.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NajahColors.teal,
          minimumSize: const Size.fromHeight(NajahSize.button),
          side: const BorderSide(color: NajahColors.teal, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: NajahRadius.cardR),
          textStyle: type.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NajahColors.teal,
          minimumSize: const Size(NajahSize.minTouch, NajahSize.minTouch),
          textStyle: type.subheading.copyWith(fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NajahColors.surface,
        contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 15),
        border: border(NajahColors.line),
        enabledBorder: border(NajahColors.line),
        focusedBorder: border(NajahColors.teal),
        errorBorder: border(NajahColors.error),
        focusedErrorBorder: border(NajahColors.error),
        labelStyle: type.label.copyWith(fontSize: 14, color: NajahColors.text),
        hintStyle: type.body.copyWith(color: NajahColors.textMuted),
        errorStyle: type.label.copyWith(color: NajahColors.error),
      ),
      cardTheme: const CardThemeData(
        color: NajahColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: NajahRadius.cardR,
          side: BorderSide(color: NajahColors.line),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(side: BorderSide(color: NajahColors.line)),
        backgroundColor: NajahColors.surface,
        selectedColor: NajahColors.ink,
        labelStyle: type.label.copyWith(color: NajahColors.text, fontWeight: FontWeight.w700),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: NajahColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: NajahRadius.dialogR),
        titleTextStyle: type.titleSmall,
        contentTextStyle: type.bodySmall,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: NajahColors.background,
        shape: RoundedRectangleBorder(borderRadius: NajahRadius.sheetR),
        showDragHandle: true,
        dragHandleColor: Color(0xFFD9D5CB),
        dragHandleSize: Size(40, 4),
        modalBarrierColor: NajahColors.scrim,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NajahColors.ink,
        contentTextStyle: type.bodySmall.copyWith(color: Colors.white),
        actionTextColor: NajahColors.mint,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: NajahRadius.cardR),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? NajahColors.teal : const Color(0xFFC9C4B8),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: NajahColors.teal,
        linearTrackColor: NajahColors.track,
      ),
      dividerTheme: const DividerThemeData(color: NajahColors.track, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: NajahColors.surface,
        indicatorColor: NajahColors.tealTint,
        labelTextStyle: WidgetStatePropertyAll(type.tab),
        height: 64,
      ),
    );
  }
}
