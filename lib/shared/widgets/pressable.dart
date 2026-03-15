import 'package:flutter/material.dart';

import 'package:dander/core/motion/dander_motion.dart';

/// A wrapper that applies opacity + scale press feedback to any tappable widget.
///
/// On tap-down: scale animates to 0.97, opacity to 0.7 over 100ms.
/// On tap-up/cancel: restores to 1.0 over 150ms.
///
/// When [DanderMotion.isReduced] is true, animations are skipped entirely;
/// the widget still fires [onTap] normally.
///
/// When [enabled] is false, tap gestures are ignored and no visual feedback
/// is shown.
///
/// Example:
/// ```dart
/// Pressable(
///   onTap: () => Navigator.of(context).push(...),
///   child: MyCard(),
/// )
/// ```
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.behavior,
  });

  /// Widget to display and make pressable.
  final Widget child;

  /// Callback fired on tap-up. If null, tapping has no effect.
  final VoidCallback? onTap;

  /// When false, ignores all tap events and shows no press feedback.
  final bool enabled;

  /// How the gesture detector should behave during hit testing.
  ///
  /// Set to [HitTestBehavior.opaque] when the pressable area should be
  /// larger than its visible child (e.g. a 44pt touch target around a
  /// small icon).
  final HitTestBehavior? behavior;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    if (widget.enabled) widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (DanderMotion.isReduced(context) || !widget.enabled) {
      return GestureDetector(
        behavior: widget.behavior,
        onTap: widget.enabled ? widget.onTap : null,
        child: widget.child,
      );
    }

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: _opacity.value,
            child: child,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
