import 'package:flutter/material.dart';

import 'package:dander/core/quiz/quiz_session.dart';
import 'package:dander/core/quiz/quiz_streak_tracker.dart';
import 'package:dander/core/theme/app_theme.dart';

/// Screen shown after a quiz session is complete.
///
/// Displays:
/// - correct/total, accuracy %
/// - mastered this session
/// - current streak
///
/// Provides two actions:
/// - "Start Another" — navigates back to quiz home
/// - "Go Explore"    — navigates to map tab (/home)
class QuizSummaryScreen extends StatelessWidget {
  const QuizSummaryScreen({
    super.key,
    required this.session,
    required this.streak,
    required this.masteredThisSession,
    required this.onStartAnother,
    required this.onGoExplore,
  });

  final QuizSession session;
  final QuizStreakTracker streak;
  final int masteredThisSession;
  final VoidCallback onStartAnother;
  final VoidCallback onGoExplore;

  @override
  Widget build(BuildContext context) {
    final total = session.questions.length;
    final correct = session.correctCount;
    final accuracyPct = total > 0 ? (correct / total * 100).round() : 0;

    return Scaffold(
      backgroundColor: DanderColors.surface,
      appBar: AppBar(
        title: Text('Session Complete', style: DanderTextStyles.titleLarge),
        backgroundColor: DanderColors.surface,
        foregroundColor: DanderColors.onSurface,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: DanderSpacing.pagePadding.copyWith(
            top: DanderSpacing.xl,
            bottom: DanderSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DanderSpacing.lg),
              // Score
              _StatRow(
                icon: Icons.check_circle_outline,
                label: 'Score',
                value: '$correct / $total',
                color: DanderColors.onSurface,
              ),
              const SizedBox(height: DanderSpacing.lg),
              // Accuracy
              _StatRow(
                icon: Icons.percent,
                label: 'Accuracy',
                value: '$accuracyPct%',
                color: accuracyPct >= 80
                    ? DanderColors.success
                    : DanderColors.streakAtRisk,
              ),
              const SizedBox(height: DanderSpacing.lg),
              // Mastered
              _StatRow(
                icon: Icons.star,
                label: 'Mastered this session',
                value: '$masteredThisSession',
                color: DanderColors.rarityRare,
              ),
              const SizedBox(height: DanderSpacing.lg),
              // Streak
              _StatRow(
                icon: Icons.local_fire_department,
                label: 'Quiz streak',
                value:
                    '${streak.currentStreak} week${streak.currentStreak == 1 ? '' : 's'}',
                color: DanderColors.streakActive,
              ),
              const Spacer(),
              // Start Another
              ElevatedButton(
                onPressed: onStartAnother,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DanderColors.secondary,
                  padding: const EdgeInsets.symmetric(
                    vertical: DanderSpacing.lg,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      DanderSpacing.borderRadiusMd,
                    ),
                  ),
                ),
                child:
                    Text('Start Another', style: DanderTextStyles.labelLarge),
              ),
              const SizedBox(height: DanderSpacing.md),
              // Go Explore
              OutlinedButton(
                onPressed: onGoExplore,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: DanderColors.divider),
                  padding: const EdgeInsets.symmetric(
                    vertical: DanderSpacing.lg,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      DanderSpacing.borderRadiusMd,
                    ),
                  ),
                ),
                child: Text(
                  'Go Explore',
                  style: DanderTextStyles.bodyMedium.copyWith(
                    color: DanderColors.onSurfaceMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: DanderSpacing.md),
        Expanded(
          child: Text(label, style: DanderTextStyles.bodyMediumMuted),
        ),
        Text(
          value,
          style: DanderTextStyles.titleMedium.copyWith(color: color),
        ),
      ],
    );
  }
}
