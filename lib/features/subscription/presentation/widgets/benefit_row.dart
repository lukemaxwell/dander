import 'package:flutter/material.dart';

import 'package:dander/core/theme/dander_colors.dart';
import 'package:dander/core/theme/dander_spacing.dart';
import 'package:dander/core/theme/dander_text_styles.dart';

/// A single feature benefit row: 20px accent icon + title + description.
///
/// Used in the paywall screen to enumerate Pro feature benefits.
/// Three rows are displayed with a 50ms stagger fade-in.
class BenefitRow extends StatelessWidget {
  const BenefitRow({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  /// Icon displayed at 20px in [DanderColors.accent].
  final IconData icon;

  /// Primary benefit label — [DanderTextStyles.titleSmall] (14px, w600).
  final String title;

  /// Supporting description — [DanderTextStyles.bodySmall] (12px, muted).
  final String description;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $description',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: DanderColors.accent,
          ),
          const SizedBox(width: DanderSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DanderTextStyles.titleSmall,
                ),
                const SizedBox(height: DanderSpacing.xs),
                Text(
                  description,
                  style: DanderTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
