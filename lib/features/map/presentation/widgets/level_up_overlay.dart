import 'package:flutter/material.dart';

import 'package:dander/core/theme/dander_colors.dart';
import 'package:dander/core/zone/level_up_detector.dart';

/// Overlay widget that celebrates a zone level-up with an animated banner.
///
/// When [event] is non-null the banner fades in, remains visible for 2 seconds,
/// then fades out automatically. When [event] is null only [child] is shown.
class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({
    super.key,
    required this.event,
    required this.child,
  });

  /// The level-up event to display, or `null` to show no overlay.
  final LevelUpEvent? event;

  /// The widget rendered beneath the overlay (typically the map).
  final Widget child;

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  /// Total visible duration before the banner starts fading out.
  static const Duration _visibleDuration = Duration(seconds: 2);

  /// Duration of the fade-out once [_visibleDuration] has elapsed.
  static const Duration _fadeOutDuration = Duration(milliseconds: 600);

  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _visibleDuration + _fadeOutDuration,
    );
    _opacity = _buildOpacityCurve();

    if (widget.event != null) {
      _runAnimation();
    }
  }

  @override
  void didUpdateWidget(LevelUpOverlay old) {
    super.didUpdateWidget(old);

    final hadEvent = old.event != null;
    final hasEvent = widget.event != null;

    if (!hadEvent && hasEvent) {
      _controller.reset();
      _runAnimation();
    } else if (hadEvent && !hasEvent) {
      _controller.stop();
      _controller.reset();
    }
  }

  /// Builds an opacity curve: hold at 1.0 for [_visibleDuration], then
  /// tween to 0.0 over [_fadeOutDuration].
  Animation<double> _buildOpacityCurve() {
    final totalMs =
        (_visibleDuration + _fadeOutDuration).inMilliseconds.toDouble();
    final visibleWeight = _visibleDuration.inMilliseconds / totalMs;
    final fadeWeight = _fadeOutDuration.inMilliseconds / totalMs;

    return TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: visibleWeight,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: fadeWeight,
      ),
    ]).animate(_controller);
  }

  void _runAnimation() {
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.event != null)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return _opacity.value > 0
                    ? _LevelUpBanner(
                        event: widget.event!,
                        opacity: _opacity.value,
                      )
                    : const SizedBox.shrink();
              },
            ),
          ),
      ],
    );
  }
}

/// The visual banner content rendered inside [LevelUpOverlay].
class _LevelUpBanner extends StatelessWidget {
  const _LevelUpBanner({
    required this.event,
    required this.opacity,
  });

  final LevelUpEvent event;
  final double opacity;

  /// Formats [meters] as a human-readable distance string.
  ///
  /// Values >= 1000 m are expressed in km (e.g. "1.5km").
  /// Values < 1000 m are expressed in meters (e.g. "500m").
  String _formatRadius(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      // Trim unnecessary trailing zero: 3.0 → "3km", 1.5 → "1.5km"
      final formatted =
          km == km.truncateToDouble() ? '${km.toInt()}km' : '${km}km';
      return formatted;
    }
    return '${meters.toInt()}m';
  }

  @override
  Widget build(BuildContext context) {
    final radiusText = _formatRadius(event.newRadiusMeters);

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          decoration: BoxDecoration(
            color: DanderColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DanderColors.secondary,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: DanderColors.secondary.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Level ${event.newLevel}!',
                style: const TextStyle(
                  color: DanderColors.secondary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore up to $radiusText!',
                style: const TextStyle(
                  color: DanderColors.onSurface,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
