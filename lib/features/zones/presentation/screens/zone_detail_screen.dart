import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/quiz/street_memory_record.dart';
import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/core/theme/dander_elevation.dart';
import 'package:dander/core/theme/rarity_colors.dart';
import 'package:dander/core/zone/zone.dart';
import 'package:dander/core/zone/zone_level.dart';
import 'package:dander/core/zone/zone_stats.dart';
import 'package:dander/core/zone/zone_stats_service.dart';
import 'package:dander/core/motion/dander_motion.dart';
import 'package:dander/shared/widgets/count_up_text.dart';

/// Detail screen for a single zone, showing progression, stats, discoveries,
/// and mastery — a "trophy case" for the user's exploration.
class ZoneDetailScreen extends StatefulWidget {
  const ZoneDetailScreen({
    super.key,
    required this.zone,
    required this.statsService,
  });

  final Zone zone;
  final ZoneStatsService statsService;

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen>
    with TickerProviderStateMixin {
  late Future<ZoneStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = widget.statsService.getStats(widget.zone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DanderColors.surfaceElevated,
      body: FutureBuilder<ZoneStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Column(
              children: [
                _BackHeader(zone: widget.zone),
                const Expanded(child: ZoneDetailLoadingSkeleton()),
              ],
            );
          }

          final stats = snapshot.data!;
          return _ZoneDetailBody(zone: widget.zone, stats: stats);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body — assembled sections
// ---------------------------------------------------------------------------

class _ZoneDetailBody extends StatefulWidget {
  const _ZoneDetailBody({required this.zone, required this.stats});

  final Zone zone;
  final ZoneStats stats;

  @override
  State<_ZoneDetailBody> createState() => _ZoneDetailBodyState();
}

class _ZoneDetailBodyState extends State<_ZoneDetailBody>
    with TickerProviderStateMixin {
  late final AnimationController _staggerController;
  final List<Animation<double>> _fadeAnimations = [];
  final List<Animation<Offset>> _slideAnimations = [];

  static const int _sectionCount = 5;
  static const Duration _staggerDelay = Duration(milliseconds: 40);
  static const Duration _animDuration = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();

    final totalDuration = Duration(
      milliseconds:
          _animDuration.inMilliseconds + (_sectionCount - 1) * _staggerDelay.inMilliseconds,
    );

    _staggerController = AnimationController(
      vsync: this,
      duration: totalDuration,
    );

    for (var i = 0; i < _sectionCount; i++) {
      final startFraction =
          (i * _staggerDelay.inMilliseconds) / totalDuration.inMilliseconds;
      final endFraction = (i * _staggerDelay.inMilliseconds +
              _animDuration.inMilliseconds) /
          totalDuration.inMilliseconds;

      final interval = Interval(
        startFraction.clamp(0.0, 1.0),
        endFraction.clamp(0.0, 1.0),
        curve: Curves.easeOut,
      );

      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _staggerController, curve: interval),
        ),
      );
      _slideAnimations.add(
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(parent: _staggerController, curve: interval),
        ),
      );
    }

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Widget _animatedSection(int index, Widget child) {
    if (DanderMotion.isReduced(context)) return child;
    return SlideTransition(
      position: _slideAnimations[index],
      child: FadeTransition(
        opacity: _fadeAnimations[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zone = widget.zone;
    final stats = widget.stats;
    final isEmpty = stats.streetsWalkedCount == 0 &&
        stats.discoveryCount == 0 &&
        stats.totalDistanceMeters == 0;

    return ListView(
      padding: EdgeInsets.only(
        bottom: DanderSpacing.lg +
            MediaQuery.of(context).padding.bottom +
            kBottomNavigationBarHeight,
      ),
      children: [
        _BackHeader(zone: zone),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DanderSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: DanderSpacing.lg),
              _animatedSection(
                0,
                _HeroHeader(zone: zone, explorationPct: stats.explorationPct),
              ),
              const SizedBox(height: DanderSpacing.lg),
              _animatedSection(1, _XpProgressCard(zone: zone)),
              const SizedBox(height: DanderSpacing.lg),
              if (isEmpty)
                _animatedSection(2, const _EmptyState())
              else ...[
                _animatedSection(2, _ExplorationStatsRow(stats: stats)),
                const SizedBox(height: DanderSpacing.lg),
                _animatedSection(3, _DiscoveryCard(stats: stats)),
                const SizedBox(height: DanderSpacing.lg),
                _animatedSection(4, _MasteryCard(stats: stats)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Back header with zone name
// ---------------------------------------------------------------------------

class _BackHeader extends StatelessWidget {
  const _BackHeader({required this.zone});

  final Zone zone;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DanderSpacing.sm,
        topPad + DanderSpacing.sm,
        DanderSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: DanderColors.onSurface),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: DanderSpacing.xs),
          Expanded(
            child: Text(
              zone.name,
              style: DanderTextStyles.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _LevelBadge(level: zone.level),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Level badge (reused from zone_card pattern)
// ---------------------------------------------------------------------------

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DanderSpacing.sm,
        vertical: DanderSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: DanderColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusSm),
      ),
      child: Text(
        'Lv.${level}',
        style: DanderTextStyles.labelMedium.copyWith(
          color: DanderColors.accent,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero header — exploration ring + created date
// ---------------------------------------------------------------------------

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.zone, required this.explorationPct});

  final Zone zone;
  final double explorationPct;

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime date) {
    final month = _monthNames[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (explorationPct * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DanderSpacing.xl,
        vertical: DanderSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
        border: Border.all(color: DanderColors.cardBorder, width: 0.5),
        boxShadow: DanderElevation.level1,
      ),
      child: Column(
        children: [
          Text(
            'Created ${_formatDate(zone.createdAt)}',
            style: DanderTextStyles.bodySmall,
          ),
          const SizedBox(height: DanderSpacing.xl),
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _RingPainter(fraction: explorationPct),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CountUpText(
                      value: percentage,
                      style: DanderTextStyles.headlineLarge,
                      suffix: '%',
                    ),
                    Text('explored', style: DanderTextStyles.bodySmall),
                  ],
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
      ..color = DanderColors.accent
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
// XP progress card
// ---------------------------------------------------------------------------

class _XpProgressCard extends StatelessWidget {
  const _XpProgressCard({required this.zone});

  final Zone zone;

  String _formatRadius(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return km == km.truncateToDouble() ? '${km.toInt()}km' : '${km}km';
    }
    return '${meters.toInt()}m';
  }

  @override
  Widget build(BuildContext context) {
    final nextLevelXp = zone.xpForNextLevel;
    final isMaxLevel = nextLevelXp == null;
    final currentRadius = _formatRadius(zone.radiusMeters);

    // Progress fraction
    double progress;
    if (isMaxLevel) {
      progress = 1.0;
    } else {
      final currentLevelXp = ZoneLevel.xpForLevel(zone.level);
      final span = nextLevelXp - currentLevelXp;
      final earned = zone.xp - currentLevelXp;
      progress = span > 0 ? (earned / span).clamp(0.0, 1.0) : 1.0;
    }

    return Container(
      padding: DanderSpacing.cardPadding,
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
        border: Border.all(color: DanderColors.cardBorder, width: 0.5),
        boxShadow: DanderElevation.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMaxLevel)
            Text(
              '${zone.xp} XP · Max level reached',
              style: DanderTextStyles.bodyMedium.copyWith(
                color: DanderColors.accent,
              ),
            )
          else
            Text(
              '${zone.xp} / $nextLevelXp XP',
              style: DanderTextStyles.bodyMedium,
            ),
          const SizedBox(height: DanderSpacing.sm),
          LinearProgressIndicator(
            value: progress,
            backgroundColor:
                DanderColors.onSurfaceDisabled.withValues(alpha: 0.3),
            valueColor:
                const AlwaysStoppedAnimation<Color>(DanderColors.accent),
            minHeight: 6,
            borderRadius:
                BorderRadius.circular(DanderSpacing.borderRadiusFull),
          ),
          const SizedBox(height: DanderSpacing.sm),
          if (!isMaxLevel)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentRadius radius',
                  style: DanderTextStyles.labelSmall,
                ),
                Text(
                  '→',
                  style: DanderTextStyles.labelSmall.copyWith(
                    color: DanderColors.onSurfaceMuted,
                  ),
                ),
                Text(
                  '${_formatRadius(ZoneLevel.radiusForXp(nextLevelXp))} radius',
                  style: DanderTextStyles.labelSmall.copyWith(
                    color: DanderColors.accent,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exploration stats row
// ---------------------------------------------------------------------------

class _ExplorationStatsRow extends StatelessWidget {
  const _ExplorationStatsRow({required this.stats});

  final ZoneStats stats;

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: DanderSpacing.cardPadding,
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
        border: Border.all(color: DanderColors.cardBorder, width: 0.5),
        boxShadow: DanderElevation.level1,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              icon: Icons.route,
              value: stats.streetsWalkedCount,
              label: 'Streets',
            ),
          ),
          Container(width: 1, height: 40, color: DanderColors.divider),
          Expanded(
            child: _StatColumn(
              icon: Icons.explore,
              value: stats.discoveryCount,
              label: 'Discoveries',
            ),
          ),
          Container(width: 1, height: 40, color: DanderColors.divider),
          Expanded(
            child: _StatColumnText(
              icon: Icons.straighten,
              value: _formatDistance(stats.totalDistanceMeters),
              label: 'Distance',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: DanderColors.accent, size: 24),
        const SizedBox(height: DanderSpacing.xs),
        CountUpText(
          value: value,
          style: DanderTextStyles.titleLarge,
        ),
        Text(label, style: DanderTextStyles.bodySmall),
      ],
    );
  }
}

class _StatColumnText extends StatelessWidget {
  const _StatColumnText({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: DanderColors.accent, size: 24),
        const SizedBox(height: DanderSpacing.xs),
        Text(value, style: DanderTextStyles.titleLarge),
        Text(label, style: DanderTextStyles.bodySmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Discovery card — rarity rows + category chips
// ---------------------------------------------------------------------------

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({required this.stats});

  final ZoneStats stats;

  int _rarityCount(RarityTier tier) =>
      stats.discoveriesByRarity[tier] ?? 0;

  @override
  Widget build(BuildContext context) {
    final categories = stats.discoveriesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: DanderSpacing.cardPadding,
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
        border: Border.all(color: DanderColors.cardBorder, width: 0.5),
        boxShadow: DanderElevation.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Discoveries', style: DanderTextStyles.titleLarge),
          const SizedBox(height: DanderSpacing.xs),
          Text(
            '${stats.discoveryCount} found',
            style: DanderTextStyles.bodySmall,
          ),
          const SizedBox(height: DanderSpacing.lg),

          // Rarity rows
          _RarityRow(tier: RarityTier.legendary, count: _rarityCount(RarityTier.legendary)),
          const SizedBox(height: DanderSpacing.sm),
          _RarityRow(tier: RarityTier.rare, count: _rarityCount(RarityTier.rare)),
          const SizedBox(height: DanderSpacing.sm),
          _RarityRow(tier: RarityTier.uncommon, count: _rarityCount(RarityTier.uncommon)),
          const SizedBox(height: DanderSpacing.sm),
          _RarityRow(tier: RarityTier.common, count: _rarityCount(RarityTier.common)),

          if (categories.isNotEmpty) ...[
            const SizedBox(height: DanderSpacing.lg),
            Wrap(
              spacing: DanderSpacing.sm,
              runSpacing: DanderSpacing.sm,
              children: categories.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DanderSpacing.sm,
                    vertical: DanderSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: DanderColors.accent.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(DanderSpacing.borderRadiusFull),
                  ),
                  child: Text(
                    '${entry.key} ${entry.value}',
                    style: DanderTextStyles.labelSmall.copyWith(
                      color: DanderColors.accent,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

// ---------------------------------------------------------------------------
// Mastery card — segmented bar + state counts
// ---------------------------------------------------------------------------

class _MasteryCard extends StatelessWidget {
  const _MasteryCard({required this.stats});

  final ZoneStats stats;

  int _count(MemoryState state) => stats.masteryStates[state] ?? 0;

  @override
  Widget build(BuildContext context) {
    final mastered = _count(MemoryState.mastered);
    final review = _count(MemoryState.review);
    final learning = _count(MemoryState.learning);
    final newCards = _count(MemoryState.newCard);
    final total = mastered + review + learning + newCards;

    final masteryPct = total > 0 ? (mastered / total * 100).round() : 0;

    return Container(
      padding: DanderSpacing.cardPadding,
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
        border: Border.all(color: DanderColors.cardBorder, width: 0.5),
        boxShadow: DanderElevation.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Quiz Mastery', style: DanderTextStyles.titleLarge),
              const Spacer(),
              Text(
                '$masteryPct%',
                style: DanderTextStyles.titleLarge.copyWith(
                  color: DanderColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: DanderSpacing.md),

          // Segmented bar
          if (total > 0)
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(DanderSpacing.borderRadiusFull),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (mastered > 0)
                      Expanded(
                        flex: mastered,
                        child: Container(color: DanderColors.success),
                      ),
                    if (review > 0)
                      Expanded(
                        flex: review,
                        child: Container(color: DanderColors.accent),
                      ),
                    if (learning > 0)
                      Expanded(
                        flex: learning,
                        child: Container(color: DanderColors.streakAtRisk),
                      ),
                    if (newCards > 0)
                      Expanded(
                        flex: newCards,
                        child: Container(
                          color: DanderColors.onSurfaceDisabled
                              .withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: DanderSpacing.md),

          // State count rows
          _MasteryStateRow(
            label: 'Mastered',
            count: mastered,
            color: DanderColors.success,
          ),
          const SizedBox(height: DanderSpacing.xs),
          _MasteryStateRow(
            label: 'Review',
            count: review,
            color: DanderColors.accent,
          ),
          const SizedBox(height: DanderSpacing.xs),
          _MasteryStateRow(
            label: 'Learning',
            count: learning,
            color: DanderColors.streakAtRisk,
          ),
          const SizedBox(height: DanderSpacing.xs),
          _MasteryStateRow(
            label: 'New',
            count: newCards,
            color: DanderColors.onSurfaceDisabled,
          ),
        ],
      ),
    );
  }
}

class _MasteryStateRow extends StatelessWidget {
  const _MasteryStateRow({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: DanderSpacing.sm),
        Text(label, style: DanderTextStyles.bodySmall),
        const Spacer(),
        Text(
          '$count',
          style: DanderTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DanderSpacing.xl,
        vertical: DanderSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
        border: Border.all(color: DanderColors.cardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(
            Icons.explore_outlined,
            color: DanderColors.onSurfaceMuted,
            size: 48,
          ),
          const SizedBox(height: DanderSpacing.md),
          Text(
            'Start exploring this zone!',
            style: DanderTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DanderSpacing.sm),
          Text(
            'Walk around your neighbourhood to discover streets, '
            'find hidden gems, and build your knowledge.',
            style: DanderTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

class ZoneDetailLoadingSkeleton extends StatelessWidget {
  const ZoneDetailLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DanderSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: DanderSpacing.lg),
          _SkeletonBox(height: 220),
          const SizedBox(height: DanderSpacing.lg),
          _SkeletonBox(height: 100),
          const SizedBox(height: DanderSpacing.lg),
          _SkeletonBox(height: 80),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: DanderColors.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
      ),
    );
  }
}
