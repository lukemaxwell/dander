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

  /// Populates the app state repository (onboarding flags, last position).
  Future<void> seedAppState(AppStateRepository repo) async {}
}
