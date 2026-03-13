import 'package:flutter/material.dart';

/// A (icon, color) pair for a single POI category pin.
typedef CategoryPinData = ({IconData icon, Color color});

/// Maps OSM category strings to a [CategoryPinData] record containing the
/// [IconData] and [Color] to use when rendering a map pin for that category.
///
/// Usage:
/// ```dart
/// final config = CategoryPinConfig.forCategory('cafe');
/// Icon(config.icon, color: config.color);
/// ```
abstract final class CategoryPinConfig {
  static const CategoryPinData _default = (
    icon: Icons.place,
    color: Color(0xFFE8EAF6),
  );

  static const Map<String, CategoryPinData> _map = {
    'cafe': (icon: Icons.coffee, color: Color(0xFF8D6E63)),
    'park': (icon: Icons.park, color: Color(0xFF66BB6A)),
    'historic': (icon: Icons.account_balance, color: Color(0xFFFFD700)),
    'street_art': (icon: Icons.palette, color: Color(0xFFAB47BC)),
    'viewpoint': (icon: Icons.visibility, color: Color(0xFF4FC3F7)),
    'pub': (icon: Icons.sports_bar, color: Color(0xFFFF8F00)),
    'library': (icon: Icons.menu_book, color: Color(0xFF42A5F5)),
  };

  /// Returns the [CategoryPinData] for [category], falling back to a default
  /// white pin with [Icons.place] for any unknown or empty string.
  static CategoryPinData forCategory(String category) {
    return _map[category] ?? _default;
  }
}
