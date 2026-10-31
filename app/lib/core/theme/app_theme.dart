import 'package:flutter/material.dart';
import 'sus_colors.dart';
import 'sus_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    const colors = SusColors.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.ink,
      fontFamily: SusTypography.fontFamily,
      extensions: const [colors],
      colorScheme: ColorScheme.dark(
        primary: colors.crimson,
        secondary: colors.crimsonBright,
        surface: colors.panel,
        error: colors.lose,
        onPrimary: Colors.white,
        onSurface: colors.bone,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.panel,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.crimsonBright, width: 2),
        ),
        hintStyle: SusTypography.body.copyWith(color: colors.mute),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1D1D1D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thumbVisibility: WidgetStatePropertyAll(false),
        trackVisibility: WidgetStatePropertyAll(false),
        thickness: WidgetStatePropertyAll(0),
        radius: Radius.zero,
      ),
    );
  }

  static ThemeData light() {
    const colors = SusColors.light;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.ink,
      fontFamily: SusTypography.fontFamily,
      extensions: const [colors],
      colorScheme: ColorScheme.light(
        primary: colors.crimson,
        secondary: colors.crimsonBright,
        surface: colors.panel,
        error: colors.lose,
        onPrimary: Colors.white,
        onSurface: colors.bone,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.panel,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.crimsonBright, width: 2),
        ),
        hintStyle: SusTypography.body.copyWith(color: colors.mute),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thumbVisibility: WidgetStatePropertyAll(false),
        trackVisibility: WidgetStatePropertyAll(false),
        thickness: WidgetStatePropertyAll(0),
        radius: Radius.zero,
      ),
    );
  }
}
