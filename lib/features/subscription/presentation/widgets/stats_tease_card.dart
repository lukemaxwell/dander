import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';

/// A card that teases a Pro-only stats feature with a blurred decorative
/// background, a lock icon, the feature title, and a "Pro" label.
///
/// Tapping the card calls [onTap], which should navigate the user to the
/// paywall screen.
class StatsTeaseCard extends StatelessWidget {
  const StatsTeaseCard({
    super.key,
    required this.title,
    required this.onTap,
    this.height = 120.0,
  });

  /// The name of the Pro feature being teased (e.g. "Heat Map").
  final String title;

  /// Called when the card is tapped.
  final VoidCallback onTap;

  /// Card height in logical pixels. Defaults to 120.
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pro feature: $title. Double-tap to learn more',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: DanderColors.cardBackground,
            borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
            border: Border.all(color: DanderColors.cardBorder, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Bottom layer: decorative abstract data shapes.
                CustomPaint(
                  painter: _StatsBehindBlurPainter(),
                  child: const SizedBox.expand(),
                ),

                // Middle layer: blur filter to obscure the background shapes.
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(color: Colors.transparent),
                ),

                // Top layer: lock icon, title, and "Pro" label.
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: DanderColors.onSurfaceMuted,
                      ),
                      SizedBox(height: DanderSpacing.xs),
                      Text(title, style: DanderTextStyles.labelMedium),
                      SizedBox(height: DanderSpacing.xs),
                      Text(
                        'Pro',
                        style: DanderTextStyles.labelMedium.copyWith(
                          color: DanderColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private painter — purely decorative abstract data shapes.
// ---------------------------------------------------------------------------

class _StatsBehindBlurPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final accentColor = DanderColors.accent;

    // ---- 3 vertical bars of varying heights ----
    final barPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final barWidth = size.width * 0.08;
    final barSpacing = size.width * 0.06;
    final barStartX = size.width * 0.15;
    final barHeights = [
      size.height * 0.5,
      size.height * 0.75,
      size.height * 0.35,
    ];

    for (var i = 0; i < barHeights.length; i++) {
      final x = barStartX + i * (barWidth + barSpacing);
      final barHeight = barHeights[i];
      final top = size.height - barHeight - size.height * 0.1;
      canvas.drawRect(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        barPaint,
      );
    }

    // ---- Trend polyline above bars ----
    final linePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.55)
      ..lineTo(size.width * 0.3, size.height * 0.30)
      ..lineTo(size.width * 0.55, size.height * 0.45)
      ..lineTo(size.width * 0.75, size.height * 0.20)
      ..lineTo(size.width * 0.90, size.height * 0.35);

    canvas.drawPath(path, linePaint);

    // ---- 5 small dots in upper area ----
    final dotPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    const dotRadius = 3.0;
    final dots = [
      Offset(size.width * 0.20, size.height * 0.18),
      Offset(size.width * 0.40, size.height * 0.10),
      Offset(size.width * 0.60, size.height * 0.22),
      Offset(size.width * 0.75, size.height * 0.08),
      Offset(size.width * 0.88, size.height * 0.16),
    ];

    for (final dot in dots) {
      canvas.drawCircle(dot, dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_StatsBehindBlurPainter old) => false;
}
