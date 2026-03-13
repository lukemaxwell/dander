import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';

/// Renders the Dander logo mark — a stylised compass with a fog motif and
/// subtle footprint trail.
///
/// The mark is drawn via [CustomPaint] so it works at any size without
/// requiring SVG assets, and it renders correctly in tests.
class DanderLogoMark extends StatelessWidget {
  const DanderLogoMark({super.key, this.size = 64.0});

  /// Side length of the bounding square.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoMarkPainter(),
      ),
    );
  }
}

/// Full Dander logo: [DanderLogoMark] + the "Dander" wordmark below.
///
/// Use [showWordmark] to toggle the text label — useful for small sizes like
/// bottom nav where only the mark is needed.
class DanderLogo extends StatelessWidget {
  const DanderLogo({
    super.key,
    this.size = 64.0,
    this.showWordmark = true,
  });

  /// Size of the logo mark (width and height).
  final double size;

  /// When `true`, the "Dander" wordmark is shown below the mark.
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DanderLogoMark(size: size),
        if (showWordmark) ...[
          SizedBox(height: size * 0.15),
          Text(
            'Dander',
            style: TextStyle(
              color: DanderColors.onSurface,
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
              letterSpacing: size * 0.04,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Custom painter for the compass/fog logo mark
// ---------------------------------------------------------------------------

class _LogoMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide / 2;

    // Background disc
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.92,
      Paint()..color = DanderColors.primary,
    );

    // Glow gradient overlay
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.92,
      Paint()
        ..shader = RadialGradient(
          colors: [
            DanderColors.secondary.withValues(alpha: 0.5),
            DanderColors.surface.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.92),
        ),
    );

    // Dashed outer fog ring
    _drawDashedCircle(canvas, Offset(cx, cy), r * 0.96, 12);

    // Cardinal tick marks
    _drawCardinalTicks(canvas, Offset(cx, cy), r * 0.62, r * 0.72);

    // Compass needle — north (accent) and south (dim)
    _drawNeedle(canvas, Offset(cx, cy), r * 0.55);

    // Centre pivot
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.09,
      Paint()..color = DanderColors.accent,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.045,
      Paint()..color = DanderColors.primary,
    );

    // Footprint dots
    _drawFootprints(canvas, Offset(cx, cy), r);
  }

  void _drawDashedCircle(
      Canvas canvas, Offset center, double radius, int dashes) {
    final paint = Paint()
      ..color = DanderColors.accent.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path();
    final dashAngle = 2 * math.pi / (dashes * 2);
    for (var i = 0; i < dashes * 2; i += 2) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle;
      path.addArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
      );
    }
    canvas.drawPath(path, paint);
  }

  void _drawCardinalTicks(
    Canvas canvas,
    Offset center,
    double innerRadius,
    double outerRadius,
  ) {
    final angles = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2];
    for (var i = 0; i < angles.length; i++) {
      final a = angles[i] - math.pi / 2; // offset so 0 = north
      final from = Offset(
        center.dx + innerRadius * math.cos(a),
        center.dy + innerRadius * math.sin(a),
      );
      final to = Offset(
        center.dx + outerRadius * math.cos(a),
        center.dy + outerRadius * math.sin(a),
      );
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = i == 0
              ? DanderColors.accent
              : DanderColors.onSurface.withValues(alpha: 0.4)
          ..strokeWidth = i == 0 ? 2.0 : 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawNeedle(Canvas canvas, Offset center, double length) {
    // North half — gradient accent
    final northPath = Path()
      ..moveTo(center.dx, center.dy - length)
      ..lineTo(center.dx + length * 0.14, center.dy)
      ..lineTo(center.dx - length * 0.14, center.dy)
      ..close();

    canvas.drawPath(
      northPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [DanderColors.accent, DanderColors.secondary],
        ).createShader(
          Rect.fromLTWH(
            center.dx - length * 0.14,
            center.dy - length,
            length * 0.28,
            length,
          ),
        ),
    );

    // South half — dim
    final southPath = Path()
      ..moveTo(center.dx, center.dy + length)
      ..lineTo(center.dx + length * 0.14, center.dy)
      ..lineTo(center.dx - length * 0.14, center.dy)
      ..close();

    canvas.drawPath(
      southPath,
      Paint()..color = DanderColors.onSurface.withValues(alpha: 0.25),
    );
  }

  void _drawFootprints(Canvas canvas, Offset center, double radius) {
    final footprintPaint = Paint()
      ..color = DanderColors.secondary.withValues(alpha: 0.65);

    // Left foot — lower left quadrant
    canvas.save();
    canvas.translate(center.dx - radius * 0.26, center.dy + radius * 0.52);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 0.18,
        height: radius * 0.12,
      ),
      footprintPaint,
    );
    canvas.restore();

    // Right foot — slightly further lower right
    canvas.save();
    canvas.translate(center.dx + radius * 0.26, center.dy + radius * 0.66);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 0.18,
        height: radius * 0.12,
      ),
      footprintPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoMarkPainter old) => false;
}
