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

  static const Duration _requestTimeout = Duration(seconds: 30);

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
            onTimeout: () => throw OverpassException('Request timed out'),
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

  /// Builds an Overpass QL query for nodes within [bounds].
  ///
  /// Bounding box order: south, west, north, east.
  String _buildQuery(LatLngBounds bounds) {
    final s = bounds.south;
    final w = bounds.west;
    final n = bounds.north;
    final e = bounds.east;
    final bbox = '$s,$w,$n,$e';

    return '''
[out:json][timeout:25];
(
  node["amenity"]($bbox);
  node["tourism"]($bbox);
  node["historic"]($bbox);
  node["leisure"]($bbox);
);
out body;
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

      // Only process node elements.
      if (map['type'] != 'node') continue;

      final id = map['id'] as int;
      final lat = (map['lat'] as num).toDouble();
      final lon = (map['lon'] as num).toDouble();
      final rawTags = (map['tags'] as Map<String, dynamic>?) ?? {};
      final tags = Map<String, String>.from(
        rawTags.map((k, v) => MapEntry(k, v.toString())),
      );

      discoveries.add(Discovery(
        id: 'node/$id',
        name: tags['name'] ?? '',
        category: RarityClassifier.inferCategory(tags),
        rarity: RarityClassifier.classify(tags),
        position: LatLng(lat, lon),
        osmTags: tags,
        discoveredAt: null,
      ));
    }

    return discoveries;
  }
}
