import 'package:flutter/material.dart';

/// A column of widgets that animate in sequentially with a staggered delay.
///
/// Each child fades and slides in from below. All animations share a single
/// [AnimationController] and use [Interval] curves to achieve the stagger
/// without creating per-item timers.
class StaggeredList extends StatefulWidget {
  const StaggeredList({
    super.key,
    required this.children,
    this.itemDuration = const Duration(milliseconds: 350),
    this.staggerDelay = const Duration(milliseconds: 80),
    this.curve = Curves.easeOutCubic,
  });

  /// The widgets to display.
  final List<Widget> children;

  /// Duration of each item's entrance animation.
  final Duration itemDuration;

  /// Delay between consecutive item animations.
  final Duration staggerDelay;

  /// Curve used for each item animation.
  final Curve curve;

  @override
  State<StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<StaggeredList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();

    final n = widget.children.length;
    if (n == 0) {
      _controller = AnimationController(vsync: this, duration: Duration.zero);
      _fades = [];
      _slides = [];
      return;
    }

    // Total duration = n*staggerDelay + itemDuration
    final totalMs = n * widget.staggerDelay.inMilliseconds +
        widget.itemDuration.inMilliseconds;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    _fades = [];
    _slides = [];

    final totalD = totalMs.toDouble();
    final itemD = widget.itemDuration.inMilliseconds.toDouble();
    final staggerD = widget.staggerDelay.inMilliseconds.toDouble();

    for (var i = 0; i < n; i++) {
      final start = (i * staggerD) / totalD;
      final end = ((i * staggerD) + itemD) / totalD;

      final interval = Interval(start, end.clamp(0.0, 1.0),
          curve: widget.curve);

      _fades.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: interval),
        ),
      );
      _slides.add(
        Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _controller, curve: interval),
        ),
      );
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          FadeTransition(
            opacity: _fades[i],
            child: SlideTransition(
              position: _slides[i],
              child: widget.children[i],
            ),
          ),
      ],
    );
  }
}
