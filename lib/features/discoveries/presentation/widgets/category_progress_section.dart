import 'package:flutter/material.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Category icon mapping
// ---------------------------------------------------------------------------

const _categoryIcons = <String, IconData>{
  'cafe': Icons.coffee,
  'restaurant': Icons.restaurant,
  'pub': Icons.local_bar,
  'bar': Icons.local_bar,
  'fast_food': Icons.fastfood,
  'park': Icons.park,
  'garden': Icons.local_florist,
  'museum': Icons.museum,
  'gallery': Icons.photo_camera,
  'library': Icons.library_books,
  'cinema': Icons.movie,
  'theatre': Icons.theater_comedy,
  'church': Icons.church,
  'place_of_worship': Icons.church,
  'school': Icons.school,
  'university': Icons.school,
  'hospital': Icons.local_hospital,
  'pharmacy': Icons.local_pharmacy,
  'supermarket': Icons.shopping_cart,
  'shop': Icons.store,
  'bus_stop': Icons.directions_bus,
  'viewpoint': Icons.visibility,
  'bench': Icons.chair,
  'fountain': Icons.water,
};

IconData _iconFor(String category) =>
    _categoryIcons[category] ?? Icons.place_outlined;

// ---------------------------------------------------------------------------
// CategoryProgressSection
// ---------------------------------------------------------------------------

/// Shows a grid of per-category progress tiles in the Discoveries screen.
///
/// - Fully-discovered categories show with a filled icon and a count badge.
/// - Partially-discovered categories show muted icon + x/y progress.
/// - Undiscovered categories show as [CategorySilhouette] with a "?" overlay.
/// - Tapping an undiscovered silhouette shows an exploration hint.
class CategoryProgressSection extends StatelessWidget {
  const CategoryProgressSection({
    super.key,
    required this.discovered,
    required this.allPois,
    this.zoneName,
  });

  /// POIs the user has discovered.
  final List<Discovery> discovered;

  /// All cached POIs (discovered + undiscovered).
  final List<Discovery> allPois;

  /// Active zone name used in the exploration hint.
  final String? zoneName;

  Map<String, int> _totals() {
    final map = <String, int>{};
    for (final d in allPois) {
      map[d.category] = (map[d.category] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> _discoveredCounts() {
    final map = <String, int>{};
    for (final d in discovered) {
      map[d.category] = (map[d.category] ?? 0) + 1;
    }
    return map;
  }

  void _showHint(BuildContext context, String category) {
    final zone = zoneName ?? 'your zone';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Keep exploring near $zone to find more ${category}s!',
          style: DanderTextStyles.bodySmall.copyWith(
            color: DanderColors.onSurface,
          ),
        ),
        backgroundColor: DanderColors.cardBackground,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals();
    if (totals.isEmpty) return const SizedBox.shrink();

    final counts = _discoveredCounts();
    final categories = totals.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DanderSpacing.lg,
        vertical: DanderSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categories', style: DanderTextStyles.labelLarge),
          const SizedBox(height: DanderSpacing.sm),
          Wrap(
            spacing: DanderSpacing.sm,
            runSpacing: DanderSpacing.sm,
            children: categories.map((cat) {
              final total = totals[cat]!;
              final found = counts[cat] ?? 0;
              final isComplete = found >= total;
              final isUndiscovered = found == 0;

              if (isUndiscovered) {
                return CategorySilhouette(
                  category: cat,
                  total: total,
                  onTap: () => _showHint(context, cat),
                );
              }

              return _CategoryTile(
                category: cat,
                found: found,
                total: total,
                isComplete: isComplete,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CategorySilhouette
// ---------------------------------------------------------------------------

/// Greyed-out silhouette for an undiscovered category.
///
/// Shows the category icon in muted form with a "?" overlay.
/// Tapping shows an exploration hint via [onTap].
class CategorySilhouette extends StatelessWidget {
  const CategorySilhouette({
    super.key,
    required this.category,
    required this.total,
    this.onTap,
  });

  final String category;
  final int total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(
          horizontal: DanderSpacing.sm,
          vertical: DanderSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: DanderColors.cardBackground,
          borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusMd),
          border: Border.all(
            color: DanderColors.divider,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  _iconFor(category),
                  color: DanderColors.onSurfaceDisabled,
                  size: 24,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: DanderColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '?',
                        style: TextStyle(
                          fontSize: 9,
                          color: DanderColors.onSurfaceMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DanderSpacing.xs),
            Text(
              category,
              style: DanderTextStyles.labelSmall.copyWith(
                color: DanderColors.onSurfaceDisabled,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '0/$total',
              style: DanderTextStyles.labelSmall.copyWith(
                color: DanderColors.onSurfaceDisabled,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CategoryTile
// ---------------------------------------------------------------------------

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.found,
    required this.total,
    required this.isComplete,
  });

  final String category;
  final int found;
  final int total;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final color =
        isComplete ? DanderColors.accent : DanderColors.onSurfaceMuted;

    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: DanderSpacing.sm,
        vertical: DanderSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusMd),
        border: Border.all(
          color: isComplete ? DanderColors.accent : DanderColors.divider,
          width: isComplete ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(category), color: color, size: 24),
          const SizedBox(height: DanderSpacing.xs),
          Text(
            category,
            style: DanderTextStyles.labelSmall.copyWith(
              color: color,
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$found/$total',
            style: DanderTextStyles.labelSmall.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
