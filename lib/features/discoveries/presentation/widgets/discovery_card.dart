import 'package:flutter/material.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/core/theme/category_icons.dart';
import 'package:dander/core/theme/rarity_colors.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime dt) =>
    '${dt.day} ${_monthNames[dt.month - 1]} ${dt.year}';

/// A card widget that displays the details of a [Discovery].
///
/// Used both as a full-size popup (after a proximity trigger) and as a
/// compact grid tile in the collection screen.
class DiscoveryCard extends StatelessWidget {
  const DiscoveryCard({
    super.key,
    required this.discovery,
    this.onDismiss,
    this.discoveryNumber = 1,
    this.compact = false,
  });

  /// The discovery to display.
  final Discovery discovery;

  /// Optional callback invoked when the "Collect" / dismiss button is tapped.
  final VoidCallback? onDismiss;

  /// Sequential discovery number shown as "Discovery #N".
  final int discoveryNumber;

  /// When true, renders a compact version suited for grid tiles.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rarityColor = RarityColors.forTier(discovery.rarity);
    final rarityLabel = RarityColors.label(discovery.rarity);
    final categoryIcon = CategoryIcons.forCategory(discovery.category);
    final dateText = discovery.discoveredAt != null
        ? _formatDate(discovery.discoveredAt!)
        : '';

    return Container(
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
        border: Border.all(color: rarityColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top rarity accent bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: rarityColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DanderSpacing.borderRadiusLg - 2),
              ),
            ),
          ),
          Padding(
            padding: DanderSpacing.cardPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rarity badge + icon row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Rarity badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DanderSpacing.md - 2,
                        vertical: DanderSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: rarityColor,
                        borderRadius: BorderRadius.circular(
                          DanderSpacing.borderRadiusFull,
                        ),
                      ),
                      child: Text(
                        rarityLabel,
                        style: DanderTextStyles.labelMedium.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Category icon
                    Container(
                      padding: const EdgeInsets.all(DanderSpacing.sm),
                      decoration: BoxDecoration(
                        color: rarityColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        categoryIcon,
                        color: rarityColor,
                        size: compact ? 20 : 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DanderSpacing.md),
                // POI name
                Text(
                  discovery.name.isEmpty ? '(Unnamed)' : discovery.name,
                  style: compact
                      ? DanderTextStyles.titleSmall
                      : DanderTextStyles.titleLarge.copyWith(fontSize: 20),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DanderSpacing.xs),
                // Category label
                Text(
                  discovery.category,
                  style: compact
                      ? DanderTextStyles.labelSmall
                      : DanderTextStyles.bodySmall,
                ),
                const SizedBox(height: DanderSpacing.sm),
                // Discovery number + date
                Text(
                  'Discovery #$discoveryNumber',
                  style: DanderTextStyles.labelMedium.copyWith(
                    color: rarityColor,
                    fontSize: compact ? 11 : 13,
                  ),
                ),
                if (dateText.isNotEmpty && !compact) ...[
                  const SizedBox(height: DanderSpacing.xs / 2),
                  Text(
                    'Found $dateText',
                    style: DanderTextStyles.bodySmall.copyWith(
                      color: DanderColors.onSurfaceDisabled,
                    ),
                  ),
                ],
                if (!compact) ...[
                  const SizedBox(height: DanderSpacing.lg),
                  ElevatedButton(
                    onPressed: onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rarityColor,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DanderSpacing.borderRadiusMd,
                        ),
                      ),
                    ),
                    child: Text(
                      'Collect',
                      style: DanderTextStyles.labelLarge.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
