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
import 'package:dander/core/sharing/share_service.dart';
import 'package:dander/core/storage/app_state_repository.dart';
import 'package:dander/core/location/compass_heading_service.dart';
import 'package:dander/core/location/location_service.dart';
import 'package:dander/core/onboarding/first_launch_service.dart';
import 'package:dander/features/map/presentation/widgets/exploration_chip.dart';
import 'package:dander/features/map/presentation/widgets/first_walk_contract_overlay.dart';
import 'package:dander/features/map/presentation/widgets/post_first_walk_overlay.dart';
import 'package:dander/features/map/presentation/widgets/walk_preview_overlay.dart';
import 'package:dander/features/sharing/presentation/widgets/first_walk_share_card.dart';
import 'package:dander/features/walk/domain/models/walk_summary.dart';
import 'package:dander/core/location/walk_repository.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/core/subscription/banner_cooldown_repository.dart';
import 'package:dander/core/subscription/milestone_pro_suggestion_frequency.dart';
import 'package:dander/core/subscription/milestone_type.dart';
import 'package:dander/core/subscription/outside_zone_detector.dart';
import 'package:dander/core/subscription/subscription_service.dart';
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
import 'package:dander/features/subscription/paywall_trigger.dart';
import 'package:dander/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:dander/features/subscription/presentation/widgets/zone_expansion_banner.dart';
import 'package:dander/features/map/presentation/widgets/discovery_burst_overlay.dart';
import 'package:dander/features/map/presentation/widgets/exploration_badge.dart';
import 'package:dander/features/map/presentation/widgets/fog_layer.dart';
import 'package:dander/features/map/presentation/widgets/level_up_overlay.dart';
import 'package:dander/features/map/presentation/widgets/location_dot_painter.dart';
import 'package:dander/features/map/presentation/widgets/mystery_marker_beacon.dart';
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
    with TickerProviderStateMixin {
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
  CompassHeadingService? _compassHeadingService;
  StreamSubscription<double>? _headingSub;
  WalkSession? _walkSession;

  // Zone progression state
  zone_model.Zone? _activeZone;
  LevelUpEvent? _levelUpEvent;
  bool _zonePromptShown = false;

  // Pro-suggestion state for level-up overlay.
  bool _showLevelUpProSuggestion = false;

  // Zone-expansion banner state (shown to free users outside all zones).
  bool _showZoneExpansionBanner = false;

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

  // Distance accumulator for XP awards — 10 XP per 100 m walked.
  double _walkXpMeters = 0.0;

  // First-launch onboarding state.
  FirstLaunchService? _firstLaunchService;
  bool _showExplorationChip = false;
  bool _showWalkPreview = false;
  bool _showFirstWalkContract = false;
  double _firstWalkDistance = 0;
  bool _showPostFirstWalkOverlay = false;
  bool _isFirstWalkCompleted = false;

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
    // Load first-launch state.
    try {
      _firstLaunchService = GetIt.instance<FirstLaunchService>();
    } catch (_) {
      _firstLaunchService = const FirstLaunchService(isFirstLaunch: false);
    }

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
        final radius = _firstLaunchService!.explorationRadius;
        grid.markExplored(latLng, radius);
        setState(() {
          _currentCenter = latLng;
          _userPosition = latLng;
          _fogGridNotifier.value = grid;
          _showExplorationChip = _firstLaunchService!.isFirstLaunch;
          _showWalkPreview = _firstLaunchService!.isFirstLaunch;
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

    // Wire up the dedicated compass heading service for smooth, distance-filter-
    // independent heading updates.
    try {
      _compassHeadingService = GetIt.instance<CompassHeadingService>();
    } catch (_) {
      // Not registered in tests — heading falls back to GPS position.heading.
    }
    _headingSub = _compassHeadingService?.headingStream.listen((degrees) {
      if (mounted) setState(() => _heading = degrees);
    });

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
      _checkBannerVisibility(latLng);
      if (_walkSession != null) {
        _earnChargesFromMove(latLng);
        _earnWalkXp(latLng);
        // Track walk points.
        _walkSession = _walkSession!.addPoint(
          WalkPoint(position: latLng, timestamp: DateTime.now()),
        );
        // Update first walk contract distance counter.
        if (_showFirstWalkContract && mounted) {
          setState(() {
            _firstWalkDistance = _walkSession!.distanceMeters;
          });
        }
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
          if (event != null) {
            _levelUpEvent = event;
            _showLevelUpProSuggestion = _computeProSuggestion();
          }
        });
      }
    } catch (_) {
      // Zone service not available — skip
    }
  }

  Future<void> _checkZoneOnMove(LatLng position) async {
    if (_zonePromptShown) return;
    // Don't trigger zone prompts during first-launch onboarding overlays.
    if (_showWalkPreview || _showFirstWalkContract || _showPostFirstWalkOverlay) {
      return;
    }

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

  /// Evaluates whether the zone-expansion banner should be shown.
  ///
  /// Shows the banner when ALL of the following conditions are true:
  /// - The user is not a Pro subscriber.
  /// - The user is outside every configured zone.
  /// - The banner cooldown has not been triggered within the last 48 hours.
  /// - First-launch onboarding overlays are not active.
  Future<void> _checkBannerVisibility(LatLng position) async {
    if (_showBannerOnboarding) return;
    try {
      final subService = GetIt.instance<SubscriptionService>();
      if (subService.state.value.isPro) {
        if (mounted && _showZoneExpansionBanner) {
          setState(() => _showZoneExpansionBanner = false);
        }
        return;
      }

      final cooldownRepo = GetIt.instance<BannerCooldownRepository>();
      if (cooldownRepo.isOnCooldown()) return;

      final zoneRepo = GetIt.instance<ZoneRepository>();
      final zones = await zoneRepo.loadAll();
      final outside = OutsideZoneDetector.isOutside(position, zones);

      if (mounted && outside && !_showZoneExpansionBanner) {
        setState(() => _showZoneExpansionBanner = true);
      } else if (mounted && !outside && _showZoneExpansionBanner) {
        setState(() => _showZoneExpansionBanner = false);
      }
    } catch (_) {
      // Services not registered — skip.
    }
  }

  /// Returns true when first-launch onboarding overlays are visible.
  bool get _showBannerOnboarding =>
      _showWalkPreview || _showFirstWalkContract || _showPostFirstWalkOverlay;

  /// Determines whether the Pro-suggestion card should appear in the level-up
  /// overlay. Records the milestone and returns true only when the user is not
  /// a Pro subscriber and the frequency utility says to show it.
  bool _computeProSuggestion() {
    try {
      final subService = GetIt.instance<SubscriptionService>();
      if (subService.state.value.isPro) return false;

      final freq = GetIt.instance<MilestoneProSuggestionFrequency>();
      freq.record();
      return freq.shouldShow();
    } catch (_) {
      // Services not registered in tests — skip.
      return false;
    }
  }

  void _dismissZoneExpansionBanner() {
    setState(() => _showZoneExpansionBanner = false);
    try {
      final cooldownRepo = GetIt.instance<BannerCooldownRepository>();
      cooldownRepo.markDismissed();
    } catch (_) {
      // Repository not registered in tests — skip.
    }
  }

  void _navigateToPaywall() {
    setState(() => _showZoneExpansionBanner = false);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PaywallScreen(trigger: PaywallTrigger.zoneExpansion),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _showNewZonePrompt(LatLng position) async {
    final nameController = TextEditingController(text: 'New Zone')
      ..selection = TextSelection.collapsed(offset: 'New Zone'.length);
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: DanderColors.surfaceElevated,
          title: Text("You're somewhere new!",
              style: DanderTextStyles.titleMedium),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: DanderTextStyles.bodyMedium,
            cursorColor: DanderColors.accent,
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

  /// Called when the user reaches 200m during the first walk contract.
  /// Auto-creates the first zone and fires the celebration.
  Future<void> _onFirstWalkGoalReached() async {
    setState(() {
      _showFirstWalkContract = false;
      _isFirstWalkCompleted = true;
    });

    if (_userPosition == null) return;

    // Show zone naming prompt and create the first zone.
    await _showNewZonePrompt(_userPosition!);

    // Persist that the contract was completed so it doesn't reappear.
    try {
      final appStateRepo = GetIt.instance<AppStateRepository>();
      await appStateRepo.markFirstWalkContractCompleted();
    } catch (_) {
      // Repository not available in tests.
    }
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
          if (event != null) {
            _levelUpEvent = event;
            _showLevelUpProSuggestion = _computeProSuggestion();
          }
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

  /// Awards [ZoneLevel.xpPerStreet] XP for every 100 m walked.
  ///
  /// Called on each GPS update during a walk session. Accumulates fractional
  /// metres so no distance is lost between updates.
  void _earnWalkXp(LatLng newPosition) {
    final prev = _prevPosition;
    if (prev == null) return;
    try {
      final detector = GetIt.instance<ZoneDetector>();
      _walkXpMeters += detector.distanceBetween(prev, newPosition);
      while (_walkXpMeters >= 100.0) {
        _walkXpMeters -= 100.0;
        _awardStreetXp();
      }
    } catch (_) {
      // ZoneDetector not registered — skip.
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
      await repo.saveDiscovered(discovery);
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
    _headingSub?.cancel();
    _compassHeadingService?.dispose();
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
    _walkXpMeters = 0.0;
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
    final isFirstWalk = _isFirstWalkCompleted &&
        _firstLaunchService?.isFirstLaunch == true;
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

    // First walk zoom-out: animate camera to neighbourhood scale, then
    // show share prompt.
    if (isFirstWalk && mounted) {
      _isFirstWalkCompleted = false; // Only fire once.
      await _animateZoomOut();
      if (mounted) {
        setState(() => _showPostFirstWalkOverlay = true);
      }
    }
  }

  /// Smoothly zooms the camera out to neighbourhood scale (~14) over 2 seconds.
  Future<void> _animateZoomOut() async {
    const targetZoom = 14.0;
    final startZoom = _mapController.camera.zoom;
    if (startZoom <= targetZoom) return; // Already zoomed out enough.

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    final animation = Tween<double>(begin: startZoom, end: targetZoom).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
    final center = _mapController.camera.center;

    animation.addListener(() {
      if (mounted) {
        _mapController.move(center, animation.value);
      }
    });

    await controller.forward();
    controller.dispose();

    // Brief pause after zoom-out settles.
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  /// Renders and shares the first walk share card via the native share sheet.
  Future<void> _shareFirstWalk() async {
    setState(() => _showPostFirstWalkOverlay = false);

    try {
      final shareService = GetIt.instance<ShareService>();
      final summary = WalkSummary(
        id: 'first-walk',
        startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        endedAt: DateTime.now(),
        distanceMetres: _firstWalkDistance,
        fogClearedPercent: _explorationPct.toDouble(),
        discoveriesFound: 0,
      );
      final imageBytes = await shareService.captureWidget(
        FirstWalkShareCard(walkSummary: summary),
        size: const Size(
          FirstWalkShareCard.cardWidth,
          FirstWalkShareCard.cardHeight,
        ),
      );
      await shareService.shareImage(imageBytes, subject: 'My first Dander walk');
    } catch (_) {
      // Share service not available — dismiss silently.
    }
  }

  /// Returns the [MysteryPoi] from [pois] with the smallest Haversine distance
  /// to [userPosition].
  MysteryPoi _nearestPoi(List<MysteryPoi> pois, LatLng userPosition) {
    MysteryPoi nearest = pois.first;
    double nearestDist = double.infinity;
    for (final poi in pois) {
      // Approximate distance using a simple latitude/longitude delta — sufficient
      // here because we only need the closest among a handful of nearby POIs.
      final dLat = poi.position.latitude - userPosition.latitude;
      final dLon = poi.position.longitude - userPosition.longitude;
      final distSq = dLat * dLat + dLon * dLon;
      if (distSq < nearestDist) {
        nearestDist = distSq;
        nearest = poi;
      }
    }
    return nearest;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: LevelUpOverlay(
        event: _levelUpEvent,
        onDismissed: () => setState(() {
          _levelUpEvent = null;
          _showLevelUpProSuggestion = false;
        }),
        showProSuggestion: _showLevelUpProSuggestion,
        milestoneType: MilestoneType.zoneLevelUp,
        onLearnAboutPro: () {
          setState(() {
            _levelUpEvent = null;
            _showLevelUpProSuggestion = false;
          });
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PaywallScreen(
                trigger: PaywallTrigger.milestone,
              ),
              fullscreenDialog: true,
            ),
          );
        },
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
            if (_burstPosition != null)
              DiscoveryBurstOverlay(
                position: _burstPosition!,
                category: _burstCategory!,
                onComplete: () => setState(() {
                  _burstPosition = null;
                  _burstCategory = null;
                }),
              ),
            // Mystery POI beacon — floating navigation HUD above the walk
            // control pointing toward the nearest hinted POI.
            ValueListenableBuilder<List<MysteryPoi>>(
              valueListenable: _mysteryPoisNotifier,
              builder: (context, pois, _) {
                final hinted =
                    pois.where((p) => p.state == PoiState.hinted).toList();
                if (hinted.isEmpty || _userPosition == null) {
                  return const SizedBox.shrink();
                }
                final nearest = _nearestPoi(hinted, _userPosition!);
                return Positioned(
                  bottom: 120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: MysteryMarkerBeacon(
                      userPosition: _userPosition!,
                      targetPosition: LatLng(
                        nearest.position.latitude,
                        nearest.position.longitude,
                      ),
                      headingDegrees: _heading,
                    ),
                  ),
                );
              },
            ),
            // Hide walk control during first-launch onboarding overlays.
            if (!_showWalkPreview && !_showExplorationChip)
              WalkControl(
                session: _walkSession,
                onStart: _startWalk,
                onStop: _stopWalk,
                sessionXp: _sessionXp,
              ),
            // Discovery notification — rendered above walk control so it's visible.
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
            // First-launch exploration chip — only visible between
            // preview dismissal and walk contract appearing.
            if (_showExplorationChip && !_showWalkPreview)
              Positioned(
                bottom: 180,
                left: 0,
                right: 0,
                child: Center(
                  child: ExplorationChip(
                    percentageExplored: _explorationPct.toDouble(),
                  ),
                ),
              ),
            // First-launch walk preview overlay.
            if (_showWalkPreview)
              WalkPreviewOverlay(
                isFirstLaunch: true,
                onComplete: () {
                  _firstLaunchService =
                      _firstLaunchService?.completeWalkPreview();
                  setState(() {
                    _showWalkPreview = false;
                    _showExplorationChip = false;
                    _showFirstWalkContract =
                        _firstLaunchService?.showFirstWalkContract ?? false;
                  });
                },
              ),
            // First walk contract — 200m prompt with live counter.
            if (_showFirstWalkContract)
              Positioned(
                bottom: 230,
                left: DanderSpacing.md,
                right: DanderSpacing.md,
                child: FirstWalkContractOverlay(
                  distanceWalked: _firstWalkDistance,
                  onDismissed: () =>
                      setState(() => _showFirstWalkContract = false),
                  onGoalReached: _onFirstWalkGoalReached,
                ),
              ),
            // Post-first-walk share prompt.
            if (_showPostFirstWalkOverlay)
              PostFirstWalkOverlay(
                onShare: _shareFirstWalk,
                onDismiss: () =>
                    setState(() => _showPostFirstWalkOverlay = false),
              ),
            // Zone-expansion banner — shown just below the safe-area app bar.
            if (_showZoneExpansionBanner)
              Positioned(
                top: MediaQuery.of(context).padding.top + 56,
                left: 0,
                right: 0,
                child: ZoneExpansionBanner(
                  onNavigateToPaywall: _navigateToPaywall,
                  onDismiss: _dismissZoneExpansionBanner,
                ),
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
                        exploreRadius:
                            _firstLaunchService?.explorationRadius ?? 50.0,
                        onFogExpanded: null,
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
