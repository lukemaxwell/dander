import 'package:flutter/material.dart';

enum Rarity { common, uncommon, rare }

extension RarityExtension on Rarity {
  String get displayName {
    switch (this) {
      case Rarity.common:
        return 'Common';
      case Rarity.uncommon:
        return 'Uncommon';
      case Rarity.rare:
        return 'Rare';
    }
  }

  Color get color {
    switch (this) {
      case Rarity.common:
        return const Color(0xFFCD7F32); // bronze
      case Rarity.uncommon:
        return const Color(0xFFC0C0C0); // silver
      case Rarity.rare:
        return const Color(0xFFFFD700); // gold
    }
  }

  String get emoji {
    switch (this) {
      case Rarity.common:
        return '(bronze)';
      case Rarity.uncommon:
        return '(silver)';
      case Rarity.rare:
        return '(gold)';
    }
  }
}

class Discovery {
  const Discovery({
    required this.id,
    required this.name,
    required this.category,
    required this.rarity,
    required this.latitude,
    required this.longitude,
    required this.discoveredAt,
  });

  final String id;
  final String name;
  final String category;
  final Rarity rarity;
  final double latitude;
  final double longitude;
  final DateTime discoveredAt;
}
