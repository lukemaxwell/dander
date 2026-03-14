import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';

/// A compact floating button showing a compass icon with a charge count badge.
///
/// When [charges] is zero the button renders in a disabled (greyed-out) style
/// and ignores taps even if [onPressed] is provided.
/// When [charges] is greater than zero the button renders in accent colour and
/// forwards taps to [onPressed].
///
/// The widget is purely presentational — it does not modify [charges] itself.
/// The caller is responsible for decrementing charges (via [CompassCharges.spend])
/// and providing the updated value on the next rebuild.
class CompassButton extends StatelessWidget {
  const CompassButton({
    super.key,
    required this.charges,
    required this.onPressed,
  });

  /// Number of available compass charges to display in the badge.
  final int charges;

  /// Callback invoked when the button is tapped and [charges] > 0.
  ///
  /// The widget ignores this when [charges] == 0, so the caller may pass a
  /// non-null callback even when the model has no charges — the visual and
  /// interaction disable are both enforced here.
  final VoidCallback? onPressed;

  bool get _isEnabled => charges > 0;

  void _showExplanation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Compass charges reveal nearby discoveries. '
          'Walk 500m to earn a charge!',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _isEnabled
        ? DanderColors.accent
        : DanderColors.onSurfaceDisabled;

    final borderColor = _isEnabled
        ? DanderColors.accent.withValues(alpha: 0.4)
        : DanderColors.onSurfaceDisabled.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: _isEnabled
          ? onPressed
          : () => _showExplanation(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: DanderColors.primary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.explore,
              color: iconColor,
              size: 24,
            ),
            Positioned(
              top: -6,
              right: -6,
              child: _ChargeBadge(charges: charges, enabled: _isEnabled),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small circular badge overlaid on the top-right of the compass icon showing
/// the current charge count.
class _ChargeBadge extends StatelessWidget {
  const _ChargeBadge({required this.charges, required this.enabled});

  final int charges;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = enabled
        ? DanderColors.accent
        : DanderColors.onSurfaceDisabled;

    final textColor = enabled
        ? DanderColors.primary
        : DanderColors.onSurfaceDisabled;

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$charges',
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}
