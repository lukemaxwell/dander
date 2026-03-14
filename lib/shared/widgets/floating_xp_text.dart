import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dander/core/motion/dander_motion.dart';
import 'package:dander/core/theme/app_theme.dart';

/// A single floating "+X XP" text that rises ~40px and fades out over 1.5s.
///
/// Used to provide immediate visual feedback when XP is awarded on the map
/// (street walked, POI discovered) or in quiz (correct answer).
///
/// The widget calls [onComplete] when its animation finishes, allowing the
/// parent to remove it from the tree.
class FloatingXpText extends StatefulWidget {
  const FloatingXpText({
    super.key,
    required this.amount,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 1500),
  });

  /// XP amount to display (e.g. 10, 50, 5).
  final int amount;

  /// Called when the animation completes — parent should remove this widget.
  final VoidCallback onComplete;

  /// How long the text animates before removal.  Defaults to 1500ms.
  final Duration duration;

  @override
  State<FloatingXpText> createState() => _FloatingXpTextState();
}

class _FloatingXpTextState extends State<FloatingXpText>
    with SingleTickerProviderStateMixin {
  static const double _riseDistance = 40.0;

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _offset;
  bool _completed = false;
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.duration);

    // Fade: fully visible for first 60%, then fade to 0.
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Rise: translate upward over the full duration.
    _offset = Tween<double>(begin: 0.0, end: -_riseDistance).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animationStarted) return;
    _animationStarted = true;

    if (DanderMotion.isReduced(context)) {
      // Skip animation entirely — schedule immediate removal.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_completed) {
          _completed = true;
          widget.onComplete();
        }
      });
    } else {
      _controller.forward().then((_) {
        if (mounted && !_completed) {
          _completed = true;
          widget.onComplete();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (DanderMotion.isReduced(context)) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _offset.value),
          child: Opacity(
            opacity: _opacity.value.clamp(0.0, 1.0),
            child: Text(
              '+${widget.amount} XP',
              style: DanderTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: DanderColors.secondary,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Controller + overlay for managing multiple floating XP texts
// ---------------------------------------------------------------------------

/// An XP event with a unique key for list diffing.
@immutable
class _XpEvent {
  _XpEvent({required this.amount, required this.duration}) : key = UniqueKey();

  final int amount;
  final Duration duration;
  final Key key;
}

/// Controller that manages a stream of XP display events.
///
/// Call [show] to add a floating "+X XP" text. The [FloatingXpTextOverlay]
/// listens to this controller and renders/removes entries automatically.
class FloatingXpController extends ChangeNotifier {
  static const Duration defaultDuration = Duration(milliseconds: 1500);

  List<_XpEvent> _events = const [];

  List<_XpEvent> get events => _events;

  void show(int amount, {Duration duration = defaultDuration}) {
    _events = [..._events, _XpEvent(amount: amount, duration: duration)];
    notifyListeners();
  }

  void _remove(_XpEvent event) {
    _events = _events.where((e) => e != event).toList();
    notifyListeners();
  }
}

/// Overlay widget that renders floating XP texts managed by a
/// [FloatingXpController].
///
/// Place this inside a [Stack] (e.g. on the map screen). Each [show] call
/// creates a new floating text that auto-removes after its animation.
class FloatingXpTextOverlay extends StatelessWidget {
  const FloatingXpTextOverlay({
    super.key,
    required this.controller,
  });

  final FloatingXpController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: controller.events.map((event) {
            return FloatingXpText(
              key: event.key,
              amount: event.amount,
              duration: event.duration,
              onComplete: () => controller._remove(event),
            );
          }).toList(),
        );
      },
    );
  }
}
