import 'package:flutter/material.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF09090B),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF59E0B),
      secondary: Color(0xFF10B981),
      surface: Color(0xFF18181B),
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 3.5,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
    ),
  );
}
