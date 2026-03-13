import 'package:flutter/material.dart';

import 'package:dander/core/quiz/quiz_session.dart';
import 'package:dander/core/quiz/quiz_streak_tracker.dart';

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
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text('Session Complete'),
        backgroundColor: const Color(0xFF0D0D1A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Score
              _StatRow(
                icon: Icons.check_circle_outline,
                label: 'Score',
                value: '$correct / $total',
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              // Accuracy
              _StatRow(
                icon: Icons.percent,
                label: 'Accuracy',
                value: '$accuracyPct%',
                color: accuracyPct >= 80 ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 16),
              // Mastered
              _StatRow(
                icon: Icons.star,
                label: 'Mastered this session',
                value: '$masteredThisSession',
                color: const Color(0xFFFFD700),
              ),
              const SizedBox(height: 16),
              // Streak
              _StatRow(
                icon: Icons.local_fire_department,
                label: 'Quiz streak',
                value: '${streak.currentStreak} week${streak.currentStreak == 1 ? '' : 's'}',
                color: Colors.orange,
              ),
              const Spacer(),
              // Start Another
              ElevatedButton(
                onPressed: onStartAnother,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Another',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Go Explore
              OutlinedButton(
                onPressed: onGoExplore,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Go Explore',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
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
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
