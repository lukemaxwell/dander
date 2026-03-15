import 'package:latlong2/latlong.dart';

import '../storage/app_state_repository.dart';

/// Abstract base for seed fixtures that populate repositories with
/// deterministic data for testing, debugging, and marketing screenshots.
///
/// Each concrete fixture populates the subset of repositories it needs.
/// The default implementations are no-ops so fixtures only override
/// the data they care about.
abstract class SeedFixture {
  const SeedFixture();

  /// Human-readable name for logging.
  String get name;

  /// Whether the fixture should suppress onboarding (mark first launch complete).
  /// Defaults to `true` — most fixtures want to skip onboarding.
  bool get suppressOnboarding => true;

  /// The fake GPS position to use for this fixture.
  ///
  /// When non-null, [FakeLocationService] is registered instead of the real
  /// GPS service. Return `null` to use real location (e.g. the `empty` fixture).
  LatLng? get seedPosition => null;

  /// Pre-walked paths to clear in the fog grid.
  ///
  /// Each inner list is a sequence of [LatLng] points representing a walked
  /// route. The fog seeder marks cells along each path as explored.
  /// Return an empty list (default) for no fog seeding.
  List<List<LatLng>> get walkedPaths => const [];

  /// Populates the app state repository (onboarding flags, last position).
  Future<void> seedAppState(AppStateRepository repo) async {}
}
