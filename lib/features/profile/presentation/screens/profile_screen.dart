import 'dart:math' as math;

import 'package:flutter/material.dart' hide Badge;
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/progress/badge.dart';
import 'package:dander/core/progress/streak_tracker.dart';
import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/core/theme/rarity_colors.dart';
import 'package:dander/shared/widgets/dander_logo.dart';

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
      backgroundColor: DanderColors.surfaceElevated,
      appBar: AppBar(
        backgroundColor: DanderColors.surfaceElevated,
        foregroundColor: DanderColors.onSurface,
        title: Text(
          'Profile',
          style: DanderTextStyles.titleLarge,
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: DanderSpacing.pagePadding.copyWith(
          bottom: DanderSpacing.pagePadding.bottom +
              MediaQuery.of(context).padding.bottom +
              kBottomNavigationBarHeight,
        ),
        children: [
          // Logo header
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: DanderSpacing.xl),
              child: DanderLogo(size: 72),
            ),
          ),
          _ExplorationRing(pct: explorationPct),
          const SizedBox(height: DanderSpacing.lg),
          _StreakCard(streak: streak),
          const SizedBox(height: DanderSpacing.lg),
          _BadgeGrid(badges: badges),
          const SizedBox(height: DanderSpacing.lg),
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
      padding: DanderSpacing.cardPadding.copyWith(
        top: DanderSpacing.xl,
        bottom: DanderSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
      ),
      child: Column(
        children: [
          Text(
            'Neighbourhood Explored',
            style: DanderTextStyles.titleMedium,
          ),
          const SizedBox(height: DanderSpacing.lg),
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: _RingPainter(fraction: pct),
              child: Center(
                child: Text(
                  '$percentage%',
                  style: DanderTextStyles.headlineMedium,
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
      ..color = DanderColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    final progressPaint = Paint()
      ..color = DanderColors.secondary
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
      padding: DanderSpacing.cardPadding,
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            color: isActive
                ? DanderColors.streakActive
                : isAtRisk
                    ? DanderColors.streakAtRisk
                    : DanderColors.onSurfaceDisabled,
            size: 36,
          ),
          const SizedBox(width: DanderSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weekly Streak', style: DanderTextStyles.bodySmall),
              Text(
                '${streak.currentStreak} week${streak.currentStreak == 1 ? '' : 's'}',
                style: DanderTextStyles.titleLarge,
              ),
            ],
          ),
          if (isAtRisk) ...[
            const Spacer(),
            Text(
              'At risk!',
              style: DanderTextStyles.labelMedium.copyWith(
                color: DanderColors.streakAtRisk,
              ),
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
      padding: DanderSpacing.cardPadding,
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Badges', style: DanderTextStyles.titleLarge),
          const SizedBox(height: DanderSpacing.lg),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: DanderSpacing.md,
              crossAxisSpacing: DanderSpacing.md,
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
                ? DanderColors.secondary.withValues(alpha: 0.2)
                : DanderColors.onSurfaceDisabled.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: unlocked ? DanderColors.secondary : DanderColors.divider,
              width: 2,
            ),
          ),
          child: Icon(
            badge.icon,
            color: unlocked
                ? DanderColors.secondary
                : DanderColors.onSurfaceDisabled,
            size: 28,
          ),
        ),
        const SizedBox(height: DanderSpacing.xs + 2),
        Text(
          badge.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: DanderTextStyles.labelSmall.copyWith(
            color: unlocked
                ? DanderColors.onSurface
                : DanderColors.onSurfaceDisabled,
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
      padding: DanderSpacing.cardPadding,
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Discoveries', style: DanderTextStyles.titleLarge),
          const SizedBox(height: DanderSpacing.xs),
          Text('$total total', style: DanderTextStyles.bodySmall),
          const SizedBox(height: DanderSpacing.lg),
          _RarityRow(tier: RarityTier.rare, count: rareCount),
          const SizedBox(height: DanderSpacing.sm),
          _RarityRow(tier: RarityTier.uncommon, count: uncommonCount),
          const SizedBox(height: DanderSpacing.sm),
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
        const SizedBox(width: DanderSpacing.sm),
        Text(
          label,
          style: DanderTextStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          '$count',
          style: DanderTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
