import 'package:latlong2/latlong.dart';

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

  /// Mystery POIs: 3 unrevealed, 2 revealed.
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
    // Unrevealed POIs (? markers on map)
    MysteryPoi(
      id: 'node/seed-3',
      position: LatLng(51.4780, 0.0005),
      category: 'memorial',
      state: PoiState.unrevealed,
    ),
    MysteryPoi(
      id: 'node/seed-4',
      position: LatLng(51.4765, -0.0025),
      category: 'viewpoint',
      state: PoiState.unrevealed,
    ),
    MysteryPoi(
      id: 'node/seed-5',
      position: LatLng(51.4775, 0.0020),
      category: 'artwork',
      state: PoiState.unrevealed,
    ),
  ];

  /// A realistic walked route through Greenwich Park.
  static final _walkedRoute = <LatLng>[
    const LatLng(51.4769, -0.0005),
    const LatLng(51.4770, -0.0007),
    const LatLng(51.4771, -0.0009),
    const LatLng(51.4772, -0.0010),
    const LatLng(51.4773, -0.0010),
    const LatLng(51.4773, -0.0012),
    const LatLng(51.4772, -0.0014),
    const LatLng(51.4771, -0.0015),
    const LatLng(51.4770, -0.0015),
    const LatLng(51.4769, -0.0014),
    const LatLng(51.4768, -0.0012),
    const LatLng(51.4768, -0.0009),
    const LatLng(51.4769, -0.0005),
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
  }) async {
    await zoneRepository.save(zone);
    await mysteryPoiRepository.savePois(_zoneId, mysteryPois);
    await mysteryPoiRepository.saveTotalCount(_zoneId, mysteryPois.length);
    await walkRepository.saveWalk(walkSession);
  }
}
