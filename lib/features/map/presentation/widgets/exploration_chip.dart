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
        horizontal: DanderSpacing.md,
        vertical: DanderSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: DanderColors.primary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusFull),
        border: Border.all(
          color: DanderColors.accent.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pctText,
            style: DanderTextStyles.headlineMedium.copyWith(
              color: DanderColors.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'of your neighbourhood explored',
            style: DanderTextStyles.labelSmall.copyWith(
              color: DanderColors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
