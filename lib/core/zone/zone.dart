import 'package:latlong2/latlong.dart';

import 'zone_level.dart';

/// An immutable geographic zone with its own progression state.
///
/// Each zone has an XP-based level that controls the fog reveal radius.
/// Zones are independent — XP earned in one zone does not affect another.
class Zone {
  const Zone({
    required this.id,
    required this.name,
    required this.centre,
    required this.createdAt,
    this.xp = 0,
  });

  /// Unique identifier for this zone.
  final String id;

  /// Human-readable name (e.g. "Hackney", "Barcelona Eixample").
  final String name;

  /// The geographic anchor point for this zone.
  final LatLng centre;

  /// Total XP earned in this zone.
  final int xp;

  /// When this zone was first created.
  final DateTime createdAt;

  /// Current level (1-based) derived from [xp].
  int get level => ZoneLevel.levelForXp(xp);

  /// Fog reveal radius in meters derived from [xp].
  double get radiusMeters => ZoneLevel.radiusForXp(xp);

  /// XP needed to reach next level, or `null` if at max level.
  int? get xpForNextLevel => ZoneLevel.xpForNextLevel(xp);

  /// Returns a new [Zone] with [amount] XP added.
  Zone addXp(int amount) {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must be non-negative');
    }
    return copyWith(xp: xp + amount);
  }

  /// Returns a new [Zone] with an updated [name].
  Zone rename(String newName) => copyWith(name: newName);

  /// Returns a copy with optionally overridden fields.
  Zone copyWith({
    String? id,
    String? name,
    LatLng? centre,
    int? xp,
    DateTime? createdAt,
  }) =>
      Zone(
        id: id ?? this.id,
        name: name ?? this.name,
        centre: centre ?? this.centre,
        xp: xp ?? this.xp,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'centreLat': centre.latitude,
        'centreLng': centre.longitude,
        'xp': xp,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
        id: json['id'] as String,
        name: json['name'] as String,
        centre: LatLng(
          (json['centreLat'] as num).toDouble(),
          (json['centreLng'] as num).toDouble(),
        ),
        xp: (json['xp'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
