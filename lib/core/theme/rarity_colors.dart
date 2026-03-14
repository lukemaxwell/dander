import 'package:flutter/material.dart';
import 'package:dander/core/discoveries/discovery.dart';

/// Colour palette for rarity tiers.
///
/// Common = bronze, Uncommon = silver, Rare = gold, Legendary = iridescent teal.
class RarityColors {
  RarityColors._();

  static const Color common = Color(0xFFCD7F32); // Bronze
  static const Color uncommon = Color(0xFFC0C0C0); // Silver
  static const Color rare = Color(0xFFFFD700); // Gold
  static const Color legendary = Color(0xFF00E5FF); // Iridescent teal / cyan

  /// Returns the display colour for [tier].
  static Color forTier(RarityTier tier) {
    switch (tier) {
      case RarityTier.common:
        return common;
      case RarityTier.uncommon:
        return uncommon;
      case RarityTier.rare:
        return rare;
      case RarityTier.legendary:
        return legendary;
    }
  }

  /// Returns a human-readable label for [tier].
  static String label(RarityTier tier) {
    switch (tier) {
      case RarityTier.common:
        return 'Common';
      case RarityTier.uncommon:
        return 'Uncommon';
      case RarityTier.rare:
        return 'Rare';
      case RarityTier.legendary:
        return 'Legendary';
    }
  }
}
