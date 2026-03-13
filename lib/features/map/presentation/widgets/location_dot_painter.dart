import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';

/// [CustomPainter] that draws the user's location dot with a pulsing ring.
///
/// Renders:
/// - An outward-fading pulse ring driven by [pulseProgress] (0.0–1.0).
/// - A translucent accuracy halo.
/// - A white-bordered gradient inner dot.
/// - A chevron direction indicator pointing upward.
class LocationDotPainter extends CustomPainter {
  const LocationDotPainter({required this.pulseProgress});

  final double pulseProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Pulsing ring
    final ringRadius = 12.0 + pulseProgress * 16.0;
    final ringOpacity = (1.0 - pulseProgress).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color = DanderColors.onSurface.withValues(alpha: ringOpacity * 0.4)
        ..style = PaintingStyle.fill,
    );

    // Accuracy halo
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = DanderColors.accent.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );

    // White border
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = DanderColors.onSurface
        ..style = PaintingStyle.fill,
    );

    // Gradient inner dot
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..shader = RadialGradient(
          colors: [DanderColors.accent, DanderColors.gradientEnd],
        ).createShader(Rect.fromCircle(center: center, radius: 7))
        ..style = PaintingStyle.fill,
    );

    // Specular highlight
    canvas.drawCircle(
      center + const Offset(-2, -2),
      2,
      Paint()
        ..color = DanderColors.onSurface.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill,
    );

    // Direction indicator (chevron pointing up)
    final chevronPaint = Paint()
      ..color = DanderColors.onSurface.withValues(alpha: 0.9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = ui.Path()
      ..moveTo(center.dx - 3, center.dy + 1)
      ..lineTo(center.dx, center.dy - 2)
      ..lineTo(center.dx + 3, center.dy + 1);
    canvas.drawPath(path, chevronPaint);
  }

  @override
  bool shouldRepaint(LocationDotPainter old) =>
      old.pulseProgress != pulseProgress;
}
