import 'package:flutter/material.dart';

import 'package:dander/core/onboarding/first_launch_service.dart';
import 'package:dander/core/theme/app_theme.dart';

/// A persistent overlay prompt showing "Walk 200m to discover your first zone"
/// with a real-time distance counter and progress bar.
///
/// Calls [onGoalReached] when [distanceWalked] reaches 200m.
/// Calls [onDismissed] when the user taps the close button.
class FirstWalkContractOverlay extends StatefulWidget {
  const FirstWalkContractOverlay({
    super.key,
    required this.distanceWalked,
    required this.onDismissed,
    required this.onGoalReached,
  });

  /// Current cumulative distance walked in metres.
  final double distanceWalked;

  /// Called when the user manually dismisses the prompt.
  final VoidCallback onDismissed;

  /// Called when the distance threshold is reached.
  final VoidCallback onGoalReached;

  @override
  State<FirstWalkContractOverlay> createState() =>
      _FirstWalkContractOverlayState();
}

class _FirstWalkContractOverlayState extends State<FirstWalkContractOverlay> {
  bool _goalFired = false;

  @override
  void didUpdateWidget(covariant FirstWalkContractOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkGoal();
  }

  @override
  void initState() {
    super.initState();
    // Check on first frame in case we're already at 200m.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGoal();
    });
  }

  void _checkGoal() {
    if (!_goalFired &&
        widget.distanceWalked >=
            FirstLaunchService.firstWalkContractDistance) {
      _goalFired = true;
      widget.onGoalReached();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.distanceWalked /
            FirstLaunchService.firstWalkContractDistance)
        .clamp(0.0, 1.0);
    final distanceDisplay = widget.distanceWalked.round();

    return Container(
      padding: const EdgeInsets.all(DanderSpacing.md),
      decoration: BoxDecoration(
        color: DanderColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(DanderSpacing.md),
        border: Border.all(
          color: DanderColors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Walk 200m to discover your first zone',
                  style: DanderTextStyles.titleSmall.copyWith(
                    color: DanderColors.onSurface,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onDismissed,
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: DanderColors.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: DanderSpacing.sm),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: DanderColors.accent.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(DanderColors.accent),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: DanderSpacing.xs),
          Text(
            '${distanceDisplay}m / 200m',
            style: DanderTextStyles.bodySmall.copyWith(
              color: DanderColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
