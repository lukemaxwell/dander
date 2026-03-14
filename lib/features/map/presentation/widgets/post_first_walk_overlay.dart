import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';

/// A full-screen overlay prompt shown after the first walk's zoom-out.
///
/// Invites the user to share their first exploration. Dismissable.
class PostFirstWalkOverlay extends StatelessWidget {
  const PostFirstWalkOverlay({
    super.key,
    required this.onShare,
    required this.onDismiss,
  });

  /// Called when the user taps the share button.
  final VoidCallback onShare;

  /// Called when the user dismisses without sharing.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DanderColors.surface.withValues(alpha: 0.85),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: DanderSpacing.pagePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: DanderColors.accent,
                ),
                const SizedBox(height: DanderSpacing.lg),
                Text(
                  'Share your first exploration',
                  style: DanderTextStyles.titleMedium.copyWith(
                    color: DanderColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DanderSpacing.sm),
                Text(
                  'Show off your first steps into the unknown',
                  style: DanderTextStyles.bodyMediumMuted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DanderSpacing.xl),
                GestureDetector(
                  onTap: onShare,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DanderSpacing.xl,
                      vertical: DanderSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: DanderColors.accent,
                      borderRadius: BorderRadius.circular(DanderSpacing.md),
                    ),
                    child: Text(
                      'Share',
                      style: DanderTextStyles.labelLarge.copyWith(
                        color: DanderColors.surface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DanderSpacing.md),
                GestureDetector(
                  onTap: onDismiss,
                  child: Text(
                    'Not now',
                    style: DanderTextStyles.bodyMediumMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
