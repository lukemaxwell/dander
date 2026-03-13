import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/discoveries/overpass_client.dart';

class MockHttpClient extends Mock implements http.Client {}

// Minimal valid Overpass JSON response with a single node.
Map<String, dynamic> _overpassResponse(
    {List<Map<String, dynamic>> elements = const []}) {
  return {
    'version': 0.6,
    'generator': 'Overpass API',
    'elements': elements,
  };
}

Map<String, dynamic> _node({
  required int id,
  required double lat,
  required double lon,
  required Map<String, dynamic> tags,
}) {
  return {
    'type': 'node',
    'id': id,
    'lat': lat,
    'lon': lon,
    'tags': tags,
  };
}

void main() {
  late MockHttpClient mockClient;
  late HttpOverpassClient overpassClient;

  final bounds = LatLngBounds(
    const LatLng(51.50, -0.13),
    const LatLng(51.52, -0.11),
  );

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    overpassClient = HttpOverpassClient(httpClient: mockClient);
  });

  void stubSuccess(Map<String, dynamic> body) {
    when(() => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer(
      (_) async => http.Response(jsonEncode(body), 200),
    );
  }

  void stubHttpError(int statusCode) {
    when(() => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer(
      (_) async => http.Response('Server error', statusCode),
    );
  }

  void stubNetworkError() {
    when(() => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenThrow(Exception('Network failure'));
  }

  group('HttpOverpassClient.fetchPOIs', () {
    group('query building', () {
      test('sends POST to overpass-api.de interpreter', () async {
        stubSuccess(_overpassResponse());

        await overpassClient.fetchPOIs(bounds);

        final captured = verify(() => mockClient.post(
              captureAny(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).captured;
        final uri = captured.first as Uri;
        expect(uri.host, contains('overpass-api.de'));
        expect(uri.path, contains('interpreter'));
      });

      test('query body contains bounding box coordinates', () async {
        stubSuccess(_overpassResponse());

        await overpassClient.fetchPOIs(bounds);

        final captured = verify(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: captureAny(named: 'body'),
            )).captured;
        final body = Uri.decodeComponent(captured.first as String);

        // south,west,north,east order
        expect(body, contains('51.5')); // south lat
        expect(body, contains('-0.13')); // west lon
        expect(body, contains('51.52')); // north lat
        expect(body, contains('-0.11')); // east lon
      });

      test('query body requests amenity, tourism, historic, leisure tags',
          () async {
        stubSuccess(_overpassResponse());

        await overpassClient.fetchPOIs(bounds);

        final captured = verify(() => mockClient.post(
              any(),
              headers: any(named: 'headers'),
              body: captureAny(named: 'body'),
            )).captured;
        final body = Uri.decodeComponent(captured.first as String);

        expect(body, contains('"amenity"'));
        expect(body, contains('"tourism"'));
        expect(body, contains('"historic"'));
        expect(body, contains('"leisure"'));
      });
    });

    group('response parsing', () {
      test('returns empty list for empty elements array', () async {
        stubSuccess(_overpassResponse());

        final result = await overpassClient.fetchPOIs(bounds);
        expect(result, isEmpty);
      });

      test('parses a single cafe node into a Discovery', () async {
        final response = _overpassResponse(elements: [
          _node(
            id: 123456,
            lat: 51.51,
            lon: -0.12,
            tags: {'amenity': 'cafe', 'name': 'Corner Brew'},
          ),
        ]);
        stubSuccess(response);

        final result = await overpassClient.fetchPOIs(bounds);

        expect(result, hasLength(1));
        final discovery = result.first;
        expect(discovery.id, equals('node/123456'));
        expect(discovery.name, equals('Corner Brew'));
        expect(discovery.category, equals('cafe'));
        expect(discovery.position.latitude, closeTo(51.51, 0.0001));
        expect(discovery.position.longitude, closeTo(-0.12, 0.0001));
        expect(discovery.osmTags['amenity'], equals('cafe'));
      });

      test('uses empty string for name when tag is absent', () async {
        final response = _overpassResponse(elements: [
          _node(
            id: 1,
            lat: 51.51,
            lon: -0.12,
            tags: {'amenity': 'restaurant'},
          ),
        ]);
        stubSuccess(response);

        final result = await overpassClient.fetchPOIs(bounds);
        expect(result.first.name, equals(''));
      });

      test('assigns correct rarity tier from tags', () async {
        final response = _overpassResponse(elements: [
          _node(
            id: 1,
            lat: 51.51,
            lon: -0.12,
            tags: {'tourism': 'viewpoint', 'name': 'Primrose Hill'},
          ),
        ]);
        stubSuccess(response);

        final result = await overpassClient.fetchPOIs(bounds);
        expect(result.first.rarity, equals(RarityTier.rare));
      });

      test('parses multiple nodes', () async {
        final response = _overpassResponse(elements: [
          _node(id: 1, lat: 51.51, lon: -0.12, tags: {'amenity': 'cafe'}),
          _node(id: 2, lat: 51.511, lon: -0.121, tags: {'amenity': 'pub'}),
          _node(
              id: 3, lat: 51.512, lon: -0.122, tags: {'tourism': 'viewpoint'}),
        ]);
        stubSuccess(response);

        final result = await overpassClient.fetchPOIs(bounds);
        expect(result, hasLength(3));
      });

      test('skips non-node elements (e.g. ways)', () async {
        final response = {
          'elements': [
            {
              'type': 'way',
              'id': 999,
              'tags': {'leisure': 'park'},
            },
            _node(id: 1, lat: 51.51, lon: -0.12, tags: {'amenity': 'cafe'}),
          ],
        };
        stubSuccess(response);

        final result = await overpassClient.fetchPOIs(bounds);
        expect(result, hasLength(1));
        expect(result.first.id, equals('node/1'));
      });

      test('all discoveries have null discoveredAt initially', () async {
        final response = _overpassResponse(elements: [
          _node(id: 1, lat: 51.51, lon: -0.12, tags: {'amenity': 'cafe'}),
        ]);
        stubSuccess(response);

        final result = await overpassClient.fetchPOIs(bounds);
        expect(result.first.discoveredAt, isNull);
        expect(result.first.isDiscovered, isFalse);
      });
    });

    group('error handling', () {
      test('throws OverpassException on non-200 HTTP response', () async {
        stubHttpError(429);

        expect(
          () => overpassClient.fetchPOIs(bounds),
          throwsA(isA<OverpassException>()),
        );
      });

      test('throws OverpassException on network failure', () async {
        stubNetworkError();

        expect(
          () => overpassClient.fetchPOIs(bounds),
          throwsA(isA<OverpassException>()),
        );
      });
    });
  });
}
