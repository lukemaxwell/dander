import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';

/// A compact badge showing exploration progress as a labelled progress bar.
class ExplorationBadge extends StatelessWidget {
  const ExplorationBadge({super.key, required this.percentageExplored});

  /// The exploration percentage in the range [0, 100].
  final int percentageExplored;

  @override
  Widget build(BuildContext context) {
    final fraction = (percentageExplored / 100.0).clamp(0.0, 1.0);
    final hidden = 100 - percentageExplored;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DanderColors.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DanderColors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentageExplored% explored',
                style: const TextStyle(
                  color: DanderColors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· $hidden% hidden',
                style: TextStyle(
                  color: DanderColors.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // Progress bar
          SizedBox(
            width: 160,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor:
                    DanderColors.onSurface.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  DanderColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
