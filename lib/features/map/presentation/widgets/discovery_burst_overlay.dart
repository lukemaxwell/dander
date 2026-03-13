import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dander/core/theme/category_pin_config.dart';

/// Data for a single outward-burst particle.
@immutable
class _BurstParticle {
  const _BurstParticle({
    required this.angle,
    required this.radius,
    required this.dotRadius,
  });

  /// Direction of travel in radians.
  final double angle;

  /// Maximum outward distance in logical pixels.
  final double radius;

  /// Radius of the dot itself.
  final double dotRadius;
}

/// A brief discovery animation placed as a [Positioned] overlay inside a
/// [Stack].
///
/// Plays two simultaneous animations triggered at construction:
///
/// 1. **Pin drop** — the category icon scales from 0 → 1 using
///    [Curves.elasticOut] over 300 ms.
/// 2. **Particle burst** — 6–8 small circles burst outward from the centre,
///    fading to transparent over 400 ms.
///
/// [onComplete] is called once both animations finish (~500 ms total). The
/// caller is responsible for removing the widget from the tree.
///
/// Designed to be embedded inside a [Stack] at the given screen [position].
///
/// ```dart
/// Stack(
///   children: [
///     mapWidget,
///     DiscoveryBurstOverlay(
///       position: screenOffset,
///       category: 'cafe',
///       onComplete: _removeOverlay,
///     ),
///   ],
/// )
/// ```
class DiscoveryBurstOverlay extends StatefulWidget {
  const DiscoveryBurstOverlay({
    super.key,
    required this.position,
    required this.category,
    required this.onComplete,
  });

  /// Centre of the burst in screen coordinates (pixels from top-left of Stack).
  final Offset position;

  /// OSM category string — used to look up icon and colour via
  /// [CategoryPinConfig.forCategory].
  final String category;

  /// Called once after all animations complete.
  final VoidCallback onComplete;

  @override
  State<DiscoveryBurstOverlay> createState() => _DiscoveryBurstOverlayState();
}

class _DiscoveryBurstOverlayState extends State<DiscoveryBurstOverlay>
    with SingleTickerProviderStateMixin {
  /// Total duration — long enough for the particle fade (400 ms) plus a small
  /// buffer so the controller completes cleanly at 500 ms.
  static const Duration _totalDuration = Duration(milliseconds: 500);

  /// Pin drop scale animates over the first 300 ms.
  static const Duration _pinDuration = Duration(milliseconds: 300);

  /// Particle burst fades over 400 ms.
  static const Duration _particleDuration = Duration(milliseconds: 400);

  /// Outward travel distance for each particle (logical pixels).
  static const double _burstRadius = 30.0;

  /// Number of particles in the burst.
  static const int _particleCount = 7;

  late final AnimationController _controller;

  /// Pin scale: 0 → 1 with elastic overshoot, completes at _pinDuration.
  late final Animation<double> _pinScale;

  /// Particle opacity: 1 → 0, completes at _particleDuration.
  late final Animation<double> _particleOpacity;

  /// Particle travel progress: 0 → 1, same timing as opacity.
  late final Animation<double> _particleProgress;

  late final List<_BurstParticle> _particles;
  bool _completed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _totalDuration);

    final pinInterval = Interval(
      0.0,
      _pinDuration.inMilliseconds / _totalDuration.inMilliseconds,
      curve: Curves.elasticOut,
    );
    _pinScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: pinInterval),
    );

    final particleEnd =
        _particleDuration.inMilliseconds / _totalDuration.inMilliseconds;
    final particleInterval = Interval(0.0, particleEnd);

    _particleOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: particleInterval),
    );
    _particleProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: particleInterval),
    );

    _particles = _buildParticles();

    _controller.forward().then((_) {
      if (mounted && !_completed) {
        _completed = true;
        widget.onComplete();
      }
    });
  }

  List<_BurstParticle> _buildParticles() {
    final rng = math.Random(widget.category.hashCode);
    return List.generate(_particleCount, (i) {
      // Distribute angles evenly with a small random jitter.
      final baseAngle = (2 * math.pi / _particleCount) * i;
      final jitter = (rng.nextDouble() - 0.5) * 0.4;
      return _BurstParticle(
        angle: baseAngle + jitter,
        radius: _burstRadius * (0.7 + rng.nextDouble() * 0.6),
        dotRadius: 3.0 + rng.nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = CategoryPinConfig.forCategory(widget.category);

    // Half the pin container size for centering the Positioned widget.
    const pinContainerSize = 40.0;
    const halfPin = pinContainerSize / 2;

    return Positioned(
      left: widget.position.dx - halfPin,
      top: widget.position.dy - halfPin,
      width: pinContainerSize,
      height: pinContainerSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Particle burst — rendered beneath pin via ordering.
              ..._particles.map((p) {
                final dx = math.cos(p.angle) * p.radius * _particleProgress.value;
                final dy = math.sin(p.angle) * p.radius * _particleProgress.value;
                return Positioned(
                  left: halfPin + dx - p.dotRadius,
                  top: halfPin + dy - p.dotRadius,
                  child: Opacity(
                    opacity: _particleOpacity.value.clamp(0.0, 1.0),
                    child: Container(
                      width: p.dotRadius * 2,
                      height: p.dotRadius * 2,
                      decoration: BoxDecoration(
                        color: config.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),

              // Pin drop — centred in the 40×40 container.
              Positioned(
                left: 0,
                top: 0,
                width: pinContainerSize,
                height: pinContainerSize,
                child: Transform.scale(
                  scale: _pinScale.value.clamp(0.0, 1.5),
                  child: Container(
                    width: pinContainerSize,
                    height: pinContainerSize,
                    decoration: BoxDecoration(
                      color: config.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      config.icon,
                      color: config.color,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
