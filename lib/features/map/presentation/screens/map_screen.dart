import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/fog/fog_grid.dart';
import 'package:dander/core/location/location_service.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/core/zone/level_up_detector.dart';
import 'package:dander/core/zone/mystery_poi.dart';
import 'package:dander/core/zone/mystery_poi_service.dart';
import 'package:dander/core/zone/zone.dart' as zone_model;
import 'package:dander/core/zone/zone_detector.dart';
import 'package:dander/core/zone/zone_repository.dart';
import 'package:dander/core/zone/zone_service.dart';
import 'package:dander/features/discoveries/presentation/widgets/discovery_notification.dart';
import 'package:dander/features/map/presentation/widgets/exploration_badge.dart';
import 'package:dander/features/map/presentation/widgets/fog_layer.dart';
import 'package:dander/features/map/presentation/widgets/level_up_overlay.dart';
import 'package:dander/features/map/presentation/widgets/mystery_poi_marker_layer.dart';
import 'package:dander/features/map/presentation/widgets/walk_control.dart';

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
  late final ValueNotifier<List<MysteryPoi>> _mysteryPoisNotifier;
  late final StreamController<LatLng> _locationStreamController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  LatLng _currentCenter = _defaultCenter;
  LatLng? _userPosition;
  StreamSubscription<Position>? _positionSub;
  WalkSession? _walkSession;

  // Zone progression state
  zone_model.Zone? _activeZone;
  LevelUpEvent? _levelUpEvent;
  bool _zonePromptShown = false;

  // POI discovery state
  Discovery? _pendingDiscovery;

  @override
  void initState() {
    super.initState();

    _fogGridNotifier = ValueNotifier(FogGrid(origin: _defaultCenter));
    _mysteryPoisNotifier = ValueNotifier(const []);
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

    // Load the active zone for the current position.
    if (_userPosition != null) {
      await _loadActiveZone(_userPosition!);
    }

    _positionSub = locationService.positionStream.listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);
      if (mounted) setState(() => _userPosition = latLng);
      _locationStreamController.add(latLng);
      _checkZoneOnMove(latLng);
      _checkPoiArrival(latLng);
    });
  }

  Future<void> _loadActiveZone(LatLng position) async {
    try {
      final zoneService = GetIt.instance<ZoneService>();
      final zone = await zoneService.getActiveZone(position);
      if (mounted) setState(() => _activeZone = zone);
    } catch (_) {
      // Zone service not available — skip
    }

    await _generatePoisForPosition(position);
  }

  Future<void> _generatePoisForPosition(LatLng position) async {
    try {
      final poiService = GetIt.instance<MysteryPoiService>();
      final pois = await poiService.generatePois(position, 500.0);
      _mysteryPoisNotifier.value = pois;
    } catch (_) {
      // POI service not available — skip
    }
  }

  void _checkPoiArrival(LatLng position) {
    final currentPois = _mysteryPoisNotifier.value;
    if (currentPois.isEmpty) return;

    try {
      final poiService = GetIt.instance<MysteryPoiService>();
      final arrived = poiService.checkArrival(position, currentPois);
      if (arrived == null) return;

      final revealedName = arrived.category;
      final revealed = poiService.revealPoi(arrived, revealedName);

      // Immutable list update — replace the arrived POI with its revealed copy.
      final updatedPois = currentPois
          .map((p) => p.id == arrived.id ? revealed : p)
          .toList();
      _mysteryPoisNotifier.value = updatedPois;

      _showPoiDiscoveryNotification(revealed);
      _awardPoiXp();
    } catch (_) {
      // POI service not available — skip
    }
  }

  void _showPoiDiscoveryNotification(MysteryPoi poi) {
    if (!mounted) return;
    final discovery = Discovery(
      id: poi.id,
      name: poi.name ?? poi.category,
      category: poi.category,
      rarity: RarityTier.uncommon,
      position: poi.position,
      osmTags: const {},
      discoveredAt: DateTime.now(),
    );
    setState(() => _pendingDiscovery = discovery);
  }

  Future<void> _awardPoiXp() async {
    if (_activeZone == null) return;
    try {
      final zoneService = GetIt.instance<ZoneService>();
      final after = await zoneService.awardPoiXp(_activeZone!.id);
      final event = LevelUpDetector.checkLevelUp(_activeZone!, after);
      if (mounted) {
        setState(() {
          _activeZone = after;
          if (event != null) _levelUpEvent = event;
        });
      }
    } catch (_) {
      // Zone service not available — skip
    }
  }

  Future<void> _checkZoneOnMove(LatLng position) async {
    if (_zonePromptShown) return;

    try {
      final detector = GetIt.instance<ZoneDetector>();
      final zoneRepo = GetIt.instance<ZoneRepository>();
      final zones = await zoneRepo.loadAll();

      if (detector.detectNewZone(position, zones)) {
        _zonePromptShown = true;
        if (mounted) _showNewZonePrompt(position);
      } else {
        // Update active zone
        final active = detector.findActiveZone(position, zones);
        if (mounted && active?.id != _activeZone?.id) {
          setState(() => _activeZone = active);
        }
      }
    } catch (_) {
      // Zone detection not available — skip
    }
  }

  Future<void> _showNewZonePrompt(LatLng position) async {
    final nameController = TextEditingController(text: 'New Zone');
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: DanderColors.surfaceElevated,
          title: Text("You're somewhere new!",
              style: DanderTextStyles.titleMedium),
          content: TextField(
            controller: nameController,
            style: DanderTextStyles.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Zone name',
              labelStyle: DanderTextStyles.bodySmall,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Not now',
                  style: DanderTextStyles.labelMedium
                      .copyWith(color: DanderColors.onSurfaceMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, nameController.text),
              child: Text('Start exploring!',
                  style: DanderTextStyles.labelMedium
                      .copyWith(color: DanderColors.accent)),
            ),
          ],
        ),
      );

      if (result != null && result.isNotEmpty) {
        final zoneRepo = GetIt.instance<ZoneRepository>();
        final newZone = zone_model.Zone(
          id: 'zone_${DateTime.now().millisecondsSinceEpoch}',
          name: result,
          centre: position,
          createdAt: DateTime.now(),
        );
        await zoneRepo.save(newZone);
        if (mounted) setState(() => _activeZone = newZone);
      }
    } finally {
      nameController.dispose();
    }
    _zonePromptShown = false;
  }

  Future<void> _awardStreetXp() async {
    if (_activeZone == null) return;
    try {
      final zoneService = GetIt.instance<ZoneService>();
      final before = _activeZone!;
      final after = await zoneService.awardStreetXp(before.id);
      final event = LevelUpDetector.checkLevelUp(before, after);
      if (mounted) {
        setState(() {
          _activeZone = after;
          if (event != null) _levelUpEvent = event;
        });
      }
    } catch (_) {
      // Zone service not available — skip
    }
  }

  int get _explorationPct {
    try {
      final pct = _fogGridNotifier.value
          .explorationPercentage(_mapController.camera.visibleBounds);
      return (pct * 100).round();
    } catch (_) {
      return 0;
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _locationStreamController.close();
    _fogGridNotifier.dispose();
    _mysteryPoisNotifier.dispose();
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startWalk() {
    setState(() {
      _walkSession = WalkSession.start(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: DateTime.now(),
      );
    });
  }

  void _stopWalk(WalkSession session) {
    setState(() => _walkSession = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: LevelUpOverlay(
        event: _levelUpEvent,
        onDismissed: () => setState(() => _levelUpEvent = null),
        child: Stack(
          children: [
            _buildMap(),
            _buildOverlays(),
            if (_pendingDiscovery != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: DiscoveryNotification(
                  discovery: _pendingDiscovery!,
                  onDismiss: () => setState(() => _pendingDiscovery = null),
                ),
              ),
            WalkControl(
              session: _walkSession,
              onStart: _startWalk,
              onStop: _stopWalk,
            ),
          ],
        ),
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
        onMapReady: () => setState(() {}),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag | InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.dander.dander',
          maxNativeZoom: 18,
        ),
        // Fog, POI markers and location dot are inside FlutterMap so they
        // share the same render frame as the tiles — no zoom/pan desync.
        Builder(
          builder: (context) {
            final camera = MapCamera.of(context);
            return IgnorePointer(
              child: Stack(
                children: [
                  FogLayer(
                    fogGridNotifier: _fogGridNotifier,
                    bounds: camera.visibleBounds,
                    locationStream: _locationStreamController.stream,
                    exploreRadius: 50.0,
                    onFogExpanded: _walkSession != null ? _awardStreetXp : null,
                  ),
                  ValueListenableBuilder<List<MysteryPoi>>(
                    valueListenable: _mysteryPoisNotifier,
                    builder: (context, pois, _) => MysteryPoiMarkerLayer(
                      pois: pois,
                      camera: camera,
                    ),
                  ),
                  if (_userPosition != null)
                    _buildLocationDot(camera),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocationDot(MapCamera camera) {
    final screenPoint = camera.getOffsetFromOrigin(_userPosition!);
    return Positioned(
      left: screenPoint.dx - 32,
      top: screenPoint.dy - 32,
      width: 64,
      height: 64,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, _) => CustomPaint(
          painter: _LocationDotPainter(pulseProgress: _pulseAnimation.value),
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
        ..color = DanderColors.onSurface.withValues(alpha: ringOpacity * 0.4)
        ..style = PaintingStyle.fill,
    );

    // Accuracy halo
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = DanderColors.secondary.withValues(alpha: 0.2)
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
          colors: [DanderColors.secondary, DanderColors.gradientStart],
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
  bool shouldRepaint(_LocationDotPainter old) =>
      old.pulseProgress != pulseProgress;

}
