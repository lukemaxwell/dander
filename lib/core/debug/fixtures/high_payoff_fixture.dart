import 'package:latlong2/latlong.dart';

import '../../location/walk_repository.dart';
import '../../location/walk_session.dart';
import '../../storage/app_state_repository.dart';
import '../../zone/mystery_poi.dart';
import '../../zone/mystery_poi_repository.dart';
import '../../zone/zone.dart';
import '../../zone/zone_repository.dart';
import '../seed_fixture.dart';

/// High-payoff marketing fixture — rich map state with multiple discoveries,
/// a large explored area, and dramatic fog contrast for hero visuals.
///
/// Produces a map with:
/// - Two walked routes covering a wide area
/// - 4 revealed discoveries with real landmark names
/// - 4 unrevealed ? markers at the edges of explored area
/// - Zone at level 3+ with high XP
class HighPayoffFixture extends SeedFixture {
  const HighPayoffFixture();

  static const _origin = LatLng(51.4772, -0.0008);
  static const _zoneId = 'seed-zone-greenwich-high';

  @override
  String get name => 'high_payoff';

  @override
  LatLng? get seedPosition => _origin;

  /// Zone with high XP (level 3+ range).
  static final zone = Zone(
    id: _zoneId,
    name: 'Greenwich',
    centre: _origin,
    xp: 1200,
    createdAt: DateTime(2025, 2, 1),
  );

  /// 8 mystery POIs: 4 revealed, 4 unrevealed.
  static const mysteryPois = <MysteryPoi>[
    // Revealed (user has visited these landmarks)
    MysteryPoi(
      id: 'node/high-1',
      position: LatLng(51.4773, -0.0010),
      category: 'monument',
      name: 'General Wolfe Statue',
      state: PoiState.revealed,
    ),
    MysteryPoi(
      id: 'node/high-2',
      position: LatLng(51.4770, -0.0015),
      category: 'museum',
      name: 'Royal Observatory',
      state: PoiState.revealed,
    ),
    MysteryPoi(
      id: 'node/high-3',
      position: LatLng(51.4768, -0.0018),
      category: 'museum',
      name: 'National Maritime Museum',
      state: PoiState.revealed,
    ),
    MysteryPoi(
      id: 'node/high-4',
      position: LatLng(51.4776, 0.0010),
      category: 'viewpoint',
      name: 'Thames Path Viewpoint',
      state: PoiState.revealed,
    ),
    // Unrevealed (? markers at exploration frontier)
    MysteryPoi(
      id: 'node/high-5',
      position: LatLng(51.4785, 0.0025),
      category: 'memorial',
      state: PoiState.unrevealed,
    ),
    MysteryPoi(
      id: 'node/high-6',
      position: LatLng(51.4755, -0.0035),
      category: 'artwork',
      state: PoiState.unrevealed,
    ),
    MysteryPoi(
      id: 'node/high-7',
      position: LatLng(51.4782, -0.0030),
      category: 'fountain',
      state: PoiState.unrevealed,
    ),
    MysteryPoi(
      id: 'node/high-8',
      position: LatLng(51.4758, 0.0020),
      category: 'statue',
      state: PoiState.unrevealed,
    ),
  ];

  /// Route 1: Through Greenwich Park (north-south loop).
  static const _route1 = <LatLng>[
    LatLng(51.4769, -0.0005),
    LatLng(51.4770, -0.0007),
    LatLng(51.4771, -0.0009),
    LatLng(51.4772, -0.0010),
    LatLng(51.4773, -0.0010),
    LatLng(51.4774, -0.0009),
    LatLng(51.4775, -0.0007),
    LatLng(51.4776, -0.0005),
    LatLng(51.4776, -0.0003),
    LatLng(51.4775, -0.0001),
    LatLng(51.4774, 0.0001),
    LatLng(51.4773, 0.0001),
    LatLng(51.4772, -0.0001),
    LatLng(51.4771, -0.0003),
    LatLng(51.4770, -0.0004),
    LatLng(51.4769, -0.0005),
  ];

  /// Route 2: South toward maritime museum and east along Thames path.
  static const _route2 = <LatLng>[
    LatLng(51.4769, -0.0005),
    LatLng(51.4768, -0.0007),
    LatLng(51.4767, -0.0010),
    LatLng(51.4766, -0.0014),
    LatLng(51.4767, -0.0017),
    LatLng(51.4768, -0.0018),
    LatLng(51.4769, -0.0015),
    LatLng(51.4770, -0.0010),
    // East toward Thames
    LatLng(51.4771, -0.0005),
    LatLng(51.4772, 0.0000),
    LatLng(51.4773, 0.0005),
    LatLng(51.4774, 0.0008),
    LatLng(51.4775, 0.0010),
    LatLng(51.4776, 0.0010),
    LatLng(51.4776, 0.0005),
    LatLng(51.4775, 0.0002),
    LatLng(51.4774, -0.0001),
    LatLng(51.4773, -0.0003),
    LatLng(51.4772, -0.0005),
    LatLng(51.4771, -0.0005),
    LatLng(51.4770, -0.0005),
    LatLng(51.4769, -0.0005),
  ];

  static final _walk1 = _buildWalkSession('seed-walk-high-1', _route1,
      DateTime(2025, 3, 5, 9, 0));
  static final _walk2 = _buildWalkSession('seed-walk-high-2', _route2,
      DateTime(2025, 3, 8, 14, 30));

  static WalkSession _buildWalkSession(
    String id,
    List<LatLng> route,
    DateTime start,
  ) {
    var session = WalkSession.start(id: id, startTime: start);
    for (var i = 0; i < route.length; i++) {
      session = session.addPoint(
        WalkPoint(
          position: route[i],
          timestamp: start.add(Duration(seconds: i * 20)),
        ),
      );
    }
    return session.completeAt(
      start.add(Duration(seconds: route.length * 20)),
    );
  }

  @override
  List<List<LatLng>> get walkedPaths => [_route1, _route2];

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
    await walkRepository.saveWalk(_walk1);
    await walkRepository.saveWalk(_walk2);
  }
}
