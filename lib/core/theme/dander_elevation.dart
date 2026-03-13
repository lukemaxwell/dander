import 'package:flutter/material.dart';

import 'dander_colors.dart';

/// Elevation presets expressed as lists of [BoxShadow].
///
/// Designed for dark-themed surfaces — shadows use a semi-transparent black
/// so they remain visible against the dark card backgrounds.
abstract final class DanderElevation {
  /// No shadow — flat surface.
  static const List<BoxShadow> level0 = [];

  /// Subtle lift — cards resting on the main surface.
  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Moderate lift — floating elements, bottom sheets.
  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// High lift — dialogs, tooltips, overlays.
  static const List<BoxShadow> level3 = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Accent glow — badge and CTA highlights using the brand secondary color.
  static const List<BoxShadow> accentGlow = [
    BoxShadow(
      color: Color(0x66FF8F00), // secondary (amber) at ~40%
      blurRadius: 20,
      spreadRadius: 2,
      offset: Offset.zero,
    ),
  ];

  /// Rarity glow — used on discovery cards for the rare tier.
  static List<BoxShadow> rarityGlow(Color rarityColor) => [
        BoxShadow(
          color: rarityColor.withValues(alpha: 0.35),
          blurRadius: 16,
          spreadRadius: 1,
          offset: Offset.zero,
        ),
      ];

  // ignore: unused_field
  static final _unused = DanderColors.primary; // keeps import alive
}
