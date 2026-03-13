import 'package:flutter/material.dart';

/// Dander brand colour palette.
abstract final class DanderColors {
  static const Color primary = Color(0xFF1A1A2E);
  static const Color fogOverlay = Color(0xCC1A1A2E);
  static const Color revealedTint = Color(0x00000000);
  static const Color accent = Color(0xFF4FC3F7);
  static const Color discoveryCommon = Color(0xFFCD7F32);
  static const Color discoveryUncommon = Color(0xFFC0C0C0);
  static const Color discoveryRare = Color(0xFFFFD700);
  static const Color surface = Color(0xFF0D0D1A);
  static const Color onSurface = Color(0xFFE8EAF6);
}

/// Returns the application [ThemeData].
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: DanderColors.accent,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: DanderColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: DanderColors.primary,
      foregroundColor: DanderColors.onSurface,
      elevation: 0,
    ),
  );
}
