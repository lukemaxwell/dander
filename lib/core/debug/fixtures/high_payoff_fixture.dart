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

/// High-payoff marketing fixture — rich map state with multiple discoveries,
/// a large explored area, and dramatic fog contrast for hero visuals.
///
/// Produces a map with:
/// - Three walked routes covering a wide area (~25-30% fog cleared)
/// - 4 revealed discoveries with real landmark names (coloured pins)
/// - 4 hinted ? markers at the exploration frontier
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

  /// 10 mystery POIs: 4 revealed, 4 hinted (visible), 2 unrevealed (hidden).
  static const mysteryPois = <MysteryPoi>[
    // Revealed — coloured category pins on map
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
      position: LatLng(51.4758, -0.0018),
      category: 'museum',
      name: 'National Maritime Museum',
      state: PoiState.revealed,
    ),
    MysteryPoi(
      id: 'node/high-4',
      position: LatLng(51.4780, 0.0008),
      category: 'viewpoint',
      name: 'Thames Path Viewpoint',
      state: PoiState.revealed,
    ),
    // Hinted — amber pulsing ? markers (visible on map)
    MysteryPoi(
      id: 'node/high-5',
      position: LatLng(51.4785, 0.0025),
      category: 'memorial',
      state: PoiState.hinted,
    ),
    MysteryPoi(
      id: 'node/high-6',
      position: LatLng(51.4752, -0.0035),
      category: 'artwork',
      state: PoiState.hinted,
    ),
    MysteryPoi(
      id: 'node/high-7',
      position: LatLng(51.4785, -0.0030),
      category: 'fountain',
      state: PoiState.hinted,
    ),
    MysteryPoi(
      id: 'node/high-8',
      position: LatLng(51.4755, 0.0020),
      category: 'statue',
      state: PoiState.hinted,
    ),
    // Unrevealed — hidden, future waves
    MysteryPoi(
      id: 'node/high-9',
      position: LatLng(51.4790, -0.0005),
      category: 'library',
      state: PoiState.unrevealed,
    ),
    MysteryPoi(
      id: 'node/high-10',
      position: LatLng(51.4748, -0.0008),
      category: 'park',
      state: PoiState.unrevealed,
    ),
  ];

  /// Corresponding Discovery entries for revealed POIs.
  static final discoveries = <Discovery>[
    Discovery(
      id: 'node/high-1',
      name: 'General Wolfe Statue',
      category: 'monument',
      rarity: RarityTier.uncommon,
      position: const LatLng(51.4773, -0.0010),
      osmTags: const {'historic': 'monument', 'name': 'General Wolfe Statue'},
      discoveredAt: DateTime(2025, 3, 5, 9, 12),
    ),
    Discovery(
      id: 'node/high-2',
      name: 'Royal Observatory',
      category: 'museum',
      rarity: RarityTier.rare,
      position: const LatLng(51.4770, -0.0015),
      osmTags: const {'tourism': 'museum', 'name': 'Royal Observatory'},
      discoveredAt: DateTime(2025, 3, 5, 9, 25),
    ),
    Discovery(
      id: 'node/high-3',
      name: 'National Maritime Museum',
      category: 'museum',
      rarity: RarityTier.rare,
      position: const LatLng(51.4758, -0.0018),
      osmTags: const {
        'tourism': 'museum',
        'name': 'National Maritime Museum',
      },
      discoveredAt: DateTime(2025, 3, 8, 14, 40),
    ),
    Discovery(
      id: 'node/high-4',
      name: 'Thames Path Viewpoint',
      category: 'viewpoint',
      rarity: RarityTier.uncommon,
      position: const LatLng(51.4780, 0.0008),
      osmTags: const {'tourism': 'viewpoint', 'name': 'Thames Path Viewpoint'},
      discoveredAt: DateTime(2025, 3, 12, 11, 5),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Walked routes — three routes for wide coverage
  // ---------------------------------------------------------------------------

  /// Route 1: Large park loop (north).
  static const _route1 = <LatLng>[
    LatLng(51.4772, -0.0008),
    LatLng(51.4774, -0.0010),
    LatLng(51.4776, -0.0012),
    LatLng(51.4778, -0.0014),
    LatLng(51.4780, -0.0012),
    LatLng(51.4782, -0.0010),
    LatLng(51.4784, -0.0008),
    LatLng(51.4784, -0.0005),
    LatLng(51.4784, -0.0002),
    LatLng(51.4784, 0.0001),
    LatLng(51.4784, 0.0004),
    LatLng(51.4782, 0.0006),
    LatLng(51.4780, 0.0008),
    LatLng(51.4778, 0.0006),
    LatLng(51.4776, 0.0004),
    LatLng(51.4774, 0.0002),
    LatLng(51.4772, 0.0000),
    LatLng(51.4772, -0.0004),
    LatLng(51.4772, -0.0008),
  ];

  /// Route 2: South toward maritime quarter and waterfront.
  static const _route2 = <LatLng>[
    LatLng(51.4772, -0.0008),
    LatLng(51.4770, -0.0010),
    LatLng(51.4768, -0.0012),
    LatLng(51.4766, -0.0014),
    LatLng(51.4764, -0.0016),
    LatLng(51.4762, -0.0018),
    LatLng(51.4760, -0.0020),
    LatLng(51.4758, -0.0018),
    LatLng(51.4756, -0.0016),
    LatLng(51.4754, -0.0014),
    LatLng(51.4754, -0.0010),
    LatLng(51.4754, -0.0006),
    LatLng(51.4754, -0.0002),
    LatLng(51.4756, -0.0002),
    LatLng(51.4758, -0.0004),
    LatLng(51.4760, -0.0006),
    LatLng(51.4762, -0.0008),
    LatLng(51.4764, -0.0008),
    LatLng(51.4766, -0.0008),
    LatLng(51.4768, -0.0008),
    LatLng(51.4770, -0.0008),
    LatLng(51.4772, -0.0008),
  ];

  /// Route 3: East toward Thames and back.
  static const _route3 = <LatLng>[
    LatLng(51.4772, -0.0008),
    LatLng(51.4772, -0.0004),
    LatLng(51.4772, 0.0000),
    LatLng(51.4772, 0.0004),
    LatLng(51.4772, 0.0008),
    LatLng(51.4772, 0.0012),
    LatLng(51.4774, 0.0012),
    LatLng(51.4776, 0.0010),
    LatLng(51.4778, 0.0008),
    LatLng(51.4776, 0.0006),
    LatLng(51.4774, 0.0004),
    LatLng(51.4772, 0.0002),
    // South branch
    LatLng(51.4770, 0.0004),
    LatLng(51.4768, 0.0006),
    LatLng(51.4766, 0.0008),
    LatLng(51.4764, 0.0006),
    LatLng(51.4762, 0.0004),
    LatLng(51.4762, 0.0000),
    LatLng(51.4764, -0.0002),
    LatLng(51.4766, -0.0004),
    LatLng(51.4768, -0.0006),
    LatLng(51.4770, -0.0008),
    LatLng(51.4772, -0.0008),
  ];

  static final _walk1 = _buildWalkSession(
    'seed-walk-high-1',
    _route1,
    DateTime(2025, 3, 5, 9, 0),
  );
  static final _walk2 = _buildWalkSession(
    'seed-walk-high-2',
    _route2,
    DateTime(2025, 3, 8, 14, 30),
  );
  static final _walk3 = _buildWalkSession(
    'seed-walk-high-3',
    _route3,
    DateTime(2025, 3, 12, 11, 0),
  );

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
  List<List<LatLng>> get walkedPaths => [_route1, _route2, _route3];

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
    await mysteryPoiRepository.saveWaveState(_zoneId, 2, 4);
    await walkRepository.saveWalk(_walk1);
    await walkRepository.saveWalk(_walk2);
    await walkRepository.saveWalk(_walk3);
    for (final discovery in discoveries) {
      await discoveryRepository.saveDiscovered(discovery);
    }
  }
}
