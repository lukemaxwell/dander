import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/compass/compass_charges.dart';
import 'package:dander/core/compass/compass_charges_repository.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/discoveries/discovery_repository.dart';
import 'package:dander/core/fog/fog_grid.dart';
import 'package:dander/core/fog/fog_repository.dart';
import 'package:dander/core/location/location_service.dart';
import 'package:dander/core/location/walk_repository.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/core/zone/level_up_detector.dart';
import 'package:dander/core/zone/zone_level.dart';
import 'package:dander/core/zone/mystery_poi.dart';
import 'package:dander/core/zone/mystery_poi_repository.dart';
import 'package:dander/core/zone/mystery_poi_service.dart';
import 'package:dander/core/zone/zone.dart' as zone_model;
import 'package:dander/core/zone/zone_detector.dart';
import 'package:dander/core/zone/zone_repository.dart';
import 'package:dander/core/zone/zone_service.dart';
import 'package:dander/features/discoveries/presentation/widgets/discovery_notification.dart';
import 'package:dander/features/discoveries/presentation/widgets/discovery_reveal_overlay.dart';
import 'package:dander/features/map/presentation/widgets/compass_button.dart';
import 'package:dander/features/map/presentation/widgets/discovery_burst_overlay.dart';
import 'package:dander/features/map/presentation/widgets/exploration_badge.dart';
import 'package:dander/features/map/presentation/widgets/fog_layer.dart';
import 'package:dander/features/map/presentation/widgets/level_up_overlay.dart';
import 'package:dander/features/map/presentation/widgets/location_dot_painter.dart';
import 'package:dander/features/map/presentation/widgets/mystery_poi_marker_layer.dart';
import 'package:dander/features/map/presentation/widgets/walk_control.dart';
import 'package:dander/features/map/presentation/widgets/xp_progress_bar.dart';
import 'package:dander/shared/widgets/floating_xp_text.dart';

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
  late final ValueNotifier<CompassCharges> _compassChargesNotifier;
  late final ValueNotifier<int> _discoveriesWaitingNotifier;
  late final StreamController<LatLng> _locationStreamController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  LatLng _currentCenter = _defaultCenter;
  LatLng? _userPosition;
  LatLng? _prevPosition;
  StreamSubscription<Position>? _positionSub;
  WalkSession? _walkSession;

  // Zone progression state
  zone_model.Zone? _activeZone;
  LevelUpEvent? _levelUpEvent;
  bool _zonePromptShown = false;

  // POI discovery state
  Discovery? _pendingDiscovery;
  Discovery? _revealingDiscovery; // actively playing reveal sequence

  // Burst animation state
  Offset? _burstPosition;
  String? _burstCategory;

  // Heading for compass arrow (degrees from north, 0–360).
  double? _heading;

  // Floating XP text controller.
  final FloatingXpController _xpController = FloatingXpController();

  // Session XP counter — reset on walk start.
  int _sessionXp = 0;

  // Fog save debounce — saves at most once every 5 seconds.
  Timer? _fogSaveTimer;

  @override
  void initState() {
    super.initState();

    _fogGridNotifier = ValueNotifier(FogGrid(origin: _defaultCenter));
    _mysteryPoisNotifier = ValueNotifier(const []);
    _compassChargesNotifier = ValueNotifier(const CompassCharges());
    _discoveriesWaitingNotifier = ValueNotifier(0);
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

        // Try to load persisted fog grid; create fresh if none exists.
        FogGrid grid;
        try {
          final fogRepo = GetIt.instance<FogRepository>();
          final saved = await fogRepo.load();
          grid = saved ?? FogGrid(origin: latLng);
        } catch (_) {
          grid = FogGrid(origin: latLng);
        }
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

    // Load persisted compass charges.
    try {
      final repo = GetIt.instance<CompassChargesRepository>();
      final saved = await repo.load();
      if (mounted) _compassChargesNotifier.value = saved;
    } catch (_) {
      // Repository not registered in tests — use defaults.
    }

    _positionSub = locationService.positionStream.listen((position) {
      final latLng = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _userPosition = latLng;
          if (position.heading.isFinite && position.heading != 0.0) {
            _heading = position.heading;
          }
        });
      }
      _locationStreamController.add(latLng);
      _checkZoneOnMove(latLng);
      _checkPoiArrival(latLng);
      if (_walkSession != null) {
        _earnChargesFromMove(latLng);
        // Track walk points.
        _walkSession = _walkSession!.addPoint(
          WalkPoint(position: latLng, timestamp: DateTime.now()),
        );
      }
      _prevPosition = latLng;
      _scheduleFogSave();
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
      final zoneId = _activeZone?.id ?? 'default';
      final result = await poiService.loadOrGenerate(zoneId, position, 500.0);
      _mysteryPoisNotifier.value = result.activePois;
      _discoveriesWaitingNotifier.value = result.totalCount;
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
      final updatedPois =
          currentPois.map((p) => p.id == arrived.id ? revealed : p).toList();
      _mysteryPoisNotifier.value = updatedPois;

      // Persist updated POI state to cache.
      _savePoisToCache(updatedPois);

      // Decrement discoveries waiting (clamp to 0).
      final waiting = _discoveriesWaitingNotifier.value;
      if (waiting > 0) {
        _discoveriesWaitingNotifier.value = waiting - 1;
      }

      _triggerDiscoveryBurst(arrived);
      _showPoiDiscoveryNotification(revealed);
      _awardPoiXp(rarity: RarityTier.uncommon);

      // Check for wave progression — may unlock additional POIs.
      _checkWaveProgression(poiService);
    } catch (_) {
      // POI service not available — skip
    }
  }

  /// Calls [MysteryPoiService.onPoiRevealed] and updates [_mysteryPoisNotifier]
  /// if the wave has advanced (new POIs are now active).
  void _checkWaveProgression(MysteryPoiService poiService) {
    final zoneId = _activeZone?.id ?? 'default';
    poiService.onPoiRevealed(zoneId).then((result) {
      if (!mounted) return;
      // Only update the notifier when the active set actually changed
      // (wave unlocked more POIs or the list composition differs).
      final current = _mysteryPoisNotifier.value;
      final updated = result.activePois;
      final sameIds = current.length == updated.length &&
          current.every((p) => updated.any((u) => u.id == p.id));
      if (!sameIds) {
        _mysteryPoisNotifier.value = updated;
      }
    }).catchError((_) {
      // Wave progression not critical — ignore errors.
    });
  }

  void _triggerDiscoveryBurst(MysteryPoi poi) {
    if (!mounted) return;
    try {
      final camera = _mapController.camera;
      final screenPoint = camera.getOffsetFromOrigin(poi.position);
      setState(() {
        _burstPosition = screenPoint;
        _burstCategory = poi.category;
      });
    } catch (_) {
      // MapController camera not available — skip burst animation.
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
    setState(() => _revealingDiscovery = discovery);
    _saveDiscovery(discovery);
  }

  Future<void> _awardPoiXp({RarityTier rarity = RarityTier.common}) async {
    if (_activeZone == null) return;
    final xpDuration = rarity == RarityTier.rare || rarity == RarityTier.legendary
        ? const Duration(milliseconds: 2500)
        : FloatingXpController.defaultDuration;
    try {
      final zoneService = GetIt.instance<ZoneService>();
      final after = await zoneService.awardPoiXp(_activeZone!.id);
      final event = LevelUpDetector.checkLevelUp(_activeZone!, after);
      if (mounted) {
        _xpController.show(ZoneLevel.xpPerPoi, duration: xpDuration);
        setState(() {
          _sessionXp += ZoneLevel.xpPerPoi;
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
        _xpController.show(ZoneLevel.xpPerStreet);
        setState(() {
          _sessionXp += ZoneLevel.xpPerStreet;
          _activeZone = after;
          if (event != null) _levelUpEvent = event;
        });
      }
    } catch (_) {
      // Zone service not available — skip
    }
  }

  void _earnChargesFromMove(LatLng newPosition) {
    final prev = _prevPosition;
    if (prev == null) return;
    try {
      final detector = GetIt.instance<ZoneDetector>();
      final deltaMeters = detector.distanceBetween(prev, newPosition);
      final updated =
          _compassChargesNotifier.value.earnFromDistance(deltaMeters);
      _compassChargesNotifier.value = updated;
      _saveCompassCharges(updated);
    } catch (_) {
      // ZoneDetector or repository not registered — skip.
    }
  }

  Future<void> _saveCompassCharges(CompassCharges charges) async {
    try {
      final repo = GetIt.instance<CompassChargesRepository>();
      await repo.save(charges);
    } catch (_) {
      // Repository not registered in tests — skip.
    }
  }

  void _scheduleFogSave() {
    if (_fogSaveTimer?.isActive ?? false) return;
    _fogSaveTimer = Timer(const Duration(seconds: 5), _saveFogGrid);
  }

  void _saveFogGrid() {
    try {
      final fogRepo = GetIt.instance<FogRepository>();
      fogRepo.save(_fogGridNotifier.value).catchError((_) {});
    } catch (_) {
      // Repository not registered in tests — skip.
    }
  }

  void _savePoisToCache(List<MysteryPoi> pois) {
    try {
      final repo = GetIt.instance<MysteryPoiRepository>();
      final zoneId = _activeZone?.id ?? 'default';
      repo.savePois(zoneId, pois).catchError((_) {});
    } catch (_) {
      // Repository not registered in tests — skip.
    }
  }

  Future<void> _saveDiscovery(Discovery discovery) async {
    try {
      final repo = GetIt.instance<DiscoveryRepository>();
      await repo.markDiscovered(discovery.id, discovery.discoveredAt!);
    } catch (_) {
      // Repository not available — skip.
    }
  }

  void _hintNearestUnrevealedPoi() {
    final charges = _compassChargesNotifier.value;
    if (!charges.canSpend) return;

    final pois = _mysteryPoisNotifier.value;
    final unrevealed =
        pois.where((p) => p.state == PoiState.unrevealed).toList();
    if (unrevealed.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Start walking to discover nearby points of interest!'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Find the nearest unrevealed POI to the user's current position.
    MysteryPoi? nearest;
    double nearestDist = double.infinity;
    try {
      final detector = GetIt.instance<ZoneDetector>();
      final userPos = _userPosition;
      if (userPos == null) return;
      for (final poi in unrevealed) {
        final dist = detector.distanceBetween(userPos, poi.position);
        if (dist < nearestDist) {
          nearestDist = dist;
          nearest = poi;
        }
      }
    } catch (_) {
      nearest = unrevealed.first;
    }

    if (nearest == null) return;

    final hinted = nearest.hint();
    final updatedPois =
        pois.map((p) => p.id == nearest!.id ? hinted : p).toList();
    _mysteryPoisNotifier.value = updatedPois;
    _savePoisToCache(updatedPois);

    final spentCharges = charges.spend();
    _compassChargesNotifier.value = spentCharges;
    _saveCompassCharges(spentCharges);
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
    _fogSaveTimer?.cancel();
    _xpController.dispose();
    // Fire-and-forget fog save on dispose — errors swallowed by _saveFogGrid.
    _saveFogGrid();
    _positionSub?.cancel();
    _locationStreamController.close();
    _fogGridNotifier.dispose();
    _mysteryPoisNotifier.dispose();
    _compassChargesNotifier.dispose();
    _discoveriesWaitingNotifier.dispose();
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startWalk() {
    setState(() {
      _sessionXp = 0;
      _walkSession = WalkSession.start(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: DateTime.now(),
      );
    });
  }

  Future<void> _stopWalk(WalkSession session) async {
    final completed = session.complete();
    setState(() => _walkSession = null);

    // Persist walk to Hive.
    try {
      final walkRepo = GetIt.instance<WalkRepository>();
      await walkRepo.saveWalk(completed);
    } catch (_) {
      // Repository not registered in tests — skip.
    }

    // Force-save fog state immediately on walk end.
    _saveFogGrid();
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
            if (_revealingDiscovery != null)
              DiscoveryRevealOverlay(
                discovery: _revealingDiscovery!,
                onComplete: () => setState(() {
                  _pendingDiscovery = _revealingDiscovery;
                  _revealingDiscovery = null;
                }),
              ),
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
            if (_burstPosition != null)
              DiscoveryBurstOverlay(
                position: _burstPosition!,
                category: _burstCategory!,
                onComplete: () => setState(() {
                  _burstPosition = null;
                  _burstCategory = null;
                }),
              ),
            WalkControl(
              session: _walkSession,
              onStart: _startWalk,
              onStop: _stopWalk,
              sessionXp: _sessionXp,
            ),
            // Floating XP text overlay — positioned top-center.
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingXpTextOverlay(controller: _xpController),
              ),
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
            return Stack(
              children: [
                // Fog and location dot don't need tap interaction.
                IgnorePointer(
                  child: Stack(
                    children: [
                      FogLayer(
                        fogGridNotifier: _fogGridNotifier,
                        bounds: camera.visibleBounds,
                        locationStream: _locationStreamController.stream,
                        exploreRadius: 50.0,
                        onFogExpanded:
                            _walkSession != null ? _awardStreetXp : null,
                      ),
                      if (_userPosition != null) _buildLocationDot(camera),
                    ],
                  ),
                ),
                // POI markers need tap handling.
                ValueListenableBuilder<List<MysteryPoi>>(
                  valueListenable: _mysteryPoisNotifier,
                  builder: (context, pois, _) => MysteryPoiMarkerLayer(
                    pois: pois,
                    camera: camera,
                    onRevealedTap: _onRevealedPoiTapped,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _onRevealedPoiTapped(MysteryPoi poi) {
    if (!mounted) return;
    final name = poi.name ?? poi.category;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name — ${poi.category}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
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
          painter: LocationDotPainter(
            pulseProgress: _pulseAnimation.value,
            headingDegrees: _heading,
          ),
        ),
      ),
    );
  }

  Widget _buildOverlays() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top-left: exploration badge.
                ValueListenableBuilder<FogGrid>(
                  valueListenable: _fogGridNotifier,
                  builder: (context, _, __) => ValueListenableBuilder<int>(
                    valueListenable: _discoveriesWaitingNotifier,
                    builder: (context, waiting, __) => ExplorationBadge(
                      percentageExplored: _explorationPct,
                      discoveriesWaiting: waiting,
                    ),
                  ),
                ),
                const Spacer(),
                // Top-right: compass charge button.
                ValueListenableBuilder<CompassCharges>(
                  valueListenable: _compassChargesNotifier,
                  builder: (context, charges, _) => CompassButton(
                    charges: charges.currentCharges,
                    onPressed: _hintNearestUnrevealedPoi,
                  ),
                ),
              ],
            ),
            // XP progress bar below exploration badge.
            if (_activeZone != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: XpProgressBar(
                  currentXp: _activeZone!.xp,
                  nextLevelXp: ZoneLevel.xpForNextLevel(_activeZone!.xp),
                  level: _activeZone!.level,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
