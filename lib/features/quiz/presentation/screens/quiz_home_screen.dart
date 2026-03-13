import 'package:flutter/material.dart';

import 'package:dander/core/quiz/quiz_scheduler.dart';
import 'package:dander/core/quiz/street_memory_record.dart';
import 'package:dander/core/streets/street.dart';

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
      MasteryLevel.newStreet => (const Color(0xFF7C3AED), 'New'),
      MasteryLevel.learning => (Colors.orange, 'Learning'),
      MasteryLevel.review => (Colors.blue, 'Review'),
      MasteryLevel.mastered => (Colors.green, 'Mastered'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12),
        ),
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
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text('Quiz'),
        backgroundColor: const Color(0xFF0D0D1A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Stats header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                  label: 'Due',
                  value: '$dueCount',
                  color: dueCount > 0 ? const Color(0xFFFFD700) : Colors.white54,
                ),
                _StatChip(
                  label: 'Mastery',
                  value: '${masteryPct.toStringAsFixed(0)}%',
                  color: Colors.green,
                ),
                _StatChip(
                  label: 'Walked',
                  value: '${walkedStreets.length}',
                  color: Colors.white70,
                ),
                _StatChip(
                  label: 'Mastered',
                  value: '$_masteredCount',
                  color: Colors.green,
                ),
              ],
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: dueCount > 0 ? onStartReview : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      disabledBackgroundColor: Colors.white12,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Start Review${dueCount > 0 ? ' ($dueCount)' : ''}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: walkedStreets.isNotEmpty ? onPracticeAll : null,
                    child: const Text(
                      'Practice All',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          // Streets list
          Expanded(
            child: walkedStreets.isEmpty
                ? const Center(
                    child: Text(
                      'Walk some streets to start quizzing!',
                      style: TextStyle(color: Colors.white38),
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
                          style: const TextStyle(color: Colors.white),
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
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}
