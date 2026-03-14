import 'package:flutter/material.dart';

import '../../../walk/domain/models/weekly_summary.dart';

/// Shareable weekly walk summary card.
///
/// Fixed size 1080x1350 (portrait, optimised for Instagram Stories / 4:5).
/// Shows aggregate weekly stats: walks, distance, active days, fog cleared,
/// streak, and a CTA question for viewers. No location data.
class WeeklyWalkShareCard extends StatelessWidget {
  const WeeklyWalkShareCard({super.key, required this.summary});

  final WeeklySummary summary;

  static const double cardWidth = 1080;
  static const double cardHeight = 1350;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E)],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildStats()),
            _buildTagline(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final dateRange = _formatDateRange(summary.weekStart);
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 60, 48, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC3F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'D',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Dander',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Weekly Walk',
            style: TextStyle(
              color: Color(0xFF4FC3F7),
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateRange,
            key: const Key('week_dates'),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 28,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final distanceStr = summary.totalDistanceKm >= 1
        ? '${summary.totalDistanceKm.toStringAsFixed(1)} km'
        : '${summary.totalDistanceMetres.toStringAsFixed(0)} m';
    final fogStr = '${summary.fogClearedPercent.toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 48, 48, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Distance',
                  value: distanceStr,
                  icon: Icons.straighten_outlined,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _StatCard(
                  label: 'Walks',
                  value: '${summary.totalWalks}',
                  icon: Icons.directions_walk_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Active Days',
                  value: '${summary.activeDays}',
                  icon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _StatCard(
                  label: 'Fog Cleared',
                  value: fogStr,
                  icon: Icons.cloud_off_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Streak',
                  value: '${summary.currentStreak}',
                  icon: Icons.local_fire_department_outlined,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _StatCard(
                  label: 'Discoveries',
                  value: '${summary.totalDiscoveries}',
                  icon: Icons.star_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagline() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: Text(
        'How well do you know your neighbourhood?',
        key: Key('tagline'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white60,
          fontSize: 36,
          fontWeight: FontWeight.w300,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(48, 0, 48, 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'dander.app',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 28,
              fontWeight: FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final startMonth = months[weekStart.month - 1];
    final endMonth = months[weekEnd.month - 1];
    if (startMonth == endMonth) {
      return '${weekStart.day} – ${weekEnd.day} $startMonth ${weekEnd.year}';
    }
    return '${weekStart.day} $startMonth – ${weekEnd.day} $endMonth ${weekEnd.year}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF4FC3F7), size: 40),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 24,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
