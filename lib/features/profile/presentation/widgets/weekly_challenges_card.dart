import 'package:flutter/material.dart';

import 'package:dander/core/challenges/challenge.dart';
import 'package:dander/core/theme/app_theme.dart';

/// Card displaying the current week's challenges with progress.
class WeeklyChallengesCard extends StatelessWidget {
  const WeeklyChallengesCard({super.key, required this.challenges});

  final List<Challenge> challenges;

  @override
  Widget build(BuildContext context) {
    final progress = WeeklyProgress(challenges: challenges);

    return Container(
      padding: DanderSpacing.cardPadding,
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Weekly Challenges', style: DanderTextStyles.titleLarge),
              const Spacer(),
              Text(
                '${progress.completedCount} / ${progress.totalCount}',
                style: DanderTextStyles.bodyMedium.copyWith(
                  color: DanderColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: DanderSpacing.lg),
          ...challenges.map(_buildChallengeRow),
        ],
      ),
    );
  }

  Widget _buildChallengeRow(Challenge challenge) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DanderSpacing.md),
      child: Row(
        children: [
          if (challenge.isCompleted)
            const Icon(
              Icons.check_circle,
              color: DanderColors.secondary,
              size: 24,
            )
          else
            Icon(
              _iconForType(challenge.type),
              color: DanderColors.onSurfaceDisabled,
              size: 24,
            ),
          const SizedBox(width: DanderSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: DanderTextStyles.bodyMedium.copyWith(
                    decoration: challenge.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: challenge.isCompleted
                        ? DanderColors.onSurfaceDisabled
                        : DanderColors.onSurface,
                  ),
                ),
                if (!challenge.isCompleted) ...[
                  const SizedBox(height: DanderSpacing.xs),
                  LinearProgressIndicator(
                    value: challenge.progress,
                    backgroundColor: DanderColors.divider,
                    color: DanderColors.accent,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: DanderSpacing.md),
          Text(
            '+${challenge.xpReward} XP',
            style: DanderTextStyles.labelSmall.copyWith(
              color: challenge.isCompleted
                  ? DanderColors.secondary
                  : DanderColors.onSurfaceDisabled,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(ChallengeType type) {
    switch (type) {
      case ChallengeType.distance:
        return Icons.directions_walk;
      case ChallengeType.discoveries:
        return Icons.explore;
      case ChallengeType.quizStreak:
        return Icons.quiz;
      case ChallengeType.fogCleared:
        return Icons.cloud_off;
    }
  }
}
