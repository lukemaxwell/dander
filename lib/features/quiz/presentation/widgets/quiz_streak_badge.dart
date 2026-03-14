import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';

/// A compact badge showing the current quiz streak count with a fire icon.
///
/// When [streak] > 3, shows a "Bonus!" label to indicate the streak bonus
/// is active (+2 XP per correct answer).
class QuizStreakBadge extends StatelessWidget {
  const QuizStreakBadge({
    super.key,
    required this.streak,
  });

  /// Current consecutive correct answers.
  final int streak;

  @override
  Widget build(BuildContext context) {
    if (streak <= 0) return const SizedBox.shrink();

    final bonusActive = streak > 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bonusActive
            ? DanderColors.secondary.withValues(alpha: 0.15)
            : DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bonusActive
              ? DanderColors.secondary.withValues(alpha: 0.5)
              : DanderColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: bonusActive
                ? DanderColors.secondary
                : DanderColors.onSurfaceMuted,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: TextStyle(
              color: bonusActive
                  ? DanderColors.secondary
                  : DanderColors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          if (bonusActive) ...[
            const SizedBox(width: 4),
            Text(
              'Bonus!',
              style: TextStyle(
                color: DanderColors.secondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
