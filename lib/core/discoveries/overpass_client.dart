import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'discovery.dart';
import 'rarity_classifier.dart';

/// Thrown when the Overpass API call fails.
class OverpassException implements Exception {
  const OverpassException(this.message);

  final String message;

  @override
  String toString() => 'OverpassException: $message';
}

/// Abstract interface for fetching POI data.
///
/// Decouples business logic from the concrete HTTP implementation.
abstract class OverpassClient {
  /// Fetches nodes within [bounds] that have amenity, tourism, historic, or
  /// leisure tags from the Overpass API.
  Future<List<Discovery>> fetchPOIs(LatLngBounds bounds);
}

/// Production implementation that queries overpass-api.de.
class HttpOverpassClient implements OverpassClient {
  HttpOverpassClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  static final Uri _endpoint =
      Uri.parse('https://overpass-api.de/api/interpreter');

  /// HTTP deadline — intentionally longer than the Overpass `[timeout:30]`
  /// directive so the server can complete or return a clean error before the
  /// client kills the connection.
  static const Duration _requestTimeout = Duration(seconds: 40);

  final http.Client _http;

  /// Releases the underlying [http.Client].  Call when this client is no
  /// longer needed to avoid leaking socket connections.
  void dispose() {
    _http.close();
  }

  @override
  Future<List<Discovery>> fetchPOIs(LatLngBounds bounds) async {
    final query = _buildQuery(bounds);
    http.Response response;
    try {
      response = await _http
          .post(
            _endpoint,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'data=${Uri.encodeComponent(query)}',
          )
          .timeout(
            _requestTimeout,
            onTimeout: () => throw const OverpassException('Request timed out'),
          );
    } on OverpassException {
      rethrow;
    } catch (e) {
      throw OverpassException('Network error: $e');
    }

    if (response.statusCode != 200) {
      debugPrint(
        'OverpassClient: HTTP ${response.statusCode} response body: '
        '${response.body}',
      );
      throw OverpassException('HTTP ${response.statusCode}: request failed');
    }

    return _parseResponse(response.body);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Builds an Overpass QL query for nodes, ways, and relations within [bounds].
  ///
  /// Nodes are fetched for all amenity/tourism/historic/leisure tags.
  /// Ways and relations use targeted tag queries to avoid fetching thousands
  /// of residential garden polygons (which cause timeouts in dense areas).
  ///
  /// Bounding box order: south, west, north, east.
  String _buildQuery(LatLngBounds bounds) {
    final s = bounds.south;
    final w = bounds.west;
    final n = bounds.north;
    final e = bounds.east;
    final bbox = '$s,$w,$n,$e';

    return '''
[out:json][timeout:30];
(
  node["amenity"]($bbox);
  node["tourism"]($bbox);
  node["historic"]($bbox);
  node["leisure"]($bbox);
  way["historic"]($bbox);
  way["tourism"~"artwork|museum|gallery|viewpoint|information"]($bbox);
  way["amenity"~"place_of_worship|community_centre|library"]($bbox);
  way["leisure"~"park|nature_reserve"]($bbox);
  relation["historic"]($bbox);
  relation["leisure"~"park|nature_reserve"]($bbox);
  relation["amenity"~"place_of_worship"]($bbox);
);
out body center;
''';
  }

  List<Discovery> _parseResponse(String body) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      throw OverpassException('Failed to parse response: $e');
    }

    final elements = (json['elements'] as List<dynamic>?) ?? [];
    final discoveries = <Discovery>[];

    for (final element in elements) {
      final map = element as Map<String, dynamic>;
      final type = map['type'] as String;

      // Extract coordinates based on element type.
      final double lat;
      final double lon;

      if (type == 'node') {
        lat = (map['lat'] as num).toDouble();
        lon = (map['lon'] as num).toDouble();
      } else if (type == 'way' || type == 'relation') {
        // Ways and relations use the computed centre from `out center`.
        final center = map['center'] as Map<String, dynamic>?;
        if (center == null) continue;
        lat = (center['lat'] as num).toDouble();
        lon = (center['lon'] as num).toDouble();
      } else {
        continue;
      }

      final id = map['id'] as int;
      final rawTags = (map['tags'] as Map<String, dynamic>?) ?? {};
      final tags = Map<String, String>.from(
        rawTags.map((k, v) => MapEntry(k, v.toString())),
      );

      discoveries.add(Discovery(
        id: '$type/$id',
        name: tags['name'] ?? '',
        category: RarityClassifier.inferCategory(tags),
        rarity: RarityClassifier.classify(tags),
        position: LatLng(lat, lon),
        osmTags: tags,
        osmType: type,
        discoveredAt: null,
      ));
    }

    return discoveries;
  }
}
