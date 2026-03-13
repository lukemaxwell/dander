import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'street.dart';

/// Thrown when the Overpass API call for street ways fails.
class StreetOverpassException implements Exception {
  const StreetOverpassException(this.message);

  final String message;

  @override
  String toString() => 'StreetOverpassException: $message';
}

/// Abstract interface for fetching street way data from Overpass.
abstract class StreetOverpassClient {
  /// Fetches named streets within [bounds] from the Overpass API.
  Future<List<Street>> fetchStreets(LatLngBounds bounds);
}

/// Production implementation that queries overpass-api.de for OSM ways that
/// have both a `highway` tag and a `name` tag.
///
/// The response is parsed into [Street] objects with ordered node geometry.
class HttpStreetOverpassClient implements StreetOverpassClient {
  HttpStreetOverpassClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  static final Uri _endpoint =
      Uri.parse('https://overpass-api.de/api/interpreter');

  static const Duration _requestTimeout = Duration(seconds: 30);

  final http.Client _http;

  /// Releases the underlying [http.Client]. Call when this client is no
  /// longer needed to avoid leaking socket connections.
  void dispose() {
    _http.close();
  }

  @override
  Future<List<Street>> fetchStreets(LatLngBounds bounds) async {
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
            onTimeout: () =>
                throw const StreetOverpassException('Request timed out'),
          );
    } on StreetOverpassException {
      rethrow;
    } catch (e) {
      throw StreetOverpassException('Network error: $e');
    }

    if (response.statusCode != 200) {
      debugPrint(
        'StreetOverpassClient: HTTP ${response.statusCode} response body: '
        '${response.body}',
      );
      throw StreetOverpassException(
          'HTTP ${response.statusCode}: request failed');
    }

    return _parseResponse(response.body);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Builds an Overpass QL query for named highway ways within [bounds].
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
way["highway"]["name"]($bbox);
out body geom;
''';
  }

  List<Street> _parseResponse(String body) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      throw StreetOverpassException('Failed to parse response: $e');
    }

    final elements = (json['elements'] as List<dynamic>?) ?? [];
    final streets = <Street>[];

    for (final element in elements) {
      final map = element as Map<String, dynamic>;

      // Only process way elements.
      if (map['type'] != 'way') continue;

      final rawTags = (map['tags'] as Map<String, dynamic>?) ?? {};
      final name = rawTags['name'] as String?;

      // Skip ways without a name tag.
      if (name == null || name.isEmpty) continue;

      final id = map['id'] as int;
      final rawGeometry = (map['geometry'] as List<dynamic>?) ?? [];
      final nodes = rawGeometry.map((g) {
        final point = g as Map<String, dynamic>;
        return LatLng(
          (point['lat'] as num).toDouble(),
          (point['lon'] as num).toDouble(),
        );
      }).toList();

      streets.add(Street(
        id: 'way/$id',
        name: name,
        nodes: nodes,
        walkedAt: null,
      ));
    }

    return streets;
  }
}
