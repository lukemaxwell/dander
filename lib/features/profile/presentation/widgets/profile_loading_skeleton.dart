import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/shared/widgets/skeleton_box.dart';

/// Skeleton placeholder shown while profile data is loading.
///
/// Mirrors the top section of ProfileScreen:
/// circular exploration ring, walk stats card, streak card, badge grid.
class ProfileLoadingSkeleton extends StatelessWidget {
  const ProfileLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: DanderColors.surfaceElevated,
      body: ListView(
        padding: DanderSpacing.pagePadding.copyWith(
          top: DanderSpacing.pagePadding.top + top,
        ),
        children: const [
          // Circular exploration ring placeholder
          Center(
            child: SkeletonBox(width: 160, height: 160, borderRadius: 80),
          ),
          SizedBox(height: DanderSpacing.lg),
          // Walk stats card
          SkeletonBox(width: double.infinity, height: 88),
          SizedBox(height: DanderSpacing.sm),
          // Walk history button
          SkeletonBox(width: double.infinity, height: 44, borderRadius: 12),
          SizedBox(height: DanderSpacing.lg),
          // Streak card
          SkeletonBox(width: double.infinity, height: 120),
          SizedBox(height: DanderSpacing.lg),
          // Badge grid title
          SkeletonBox(width: 80, height: 14),
          SizedBox(height: DanderSpacing.sm),
          // Badge grid (2 rows of 4)
          Row(
            children: [
              Expanded(child: SkeletonBox(width: double.infinity, height: 72, borderRadius: 12)),
              SizedBox(width: DanderSpacing.sm),
              Expanded(child: SkeletonBox(width: double.infinity, height: 72, borderRadius: 12)),
              SizedBox(width: DanderSpacing.sm),
              Expanded(child: SkeletonBox(width: double.infinity, height: 72, borderRadius: 12)),
              SizedBox(width: DanderSpacing.sm),
              Expanded(child: SkeletonBox(width: double.infinity, height: 72, borderRadius: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
