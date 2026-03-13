import 'package:flutter/material.dart';

/// Animated text widget that counts up from 0 to [value] over [duration].
///
/// Uses [AnimationController] with [Curves.easeOut] for a natural deceleration.
class CountUpText extends StatefulWidget {
  const CountUpText({
    super.key,
    required this.value,
    this.style,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 500),
  });

  /// The target integer value to count up to.
  final int value;

  /// Optional text style; falls back to the ambient [DefaultTextStyle].
  final TextStyle? style;

  /// Optional string appended after the number (e.g. `'%'`).
  final String suffix;

  /// Duration of the count-up animation.
  final Duration duration;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<int> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _countAnimation = _buildAnimation(0, widget.value);
    if (widget.value > 0) _controller.forward();
  }

  Animation<int> _buildAnimation(int from, int to) {
    return IntTween(begin: from, end: to).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(CountUpText old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _countAnimation = _buildAnimation(_countAnimation.value, widget.value);
      _controller
        ..reset()
        ..forward();
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
      animation: _countAnimation,
      builder: (context, _) {
        return Text(
          '${_countAnimation.value}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}
