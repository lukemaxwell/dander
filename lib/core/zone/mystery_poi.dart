import 'package:latlong2/latlong.dart';

/// An immutable mystery point of interest that is hidden until the user arrives.
///
/// [name] is `null` while the POI is unrevealed; it is set via [reveal] when
/// the user physically arrives at the location.
///
/// Valid categories: 'pub', 'park', 'historic', 'street_art', 'viewpoint',
/// 'cafe', 'library'.
class MysteryPoi {
  const MysteryPoi({
    required this.id,
    required this.position,
    required this.category,
    this.name,
  });

  /// Unique identifier for this POI (typically matches the OSM node id).
  final String id;

  /// Geographic position of the POI.
  final LatLng position;

  /// Category of the POI (e.g. 'pub', 'park', 'historic').
  final String category;

  /// Display name — `null` while the POI is unrevealed.
  final String? name;

  /// Whether this POI has been revealed (i.e. [name] is set).
  bool get isRevealed => name != null;

  /// Returns a new [MysteryPoi] with [name] set to [revealedName].
  ///
  /// The original is never mutated.
  MysteryPoi reveal(String revealedName) => MysteryPoi(
        id: id,
        position: position,
        category: category,
        name: revealedName,
      );

  /// Serialises to a JSON-compatible [Map].
  ///
  /// The 'name' key is omitted when [name] is null to indicate an unrevealed
  /// state, matching the [fromJson] convention.
  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': position.latitude,
        'lng': position.longitude,
        'category': category,
        if (name != null) 'name': name,
      };

  /// Restores a [MysteryPoi] from the map produced by [toJson].
  factory MysteryPoi.fromJson(Map<String, dynamic> json) => MysteryPoi(
        id: json['id'] as String,
        position: LatLng(
          (json['lat'] as num).toDouble(),
          (json['lng'] as num).toDouble(),
        ),
        category: json['category'] as String,
        name: json['name'] as String?,
      );
}
