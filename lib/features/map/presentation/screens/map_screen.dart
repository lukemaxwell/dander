import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/fog/fog_grid.dart';
import 'package:dander/core/location/location_service.dart';
import 'package:dander/features/map/presentation/widgets/exploration_badge.dart';
import 'package:dander/features/map/presentation/widgets/fog_layer.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.locationService});

  /// Optional override for testing. Falls back to GetIt in production.
  final LocationService? locationService;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  static const LatLng _defaultCenter = LatLng(51.5074, -0.1278);
  static const double _defaultZoom = 15.0;

  final MapController _mapController = MapController();

  late final ValueNotifier<FogGrid> _fogGridNotifier;
  late final StreamController<LatLng> _locationStreamController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  LatLngBounds _visibleBounds = LatLngBounds(
    const LatLng(51.48, -0.15),
    const LatLng(51.53, -0.10),
  );

  LatLng _currentCenter = _defaultCenter;
  LatLng? _userPosition;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();

    _fogGridNotifier = ValueNotifier(FogGrid(origin: _defaultCenter));
    _locationStreamController = StreamController<LatLng>.broadcast();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _initLocation();
  }

  Future<void> _initLocation() async {
    final locationService =
        widget.locationService ?? GetIt.instance<LocationService>();
    final granted = await locationService.requestPermission();
    if (!granted) return;

    try {
      final position = await locationService.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      if (mounted) {
        _mapController.move(latLng, _defaultZoom);
        final grid = FogGrid(origin: latLng);
        grid.markExplored(latLng, 50.0);
        setState(() {
          _currentCenter = latLng;
          _userPosition = latLng;
          _fogGridNotifier.value = grid;
        });
      }
    } catch (_) {
      // Simulator / no GPS — stay at default centre
    }

    _positionSub = locationService.positionStream.listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);
      if (mounted) setState(() => _userPosition = latLng);
      _locationStreamController.add(latLng);
    });
  }

  int get _explorationPct {
    final pct = _fogGridNotifier.value.explorationPercentage(_visibleBounds);
    return (pct * 100).round();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _locationStreamController.close();
    _fogGridNotifier.dispose();
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildFog(),
          if (_userPosition != null) _buildLocationDot(),
          _buildOverlays(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentCenter,
        initialZoom: _defaultZoom,
        minZoom: 10,
        maxZoom: 18,
        onMapReady: () {
          setState(() {
            _visibleBounds = _mapController.camera.visibleBounds;
          });
        },
        onPositionChanged: (camera, _) {
          setState(() {
            _visibleBounds = camera.visibleBounds;
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.dander.dander',
          maxNativeZoom: 18,
        ),
      ],
    );
  }

  Widget _buildFog() {
    return Positioned.fill(
      child: IgnorePointer(
        child: FogLayer(
          fogGridNotifier: _fogGridNotifier,
          bounds: _visibleBounds,
          locationStream: _locationStreamController.stream,
          exploreRadius: 50.0,
        ),
      ),
    );
  }

  Widget _buildLocationDot() {
    final pos = _userPosition!;
    final screenPoint = _mapController.camera.getOffsetFromOrigin(pos);

    return Positioned(
      left: screenPoint.dx - 32,
      top: screenPoint.dy - 32,
      width: 64,
      height: 64,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final pulse = _pulseAnimation.value;
            return CustomPaint(
              painter: _LocationDotPainter(pulseProgress: pulse),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverlays() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ValueListenableBuilder<FogGrid>(
          valueListenable: _fogGridNotifier,
          builder: (context, _, __) => ExplorationBadge(
            percentageExplored: _explorationPct,
          ),
        ),
      ),
    );
  }
}

class _LocationDotPainter extends CustomPainter {
  const _LocationDotPainter({required this.pulseProgress});

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
        ..color = Colors.white.withValues(alpha: ringOpacity * 0.4)
        ..style = PaintingStyle.fill,
    );

    // Accuracy halo
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = const Color(0x336C63FF)
        ..style = PaintingStyle.fill,
    );

    // White border
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Gradient inner dot
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4A42D4)],
        ).createShader(Rect.fromCircle(center: center, radius: 7))
        ..style = PaintingStyle.fill,
    );

    // Specular highlight
    canvas.drawCircle(
      center + const Offset(-2, -2),
      2,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill,
    );

    // Direction indicator (chevron pointing up)
    final chevronPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
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
  bool shouldRepaint(_LocationDotPainter old) =>
      old.pulseProgress != pulseProgress;

  // ignore: unused_element
  static double _toRad(double deg) => deg * math.pi / 180;
}
