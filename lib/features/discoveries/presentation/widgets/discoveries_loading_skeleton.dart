import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/shared/widgets/skeleton_box.dart';

/// Skeleton placeholder shown while discoveries data is loading.
///
/// Mirrors the layout of a list of DiscoveryCard rows.
class DiscoveriesLoadingSkeleton extends StatelessWidget {
  const DiscoveriesLoadingSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DanderColors.surfaceElevated,
      body: SafeArea(
        bottom: false,
        child: ListView.separated(
          padding: DanderSpacing.pagePadding,
          itemCount: count,
          separatorBuilder: (_, __) =>
              const SizedBox(height: DanderSpacing.md),
          itemBuilder: (_, __) => const _DiscoveryCardSkeleton(),
        ),
      ),
    );
  }
}

class _DiscoveryCardSkeleton extends StatelessWidget {
  const _DiscoveryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: DanderSpacing.cardPadding,
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon placeholder
          SkeletonBox(width: 48, height: 48, borderRadius: 12),
          SizedBox(width: DanderSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                SkeletonBox(width: double.infinity, height: 14),
                SizedBox(height: DanderSpacing.xs),
                // Category + rarity row
                Row(
                  children: [
                    SkeletonBox(width: 60, height: 11),
                    SizedBox(width: DanderSpacing.sm),
                    SkeletonBox(width: 48, height: 11),
                  ],
                ),
                SizedBox(height: DanderSpacing.xs),
                // Description line
                SkeletonBox(width: 180, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
