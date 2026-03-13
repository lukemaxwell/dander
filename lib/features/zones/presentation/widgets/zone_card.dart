import 'package:flutter/material.dart';
import 'package:dander/core/zone/zone.dart';
import 'package:dander/core/zone/zone_level.dart';
import 'package:dander/core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Month name helper (immutable constant — no mutation)
// ---------------------------------------------------------------------------

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime dt) =>
    '${dt.day} ${_monthNames[dt.month - 1]} ${dt.year}';

/// Computes the XP progress fraction toward the next level.
///
/// Returns 1.0 when the zone is at max level.
double _xpProgress(Zone zone) {
  final nextLevelXp = zone.xpForNextLevel;
  if (nextLevelXp == null) return 1.0;

  // XP threshold for the current level start.
  final currentLevelXp = ZoneLevel.xpForLevel(zone.level);

  final span = nextLevelXp - currentLevelXp;
  if (span <= 0) return 1.0;

  final earned = zone.xp - currentLevelXp;
  return (earned / span).clamp(0.0, 1.0);
}

/// A card representing a single [Zone] in the zones list.
///
/// Shows the zone name, level badge, XP progress bar, streets explored
/// placeholder, and creation date.  When [isActive] is `true` the card
/// gains a highlighted border using [DanderColors.accent].
class ZoneCard extends StatelessWidget {
  const ZoneCard({
    super.key,
    required this.zone,
    required this.isActive,
    this.onTap,
    this.onDelete,
  });

  /// The zone to display.
  final Zone zone;

  /// Whether this is the currently active zone.
  final bool isActive;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Called when the user confirms deletion of this zone.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = _xpProgress(zone);
    final nextXp = zone.xpForNextLevel;
    final isMaxLevel = nextXp == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DanderColors.cardBackground,
          borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
          border: isActive
              ? Border.all(
                  color: DanderColors.accent,
                  width: 1.5,
                )
              : null,
        ),
        padding: DanderSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(zone: zone, isMaxLevel: isMaxLevel, onDelete: onDelete),
            const SizedBox(height: DanderSpacing.sm),
            _XpRow(
              zone: zone,
              nextXp: nextXp,
              isMaxLevel: isMaxLevel,
            ),
            const SizedBox(height: DanderSpacing.xs),
            LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  DanderColors.onSurfaceDisabled.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                DanderColors.accent,
              ),
              minHeight: 4,
              borderRadius:
                  BorderRadius.circular(DanderSpacing.borderRadiusFull),
            ),
            const SizedBox(height: DanderSpacing.sm),
            _Footer(zone: zone),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.zone,
    required this.isMaxLevel,
    this.onDelete,
  });

  final Zone zone;
  final bool isMaxLevel;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            zone.name,
            style: DanderTextStyles.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: DanderSpacing.sm),
        _LevelBadge(level: zone.level),
        if (onDelete != null) ...[
          const SizedBox(width: DanderSpacing.sm),
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(DanderSpacing.xs),
              child: Icon(
                Icons.delete_outline,
                color: DanderColors.onSurfaceMuted,
                size: 20,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

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
        'L$level',
        style: DanderTextStyles.labelMedium.copyWith(
          color: DanderColors.accent,
        ),
      ),
    );
  }
}

class _XpRow extends StatelessWidget {
  const _XpRow({
    required this.zone,
    required this.nextXp,
    required this.isMaxLevel,
  });

  final Zone zone;
  final int? nextXp;
  final bool isMaxLevel;

  @override
  Widget build(BuildContext context) {
    final xpLabel = isMaxLevel
        ? '${zone.xp} XP · Max level'
        : '${zone.xp} / $nextXp XP';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(xpLabel, style: DanderTextStyles.bodySmall),
        // Streets explored placeholder (will be wired to real data later)
        Row(
          children: [
            Text('—', style: DanderTextStyles.bodySmall),
            const SizedBox(width: DanderSpacing.xs),
            Text('streets', style: DanderTextStyles.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.zone});

  final Zone zone;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Created ${_formatDate(zone.createdAt)}',
      style: DanderTextStyles.labelSmall,
    );
  }
}
