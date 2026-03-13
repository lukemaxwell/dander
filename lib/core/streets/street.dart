import 'package:latlong2/latlong.dart';

/// An immutable representation of an OSM street (way) in the user's
/// neighbourhood.
///
/// [id] is the OSM way ID formatted as `"way/<id>"`.
/// [nodes] holds the ordered geometry as a sequence of [LatLng] points.
/// [walkedAt] is `null` until the user's GPS track intersects the street
/// geometry; set via [markWalked].
class Street {
  const Street({
    required this.id,
    required this.name,
    required this.nodes,
    required this.walkedAt,
  });

  /// OSM way ID formatted as `"way/<id>"`.
  final String id;

  /// Display name from the OSM `name` tag.
  final String name;

  /// Ordered geometry — each element is one node in the way.
  final List<LatLng> nodes;

  /// UTC timestamp when the user first walked this street.
  ///
  /// `null` means the street has not yet been walked.
  final DateTime? walkedAt;

  /// Whether the user has walked this street.
  bool get isWalked => walkedAt != null;

  /// Returns a new [Street] identical to this one but with [walkedAt] set to
  /// [at].
  ///
  /// The original instance is never mutated.
  Street markWalked(DateTime at) => Street(
        id: id,
        name: name,
        nodes: nodes,
        walkedAt: at,
      );

  /// Serialises this [Street] to a JSON-compatible [Map].
  ///
  /// [walkedAt] is omitted when `null`.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nodes': nodes
            .map((n) => {'lat': n.latitude, 'lng': n.longitude})
            .toList(),
        if (walkedAt != null) 'walkedAt': walkedAt!.toIso8601String(),
      };

  /// Restores a [Street] from the JSON map produced by [toJson].
  factory Street.fromJson(Map<String, dynamic> json) {
    final rawNodes = (json['nodes'] as List<dynamic>?) ?? [];
    final nodes = rawNodes.map((n) {
      final nodeMap = n as Map<String, dynamic>;
      return LatLng(
        (nodeMap['lat'] as num).toDouble(),
        (nodeMap['lng'] as num).toDouble(),
      );
    }).toList();

    return Street(
      id: json['id'] as String,
      name: json['name'] as String,
      nodes: nodes,
      walkedAt: json['walkedAt'] != null
          ? DateTime.parse(json['walkedAt'] as String)
          : null,
    );
  }
}
