import 'package:flutter/material.dart';

import '../../../walk/domain/models/walk_summary.dart';

/// Shareable card for the user's first-ever walk.
///
/// Fixed size 1080x1350 (portrait, optimised for Instagram Stories / 4:5).
/// Shows walk stats, a motivational tagline, and Dander branding.
/// Contains NO GPS coordinates, street names, or location-identifying data.
class FirstWalkShareCard extends StatelessWidget {
  const FirstWalkShareCard({super.key, required this.walkSummary});

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
            'First Exploration',
            style: TextStyle(
              color: Color(0xFF4FC3F7),
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
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
                  label: 'Discoveries',
                  value: '${walkSummary.discoveriesFound}',
                  valueKey: const Key('discoveries_found'),
                  icon: Icons.star_outline,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _StatCard(
                  label: 'Fog Cleared',
                  value:
                      '${walkSummary.fogClearedPercent.toStringAsFixed(1)}%',
                  valueKey: const Key('fog_cleared'),
                  icon: Icons.cloud_off_outlined,
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
        'My first steps into the unknown.',
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
          Icon(icon, color: const Color(0xFF4FC3F7), size: 40),
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
