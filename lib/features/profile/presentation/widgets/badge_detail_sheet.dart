import 'package:flutter/material.dart' hide Badge;
import 'package:dander/core/progress/badge.dart';
import 'package:dander/core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime dt) =>
    '${dt.day} ${_monthNames[dt.month - 1]} ${dt.year}';

/// A detail sheet for a single [Badge].
///
/// Shows badge icon, name, description, and either unlock date (if unlocked)
/// or progress toward unlock (if locked).
class BadgeDetailSheet extends StatelessWidget {
  const BadgeDetailSheet({
    super.key,
    required this.badge,
    required this.currentExplorationPct,
  });

  final Badge badge;
  final double currentExplorationPct;

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.isUnlocked;
    final requiredPct = (badge.requiredExplorationPct * 100).round();
    final currentPct = (currentExplorationPct * 100).round();

    return Padding(
      padding: DanderSpacing.pagePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: unlocked
                  ? DanderColors.secondary.withValues(alpha: 0.2)
                  : DanderColors.onSurfaceDisabled.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: unlocked
                    ? DanderColors.secondary
                    : DanderColors.divider,
                width: 2,
              ),
            ),
            child: Icon(
              badge.icon,
              color: unlocked
                  ? DanderColors.secondary
                  : DanderColors.onSurfaceDisabled,
              size: 36,
            ),
          ),
          const SizedBox(height: DanderSpacing.md),
          // Name
          Text(
            badge.name,
            style: DanderTextStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DanderSpacing.xs),
          // Description
          Text(
            badge.description,
            style: DanderTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DanderSpacing.lg),
          // Status
          if (unlocked) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DanderSpacing.md,
                vertical: DanderSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: DanderColors.secondary.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(DanderSpacing.borderRadiusMd),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: DanderColors.secondary,
                    size: 16,
                  ),
                  const SizedBox(width: DanderSpacing.sm),
                  Text(
                    'Unlocked ${_formatDate(badge.unlockedAt!)}',
                    style: DanderTextStyles.labelSmall.copyWith(
                      color: DanderColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Locked',
              style: DanderTextStyles.labelMedium.copyWith(
                color: DanderColors.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: DanderSpacing.sm),
            Text(
              '$currentPct% / $requiredPct% explored',
              style: DanderTextStyles.bodySmall,
            ),
            const SizedBox(height: DanderSpacing.sm),
            LinearProgressIndicator(
              value: requiredPct > 0
                  ? (currentExplorationPct / badge.requiredExplorationPct)
                      .clamp(0.0, 1.0)
                  : 0.0,
              backgroundColor:
                  DanderColors.onSurfaceDisabled.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                DanderColors.accent,
              ),
              minHeight: 4,
              borderRadius:
                  BorderRadius.circular(DanderSpacing.borderRadiusFull),
            ),
          ],
          const SizedBox(height: DanderSpacing.lg),
        ],
      ),
    );
  }
}
