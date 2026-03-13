import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dander_colors.dart';
import 'dander_text_styles.dart';

// Re-export design system tokens so callers can import a single file.
export 'dander_colors.dart';
export 'dander_elevation.dart';
export 'dander_spacing.dart';
export 'dander_text_styles.dart';

/// Builds the Material 3 [TextTheme] wired with Google Fonts:
/// - **Space Grotesk** for display / headline (exploratory, techy feel).
/// - **Inter** for body / label (legible, modern, neutral).
///
/// Every style inherits the [DanderColors.onSurface] foreground color so
/// widgets that do not inherit from a Scaffold still render legibly.
///
/// If Google Fonts assets are unavailable (e.g. in unit tests without
/// runtime fetching) the method gracefully falls back to the default
/// Material dark text theme.
TextTheme buildTextTheme() {
  TextTheme spaceGrotesk;
  TextTheme inter;

  try {
    // Space Grotesk for display & headline text.
    spaceGrotesk = GoogleFonts.spaceGroteskTextTheme(
      ThemeData.dark().textTheme,
    );
    // Inter for body & label text.
    inter = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );
  } catch (_) {
    // Font assets not available (unit tests without runtime fetching).
    spaceGrotesk = ThemeData.dark().textTheme;
    inter = ThemeData.dark().textTheme;
  }

  const onSurface = DanderColors.onSurface;
  const onSurfaceMuted = DanderColors.onSurfaceMuted;

  return TextTheme(
    // ---- Display (hero / splash numbers) ----
    displayLarge: spaceGrotesk.displayLarge!.copyWith(
      color: onSurface,
      fontWeight: FontWeight.bold,
      fontSize: DanderTextStyles.displayLarge.fontSize,
      height: DanderTextStyles.displayLarge.height,
      letterSpacing: DanderTextStyles.displayLarge.letterSpacing,
    ),
    displayMedium: spaceGrotesk.displayMedium!.copyWith(
      color: onSurface,
      fontWeight: FontWeight.bold,
      fontSize: DanderTextStyles.displayMedium.fontSize,
      height: DanderTextStyles.displayMedium.height,
    ),
    displaySmall: spaceGrotesk.displaySmall!.copyWith(
      color: onSurface,
      fontWeight: FontWeight.w600,
    ),

    // ---- Headline (screen / section titles) ----
    headlineLarge: spaceGrotesk.headlineLarge!.copyWith(
      color: onSurface,
      fontWeight: FontWeight.bold,
      fontSize: DanderTextStyles.headlineLarge.fontSize,
      height: DanderTextStyles.headlineLarge.height,
    ),
    headlineMedium: spaceGrotesk.headlineMedium!.copyWith(
      color: onSurface,
      fontWeight: FontWeight.bold,
      fontSize: DanderTextStyles.headlineMedium.fontSize,
      height: DanderTextStyles.headlineMedium.height,
    ),
    headlineSmall: spaceGrotesk.headlineSmall!.copyWith(
      color: onSurface,
      fontWeight: FontWeight.w600,
      fontSize: DanderTextStyles.headlineSmall.fontSize,
    ),

    // ---- Title (card / list-item primaries) ----
    titleLarge: inter.titleLarge!.copyWith(
      color: onSurface,
      fontWeight: FontWeight.w600,
      fontSize: DanderTextStyles.titleLarge.fontSize,
    ),
    titleMedium: inter.titleMedium!.copyWith(
      color: onSurface,
      fontWeight: FontWeight.w600,
      fontSize: DanderTextStyles.titleMedium.fontSize,
      letterSpacing: DanderTextStyles.titleMedium.letterSpacing,
    ),
    titleSmall: inter.titleSmall!.copyWith(
      color: onSurface,
      fontWeight: FontWeight.w600,
      fontSize: DanderTextStyles.titleSmall.fontSize,
    ),

    // ---- Body (readable prose) ----
    bodyLarge: inter.bodyLarge!.copyWith(
      color: onSurface,
      fontWeight: FontWeight.normal,
      fontSize: DanderTextStyles.bodyLarge.fontSize,
      height: DanderTextStyles.bodyLarge.height,
    ),
    bodyMedium: inter.bodyMedium!.copyWith(
      color: onSurface,
      fontWeight: FontWeight.normal,
      fontSize: DanderTextStyles.bodyMedium.fontSize,
      height: DanderTextStyles.bodyMedium.height,
    ),
    bodySmall: inter.bodySmall!.copyWith(
      color: onSurfaceMuted,
      fontWeight: FontWeight.normal,
      fontSize: DanderTextStyles.bodySmall.fontSize,
    ),

    // ---- Label (chips, badges, buttons) ----
    labelLarge: inter.labelLarge!.copyWith(
      color: onSurface,
      fontWeight: FontWeight.w600,
      fontSize: DanderTextStyles.labelLarge.fontSize,
    ),
    labelMedium: inter.labelMedium!.copyWith(
      color: onSurface,
      fontWeight: FontWeight.w600,
      fontSize: DanderTextStyles.labelMedium.fontSize,
    ),
    labelSmall: inter.labelSmall!.copyWith(
      color: onSurfaceMuted,
      fontWeight: FontWeight.w500,
      fontSize: DanderTextStyles.labelSmall.fontSize,
    ),
  );
}

/// Returns the application [ThemeData] with Google Fonts typography.
///
/// Pass [useGoogleFonts] as `false` in unit tests to skip font loading and
/// use the Material default text theme instead (avoids network requests and
/// missing-asset errors in CI).
ThemeData buildAppTheme({bool useGoogleFonts = true}) {
  final textTheme = useGoogleFonts ? buildTextTheme() : null;

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
    textTheme: textTheme,
    scaffoldBackgroundColor: DanderColors.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: DanderColors.surfaceElevated,
      foregroundColor: DanderColors.onSurface,
      elevation: 0,
      titleTextStyle: textTheme?.titleLarge,
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
