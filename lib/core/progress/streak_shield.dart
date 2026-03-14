/// Immutable streak shield — protects a walking streak from one missed week.
///
/// Earned by getting a perfect quiz score (100% correct). Max 1 held at a time.
/// When the streak would break, the shield is consumed instead.
class StreakShield {
  const StreakShield({
    required this.hasShield,
    this.earnedAt,
  });

  factory StreakShield.empty() =>
      const StreakShield(hasShield: false, earnedAt: null);

  /// Whether a shield is currently held.
  final bool hasShield;

  /// When the shield was earned (null if not held).
  final DateTime? earnedAt;

  /// Earn a shield. If already holding one, returns unchanged.
  StreakShield earn(DateTime at) {
    if (hasShield) return StreakShield(hasShield: true, earnedAt: earnedAt);
    return StreakShield(hasShield: true, earnedAt: at);
  }

  /// Consume the shield (used to protect streak). Returns empty shield.
  StreakShield consume() => StreakShield.empty();

  Map<String, dynamic> toJson() => {
        'hasShield': hasShield,
        'earnedAt': earnedAt?.toIso8601String(),
      };

  factory StreakShield.fromJson(Map<String, dynamic> json) {
    final raw = json['earnedAt'] as String?;
    return StreakShield(
      hasShield: json['hasShield'] as bool? ?? false,
      earnedAt: raw != null ? DateTime.parse(raw) : null,
    );
  }
}
