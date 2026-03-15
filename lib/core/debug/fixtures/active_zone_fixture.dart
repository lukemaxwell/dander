import 'package:latlong2/latlong.dart';

import '../../discoveries/discovery.dart';
import '../../discoveries/discovery_repository.dart';
import '../../location/walk_repository.dart';
import '../../location/walk_session.dart';
import '../../storage/app_state_repository.dart';
import '../../zone/mystery_poi.dart';
import '../../zone/mystery_poi_repository.dart';
import '../../zone/zone.dart';
import '../../zone/zone_repository.dart';
import '../seed_fixture.dart';

/// Active zone fixture — one zone with mystery POIs at various states,
/// a partial fog grid, and walk history.
///
/// Uses real Greenwich/Blackheath coordinates for good POI density.
class ActiveZoneFixture extends SeedFixture {
  const ActiveZoneFixture();

  /// Greenwich Park area.
  static const _origin = LatLng(51.4769, -0.0005);

  static const _zoneId = 'seed-zone-greenwich';

  @override
  String get name => 'active_zone';

  @override
  LatLng? get seedPosition => _origin;

  /// The seeded zone — Greenwich with some accumulated XP.
  static final zone = Zone(
    id: _zoneId,
    name: 'Greenwich',
    centre: _origin,
    xp: 350,
    createdAt: DateTime(2025, 3, 1),
  );

  /// Mystery POIs: 2 revealed, 3 hinted (visible as ? markers).
  static const mysteryPois = <MysteryPoi>[
    // Revealed POIs (user has visited these)
    MysteryPoi(
      id: 'node/seed-1',
      position: LatLng(51.4773, -0.0010),
      category: 'monument',
      name: 'General Wolfe Statue',
      state: PoiState.revealed,
    ),
    MysteryPoi(
      id: 'node/seed-2',
      position: LatLng(51.4770, -0.0015),
      category: 'museum',
      name: 'Royal Observatory',
      state: PoiState.revealed,
    ),
    // Hinted POIs (amber ? markers on map)
    MysteryPoi(
      id: 'node/seed-3',
      position: LatLng(51.4780, 0.0005),
      category: 'memorial',
      state: PoiState.hinted,
    ),
    MysteryPoi(
      id: 'node/seed-4',
      position: LatLng(51.4765, -0.0025),
      category: 'viewpoint',
      state: PoiState.hinted,
    ),
    MysteryPoi(
      id: 'node/seed-5',
      position: LatLng(51.4775, 0.0020),
      category: 'artwork',
      state: PoiState.hinted,
    ),
  ];

  /// Corresponding Discovery entries for the revealed POIs.
  static final discoveries = <Discovery>[
    Discovery(
      id: 'node/seed-1',
      name: 'General Wolfe Statue',
      category: 'monument',
      rarity: RarityTier.uncommon,
      position: const LatLng(51.4773, -0.0010),
      osmTags: const {'historic': 'monument', 'name': 'General Wolfe Statue'},
      discoveredAt: DateTime(2025, 3, 10, 14, 4),
    ),
    Discovery(
      id: 'node/seed-2',
      name: 'Royal Observatory',
      category: 'museum',
      rarity: RarityTier.rare,
      position: const LatLng(51.4770, -0.0015),
      osmTags: const {'tourism': 'museum', 'name': 'Royal Observatory'},
      discoveredAt: DateTime(2025, 3, 10, 14, 6),
    ),
  ];

  /// A realistic walked route through Greenwich Park.
  static const _walkedRoute = <LatLng>[
    LatLng(51.4769, -0.0005),
    LatLng(51.4770, -0.0007),
    LatLng(51.4771, -0.0009),
    LatLng(51.4772, -0.0010),
    LatLng(51.4773, -0.0010),
    LatLng(51.4773, -0.0012),
    LatLng(51.4772, -0.0014),
    LatLng(51.4771, -0.0015),
    LatLng(51.4770, -0.0015),
    LatLng(51.4769, -0.0014),
    LatLng(51.4768, -0.0012),
    LatLng(51.4768, -0.0009),
    LatLng(51.4769, -0.0005),
  ];

  /// Completed walk session matching the walked route.
  static final walkSession = _buildWalkSession();

  static WalkSession _buildWalkSession() {
    final start = DateTime(2025, 3, 10, 14, 0);
    var session = WalkSession.start(id: 'seed-walk-1', startTime: start);
    for (var i = 0; i < _walkedRoute.length; i++) {
      session = session.addPoint(
        WalkPoint(
          position: _walkedRoute[i],
          timestamp: start.add(Duration(seconds: i * 30)),
        ),
      );
    }
    return session.completeAt(
      start.add(Duration(seconds: _walkedRoute.length * 30)),
    );
  }

  @override
  List<List<LatLng>> get walkedPaths => [_walkedRoute];

  @override
  Future<void> seedAppState(AppStateRepository repo) async {
    await repo.saveLastPosition(_origin);
  }

  @override
  Future<void> seedData({
    required ZoneRepository zoneRepository,
    required MysteryPoiRepository mysteryPoiRepository,
    required WalkRepository walkRepository,
    required DiscoveryRepository discoveryRepository,
  }) async {
    await zoneRepository.save(zone);
    await mysteryPoiRepository.savePois(_zoneId, mysteryPois);
    await mysteryPoiRepository.saveTotalCount(_zoneId, mysteryPois.length);
    await mysteryPoiRepository.saveWaveState(_zoneId, 1, 2);
    await walkRepository.saveWalk(walkSession);
    for (final discovery in discoveries) {
      await discoveryRepository.saveDiscovered(discovery);
    }
  }
}
