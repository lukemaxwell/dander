import 'package:flutter/material.dart';

import '../../../../core/zone/zone.dart';
import '../../../../core/fog/fog_grid.dart';

/// Shareable turf/zone summary card.
///
/// Fixed size 1080x1350 (portrait, 4:5 — matches other share cards).
/// Shows zone name, explorer level badge, streets explored count,
/// a territory preview area, and Dander branding.
///
/// The [fogGrid] is optional; when provided a golden silhouette of the
/// explored territory is rendered. When null a placeholder circle is shown.
class TurfShareCard extends StatelessWidget {
  const TurfShareCard({
    super.key,
    required this.zone,
    required this.streetCount,
    this.fogGrid,
  });

  final Zone zone;
  final int streetCount;
  final FogGrid? fogGrid;

  static const double cardWidth = 1080;
  static const double cardHeight = 1350;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E)],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildZoneName(),
            _buildLevelBadge(),
            Expanded(child: _buildTerritoryPreview()),
            _buildStreetCount(),
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
        ),
      ),
    );
  }

  Widget _buildLevelBadge() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFC107).withAlpha(38),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFFFC107), width: 2),
        ),
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
    );
  }

  Widget _buildTerritoryPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Center(
        key: const Key('territory_preview'),
        child: _TerritoryPreview(fogGrid: fogGrid),
      ),
    );
  }

  Widget _buildStreetCount() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 0, 48, 24),
      child: Column(
        children: [
          Text(
            '$streetCount',
            key: const Key('street_count'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 96,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
            ),
          ),
          const Text(
            'streets explored',
            key: Key('street_count_label'),
            style: TextStyle(
              color: Colors.white60,
              fontSize: 32,
              fontWeight: FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(48, 0, 48, 60),
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
    );
  }
}

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

    final cellPaint = Paint()
      ..color = _goldenColor.withAlpha(204)
      ..style = PaintingStyle.fill;

    const padding = 0.5;
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
