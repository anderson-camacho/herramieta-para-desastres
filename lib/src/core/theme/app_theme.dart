import 'package:flutter/material.dart';

final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF003555),
      onPrimary: Colors.white,
      secondary: Color(0xFFBB0312),
      onSecondary: Colors.white,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      surface: Color(0xFFFDF9F3),
      onSurface: Color(0xFF1D1B18),
      onSurfaceVariant: Color(0xFF41474E),
      outline: Color(0xFF72787F),
      outlineVariant: Color(0xFFC1C7CF),
      secondaryContainer: Color(0xFFE02A28),
      onSecondaryContainer: Color(0xFFFFFBFF),
      primaryContainer: Color(0xFF0F4C75),
      onPrimaryContainer: Color(0xFFCEE5FF),
      surfaceContainerHighest: Color(0xFFE6E2DC),
      surfaceContainerHigh: Color(0xFFECE7E2),
      surfaceContainer: Color(0xFFF2EDE8),
      surfaceContainerLow: Color(0xFFF8F3ED),
      surfaceContainerLowest: Colors.white,
      inverseSurface: Color(0xFF32302D),
      onInverseSurface: Color(0xFFF5F0EB),
      tertiary: Color(0xFF5B1E00),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFF7C310A),
      onTertiaryContainer: Color(0xFFFFB597),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
      surfaceTint: Color(0xFF2E628C),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF1E1C1A),
      fontFamily: 'Atkinson Hyperlegible Next',
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: Color(0xFFC1C7CF), width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return light();
  }
}
