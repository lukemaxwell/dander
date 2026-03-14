import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/core/zone/zone_level.dart';

/// A thin progress bar showing current XP toward the next level.
///
/// Displays the zone level label (L1–L5), a progress bar, and text showing
/// XP remaining to reach the next level. At max level, shows "MAX".
class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    super.key,
    required this.currentXp,
    required this.nextLevelXp,
    required this.level,
  });

  /// Total accumulated XP in the zone.
  final int currentXp;

  /// XP threshold for the next level, or `null` if at max level.
  final int? nextLevelXp;

  /// Current 1-based level (1–5).
  final int level;

  double get _fraction {
    if (nextLevelXp == null) return 1.0;
    final currentLevelXp = ZoneLevel.xpForLevel(level);
    final range = nextLevelXp! - currentLevelXp;
    if (range <= 0) return 1.0;
    return ((currentXp - currentLevelXp) / range).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = nextLevelXp != null ? nextLevelXp! - currentXp : 0;
    final nextLevel = level + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DanderColors.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DanderColors.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'L$level',
            style: const TextStyle(
              color: DanderColors.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _fraction,
                backgroundColor:
                    DanderColors.onSurface.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  DanderColors.secondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            nextLevelXp != null ? '$remaining XP to L$nextLevel' : 'MAX',
            style: TextStyle(
              color: DanderColors.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
