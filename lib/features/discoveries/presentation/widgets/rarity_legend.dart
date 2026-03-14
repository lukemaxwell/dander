import 'package:flutter/material.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/core/theme/rarity_colors.dart';

/// A compact legend explaining all four rarity tiers with colors.
class RarityLegend extends StatelessWidget {
  const RarityLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DanderSpacing.lg,
        vertical: DanderSpacing.sm,
      ),
      child: Wrap(
        spacing: DanderSpacing.md,
        runSpacing: DanderSpacing.xs,
        children: [
          for (final tier in RarityTier.values)
            _TierDot(tier: tier),
        ],
      ),
    );
  }
}

class _TierDot extends StatelessWidget {
  const _TierDot({required this.tier});

  final RarityTier tier;

  String get _description {
    switch (tier) {
      case RarityTier.common:
        return 'Common';
      case RarityTier.uncommon:
        return 'Uncommon';
      case RarityTier.rare:
        return 'Rare';
      case RarityTier.legendary:
        return 'Legendary — Wikipedia entries!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = RarityColors.forTier(tier);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: DanderSpacing.xs),
        Text(
          _description,
          style: DanderTextStyles.labelSmall.copyWith(
            color: DanderColors.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}
