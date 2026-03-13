import 'package:flutter/material.dart';

import 'dander_colors.dart';

// Re-export design system tokens so callers can import a single file.
export 'dander_colors.dart';
export 'dander_elevation.dart';
export 'dander_spacing.dart';
export 'dander_text_styles.dart';

/// Returns the application [ThemeData].
///
/// Fonts are wired in by Issue #34 (Typography); until then the default
/// Material font family is used.
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: DanderColors.accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: DanderColors.surface,
      primary: DanderColors.primary,
      secondary: DanderColors.secondary,
      error: DanderColors.error,
    ),
    scaffoldBackgroundColor: DanderColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: DanderColors.surfaceElevated,
      foregroundColor: DanderColors.onSurface,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: DanderColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: DanderColors.divider,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: DanderColors.surfaceElevated,
      selectedItemColor: DanderColors.accent,
      unselectedItemColor: DanderColors.onSurfaceMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
