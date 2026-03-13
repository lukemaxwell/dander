import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/core/zone/mystery_poi.dart';

/// A map layer that renders mystery POI markers over the FlutterMap canvas.
///
/// Unrevealed POIs are shown as a pulsing amber "?" circle.
/// Revealed POIs are shown as a gold trophy icon ([Icons.emoji_events]).
///
/// Place this inside a [Builder] within [FlutterMap.children], where
/// [MapCamera.of(context)] is accessible — identical to the pattern used in
/// [FogLayer] and the location dot in [MapScreen].
///
/// Example:
/// ```dart
/// Builder(builder: (context) {
///   final camera = MapCamera.of(context);
///   return MysteryPoiMarkerLayer(pois: pois, camera: camera);
/// })
/// ```
class MysteryPoiMarkerLayer extends StatefulWidget {
  const MysteryPoiMarkerLayer({
    super.key,
    required this.pois,
    required this.camera,
  });

  /// The list of mystery POIs to render.  May be empty.
  final List<MysteryPoi> pois;

  /// The current [MapCamera] used to project [LatLng] → screen offsets.
  final MapCamera camera;

  @override
  State<MysteryPoiMarkerLayer> createState() => _MysteryPoiMarkerLayerState();
}

class _MysteryPoiMarkerLayerState extends State<MysteryPoiMarkerLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pois.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return Stack(
          children: widget.pois.map((poi) {
            return _buildMarker(poi);
          }).toList(),
        );
      },
    );
  }

  Widget _buildMarker(MysteryPoi poi) {
    // Convert geographic position to screen offset.
    final screenPoint = widget.camera.getOffsetFromOrigin(poi.position);

    if (poi.isRevealed) {
      return _RevealedMarker(
        key: ValueKey('poi_revealed_${poi.id}'),
        screenPoint: screenPoint,
      );
    }

    return _UnrevealedMarker(
      key: ValueKey('poi_unrevealed_${poi.id}'),
      screenPoint: screenPoint,
      pulseProgress: _pulseAnimation.value,
    );
  }
}

// ---------------------------------------------------------------------------
// Revealed marker — gold trophy icon
// ---------------------------------------------------------------------------

class _RevealedMarker extends StatelessWidget {
  const _RevealedMarker({
    super.key,
    required this.screenPoint,
  });

  final Offset screenPoint;

  static const double _size = 40.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: screenPoint.dx - _size / 2,
      top: screenPoint.dy - _size / 2,
      width: _size,
      height: _size,
      child: const Icon(
        Icons.emoji_events,
        color: DanderColors.rarityRare, // gold
        size: 28,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Unrevealed marker — pulsing amber "?" circle
// ---------------------------------------------------------------------------

class _UnrevealedMarker extends StatelessWidget {
  const _UnrevealedMarker({
    super.key,
    required this.screenPoint,
    required this.pulseProgress,
  });

  final Offset screenPoint;
  final double pulseProgress;

  static const double _size = 48.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: screenPoint.dx - _size / 2,
      top: screenPoint.dy - _size / 2,
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: MysteryPoiMarkerPainter(
          pois: const [],   // painter draws a single marker; pois unused here
          pulseProgress: pulseProgress,
          isSingleMarker: true,
        ),
        child: const Center(
          child: Text(
            '?',
            style: TextStyle(
              color: DanderColors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter (also exported for unit testing of shouldRepaint logic)
// ---------------------------------------------------------------------------

/// Custom painter for the pulsing mystery-POI circle.
///
/// When [isSingleMarker] is `true` (used by [_UnrevealedMarker]) it draws a
/// single circle centered in the canvas.  When `false` it is used in tests
/// for [shouldRepaint] verification only; no drawing occurs.
class MysteryPoiMarkerPainter extends CustomPainter {
  const MysteryPoiMarkerPainter({
    required this.pois,
    required this.pulseProgress,
    this.isSingleMarker = false,
  });

  final List<MysteryPoi> pois;
  final double pulseProgress;
  final bool isSingleMarker;

  @override
  void paint(Canvas canvas, Size size) {
    if (!isSingleMarker) return;

    final center = Offset(size.width / 2, size.height / 2);

    // Pulsing halo ring.
    final haloRadius = 12.0 + pulseProgress * 8.0;
    final haloOpacity = (1.0 - pulseProgress).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      haloRadius,
      Paint()
        ..color = DanderColors.secondary.withValues(alpha: haloOpacity * 0.5)
        ..style = PaintingStyle.fill,
    );

    // Solid amber fill circle.
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = DanderColors.secondary.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill,
    );

    // White border ring.
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = DanderColors.onSurface.withValues(alpha: 0.8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(MysteryPoiMarkerPainter old) {
    return old.pois != pois || old.pulseProgress != pulseProgress;
  }
}
