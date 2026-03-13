import 'package:flutter/material.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/core/location/walk_stats_formatter.dart';
import 'package:dander/core/theme/app_theme.dart';

/// A floating bottom panel that controls walk sessions.
///
/// Displays two distinct states:
/// - **Idle**: a single "Start Walk" pill button.
/// - **Active**: live stats (duration, distance, discoveries) plus "End Walk".
///
/// The parent is responsible for driving state via [session] and wiring the
/// [onStart] / [onStop] callbacks to [WalkService].
class WalkControl extends StatelessWidget {
  const WalkControl({
    super.key,
    required this.session,
    required this.onStart,
    required this.onStop,
    this.discoveriesThisWalk = 0,
  });

  /// The active [WalkSession], or `null` when no walk is in progress.
  final WalkSession? session;

  /// Called when the user taps "Start Walk".
  final VoidCallback onStart;

  /// Called with the current [WalkSession] when the user taps "End Walk".
  final void Function(WalkSession session) onStop;

  /// Number of discoveries found during the active walk.
  final int discoveriesThisWalk;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: DanderSpacing.lg,
      right: DanderSpacing.lg,
      bottom: DanderSpacing.xl,
      child: _Panel(
        session: session,
        onStart: onStart,
        onStop: onStop,
        discoveriesThisWalk: discoveriesThisWalk,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal panel widget — animates between idle and active states.
// ---------------------------------------------------------------------------

class _Panel extends StatelessWidget {
  const _Panel({
    required this.session,
    required this.onStart,
    required this.onStop,
    required this.discoveriesThisWalk,
  });

  final WalkSession? session;
  final VoidCallback onStart;
  final void Function(WalkSession) onStop;
  final int discoveriesThisWalk;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: session == null
          ? _IdlePanel(key: const ValueKey('idle'), onStart: onStart)
          : _ActivePanel(
              key: const ValueKey('active'),
              session: session!,
              onStop: onStop,
              discoveriesThisWalk: discoveriesThisWalk,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Idle state
// ---------------------------------------------------------------------------

class _IdlePanel extends StatelessWidget {
  const _IdlePanel({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: DanderSpacing.cardPadding,
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusXl - 4),
        boxShadow: DanderElevation.level2,
      ),
      child: ElevatedButton(
        onPressed: onStart,
        style: ElevatedButton.styleFrom(
          backgroundColor: DanderColors.secondary,
          foregroundColor: DanderColors.onSurface,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(DanderSpacing.borderRadiusMd + 2),
          ),
          elevation: 0,
        ),
        child: Text(
          'Start Walk',
          style: DanderTextStyles.titleMedium,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active state
// ---------------------------------------------------------------------------

class _ActivePanel extends StatelessWidget {
  const _ActivePanel({
    super.key,
    required this.session,
    required this.onStop,
    required this.discoveriesThisWalk,
  });

  final WalkSession session;
  final void Function(WalkSession) onStop;
  final int discoveriesThisWalk;

  @override
  Widget build(BuildContext context) {
    final duration = WalkStatsFormatter.formatDuration(session.duration);
    final distance = WalkStatsFormatter.formatDistance(session.distanceMeters);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DanderSpacing.lg,
        vertical: DanderSpacing.md + 2,
      ),
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusXl - 4),
        boxShadow: DanderElevation.level2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatCell(label: 'Duration', value: duration),
              _StatDivider(),
              _StatCell(label: 'Distance', value: distance),
              _StatDivider(),
              _StatCell(
                label: 'Discoveries',
                value: '$discoveriesThisWalk',
              ),
            ],
          ),
          const SizedBox(height: DanderSpacing.md),
          // End walk button
          ElevatedButton(
            onPressed: () => onStop(session),
            style: ElevatedButton.styleFrom(
              backgroundColor: DanderColors.error,
              foregroundColor: DanderColors.onSurface,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  DanderSpacing.borderRadiusMd + 2,
                ),
              ),
              elevation: 0,
            ),
            child: Text('End Walk', style: DanderTextStyles.titleMedium),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: DanderTextStyles.titleMedium.copyWith(fontSize: 18),
        ),
        const SizedBox(height: DanderSpacing.xs / 2),
        Text(label, style: DanderTextStyles.labelSmall),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: DanderColors.divider,
    );
  }
}
