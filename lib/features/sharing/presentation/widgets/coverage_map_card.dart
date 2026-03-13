import 'package:flutter/material.dart';

/// Shareable card showing the fog-of-war coverage map.
///
/// Fixed size 1080x1080 (square, optimised for Instagram).
/// Displays Dander branding, exploration percentage, and neighbourhood name.
class CoverageMapCard extends StatelessWidget {
  const CoverageMapCard({
    super.key,
    required this.explorationPercent,
    required this.neighbourhoodName,
  });

  final double explorationPercent;
  final String neighbourhoodName;

  static const double cardWidth = 1080;
  static const double cardHeight = 1080;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(child: _buildMapArea()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 48, 48, 16),
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
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    final percentText = '${explorationPercent.toStringAsFixed(0)}% explored';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            neighbourhoodName,
            key: const Key('neighbourhood_name'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 36,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: _FogMapPreview(explorationPercent: explorationPercent),
            ),
          ),
          Text(
            percentText,
            key: const Key('exploration_percent'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 16, 48, 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'dander.app',
            key: const Key('watermark'),
            style: const TextStyle(
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

class _FogMapPreview extends StatelessWidget {
  const _FogMapPreview({required this.explorationPercent});

  final double explorationPercent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: CustomPaint(
              painter: _FogMapPainter(explorationPercent: explorationPercent),
            ),
          ),
        );
      },
    );
  }
}

class _FogMapPainter extends CustomPainter {
  const _FogMapPainter({required this.explorationPercent});

  final double explorationPercent;

  @override
  void paint(Canvas canvas, Size size) {
    final fogPaint = Paint()
      ..color = const Color(0xFF6C63FF).withAlpha(204)
      ..style = PaintingStyle.fill;

    final exploredPaint = Paint()
      ..color = const Color(0xFF2ECC71).withAlpha(179)
      ..style = PaintingStyle.fill;

    const cols = 10;
    const rows = 10;
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;
    final totalCells = cols * rows;
    final exploredCells = (totalCells * explorationPercent / 100).round();

    var cellIndex = 0;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final rect = Rect.fromLTWH(
          col * cellWidth + 1,
          row * cellHeight + 1,
          cellWidth - 2,
          cellHeight - 2,
        );
        final isExplored = cellIndex < exploredCells;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          isExplored ? exploredPaint : fogPaint,
        );
        cellIndex++;
      }
    }
  }

  @override
  bool shouldRepaint(_FogMapPainter oldDelegate) =>
      oldDelegate.explorationPercent != explorationPercent;
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
