import 'package:flutter/material.dart';

import 'package:dander/core/quiz/quiz_scheduler.dart';
import 'package:dander/core/quiz/street_memory_record.dart';
import 'package:dander/core/streets/street.dart';
import 'package:dander/core/theme/app_theme.dart';

/// The mastery level label shown next to each street in the quiz home list.
enum MasteryLevel {
  /// Never reviewed — newly walked street.
  newStreet,

  /// Answering incorrectly, being re-learned.
  learning,

  /// Actively in spaced repetition cycle.
  review,

  /// Well-known; interval ≥ 30 days.
  mastered,
}

/// A colored dot + label badge indicating a street's mastery level.
class MasteryBadge extends StatelessWidget {
  const MasteryBadge({super.key, required this.level});

  final MasteryLevel level;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (level) {
      MasteryLevel.newStreet => (DanderColors.secondary, 'New'),
      MasteryLevel.learning => (DanderColors.streakAtRisk, 'Learning'),
      MasteryLevel.review => (DanderColors.accent, 'Review'),
      MasteryLevel.mastered => (DanderColors.success, 'Mastered'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: DanderSpacing.xs),
        Text(label, style: DanderTextStyles.labelSmall.copyWith(color: color)),
      ],
    );
  }
}

/// The quiz home screen showing due count, mastery stats, and a list of
/// walked streets with their mastery badges.
class QuizHomeScreen extends StatelessWidget {
  const QuizHomeScreen({
    super.key,
    required this.walkedStreets,
    required this.records,
    required this.onStartReview,
    required this.onPracticeAll,
  });

  /// All streets the user has walked.
  final List<Street> walkedStreets;

  /// Saved memory records for quizzed streets.
  final List<StreetMemoryRecord> records;

  /// Called when the user taps "Start Review".
  final VoidCallback onStartReview;

  /// Called when the user taps "Practice All".
  final VoidCallback onPracticeAll;

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  int get _dueCount {
    final today = DateTime.now();
    return QuizScheduler.getDueToday(records, today).length;
  }

  int get _masteredCount =>
      records.where((r) => r.state == MemoryState.mastered).length;

  double get _masteryPct => walkedStreets.isEmpty
      ? 0.0
      : (_masteredCount / walkedStreets.length * 100).clamp(0, 100);

  void _showExploreFirst(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.directions_walk, color: DanderColors.surface),
              const SizedBox(width: DanderSpacing.sm),
              Expanded(
                child: Text(
                  'Go for a walk first — explore your neighbourhood to unlock the quiz!',
                  style: DanderTextStyles.bodySmall.copyWith(
                    color: DanderColors.surface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: DanderColors.secondary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(
            left: DanderSpacing.lg,
            right: DanderSpacing.lg,
            bottom: DanderSpacing.xl,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(DanderSpacing.borderRadiusMd),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  MasteryLevel _masteryLevelFor(String streetId) {
    final record = records.where((r) => r.streetId == streetId).firstOrNull;
    if (record == null) return MasteryLevel.newStreet;
    return switch (record.state) {
      MemoryState.newCard => MasteryLevel.newStreet,
      MemoryState.learning => MasteryLevel.learning,
      MemoryState.review => MasteryLevel.review,
      MemoryState.mastered => MasteryLevel.mastered,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dueCount = _dueCount;
    final masteryPct = _masteryPct;

    return Scaffold(
      backgroundColor: DanderColors.surface,
      appBar: AppBar(
        title: Text('Quiz', style: DanderTextStyles.titleLarge),
        backgroundColor: DanderColors.surface,
        foregroundColor: DanderColors.onSurface,
      ),
      body: Column(
        children: [
          // Stats header
          Padding(
            padding: DanderSpacing.pagePadding.copyWith(
              top: DanderSpacing.xl,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                  label: 'Due',
                  value: '$dueCount',
                  color: dueCount > 0
                      ? DanderColors.rarityRare
                      : DanderColors.onSurfaceMuted,
                ),
                _StatChip(
                  label: 'Mastery',
                  value: '${masteryPct.toStringAsFixed(0)}%',
                  color: DanderColors.success,
                ),
                _StatChip(
                  label: 'Walked',
                  value: '${walkedStreets.length}',
                  color: DanderColors.onSurfaceMuted,
                ),
                _StatChip(
                  label: 'Mastered',
                  value: '$_masteredCount',
                  color: DanderColors.success,
                ),
              ],
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DanderSpacing.xl),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: dueCount > 0
                        ? onStartReview
                        : () => _showExploreFirst(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dueCount > 0
                          ? DanderColors.secondary
                          : DanderColors.cardBackground,
                      foregroundColor: dueCount > 0
                          ? DanderColors.onSurface
                          : DanderColors.onSurfaceMuted,
                      padding: const EdgeInsets.symmetric(
                        vertical: DanderSpacing.md + 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DanderSpacing.borderRadiusMd,
                        ),
                      ),
                    ),
                    child: Text(
                      dueCount > 0
                          ? 'Start Review ($dueCount)'
                          : 'Start Review',
                      style: DanderTextStyles.labelLarge,
                    ),
                  ),
                ),
                const SizedBox(height: DanderSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: walkedStreets.isNotEmpty
                        ? onPracticeAll
                        : () => _showExploreFirst(context),
                    child: Text(
                      'Practice All',
                      style: DanderTextStyles.bodyMediumMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: DanderColors.divider),
          // Streets list
          Expanded(
            child: walkedStreets.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DanderSpacing.xxl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_walk_rounded,
                            size: 64,
                            color: DanderColors.secondary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: DanderSpacing.lg),
                          Text(
                            'No streets explored yet',
                            style: DanderTextStyles.titleMedium.copyWith(
                              color: DanderColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: DanderSpacing.sm),
                          Text(
                            'Head to the Explore tab and go for a walk — '
                            'every street you visit will appear here '
                            'as a quiz question.',
                            textAlign: TextAlign.center,
                            style: DanderTextStyles.bodyMedium.copyWith(
                              color: DanderColors.onSurfaceMuted,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: walkedStreets.length,
                    itemBuilder: (context, index) {
                      final street = walkedStreets[index];
                      final level = _masteryLevelFor(street.id);
                      return ListTile(
                        title: Text(
                          street.name,
                          style: DanderTextStyles.bodyMedium,
                        ),
                        trailing: MasteryBadge(level: level),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: DanderTextStyles.headlineSmall.copyWith(
            color: color,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: DanderSpacing.xs / 2),
        Text(label, style: DanderTextStyles.labelSmall),
      ],
    );
  }
}
