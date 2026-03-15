import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/zone/zone.dart';
import '../../../../core/fog/fog_grid.dart';

/// Shareable turf/zone summary card.
///
/// Fixed size 1080x1350 (portrait, 4:5 — matches other share cards).
/// Shows zone name, explorer level badge, streets walked count,
/// explored percentage, a territory preview area, and Dander branding.
///
/// The [fogGrid] is optional; when provided a golden silhouette of the
/// explored territory is rendered. When null a placeholder circle is shown.
class TurfShareCard extends StatelessWidget {
  const TurfShareCard({
    super.key,
    required this.zone,
    required this.streetCount,
    required this.explorationPct,
    this.fogGrid,
  });

  final Zone zone;
  final int streetCount;

  /// Fraction of zone explored, from 0.0 to 1.0.
  final double explorationPct;
  final FogGrid? fogGrid;

  static const double cardWidth = 1080;
  static const double cardHeight = 1350;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: CustomPaint(
        painter: _BackgroundPainter(seed: zone.name.hashCode),
        child: Column(
          children: [
            _buildHeader(),
            _buildZoneName(),
            _buildLevelBadge(),
            Expanded(child: _buildTerritoryPreview()),
            _buildStats(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 60, 48, 0),
      child: Row(
        children: [
          _DanderLogo(),
          const SizedBox(width: 16),
          const Text(
            'Dander',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const Spacer(),
          const Text(
            'My Turf',
            style: TextStyle(
              color: Color(0xFFFFC107),
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneName() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 48, 48, 0),
      child: Text(
        zone.name,
        key: const Key('zone_name'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 72,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          height: 1.1,
          shadows: [
            Shadow(
              color: Color(0x3DFFC107),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFC107), Color(0xFFFF8F00)],
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(98),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          child: Text(
            'Level ${zone.level} Explorer',
            key: const Key('level_badge'),
            style: const TextStyle(
              color: Color(0xFFFFC107),
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTerritoryPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Center(
        key: const Key('territory_preview'),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _TerritoryPreview(fogGrid: fogGrid),
            Positioned.fill(
              child: CustomPaint(
                painter: _ExplorationRingPainter(explorationPct: explorationPct),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    final exploredLabel = '${(explorationPct * 100).round()}%';
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 0, 48, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  exploredLabel,
                  key: const Key('exploration_pct'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 96,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
                const Text(
                  'explored',
                  key: Key('explored_label'),
                  style: TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 80,
            color: const Color(0x33FFFFFF),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$streetCount',
                  key: const Key('street_count'),
                  style: const TextStyle(
                    color: Color(0xFFFFC107),
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'streets walked',
                  key: Key('street_count_label'),
                  style: TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(height: 1, color: const Color(0x33FFC107)),
        const Padding(
          padding: EdgeInsets.fromLTRB(48, 16, 48, 60),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'dander.app',
                key: Key('watermark'),
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Background painter — base gradient + coordinate grid + star field
// ---------------------------------------------------------------------------

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBaseGradient(canvas, size);
    _paintCoordinateGrid(canvas, size);
    _paintStarField(canvas, size);
  }

  void _paintBaseGradient(Canvas canvas, Size size) {
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E)],
    );
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _paintCoordinateGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const step = 60.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintStarField(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    const starCount = 40;

    for (var i = 0; i < starCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = 1.0 + rng.nextDouble() * 2.0; // 1–3 px
      final opacity = 0.15 + rng.nextDouble() * 0.25; // 15–40%

      final paint = Paint()
        ..color = Color.fromRGBO(255, 255, 255, opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.seed != seed;
}

// ---------------------------------------------------------------------------
// Territory preview widget + painter
// ---------------------------------------------------------------------------

/// Renders a golden silhouette of explored territory, or a placeholder when
/// no [FogGrid] is available.
class _TerritoryPreview extends StatelessWidget {
  const _TerritoryPreview({this.fogGrid});

  final FogGrid? fogGrid;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return SizedBox(
          width: side,
          height: side,
          child: CustomPaint(
            painter: _TerritoryPainter(fogGrid: fogGrid),
          ),
        );
      },
    );
  }
}

class _TerritoryPainter extends CustomPainter {
  const _TerritoryPainter({this.fogGrid});

  final FogGrid? fogGrid;

  static const Color _goldenColor = Color(0xFFFFC107);
  static const Color _fogColor = Color(0xFF1A1A2E);

  @override
  void paint(Canvas canvas, Size size) {
    if (fogGrid == null) {
      _paintPlaceholder(canvas, size);
    } else {
      _paintFogSilhouette(canvas, size, fogGrid!);
    }
  }

  void _paintPlaceholder(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = _fogColor.withAlpha(200)
      ..style = PaintingStyle.fill;

    final circlePaint = Paint()
      ..color = _goldenColor.withAlpha(153)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = _goldenColor.withAlpha(204)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.38;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius, borderPaint);
  }

  void _paintFogSilhouette(Canvas canvas, Size size, FogGrid grid) {
    final cells = grid.exploredCells;
    if (cells.isEmpty) {
      _paintPlaceholder(canvas, size);
      return;
    }

    // Compute bounding box of explored cells for scaling.
    final xs = cells.map((c) => c.x);
    final ys = cells.map((c) => c.y);
    final minX = xs.reduce((a, b) => a < b ? a : b);
    final maxX = xs.reduce((a, b) => a > b ? a : b);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);

    final rangeX = (maxX - minX + 1).toDouble();
    final rangeY = (maxY - minY + 1).toDouble();

    final scaleX = size.width / rangeX;
    final scaleY = size.height / rangeY;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final offsetX = (size.width - rangeX * scale) / 2;
    final offsetY = (size.height - rangeY * scale) / 2;

    final bgPaint = Paint()
      ..color = _fogColor.withAlpha(200)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    const padding = 0.5;

    // Glow pass — drawn first, behind the fill cells.
    final glowPaint = Paint()
      ..color = const Color(0x33FFC107)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    for (final cell in cells) {
      final left = offsetX + (cell.x - minX) * scale + padding - 8;
      final top = offsetY + (cell.y - minY) * scale + padding - 8;
      final cellW = scale - padding * 2 + 16;
      final cellH = scale - padding * 2 + 16;
      canvas.drawRect(Rect.fromLTWH(left, top, cellW, cellH), glowPaint);
    }

    // Fill pass — drawn on top of glow.
    final cellPaint = Paint()
      ..color = const Color(0xD9FFC107)
      ..style = PaintingStyle.fill;

    for (final cell in cells) {
      final left = offsetX + (cell.x - minX) * scale + padding;
      final top = offsetY + (cell.y - minY) * scale + padding;
      final cellW = scale - padding * 2;
      final cellH = scale - padding * 2;
      canvas.drawRect(Rect.fromLTWH(left, top, cellW, cellH), cellPaint);
    }
  }

  @override
  bool shouldRepaint(_TerritoryPainter old) => old.fogGrid != fogGrid;
}

// ---------------------------------------------------------------------------
// Exploration ring painter
// ---------------------------------------------------------------------------

class _ExplorationRingPainter extends CustomPainter {
  const _ExplorationRingPainter({required this.explorationPct});

  final double explorationPct;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 8;

    // Background track.
    final trackPaint = Paint()
      ..color = const Color(0x14FFFFFF)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, trackPaint);

    if (explorationPct <= 0.0) return;

    final sweepAngle = explorationPct * 2 * math.pi;

    // Progress arc.
    final arcPaint = Paint()
      ..color = const Color(0xFFFFC107)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, arcPaint);

    // Tip dot at the arc endpoint.
    final tipAngle = -math.pi / 2 + sweepAngle;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);

    final dotPaint = Paint()
      ..color = const Color(0xFFFFC107)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(tipX, tipY), 5, dotPaint);
  }

  @override
  bool shouldRepaint(_ExplorationRingPainter old) =>
      old.explorationPct != explorationPct;
}

// ---------------------------------------------------------------------------
// Dander logo mark
// ---------------------------------------------------------------------------

class _DanderLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'D',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
