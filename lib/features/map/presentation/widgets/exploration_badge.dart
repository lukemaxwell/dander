import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';

/// A compact badge displaying the user's current exploration percentage.
class ExplorationBadge extends StatelessWidget {
  const ExplorationBadge({super.key, required this.percentageExplored});

  /// The exploration percentage in the range [0, 100].
  final int percentageExplored;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DanderColors.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DanderColors.accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$percentageExplored% explored',
        style: const TextStyle(
          color: DanderColors.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
