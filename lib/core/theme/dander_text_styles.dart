import 'package:flutter/material.dart';

import 'dander_colors.dart';

/// Named text style tokens for the Dander design system.
///
/// These styles intentionally do NOT specify a font family — that is injected
/// by the `ThemeData.textTheme` (see [buildAppTheme]).  Specifying color here
/// covers the dark-theme defaults so widgets that don't inherit from a
/// Scaffold still render legibly.
abstract final class DanderTextStyles {
  // ---------------------------------------------------------------------------
  // Display (hero numbers / large splash text)
  // ---------------------------------------------------------------------------

  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.bold,
    color: DanderColors.onSurface,
    height: 1.12,
    letterSpacing: -0.25,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.bold,
    color: DanderColors.onSurface,
    height: 1.16,
  );

  // ---------------------------------------------------------------------------
  // Headline (screen titles, section headers)
  // ---------------------------------------------------------------------------

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: DanderColors.onSurface,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: DanderColors.onSurface,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: DanderColors.onSurface,
    height: 1.33,
  );

  // ---------------------------------------------------------------------------
  // Title (card titles, list item primaries)
  // ---------------------------------------------------------------------------

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: DanderColors.onSurface,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: DanderColors.onSurface,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: DanderColors.onSurface,
    height: 1.43,
    letterSpacing: 0.1,
  );

  // ---------------------------------------------------------------------------
  // Body (readable prose, descriptions)
  // ---------------------------------------------------------------------------

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: DanderColors.onSurface,
    height: 1.5,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyLargeMuted = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: DanderColors.onSurfaceMuted,
    height: 1.5,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: DanderColors.onSurface,
    height: 1.43,
    letterSpacing: 0.25,
  );

  static const TextStyle bodyMediumMuted = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: DanderColors.onSurfaceMuted,
    height: 1.43,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: DanderColors.onSurfaceMuted,
    height: 1.33,
    letterSpacing: 0.4,
  );

  // ---------------------------------------------------------------------------
  // Label (chips, badges, buttons)
  // ---------------------------------------------------------------------------

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: DanderColors.onSurface,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: DanderColors.onSurface,
    height: 1.33,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: DanderColors.onSurfaceMuted,
    height: 1.45,
    letterSpacing: 0.5,
  );
}
