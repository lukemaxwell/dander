import 'package:flutter/material.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/core/theme/category_icons.dart';
import 'package:dander/core/theme/rarity_colors.dart';
import 'package:dander/core/zone/zone_level.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime dt) =>
    '${dt.day} ${_monthNames[dt.month - 1]} ${dt.year}';

String _rarityExplanation(RarityTier tier) {
  switch (tier) {
    case RarityTier.common:
      return 'Common — frequently found points of interest';
    case RarityTier.uncommon:
      return 'Uncommon — distinctive local spots';
    case RarityTier.rare:
      return 'Rare — historic landmarks are uncommon finds';
    case RarityTier.legendary:
      return 'Legendary — notable places with Wikipedia entries';
  }
}

/// A detail view for a single [Discovery].
///
/// Shows name, category icon, rarity explanation, discovered date, and XP
/// earned. Designed for use in a bottom sheet or inline.
class DiscoveryDetailSheet extends StatelessWidget {
  const DiscoveryDetailSheet({
    super.key,
    required this.discovery,
  });

  final Discovery discovery;

  @override
  Widget build(BuildContext context) {
    final rarityColor = RarityColors.forTier(discovery.rarity);
    final rarityLabel = RarityColors.label(discovery.rarity);
    final categoryIcon = CategoryIcons.forCategory(discovery.category);
    final displayName =
        discovery.name.isEmpty ? '(Unnamed)' : discovery.name;

    return Padding(
      padding: DanderSpacing.pagePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Category icon
          Container(
            padding: const EdgeInsets.all(DanderSpacing.md),
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              categoryIcon,
              color: rarityColor,
              size: 32,
            ),
          ),
          const SizedBox(height: DanderSpacing.md),
          // Name
          Text(
            displayName,
            style: DanderTextStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DanderSpacing.xs),
          // Category
          Text(
            discovery.category,
            style: DanderTextStyles.bodySmall,
          ),
          const SizedBox(height: DanderSpacing.md),
          // Rarity badge + explanation
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DanderSpacing.md,
              vertical: DanderSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(DanderSpacing.borderRadiusMd),
              border: Border.all(
                color: rarityColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: rarityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: DanderSpacing.sm),
                Flexible(
                  child: Text(
                    _rarityExplanation(discovery.rarity),
                    style: DanderTextStyles.labelSmall.copyWith(
                      color: DanderColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DanderSpacing.lg),
          // Date + XP row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (discovery.discoveredAt != null) ...[
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: DanderColors.onSurfaceMuted,
                ),
                const SizedBox(width: DanderSpacing.xs),
                Text(
                  _formatDate(discovery.discoveredAt!),
                  style: DanderTextStyles.bodySmall,
                ),
                const SizedBox(width: DanderSpacing.lg),
              ],
              Icon(
                Icons.star,
                size: 14,
                color: rarityColor,
              ),
              const SizedBox(width: DanderSpacing.xs),
              Text(
                '${ZoneLevel.xpPerPoi} XP earned',
                style: DanderTextStyles.bodySmall.copyWith(
                  color: rarityColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: DanderSpacing.md),
        ],
      ),
    );
  }
}
