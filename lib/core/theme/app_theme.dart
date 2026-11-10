import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0C0C0E);
  static const Color surface = Color(0xFF141418);
  static const Color surfaceElevated = Color(0xFF1C1C24);
  static const Color surfaceHighlight = Color(0xFF262632);
  static const Color border = Color(0xFF2E2E3C);
  static const Color primary = Color(0xFFF59E0B);
  static const Color primarySubtle = Color(0x28F59E0B);
  static const Color secondary = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFFEDEDF0);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);

  static const List<String> fontFallbacks = [
    'Segoe UI Variable Text',
    'Segoe UI Variable',
    'Segoe UI',
    'Inter',
    'SF Pro Display',
    'Roboto',
    'Arial',
    'sans-serif',
  ];

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      onSurface: textPrimary,
      onPrimary: Colors.black,
      outline: border,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontFamilyFallback: fontFallbacks,
        letterSpacing: 0.15,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamilyFallback: fontFallbacks,
        letterSpacing: 0.15,
        color: textPrimary,
      ),
      bodySmall: TextStyle(
        fontFamilyFallback: fontFallbacks,
        letterSpacing: 0.2,
        color: textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamilyFallback: fontFallbacks,
        letterSpacing: 0.3,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        fontFamilyFallback: fontFallbacks,
        letterSpacing: 0.3,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        fontFamilyFallback: fontFallbacks,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: TextStyle(
        fontFamilyFallback: fontFallbacks,
        letterSpacing: 0.2,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: TextStyle(
        fontFamilyFallback: fontFallbacks,
        letterSpacing: 0.2,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 2.5,
      activeTrackColor: primary,
      inactiveTrackColor: Color(0x33FFFFFF),
      thumbColor: primary,
      overlayColor: primarySubtle,
      thumbShape: RoundSliderThumbShape(
        enabledThumbRadius: 4.5,
        elevation: 1,
        pressedElevation: 3,
      ),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 10),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 350),
      showDuration: const Duration(milliseconds: 2500),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F28),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: const Color(0x38FFFFFF), width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      textStyle: const TextStyle(
        fontSize: 11,
        color: textPrimary,
        fontWeight: FontWeight.w400,
        fontFamilyFallback: fontFallbacks,
        letterSpacing: 0.2,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: surfaceElevated,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: border),
      ),
      titleTextStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        fontFamilyFallback: fontFallbacks,
        letterSpacing: 0.3,
      ),
    ),
    menuTheme: const MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(surfaceElevated),
        shadowColor: WidgetStatePropertyAll(Colors.black87),
        elevation: WidgetStatePropertyAll(16),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: border),
          ),
        ),
      ),
    ),
    menuButtonTheme: const MenuButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(textPrimary),
        textStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamilyFallback: fontFallbacks,
            letterSpacing: 0.2,
          ),
        ),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        minimumSize: WidgetStatePropertyAll(Size(220, 30)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
  );
}
