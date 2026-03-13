import 'dart:math' as math;

import 'package:flutter/material.dart' hide Badge;
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/progress/badge.dart';
import 'package:dander/core/progress/streak_tracker.dart';
import 'package:dander/core/theme/rarity_colors.dart';

/// Profile screen showing exploration progress, streak, badges, and discoveries.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.discoveries,
    required this.explorationPct,
    required this.streak,
    required this.badges,
  });

  /// All discoveries the user has collected.
  final List<Discovery> discoveries;

  /// Current exploration fraction (0.0–1.0).
  final double explorationPct;

  /// Weekly streak state.
  final StreakTracker streak;

  /// Badge definitions with unlock state.
  final List<Badge> badges;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        foregroundColor: Colors.white,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ExplorationRing(pct: explorationPct),
          const SizedBox(height: 16),
          _StreakCard(streak: streak),
          const SizedBox(height: 16),
          _BadgeGrid(badges: badges),
          const SizedBox(height: 16),
          _DiscoveryStatsSection(discoveries: discoveries),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exploration ring
// ---------------------------------------------------------------------------

class _ExplorationRing extends StatelessWidget {
  const _ExplorationRing({required this.pct});

  final double pct;

  @override
  Widget build(BuildContext context) {
    final percentage = (pct * 100).round();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Neighbourhood Explored',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: _RingPainter(fraction: pct),
              child: Center(
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.fraction});

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 8;

    final trackPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    final progressPaint = Paint()
      ..color = const Color(0xFF6E56CF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * math.pi * fraction.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}

// ---------------------------------------------------------------------------
// Streak card
// ---------------------------------------------------------------------------

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final StreakTracker streak;

  @override
  Widget build(BuildContext context) {
    final isAtRisk = streak.isAtRisk;
    final isActive = streak.isActiveThisWeek;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            color: isActive
                ? const Color(0xFFFF6B35)
                : isAtRisk
                    ? Colors.orange
                    : Colors.white30,
            size: 36,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weekly Streak',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
              Text(
                '${streak.currentStreak} week${streak.currentStreak == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (isAtRisk) ...[
            const Spacer(),
            const Text(
              'At risk!',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badge grid
// ---------------------------------------------------------------------------

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges});

  final List<Badge> badges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Badges',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) => _BadgeTile(badge: badges[index]),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final Badge badge;

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.isUnlocked;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: unlocked
                ? const Color(0xFF6E56CF).withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: unlocked ? const Color(0xFF6E56CF) : Colors.white24,
              width: 2,
            ),
          ),
          child: Icon(
            badge.icon,
            color: unlocked ? const Color(0xFF6E56CF) : Colors.white24,
            size: 28,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          badge.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: unlocked ? Colors.white : Colors.white38,
            fontSize: 11,
            fontWeight: unlocked ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Discovery stats section
// ---------------------------------------------------------------------------

class _DiscoveryStatsSection extends StatelessWidget {
  const _DiscoveryStatsSection({required this.discoveries});

  final List<Discovery> discoveries;

  int _count(RarityTier tier) =>
      discoveries.where((d) => d.rarity == tier).length;

  @override
  Widget build(BuildContext context) {
    final total = discoveries.length;
    final rareCount = _count(RarityTier.rare);
    final uncommonCount = _count(RarityTier.uncommon);
    final commonCount = _count(RarityTier.common);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discoveries',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$total total',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _RarityRow(tier: RarityTier.rare, count: rareCount),
          const SizedBox(height: 8),
          _RarityRow(tier: RarityTier.uncommon, count: uncommonCount),
          const SizedBox(height: 8),
          _RarityRow(tier: RarityTier.common, count: commonCount),
        ],
      ),
    );
  }
}

class _RarityRow extends StatelessWidget {
  const _RarityRow({required this.tier, required this.count});

  final RarityTier tier;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = RarityColors.forTier(tier);
    final label = RarityColors.label(tier);

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
