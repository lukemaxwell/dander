import 'dart:math';

/// Types of challenges available in the weekly challenge system.
enum ChallengeType {
  distance,
  discoveries,
  quizStreak,
  fogCleared,
}

/// An immutable weekly challenge with progress tracking.
class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.xpReward,
  });

  final String id;
  final String title;
  final ChallengeType type;
  final double targetValue;
  final double currentValue;
  final int xpReward;

  /// Progress as a fraction from 0.0 to 1.0.
  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);

  /// Whether the challenge target has been met or exceeded.
  bool get isCompleted => currentValue >= targetValue;

  /// Returns a new [Challenge] with [amount] added to [currentValue].
  Challenge addProgress(double amount) {
    return Challenge(
      id: id,
      title: title,
      type: type,
      targetValue: targetValue,
      currentValue: currentValue + amount,
      xpReward: xpReward,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'xpReward': xpReward,
    };
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      type: ChallengeType.values.byName(json['type'] as String),
      targetValue: (json['targetValue'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      xpReward: json['xpReward'] as int,
    );
  }
}

/// Static catalog of challenge definitions and weekly selection logic.
class ChallengeDefinitions {
  ChallengeDefinitions._();

  static final List<Challenge> all = [
    const Challenge(
      id: 'walk-1km',
      title: 'Walk 1 kilometre',
      type: ChallengeType.distance,
      targetValue: 1000,
      currentValue: 0,
      xpReward: 50,
    ),
    const Challenge(
      id: 'walk-3km',
      title: 'Walk 3 kilometres',
      type: ChallengeType.distance,
      targetValue: 3000,
      currentValue: 0,
      xpReward: 100,
    ),
    const Challenge(
      id: 'discover-3-pois',
      title: 'Discover 3 points of interest',
      type: ChallengeType.discoveries,
      targetValue: 3,
      currentValue: 0,
      xpReward: 30,
    ),
    const Challenge(
      id: 'discover-5-pois',
      title: 'Discover 5 points of interest',
      type: ChallengeType.discoveries,
      targetValue: 5,
      currentValue: 0,
      xpReward: 60,
    ),
    const Challenge(
      id: 'quiz-streak-5',
      title: 'Get 5 quiz answers right in a row',
      type: ChallengeType.quizStreak,
      targetValue: 5,
      currentValue: 0,
      xpReward: 25,
    ),
    const Challenge(
      id: 'quiz-streak-10',
      title: 'Get 10 quiz answers right in a row',
      type: ChallengeType.quizStreak,
      targetValue: 10,
      currentValue: 0,
      xpReward: 50,
    ),
    const Challenge(
      id: 'clear-fog-1pct',
      title: 'Clear 1% more fog',
      type: ChallengeType.fogCleared,
      targetValue: 1,
      currentValue: 0,
      xpReward: 20,
    ),
    const Challenge(
      id: 'clear-fog-2pct',
      title: 'Clear 2% more fog',
      type: ChallengeType.fogCleared,
      targetValue: 2,
      currentValue: 0,
      xpReward: 40,
    ),
  ];

  /// Returns 4 challenges for the given [weekNumber].
  ///
  /// Uses a seeded random to ensure the same week always returns
  /// the same set, while different weeks return different sets.
  static List<Challenge> challengesForWeek(int weekNumber) {
    final random = Random(weekNumber);
    final shuffled = List<Challenge>.from(all)..shuffle(random);
    return shuffled.sublist(0, min(4, shuffled.length));
  }
}

/// Aggregates progress across a set of weekly challenges.
class WeeklyProgress {
  const WeeklyProgress({required this.challenges});

  final List<Challenge> challenges;

  int get completedCount => challenges.where((c) => c.isCompleted).length;

  int get totalCount => challenges.length;

  bool get isPerfectWeek => completedCount == totalCount;

  int get totalXpAvailable =>
      challenges.fold(0, (sum, c) => sum + c.xpReward);
}
