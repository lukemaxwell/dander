import 'package:flutter/material.dart';

import 'package:dander/core/subscription/milestone_type.dart';
import 'package:dander/core/theme/dander_colors.dart';
import 'package:dander/core/theme/dander_spacing.dart';
import 'package:dander/core/theme/dander_text_styles.dart';

/// Card shown after a milestone celebration that gently suggests the Pro tier.
///
/// Rendered below the level-up banner (or any milestone banner) after a short
/// delay. Provides two actions:
///   - "Continue" — dismisses the whole overlay.
///   - "Learn about Pro →" — navigates to the paywall.
///
/// The contextual body copy is selected based on [milestoneType] so the
/// message always relates to the achievement the user just unlocked.
class MilestoneProSuggestionCard extends StatelessWidget {
  const MilestoneProSuggestionCard({
    super.key,
    required this.milestoneType,
    required this.onLearnAboutPro,
    required this.onContinue,
  });

  final MilestoneType milestoneType;
  final VoidCallback onLearnAboutPro;
  final VoidCallback onContinue;

  static String _contextualMessage(MilestoneType type) => switch (type) {
        MilestoneType.zoneLevelUp =>
          'Unlock weekly challenges to earn exclusive badges',
        MilestoneType.fogMilestone =>
          'See your exploration heat map with Pro',
        MilestoneType.streakMilestone =>
          'Track your monthly walking trends with Pro',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(DanderSpacing.lg),
      decoration: BoxDecoration(
        color: DanderColors.surfaceElevated,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
        border: Border.all(
          color: DanderColors.cardBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "There's more to unlock",
            style: DanderTextStyles.bodyMedium.copyWith(
              color: DanderColors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: DanderSpacing.sm),
          Text(
            _contextualMessage(milestoneType),
            style: DanderTextStyles.bodyMedium,
          ),
          const SizedBox(height: DanderSpacing.lg),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DanderColors.secondary,
                      foregroundColor: DanderColors.onSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DanderSpacing.borderRadiusMd,
                        ),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ),
              const SizedBox(width: DanderSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: onLearnAboutPro,
                    style: TextButton.styleFrom(
                      foregroundColor: DanderColors.secondary,
                    ),
                    child: const Text('Learn about Pro \u2192'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
