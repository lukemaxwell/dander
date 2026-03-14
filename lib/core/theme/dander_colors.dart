import 'package:flutter/material.dart';

/// Semantic color tokens for the Dander design system.
///
/// All feature screens MUST reference these constants — no hardcoded
/// [Color] literals should appear in `lib/features/`.
abstract final class DanderColors {
  // ---------------------------------------------------------------------------
  // Core brand
  // ---------------------------------------------------------------------------

  /// Deep navy — primary brand background and app bar.
  static const Color primary = Color(0xFF1A1A2E);

  /// Bold amber — action-only CTA color: walk start/stop, primary buttons.
  static const Color secondary = Color(0xFFFF8F00);

  /// Sky blue — information/state color: nav active, progress, XP, links.
  static const Color accent = Color(0xFF4FC3F7);

  // ---------------------------------------------------------------------------
  // Surfaces
  // ---------------------------------------------------------------------------

  /// Deepest background (scaffold).
  static const Color surface = Color(0xFF0A0A14);

  /// Slightly elevated surface — app bars, bottom nav.
  static const Color surfaceElevated = Color(0xFF111120);

  /// Card / container background.
  static const Color cardBackground = Color(0xFF1A1A2C);

  /// Subtle 0.5px border on cards — separates them from background on OLED.
  static const Color cardBorder = Color(0x18FFFFFF); // 9% white

  // ---------------------------------------------------------------------------
  // On-surface text
  // ---------------------------------------------------------------------------

  /// High-emphasis text on dark surfaces.
  static const Color onSurface = Color(0xFFE8EAF6);

  /// Medium-emphasis text — subtitles, captions.
  static const Color onSurfaceMuted = Color(0x99E8EAF6); // ~60% opacity

  /// Disabled / lowest-emphasis text.
  static const Color onSurfaceDisabled = Color(0x3DE8EAF6); // ~24% opacity

  // ---------------------------------------------------------------------------
  // Semantic feedback
  // ---------------------------------------------------------------------------

  /// Success green.
  static const Color success = Color(0xFF4CAF50);

  /// Error / destructive red.
  static const Color error = Color(0xFFEF5350);

  /// Warning amber.
  static const Color warning = Color(0xFFFFA726);

  // ---------------------------------------------------------------------------
  // Fog / map layer
  // ---------------------------------------------------------------------------

  /// Semi-transparent fog overlay on the map.
  static const Color fogOverlay = Color(0xCC1A1A2E);

  /// Fully transparent (revealed tiles).
  static const Color revealedTint = Color(0x00000000);

  // ---------------------------------------------------------------------------
  // Rarity tiers
  // ---------------------------------------------------------------------------

  /// Common = bronze.
  static const Color rarityCommon = Color(0xFFCD7F32);

  /// Uncommon = silver.
  static const Color rarityUncommon = Color(0xFFC0C0C0);

  /// Rare = gold.
  static const Color rarityRare = Color(0xFFFFD700);

  // ---------------------------------------------------------------------------
  // Gamification
  // ---------------------------------------------------------------------------

  /// Active streak — fire orange.
  static const Color streakActive = Color(0xFFFF6B35);

  /// At-risk streak — muted orange.
  static const Color streakAtRisk = Color(0xFFFFA726);

  /// Badge unlocked highlight.
  static const Color badgeUnlocked = secondary;

  // ---------------------------------------------------------------------------
  // Gradient pair (primary CTA gradient)
  // ---------------------------------------------------------------------------

  /// Start color of the primary gradient (amber).
  static const Color gradientStart = Color(0xFFFF8F00);

  /// End color of the primary gradient (cyan).
  static const Color gradientEnd = Color(0xFF4FC3F7);

  // ---------------------------------------------------------------------------
  // Utility
  // ---------------------------------------------------------------------------

  /// Standard divider / separator color.
  static const Color divider = Color(0x2EE8EAF6); // ~18% white

  /// Overlay used for modals and bottom sheets.
  static const Color scrim = Color(0xCC000000);
}
