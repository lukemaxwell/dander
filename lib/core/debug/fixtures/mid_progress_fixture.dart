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

/// Mid-progress marketing fixture — visible walked route, discoveries,
/// and enough UI state to feel alive. Default hero screenshot preset.
///
/// Produces a map with:
/// - Wide looping walked routes through Greenwich Park (strong fog contrast)
/// - 2 revealed discoveries with real landmark names (coloured pins)
/// - 3 hinted ? markers at the exploration frontier
/// - Zone at level 2 with moderate XP
/// - ~15-20% fog exploration within the zone bounds
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

  /// 8 mystery POIs: 2 revealed, 3 hinted (visible as ?), 3 unrevealed (hidden).
  static const mysteryPois = <MysteryPoi>[
    // Revealed — coloured category pins on map
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
    // Hinted — amber pulsing ? markers (visible on map)
    MysteryPoi(
      id: 'node/mid-3',
      position: LatLng(51.4780, 0.0005),
      category: 'memorial',
      state: PoiState.hinted,
    ),
    MysteryPoi(
      id: 'node/mid-4',
      position: LatLng(51.4762, -0.0030),
      category: 'viewpoint',
      state: PoiState.hinted,
    ),
    MysteryPoi(
      id: 'node/mid-5',
      position: LatLng(51.4778, 0.0018),
      category: 'artwork',
      state: PoiState.hinted,
    ),
    // Unrevealed — hidden, future waves
    MysteryPoi(
      id: 'node/mid-6',
      position: LatLng(51.4760, -0.0005),
      category: 'fountain',
      state: PoiState.unrevealed,
    ),
    MysteryPoi(
      id: 'node/mid-7',
      position: LatLng(51.4782, -0.0020),
      category: 'statue',
      state: PoiState.unrevealed,
    ),
    MysteryPoi(
      id: 'node/mid-8',
      position: LatLng(51.4758, 0.0010),
      category: 'library',
      state: PoiState.unrevealed,
    ),
  ];

  /// Corresponding Discovery entries for the revealed POIs.
  static final discoveries = <Discovery>[
    Discovery(
      id: 'node/mid-1',
      name: 'General Wolfe Statue',
      category: 'monument',
      rarity: RarityTier.uncommon,
      position: const LatLng(51.4773, -0.0010),
      osmTags: const {'historic': 'monument', 'name': 'General Wolfe Statue'},
      discoveredAt: DateTime(2025, 3, 8, 10, 8),
    ),
    Discovery(
      id: 'node/mid-2',
      name: 'National Maritime Museum',
      category: 'museum',
      rarity: RarityTier.rare,
      position: const LatLng(51.4768, -0.0018),
      osmTags: const {
        'tourism': 'museum',
        'name': 'National Maritime Museum',
      },
      discoveredAt: DateTime(2025, 3, 8, 10, 18),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Walked routes — spread out for better fog coverage (~15-20% of zone)
  // ---------------------------------------------------------------------------

  /// Main route: large loop through Greenwich Park.
  static const _route1 = <LatLng>[
    // Start south of park
    LatLng(51.4762, -0.0008),
    LatLng(51.4764, -0.0010),
    LatLng(51.4766, -0.0012),
    LatLng(51.4768, -0.0014),
    LatLng(51.4770, -0.0016),
    LatLng(51.4772, -0.0018),
    // West then north along path
    LatLng(51.4774, -0.0016),
    LatLng(51.4776, -0.0014),
    LatLng(51.4778, -0.0012),
    LatLng(51.4780, -0.0010),
    // Along the ridge eastward
    LatLng(51.4780, -0.0007),
    LatLng(51.4780, -0.0004),
    LatLng(51.4780, -0.0001),
    LatLng(51.4780, 0.0002),
    LatLng(51.4780, 0.0005),
    // South through park
    LatLng(51.4778, 0.0004),
    LatLng(51.4776, 0.0003),
    LatLng(51.4774, 0.0002),
    LatLng(51.4772, 0.0001),
    LatLng(51.4770, 0.0000),
    LatLng(51.4768, -0.0002),
    LatLng(51.4766, -0.0004),
    LatLng(51.4764, -0.0006),
    LatLng(51.4762, -0.0008),
  ];

  /// Second route: south toward maritime quarter.
  static const _route2 = <LatLng>[
    LatLng(51.4772, -0.0008),
    LatLng(51.4770, -0.0010),
    LatLng(51.4768, -0.0012),
    LatLng(51.4766, -0.0014),
    LatLng(51.4764, -0.0016),
    LatLng(51.4762, -0.0018),
    LatLng(51.4760, -0.0020),
    LatLng(51.4758, -0.0022),
    // East along waterfront
    LatLng(51.4758, -0.0018),
    LatLng(51.4758, -0.0014),
    LatLng(51.4758, -0.0010),
    LatLng(51.4758, -0.0006),
    LatLng(51.4758, -0.0002),
    // Back north
    LatLng(51.4760, -0.0002),
    LatLng(51.4762, -0.0004),
    LatLng(51.4764, -0.0006),
    LatLng(51.4766, -0.0008),
    LatLng(51.4768, -0.0008),
    LatLng(51.4770, -0.0008),
    LatLng(51.4772, -0.0008),
  ];

  static final _walk1 = _buildWalkSession(
    'seed-walk-mid-1',
    _route1,
    DateTime(2025, 3, 8, 10, 0),
  );
  static final _walk2 = _buildWalkSession(
    'seed-walk-mid-2',
    _route2,
    DateTime(2025, 3, 10, 14, 0),
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
          timestamp: start.add(Duration(seconds: i * 25)),
        ),
      );
    }
    return session.completeAt(
      start.add(Duration(seconds: route.length * 25)),
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
    required DiscoveryRepository discoveryRepository,
  }) async {
    await zoneRepository.save(zone);
    await mysteryPoiRepository.savePois(_zoneId, mysteryPois);
    await mysteryPoiRepository.saveTotalCount(_zoneId, mysteryPois.length);
    await mysteryPoiRepository.saveWaveState(_zoneId, 1, 2);
    await walkRepository.saveWalk(_walk1);
    await walkRepository.saveWalk(_walk2);
    for (final discovery in discoveries) {
      await discoveryRepository.saveDiscovered(discovery);
    }
  }
}
