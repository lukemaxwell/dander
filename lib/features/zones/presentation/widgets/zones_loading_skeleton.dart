import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/shared/widgets/skeleton_box.dart';

/// Skeleton placeholder shown while zone data is loading.
///
/// Mirrors the layout of [ZoneCard] — header row, progress bar, footer.
class ZonesLoadingSkeleton extends StatelessWidget {
  const ZonesLoadingSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: DanderSpacing.pagePadding.copyWith(
        top: DanderSpacing.pagePadding.top + MediaQuery.of(context).padding.top,
      ),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: DanderSpacing.md),
      itemBuilder: (_, __) => const _ZoneCardSkeleton(),
    );
  }
}

class _ZoneCardSkeleton extends StatelessWidget {
  const _ZoneCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: DanderSpacing.cardPadding,
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: name + level badge
          Row(
            children: [
              const Expanded(
                child: SkeletonBox(width: double.infinity, height: 16),
              ),
              const SizedBox(width: DanderSpacing.sm),
              SkeletonBox(
                width: 32,
                height: 24,
                borderRadius: DanderSpacing.borderRadiusSm,
              ),
            ],
          ),
          const SizedBox(height: DanderSpacing.sm),
          // XP row
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 80, height: 12),
              SkeletonBox(width: 60, height: 12),
            ],
          ),
          const SizedBox(height: DanderSpacing.xs),
          // Progress bar
          const SkeletonBox(
            width: double.infinity,
            height: 4,
            borderRadius: DanderSpacing.borderRadiusFull,
          ),
          const SizedBox(height: DanderSpacing.sm),
          // Level explainer
          const SkeletonBox(width: 200, height: 12),
          const SizedBox(height: DanderSpacing.sm),
          // Footer
          const SkeletonBox(width: 120, height: 11),
        ],
      ),
    );
  }
}
