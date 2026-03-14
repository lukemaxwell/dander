import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';

/// [CustomPainter] that draws the user's location dot with a pulsing ring
/// and an optional heading arrow indicating direction of travel.
///
/// Renders:
/// - An outward-fading pulse ring driven by [pulseProgress] (0.0–1.0).
/// - A translucent accuracy halo.
/// - A white-bordered gradient inner dot.
/// - A heading arrow when [headingDegrees] is provided (0 = north, 90 = east).
class LocationDotPainter extends CustomPainter {
  const LocationDotPainter({
    required this.pulseProgress,
    this.headingDegrees,
  });

  final double pulseProgress;

  /// Compass heading in degrees (0–360, clockwise from north).
  /// When null, no heading arrow is drawn.
  final double? headingDegrees;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Heading cone (drawn first so it appears behind the dot).
    if (headingDegrees != null) {
      _drawHeadingCone(canvas, center, headingDegrees!);
    }

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
  }

  void _drawHeadingCone(Canvas canvas, Offset center, double degrees) {
    final radians = (degrees - 90) * math.pi / 180.0;
    const coneLength = 24.0;
    const coneHalfAngle = 0.35; // ~20 degrees

    final tipX = center.dx + math.cos(radians) * coneLength;
    final tipY = center.dy + math.sin(radians) * coneLength;

    final leftX = center.dx + math.cos(radians - coneHalfAngle) * 10.0;
    final leftY = center.dy + math.sin(radians - coneHalfAngle) * 10.0;

    final rightX = center.dx + math.cos(radians + coneHalfAngle) * 10.0;
    final rightY = center.dy + math.sin(radians + coneHalfAngle) * 10.0;

    final path = ui.Path()
      ..moveTo(leftX, leftY)
      ..lineTo(tipX, tipY)
      ..lineTo(rightX, rightY)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = DanderColors.accent.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(LocationDotPainter old) =>
      old.pulseProgress != pulseProgress ||
      old.headingDegrees != headingDegrees;
}
