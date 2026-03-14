/// Immutable state object tracking the first-launch onboarding phases.
///
/// Created once from [InitResult.isFirstLaunch] and threaded through the
/// onboarding flow. Each phase completion returns a new instance with the
/// relevant flag set.
class FirstLaunchService {
  const FirstLaunchService({
    required this.isFirstLaunch,
    this.microRevealCompleted = false,
  });

  /// Whether this session is the user's very first launch.
  final bool isFirstLaunch;

  /// Whether the 100m micro-reveal animation has completed.
  final bool microRevealCompleted;

  /// Exploration radius used on first launch (larger to create impact).
  static const double firstLaunchExplorationRadius = 100.0;

  /// Default exploration radius for returning users.
  static const double defaultExplorationRadius = 50.0;

  /// Returns the appropriate exploration radius for this session.
  double get explorationRadius =>
      isFirstLaunch ? firstLaunchExplorationRadius : defaultExplorationRadius;

  /// Returns a new instance with [microRevealCompleted] set to `true`.
  FirstLaunchService completeMicroReveal() => FirstLaunchService(
        isFirstLaunch: isFirstLaunch,
        microRevealCompleted: true,
      );
}
