import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dander/core/streets/street_overpass_client.dart';

class MockHttpClient extends Mock implements http.Client {}

// ---------------------------------------------------------------------------
// Response builders
// ---------------------------------------------------------------------------

Map<String, dynamic> _overpassResponse({
  List<Map<String, dynamic>> elements = const [],
}) {
  return {
    'version': 0.6,
    'generator': 'Overpass API',
    'elements': elements,
  };
}

Map<String, dynamic> _wayElement({
  required int id,
  required String name,
  String highway = 'residential',
  List<Map<String, double>>? geometry,
}) {
  return {
    'type': 'way',
    'id': id,
    'tags': {'name': name, 'highway': highway},
    'geometry': geometry ??
        [
          {'lat': 51.523, 'lon': -0.157},
          {'lat': 51.524, 'lon': -0.158},
        ],
  };
}

void main() {
  late MockHttpClient mockClient;
  late HttpStreetOverpassClient overpassClient;

  final bounds = LatLngBounds(
    const LatLng(51.50, -0.13),
    const LatLng(51.52, -0.11),
  );

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    overpassClient = HttpStreetOverpassClient(httpClient: mockClient);
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

  void stubHttpError(int statusCode, {String body = 'Server error'}) {
    when(() => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer(
      (_) async => http.Response(body, statusCode),
    );
  }

  void stubNetworkError() {
    when(() => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenThrow(Exception('Network failure'));
  }

  // ---------------------------------------------------------------------------
  // Query building
  // ---------------------------------------------------------------------------
  group('query building', () {
    test('sends POST to overpass-api.de interpreter', () async {
      stubSuccess(_overpassResponse());

      await overpassClient.fetchStreets(bounds);

      final captured = verify(() => mockClient.post(
            captureAny(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).captured;
      final uri = captured.first as Uri;
      expect(uri.host, contains('overpass-api.de'));
      expect(uri.path, contains('interpreter'));
    });

    test('query contains bounding box in south,west,north,east order',
        () async {
      stubSuccess(_overpassResponse());

      await overpassClient.fetchStreets(bounds);

      final captured = verify(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured;
      final body = Uri.decodeComponent(captured.first as String);
      // south=51.50, west=-0.13, north=51.52, east=-0.11
      expect(body, contains('51.5'));   // south lat
      expect(body, contains('-0.13')); // west lon
      expect(body, contains('51.52')); // north lat
      expect(body, contains('-0.11')); // east lon
    });

    test('query filters by highway and name tags', () async {
      stubSuccess(_overpassResponse());

      await overpassClient.fetchStreets(bounds);

      final captured = verify(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured;
      final body = Uri.decodeComponent(captured.first as String);
      expect(body, contains('"highway"'));
      expect(body, contains('"name"'));
    });

    test('query requests geometry output', () async {
      stubSuccess(_overpassResponse());

      await overpassClient.fetchStreets(bounds);

      final captured = verify(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured;
      final body = Uri.decodeComponent(captured.first as String);
      expect(body, contains('out body geom'));
    });

    test('query uses out:json and timeout:25', () async {
      stubSuccess(_overpassResponse());

      await overpassClient.fetchStreets(bounds);

      final captured = verify(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured;
      final body = Uri.decodeComponent(captured.first as String);
      expect(body, contains('[out:json]'));
      expect(body, contains('[timeout:25]'));
    });
  });

  // ---------------------------------------------------------------------------
  // Response parsing
  // ---------------------------------------------------------------------------
  group('response parsing', () {
    test('returns empty list for empty elements array', () async {
      stubSuccess(_overpassResponse());

      final result = await overpassClient.fetchStreets(bounds);
      expect(result, isEmpty);
    });

    test('parses a single way element into a Street', () async {
      final response = _overpassResponse(elements: [
        _wayElement(id: 123456, name: 'Baker Street'),
      ]);
      stubSuccess(response);

      final result = await overpassClient.fetchStreets(bounds);
      expect(result, hasLength(1));
      final street = result.first;
      expect(street.id, equals('way/123456'));
      expect(street.name, equals('Baker Street'));
      expect(street.walkedAt, isNull);
    });

    test('parses geometry into ordered LatLng nodes', () async {
      final response = _overpassResponse(elements: [
        _wayElement(
          id: 1,
          name: 'Test Road',
          geometry: [
            {'lat': 51.523, 'lon': -0.157},
            {'lat': 51.524, 'lon': -0.158},
            {'lat': 51.525, 'lon': -0.159},
          ],
        ),
      ]);
      stubSuccess(response);

      final result = await overpassClient.fetchStreets(bounds);
      final street = result.first;
      expect(street.nodes, hasLength(3));
      expect(street.nodes[0].latitude, closeTo(51.523, 0.0001));
      expect(street.nodes[0].longitude, closeTo(-0.157, 0.0001));
      expect(street.nodes[2].latitude, closeTo(51.525, 0.0001));
    });

    test('parses multiple way elements', () async {
      final response = _overpassResponse(elements: [
        _wayElement(id: 1, name: 'Alpha Street'),
        _wayElement(id: 2, name: 'Beta Road'),
        _wayElement(id: 3, name: 'Gamma Lane'),
      ]);
      stubSuccess(response);

      final result = await overpassClient.fetchStreets(bounds);
      expect(result, hasLength(3));
      expect(result.map((s) => s.name),
          containsAll(['Alpha Street', 'Beta Road', 'Gamma Lane']));
    });

    test('skips elements that are not ways', () async {
      final response = {
        'elements': [
          {
            'type': 'node',
            'id': 999,
            'lat': 51.51,
            'lon': -0.12,
            'tags': {'name': 'A Node'},
          },
          _wayElement(id: 1, name: 'Baker Street'),
        ],
      };
      stubSuccess(response);

      final result = await overpassClient.fetchStreets(bounds);
      expect(result, hasLength(1));
      expect(result.first.id, equals('way/1'));
    });

    test('skips way elements without a name tag', () async {
      final response = {
        'elements': [
          {
            'type': 'way',
            'id': 10,
            'tags': {'highway': 'footway'},
            'geometry': [
              {'lat': 51.5, 'lon': -0.1},
            ],
          },
          _wayElement(id: 20, name: 'Named Road'),
        ],
      };
      stubSuccess(response);

      final result = await overpassClient.fetchStreets(bounds);
      expect(result, hasLength(1));
      expect(result.first.name, equals('Named Road'));
    });

    test('all returned streets have null walkedAt', () async {
      final response = _overpassResponse(elements: [
        _wayElement(id: 1, name: 'Test Street'),
      ]);
      stubSuccess(response);

      final result = await overpassClient.fetchStreets(bounds);
      expect(result.first.walkedAt, isNull);
      expect(result.first.isWalked, isFalse);
    });

    test('handles empty geometry list gracefully', () async {
      final response = {
        'elements': [
          {
            'type': 'way',
            'id': 5,
            'tags': {'name': 'Ghost Lane', 'highway': 'residential'},
            'geometry': <Map<String, double>>[],
          },
        ],
      };
      stubSuccess(response);

      final result = await overpassClient.fetchStreets(bounds);
      expect(result, hasLength(1));
      expect(result.first.nodes, isEmpty);
    });

    test('handles missing geometry key gracefully (returns empty nodes)',
        () async {
      final response = {
        'elements': [
          {
            'type': 'way',
            'id': 6,
            'tags': {'name': 'Shadow Street', 'highway': 'residential'},
          },
        ],
      };
      stubSuccess(response);

      final result = await overpassClient.fetchStreets(bounds);
      expect(result, hasLength(1));
      expect(result.first.nodes, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------
  group('error handling', () {
    test('throws StreetOverpassException on non-200 response', () async {
      stubHttpError(429);

      expect(
        () => overpassClient.fetchStreets(bounds),
        throwsA(isA<StreetOverpassException>()),
      );
    });

    test('exception message is sanitised — does not include response body',
        () async {
      const sensitiveBody = 'Internal error: db_password=super_secret';
      stubHttpError(500, body: sensitiveBody);

      StreetOverpassException? caught;
      try {
        await overpassClient.fetchStreets(bounds);
      } on StreetOverpassException catch (e) {
        caught = e;
      }

      expect(caught, isNotNull);
      expect(caught!.message, isNot(contains(sensitiveBody)));
      expect(caught.message, equals('HTTP 500: request failed'));
    });

    test('exception message includes the HTTP status code', () async {
      stubHttpError(404);

      StreetOverpassException? caught;
      try {
        await overpassClient.fetchStreets(bounds);
      } on StreetOverpassException catch (e) {
        caught = e;
      }

      expect(caught!.message, contains('404'));
    });

    test('throws StreetOverpassException on network failure', () async {
      stubNetworkError();

      expect(
        () => overpassClient.fetchStreets(bounds),
        throwsA(isA<StreetOverpassException>()),
      );
    });

    test('StreetOverpassException.toString includes message', () {
      const e = StreetOverpassException('something went wrong');
      expect(e.toString(), contains('something went wrong'));
    });
  });

  // ---------------------------------------------------------------------------
  // dispose
  // ---------------------------------------------------------------------------
  group('dispose', () {
    test('dispose closes the underlying http client', () {
      when(() => mockClient.close()).thenReturn(null);

      expect(() => overpassClient.dispose(), returnsNormally);
      verify(() => mockClient.close()).called(1);
    });
  });
}
