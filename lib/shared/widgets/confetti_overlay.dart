import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Confetti particle data.
class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.rotation,
    required this.size,
  });

  double x;
  double y;
  double vx;
  double vy;
  final Color color;
  double rotation;
  final double size;
}

/// Overlays an animated confetti burst on top of [child].
///
/// When [active] transitions from `false` to `true` a burst of confetti
/// particles falls from the top of the widget. When [active] is `false` no
/// animation runs.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    required this.active,
    required this.child,
    this.particleCount = 60,
  });

  /// Whether the confetti animation is running.
  final bool active;

  /// The widget displayed beneath the confetti.
  final Widget child;

  /// Number of particles to spawn.
  final int particleCount;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 1800);

  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final math.Random _rng = math.Random(42);

  static const _colors = [
    Color(0xFFFF8F00), // amber (brand secondary)
    Color(0xFF4FC3F7),
    Color(0xFFFF6B35),
    Color(0xFFFFD700),
    Color(0xFF4CAF50),
    Color(0xFFE8EAF6),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _particles = _buildParticles(widget.particleCount);

    if (widget.active) _controller.forward();
  }

  @override
  void didUpdateWidget(ConfettiOverlay old) {
    super.didUpdateWidget(old);
    if (!old.active && widget.active) {
      _particles.forEach(_resetParticle);
      _controller
        ..reset()
        ..forward();
    }
  }

  List<_Particle> _buildParticles(int count) {
    return List.generate(count, (_) {
      final p = _Particle(
        x: 0,
        y: 0,
        vx: 0,
        vy: 0,
        color: _colors[_rng.nextInt(_colors.length)],
        rotation: 0,
        size: 6 + _rng.nextDouble() * 8,
      );
      _resetParticle(p);
      return p;
    });
  }

  void _resetParticle(_Particle p) {
    p
      ..x = 0.1 + _rng.nextDouble() * 0.8
      ..y = -0.05
      ..vx = (_rng.nextDouble() - 0.5) * 0.003
      ..vy = 0.002 + _rng.nextDouble() * 0.004
      ..rotation = _rng.nextDouble() * math.pi * 2;
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
        if (widget.active)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                // Update particle positions based on progress
                final t = _controller.value;
                for (final p in _particles) {
                  p
                    ..x += p.vx
                    ..y += p.vy + t * 0.001
                    ..rotation += 0.05;
                }
                return CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    opacity: (1 - t * 0.8).clamp(0.0, 1.0),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.particles,
    required this.opacity,
  });

  final List<_Particle> particles;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
