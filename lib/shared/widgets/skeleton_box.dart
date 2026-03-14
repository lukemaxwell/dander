import 'package:flutter/material.dart';

import 'package:dander/core/motion/dander_motion.dart';
import 'package:dander/core/theme/dander_colors.dart';

/// A single shimmer skeleton rectangle.
///
/// Animates a subtle light sweep from left to right when motion is enabled.
/// Falls back to a static placeholder when reduced motion is on.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!DanderMotion.isReduced(context)) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = DanderMotion.isReduced(context);
    final radius = BorderRadius.circular(widget.borderRadius);

    if (reduced) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: DanderColors.cardBackground,
          borderRadius: radius,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment(-1.5 + _controller.value * 3.0, 0),
              end: Alignment(-0.5 + _controller.value * 3.0, 0),
              colors: const [
                DanderColors.cardBackground,
                Color(0xFF2A2A3E), // slightly lighter sweep
                DanderColors.cardBackground,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A vertical list of [SkeletonBox] items — for loading placeholders.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    required this.count,
    required this.itemHeight,
    this.spacing = 12,
    this.padding = const EdgeInsets.all(16),
  });

  final int count;
  final double itemHeight;
  final double spacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: count,
      separatorBuilder: (_, __) => SizedBox(height: spacing),
      itemBuilder: (context, _) => SkeletonBox(
        width: double.infinity,
        height: itemHeight,
      ),
    );
  }
}
