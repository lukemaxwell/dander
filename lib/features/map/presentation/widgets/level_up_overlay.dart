import 'package:flutter/material.dart';

import 'package:dander/core/haptics/haptic_service.dart';
import 'package:dander/core/theme/dander_colors.dart';
import 'package:dander/core/zone/level_up_detector.dart';
import 'package:dander/core/zone/zone_level.dart';
import 'package:dander/shared/widgets/confetti_overlay.dart';

/// Overlay widget that celebrates a zone level-up.
///
/// When [event] is non-null the banner is displayed with confetti and haptic
/// feedback. The overlay persists until the user taps it (tap-to-dismiss).
/// When [event] is null only [child] is shown.
class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({
    super.key,
    required this.event,
    required this.child,
    this.onDismissed,
  });

  /// The level-up event to display, or `null` to show no overlay.
  final LevelUpEvent? event;

  /// The widget rendered beneath the overlay (typically the map).
  final Widget child;

  /// Called when the user taps to dismiss the overlay.
  final VoidCallback? onDismissed;

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay> {
  @override
  void didUpdateWidget(LevelUpOverlay old) {
    super.didUpdateWidget(old);

    // Trigger haptic on new level-up event.
    if (old.event == null && widget.event != null) {
      HapticService.levelUp();
    }
  }

  void _dismiss() {
    widget.onDismissed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasEvent = widget.event != null;

    return Stack(
      children: [
        ConfettiOverlay(
          active: hasEvent,
          child: widget.child,
        ),
        if (hasEvent)
          Positioned.fill(
            child: GestureDetector(
              onTap: _dismiss,
              behavior: HitTestBehavior.opaque,
              child: _LevelUpBanner(event: widget.event!),
            ),
          ),
      ],
    );
  }
}

/// The visual banner content rendered inside [LevelUpOverlay].
class _LevelUpBanner extends StatelessWidget {
  const _LevelUpBanner({required this.event});

  final LevelUpEvent event;

  String _formatRadius(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      final formatted =
          km == km.truncateToDouble() ? '${km.toInt()}km' : '${km}km';
      return formatted;
    }
    return '${meters.toInt()}m';
  }

  String _nextLevelText() {
    final nextLevel = event.newLevel + 1;
    final nextXp = ZoneLevel.xpForNextLevel(
      ZoneLevel.xpForLevel(event.newLevel),
    );
    if (nextXp == null) {
      return "You've reached the highest level!";
    }
    final currentLevelXp = ZoneLevel.xpForLevel(event.newLevel);
    final xpNeeded = nextXp - currentLevelXp;
    return 'Keep walking to reach Level $nextLevel ($xpNeeded XP)';
  }

  @override
  Widget build(BuildContext context) {
    final radiusText = _formatRadius(event.newRadiusMeters);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: DanderColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: DanderColors.secondary,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: DanderColors.secondary.withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Level ${event.newLevel}!',
              style: const TextStyle(
                color: DanderColors.secondary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore up to $radiusText!',
              style: const TextStyle(
                color: DanderColors.onSurface,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _nextLevelText(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DanderColors.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to continue',
              style: TextStyle(
                color: DanderColors.onSurface.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
