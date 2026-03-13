import 'package:flutter/material.dart';

/// Maps OSM category strings to Material [IconData].
class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> _map = {
    'cafe': Icons.local_cafe,
    'park': Icons.park,
    'viewpoint': Icons.landscape,
    'historic': Icons.account_balance,
    'artwork': Icons.palette,
    'museum': Icons.museum,
    'library': Icons.local_library,
    'pub': Icons.sports_bar,
    'restaurant': Icons.restaurant,
  };

  /// Returns the icon for [category], or [Icons.place] for unknown categories.
  static IconData forCategory(String category) {
    return _map[category] ?? Icons.place;
  }
}
