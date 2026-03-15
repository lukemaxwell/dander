import 'package:latlong2/latlong.dart';

import '../../location/walk_repository.dart';
import '../../location/walk_session.dart';
import '../../storage/app_state_repository.dart';
import '../../zone/mystery_poi.dart';
import '../../zone/mystery_poi_repository.dart';
import '../../zone/zone.dart';
import '../../zone/zone_repository.dart';
import '../seed_fixture.dart';

/// Mid-progress marketing fixture — visible walked route, discoveries,
/// and enough UI state to feel alive. Default hero screenshot preset.
///
/// Produces a map with:
/// - A looping walked route through Greenwich Park (good fog contrast)
/// - 2 revealed discoveries with real names
/// - 4 unrevealed ? markers scattered nearby
/// - Zone at level 2 with moderate XP
class MidProgressFixture extends SeedFixture {
  const MidProgressFixture();

  static const _origin = LatLng(51.4772, -0.0008);
  static const _zoneId = 'seed-zone-greenwich-mid';

  @override
  String get name => 'mid_progress';

  @override
  LatLng? get seedPosition => _origin;

  /// Zone with moderate XP (level 2 range).
  static final zone = Zone(
    id: _zoneId,
    name: 'Greenwich',
    centre: _origin,
    xp: 500,
    createdAt: DateTime(2025, 2, 20),
  );

  /// 6 mystery POIs: 2 revealed, 4 unrevealed.
  static const mysteryPois = <MysteryPoi>[
    // Revealed
    MysteryPoi(
      id: 'node/mid-1',
      position: LatLng(51.4773, -0.0010),
      category: 'monument',
      name: 'General Wolfe Statue',
      state: PoiState.revealed,
    ),
    MysteryPoi(
      id: 'node/mid-2',
      position: LatLng(51.4768, -0.0018),
      category: 'museum',
      name: 'National Maritime Museum',
      state: PoiState.revealed,
    ),
    // Unrevealed
    MysteryPoi(
      id: 'node/mid-3',
      position: LatLng(51.4780, 0.0005),
      category: 'memorial',
      state: PoiState.unrevealed,
    ),
    MysteryPoi(
      id: 'node/mid-4',
      position: LatLng(51.4762, -0.0030),
      category: 'viewpoint',
      state: PoiState.unrevealed,
    ),
    MysteryPoi(
      id: 'node/mid-5',
      position: LatLng(51.4778, 0.0018),
      category: 'artwork',
      state: PoiState.unrevealed,
    ),
    MysteryPoi(
      id: 'node/mid-6',
      position: LatLng(51.4760, -0.0005),
      category: 'fountain',
      state: PoiState.unrevealed,
    ),
  ];

  /// Looping route through Greenwich Park — creates an interesting fog shape.
  static const _walkedRoute = <LatLng>[
    // Start at park entrance
    LatLng(51.4769, -0.0005),
    LatLng(51.4770, -0.0007),
    LatLng(51.4771, -0.0009),
    // Up toward the observatory
    LatLng(51.4772, -0.0010),
    LatLng(51.4773, -0.0010),
    LatLng(51.4774, -0.0009),
    LatLng(51.4775, -0.0007),
    // Along the ridge
    LatLng(51.4776, -0.0005),
    LatLng(51.4776, -0.0003),
    LatLng(51.4775, -0.0001),
    // Curve back south
    LatLng(51.4774, 0.0001),
    LatLng(51.4773, 0.0001),
    LatLng(51.4772, -0.0001),
    // Back toward start, different path
    LatLng(51.4771, -0.0003),
    LatLng(51.4770, -0.0004),
    LatLng(51.4769, -0.0005),
    // Side loop south
    LatLng(51.4768, -0.0007),
    LatLng(51.4767, -0.0010),
    LatLng(51.4766, -0.0014),
    LatLng(51.4767, -0.0017),
    LatLng(51.4768, -0.0018),
    // Return
    LatLng(51.4769, -0.0015),
    LatLng(51.4770, -0.0010),
    LatLng(51.4769, -0.0005),
  ];

  static final _walkSession = _buildWalkSession();

  static WalkSession _buildWalkSession() {
    final start = DateTime(2025, 3, 8, 10, 0);
    var session = WalkSession.start(id: 'seed-walk-mid-1', startTime: start);
    for (var i = 0; i < _walkedRoute.length; i++) {
      session = session.addPoint(
        WalkPoint(
          position: _walkedRoute[i],
          timestamp: start.add(Duration(seconds: i * 25)),
        ),
      );
    }
    return session.completeAt(
      start.add(Duration(seconds: _walkedRoute.length * 25)),
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
    await walkRepository.saveWalk(_walkSession);
  }
}
