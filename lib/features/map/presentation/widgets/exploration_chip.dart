import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';

/// A floating chip that displays the user's exploration percentage.
///
/// Shown during the first-launch micro-reveal to communicate
/// "You've explored X% of your neighbourhood" — activating the
/// curiosity gap with a tiny number against a vast fog.
class ExplorationChip extends StatelessWidget {
  const ExplorationChip({
    super.key,
    required this.percentageExplored,
  });

  /// The exploration percentage (e.g. 0.2 for "0.2%").
  final double percentageExplored;

  @override
  Widget build(BuildContext context) {
    final pctText = percentageExplored % 1 == 0
        ? '${percentageExplored.toInt()}.0%'
        : '${percentageExplored.toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DanderSpacing.xl,
        vertical: DanderSpacing.md,
      ),
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
        border: Border.all(
          color: DanderColors.accent.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: DanderElevation.level2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pctText,
            style: DanderTextStyles.headlineLarge.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'of your neighbourhood explored',
            style: DanderTextStyles.bodySmall.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
