import 'package:latlong2/latlong.dart';

/// Rarity tier assigned to a point of interest.
///
/// Tiers are ordered from most to least rare:
/// [legendary] > [rare] > [uncommon] > [common].
enum RarityTier { common, uncommon, rare, legendary }

/// An immutable representation of a discoverable point of interest.
///
/// Sourced from OpenStreetMap via the Overpass API.  [discoveredAt] is `null`
/// while the POI is undiscovered; set via [markDiscovered] when the user
/// enters its proximity.
class Discovery {
  const Discovery({
    required this.id,
    required this.name,
    required this.category,
    required this.rarity,
    required this.position,
    required this.osmTags,
    required this.discoveredAt,
  });

  /// The OSM node ID formatted as `"node/<id>"`.
  final String id;

  /// Display name taken from the OSM `name` tag, or empty string if absent.
  final String name;

  /// Human-readable category inferred from OSM tags (e.g. `"cafe"`, `"park"`).
  final String category;

  /// Rarity tier derived from the OSM tags.
  final RarityTier rarity;

  /// Geographic position of the POI.
  final LatLng position;

  /// The full set of OSM tags on the node.
  final Map<String, String> osmTags;

  /// UTC timestamp when the user first discovered this POI.
  ///
  /// `null` means the POI has not yet been discovered.
  final DateTime? discoveredAt;

  /// Whether this POI has been discovered by the user.
  bool get isDiscovered => discoveredAt != null;

  /// Returns a new [Discovery] identical to this one but with [discoveredAt]
  /// set to [at].
  ///
  /// The original instance is never mutated.
  Discovery markDiscovered(DateTime at) => Discovery(
        id: id,
        name: name,
        category: category,
        rarity: rarity,
        position: position,
        osmTags: osmTags,
        discoveredAt: at,
      );

  /// Serialises this [Discovery] to a JSON-compatible [Map].
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'rarity': rarity.name,
        'lat': position.latitude,
        'lng': position.longitude,
        'osmTags': osmTags,
        if (discoveredAt != null)
          'discoveredAt': discoveredAt!.toIso8601String(),
      };

  /// Restores a [Discovery] from the JSON map produced by [toJson].
  factory Discovery.fromJson(Map<String, dynamic> json) {
    final rawTags = (json['osmTags'] as Map<String, dynamic>?) ?? {};
    return Discovery(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      rarity: RarityTier.values.firstWhere(
        (t) => t.name == json['rarity'] as String,
        orElse: () => RarityTier.common,
      ),
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      osmTags: Map<String, String>.from(rawTags),
      discoveredAt: json['discoveredAt'] != null
          ? DateTime.parse(json['discoveredAt'] as String)
          : null,
    );
  }
}
