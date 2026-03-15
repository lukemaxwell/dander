/// Identifies the category of milestone that triggered a Pro suggestion.
enum MilestoneType {
  /// The user's zone reached a new level.
  zoneLevelUp,

  /// The user reached a fog-exploration threshold.
  fogMilestone,

  /// The user hit a walking streak milestone.
  streakMilestone,
}
