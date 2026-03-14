import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:dander/core/progress/daily_target.dart';
import 'package:dander/core/theme/app_theme.dart';

/// A compact daily exploration target ring.
///
/// Shows a circular progress ring with the current count vs target.
/// Purely positive — no punishment for missing a day.
class DailyTargetRing extends StatelessWidget {
  const DailyTargetRing({
    super.key,
    required this.target,
  });

  final DailyTarget target;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CustomPaint(
            painter: _RingPainter(
              fraction: target.progress,
              isComplete: target.isComplete,
            ),
            child: Center(
              child: Text(
                '${target.streetsToday}',
                style: DanderTextStyles.labelSmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: target.isComplete
                      ? DanderColors.secondary
                      : DanderColors.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: DanderSpacing.xs),
        Text(
          '/${target.target} street',
          style: DanderTextStyles.labelSmall.copyWith(
            color: DanderColors.onSurfaceMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.isComplete,
  });

  final double fraction;
  final bool isComplete;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 3;

    final trackPaint = Paint()
      ..color = DanderColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final progressColor =
        isComplete ? DanderColors.secondary : DanderColors.accent;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (fraction > 0) {
      final sweepAngle = 2 * math.pi * fraction.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.isComplete != isComplete;
}
