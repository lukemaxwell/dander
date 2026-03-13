import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A card that flips between a [front] and [back] face with a 3-D rotation.
///
/// The flip is triggered by changing the [flipped] property. The animation
/// uses a Y-axis rotation around the card's centre.
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.flipped = false,
    this.duration = const Duration(milliseconds: 400),
  });

  /// Widget shown on the front face.
  final Widget front;

  /// Widget shown on the back face.
  final Widget back;

  /// When `true` the card displays [back]; when `false` it shows [front].
  final bool flipped;

  /// Duration of the flip animation.
  final Duration duration;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.flipped) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(FlipCard old) {
    super.didUpdateWidget(old);
    if (old.flipped != widget.flipped) {
      if (widget.flipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final angle = _animation.value * math.pi;
        final showBack = _animation.value >= 0.5;

        Widget face;
        double faceAngle;
        if (showBack) {
          face = widget.back;
          faceAngle = angle - math.pi;
        } else {
          face = widget.front;
          faceAngle = angle;
        }

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(faceAngle),
          child: face,
        );
      },
    );
  }
}
