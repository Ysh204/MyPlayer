import 'package:flutter/material.dart';

class SubtitleConfig {
  /// mpv `sub-pos`: 0 (top) to 100 (bottom); values over 100 reach the letterbox.
  final double verticalPosition;

  /// mpv `sub-scale` multiplier.
  final double scale;

  /// Subtitle delay in seconds.
  final double delaySeconds;

  final double fontSize;
  final double backgroundOpacity;
  final Color textColor;
  final String? externalFilePath;

  const SubtitleConfig({
    this.verticalPosition = 95.0,
    this.scale = 1.0,
    this.delaySeconds = 0.0,
    this.fontSize = 24.0,
    this.backgroundOpacity = 0.65,
    this.textColor = Colors.white,
    this.externalFilePath,
  });

  SubtitleConfig copyWith({
    double? verticalPosition,
    double? scale,
    double? delaySeconds,
    double? fontSize,
    double? backgroundOpacity,
    Color? textColor,
    String? externalFilePath,
  }) {
    return SubtitleConfig(
      verticalPosition: verticalPosition ?? this.verticalPosition,
      scale: scale ?? this.scale,
      delaySeconds: delaySeconds ?? this.delaySeconds,
      fontSize: fontSize ?? this.fontSize,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      textColor: textColor ?? this.textColor,
      externalFilePath: externalFilePath ?? this.externalFilePath,
    );
  }
}
