/// Identifies what brought the user to the paywall screen.
///
/// Used to select the contextual hero animation and analytics events.
enum PaywallTrigger {
  /// User tapped the Pro badge on their profile screen.
  profile,

  /// User reached the daily quiz question limit.
  quizLimit,

  /// User entered a new area with no active zone.
  zoneExpansion,

  /// User tapped a blurred Pro stats card.
  stats,

  /// User just completed a significant milestone (zone level-up, streak, etc.).
  milestone,
}
