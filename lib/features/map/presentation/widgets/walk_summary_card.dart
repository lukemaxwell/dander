import 'package:flutter/material.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/core/location/walk_stats_formatter.dart';
import 'package:dander/core/theme/app_theme.dart';

/// A card shown at the end of a walk summarising key stats.
///
/// Intended to be displayed as a modal bottom sheet (or embedded in a sheet
/// by the caller).  Provides a "Share" placeholder and a "Done" button.
class WalkSummaryCard extends StatelessWidget {
  const WalkSummaryCard({
    super.key,
    required this.session,
    required this.fogClearedPercent,
    required this.discoveriesFound,
    required this.onDone,
    required this.onShare,
  });

  /// The completed [WalkSession].
  final WalkSession session;

  /// Percentage of fog cleared during this walk (0–100).
  final double fogClearedPercent;

  /// Number of new discoveries found during this walk.
  final int discoveriesFound;

  /// Called when the user taps "Done".
  final VoidCallback onDone;

  /// Called when the user taps "Share" (placeholder for Issue #8).
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final duration = WalkStatsFormatter.formatDuration(session.duration);
    final distance = WalkStatsFormatter.formatDistance(session.distanceMeters);
    final fogLabel = WalkStatsFormatter.formatFogCleared(fogClearedPercent);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        DanderSpacing.xl,
        DanderSpacing.xl,
        DanderSpacing.xl,
        DanderSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DanderSpacing.borderRadiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: DanderSpacing.lg),
              decoration: BoxDecoration(
                color: DanderColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Text(
            'Walk Complete',
            textAlign: TextAlign.center,
            style: DanderTextStyles.headlineSmall,
          ),
          const SizedBox(height: DanderSpacing.xl),
          // Stats grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatTile(label: 'Duration', value: duration),
              _StatTile(label: 'Distance', value: distance),
            ],
          ),
          const SizedBox(height: DanderSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatTile(label: 'Fog Cleared', value: fogLabel),
              _StatTile(label: 'Discoveries', value: '$discoveriesFound'),
            ],
          ),
          const SizedBox(height: DanderSpacing.xxl),
          // Share button (placeholder)
          OutlinedButton(
            onPressed: onShare,
            style: OutlinedButton.styleFrom(
              foregroundColor: DanderColors.secondary,
              side: const BorderSide(color: DanderColors.secondary),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  DanderSpacing.borderRadiusMd + 2,
                ),
              ),
            ),
            child: Text(
              'Share',
              style: DanderTextStyles.labelLarge.copyWith(
                color: DanderColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: DanderSpacing.md),
          // Done button
          ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: DanderColors.secondary,
              foregroundColor: DanderColors.onSurface,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  DanderSpacing.borderRadiusMd + 2,
                ),
              ),
              elevation: 0,
            ),
            child: Text('Done', style: DanderTextStyles.labelLarge),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: DanderSpacing.md + 2,
          horizontal: DanderSpacing.sm,
        ),
        margin: const EdgeInsets.symmetric(horizontal: DanderSpacing.xs),
        decoration: BoxDecoration(
          color: DanderColors.surfaceElevated,
          borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: DanderTextStyles.titleLarge.copyWith(fontSize: 20),
            ),
            const SizedBox(height: DanderSpacing.xs),
            Text(label, style: DanderTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }
}
