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
    sliderTheme: const SliderThemeData(
      trackHeight: 3.5,
      activeTrackColor: primary,
      inactiveTrackColor: Color(0x38FFFFFF),
      thumbColor: primary,
      overlayColor: primarySubtle,
      thumbShape: RoundSliderThumbShape(
        enabledThumbRadius: 6,
        elevation: 2,
        pressedElevation: 4,
      ),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 350),
      showDuration: const Duration(milliseconds: 2500),
      decoration: BoxDecoration(
        color: const Color(0xFF202028),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      textStyle: const TextStyle(
        fontSize: 11.5,
        color: textPrimary,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceElevated,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(surfaceElevated),
        shadowColor: const WidgetStatePropertyAll(Colors.black87),
        elevation: const WidgetStatePropertyAll(16),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: border),
          ),
        ),
      ),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(textPrimary),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(220, 32)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
  );
}
