/// Immutable model tracking the POI request cooldown state for a single zone.
///
/// Each zone has an independent cooldown. A cooldown begins when a POI request
/// is recorded via [recordRequest] and expires after [cooldownDuration].
class PoiCooldown {
  const PoiCooldown({
    required this.zoneId,
    this.lastRequestedAt,
    this.cooldownDuration = const Duration(hours: 4),
  });

  /// The zone this cooldown belongs to.
  final String zoneId;

  /// When the last POI request was made, or `null` if never requested.
  final DateTime? lastRequestedAt;

  /// How long after a request the cooldown lasts. Defaults to 4 hours.
  final Duration cooldownDuration;

  /// Returns `true` if a request was made within [cooldownDuration] of [now].
  bool isOnCooldown(DateTime now) {
    if (lastRequestedAt == null) return false;
    final elapsed = now.difference(lastRequestedAt!);
    return elapsed < cooldownDuration;
  }

  /// Returns how much time remains on the cooldown, or [Duration.zero] if
  /// there is no active cooldown.
  Duration remainingCooldown(DateTime now) {
    if (!isOnCooldown(now)) return Duration.zero;
    final elapsed = now.difference(lastRequestedAt!);
    final remaining = cooldownDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Returns a new [PoiCooldown] with [lastRequestedAt] set to [now].
  PoiCooldown recordRequest(DateTime now) => copyWith(lastRequestedAt: now);

  /// Returns a copy with optionally overridden fields.
  ///
  /// Note: to explicitly clear [lastRequestedAt] use [PoiCooldown] directly,
  /// since `null` means "no override" in the copyWith pattern.
  PoiCooldown copyWith({
    String? zoneId,
    DateTime? lastRequestedAt,
    Duration? cooldownDuration,
  }) =>
      PoiCooldown(
        zoneId: zoneId ?? this.zoneId,
        lastRequestedAt: lastRequestedAt ?? this.lastRequestedAt,
        cooldownDuration: cooldownDuration ?? this.cooldownDuration,
      );

  /// Serialises to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'zoneId': zoneId,
        'lastRequestedAt': lastRequestedAt?.toIso8601String(),
        'cooldownSeconds': cooldownDuration.inSeconds,
      };

  /// Deserialises from a JSON-compatible map produced by [toJson].
  factory PoiCooldown.fromJson(Map<String, dynamic> json) => PoiCooldown(
        zoneId: json['zoneId'] as String,
        lastRequestedAt: json['lastRequestedAt'] == null
            ? null
            : DateTime.parse(json['lastRequestedAt'] as String),
        cooldownDuration: Duration(
          seconds: (json['cooldownSeconds'] as num).toInt(),
        ),
      );
}
