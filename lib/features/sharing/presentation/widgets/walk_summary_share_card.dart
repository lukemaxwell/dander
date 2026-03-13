import 'package:flutter/material.dart';

import '../../../walk/domain/models/walk_summary.dart';

/// Shareable post-walk stats card.
///
/// Fixed size 1080x1350 (portrait, optimised for Instagram Stories / 4:5).
/// Shows walk date, duration, distance, fog cleared %, discoveries found,
/// Dander branding, and a motivational tagline.
class WalkSummaryShareCard extends StatelessWidget {
  const WalkSummaryShareCard({super.key, required this.walkSummary});

  final WalkSummary walkSummary;

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
    final dateStr = _formatDate(walkSummary.startedAt);
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 60, 48, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DanderLogo(),
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
            'Walk Summary',
            style: TextStyle(
              color: Color(0xFF6C63FF),
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateStr,
            key: const Key('walk_date'),
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
    final durationStr = _formatDuration(walkSummary.duration);
    final distanceStr = walkSummary.distanceKm >= 1
        ? '${walkSummary.distanceKm.toStringAsFixed(1)} km'
        : '${walkSummary.distanceMetres.toStringAsFixed(0)} m';
    final fogStr = '${walkSummary.fogClearedPercent.toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 48, 48, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Duration',
                  value: durationStr,
                  valueKey: const Key('walk_duration'),
                  icon: Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _StatCard(
                  label: 'Distance',
                  value: distanceStr,
                  valueKey: const Key('walk_distance'),
                  icon: Icons.straighten_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Fog Cleared',
                  value: fogStr,
                  valueKey: const Key('fog_cleared'),
                  icon: Icons.cloud_off_outlined,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _StatCard(
                  label: 'Discoveries',
                  value: '${walkSummary.discoveriesFound}',
                  valueKey: const Key('discoveries_found'),
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
        'Every street tells a story.',
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
            key: Key('watermark'),
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

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueKey,
  });

  final String label;
  final String value;
  final IconData icon;
  final Key? valueKey;

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
          Icon(icon, color: const Color(0xFF6C63FF), size: 40),
          const SizedBox(height: 16),
          Text(
            value,
            key: valueKey,
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

class _DanderLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF),
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
    );
  }
}
