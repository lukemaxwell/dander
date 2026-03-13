import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:latlong2/latlong.dart';
import 'package:hive/hive.dart';

import 'package:dander/core/storage/app_state_repository.dart';

// ---------------------------------------------------------------------------
// Mock Hive box
// ---------------------------------------------------------------------------

class MockBox extends Mock implements Box<dynamic> {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockBox mockBox;
  late AppStateRepositoryImpl repository;

  setUp(() {
    mockBox = MockBox();
    repository = AppStateRepositoryImpl(box: mockBox);
  });

  group('AppStateRepository — saveLastPosition / getLastPosition', () {
    test('saves last position as a map with lat and lng keys', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      await repository.saveLastPosition(const LatLng(51.5, -0.1));

      verify(
        () => mockBox.put(
          'last_position',
          {'lat': 51.5, 'lng': -0.1},
        ),
      ).called(1);
    });

    test('returns null when no position stored', () async {
      when(() => mockBox.get('last_position')).thenReturn(null);

      final result = await repository.getLastPosition();

      expect(result, isNull);
    });

    test('returns stored LatLng correctly', () async {
      when(
        () => mockBox.get('last_position'),
      ).thenReturn({'lat': 51.5074, 'lng': -0.1278});

      final result = await repository.getLastPosition();

      expect(result, isNotNull);
      expect(result!.latitude, closeTo(51.5074, 0.0001));
      expect(result.longitude, closeTo(-0.1278, 0.0001));
    });

    test('round-trips positive coordinates correctly', () async {
      const original = LatLng(40.7128, -74.0060);
      Map<String, dynamic>? stored;

      when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
        stored = inv.positionalArguments[1] as Map<String, dynamic>;
      });
      when(() => mockBox.get('last_position')).thenAnswer((_) => stored);

      await repository.saveLastPosition(original);
      final result = await repository.getLastPosition();

      expect(result, isNotNull);
      expect(result!.latitude, closeTo(original.latitude, 0.0001));
      expect(result.longitude, closeTo(original.longitude, 0.0001));
    });

    test('round-trips negative coordinates correctly', () async {
      const original = LatLng(-33.8688, 151.2093);
      Map<String, dynamic>? stored;

      when(() => mockBox.put(any(), any())).thenAnswer((inv) async {
        stored = inv.positionalArguments[1] as Map<String, dynamic>;
      });
      when(() => mockBox.get('last_position')).thenAnswer((_) => stored);

      await repository.saveLastPosition(original);
      final result = await repository.getLastPosition();

      expect(result, isNotNull);
      expect(result!.latitude, closeTo(original.latitude, 0.0001));
      expect(result.longitude, closeTo(original.longitude, 0.0001));
    });
  });

  group('AppStateRepository — saveNeighbourhoodBounds / getNeighbourhoodBounds',
      () {
    test('saves neighbourhood bounds with all four corners', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      await repository.saveNeighbourhoodBounds(
        const NeighbourhoodBounds(
          southWestLat: 51.4,
          southWestLng: -0.2,
          northEastLat: 51.6,
          northEastLng: 0.0,
        ),
      );

      verify(
        () => mockBox.put(
          'neighbourhood_bounds',
          {
            'sw_lat': 51.4,
            'sw_lng': -0.2,
            'ne_lat': 51.6,
            'ne_lng': 0.0,
          },
        ),
      ).called(1);
    });

    test('returns null when no bounds stored', () async {
      when(() => mockBox.get('neighbourhood_bounds')).thenReturn(null);

      final result = await repository.getNeighbourhoodBounds();

      expect(result, isNull);
    });

    test('returns stored bounds correctly', () async {
      when(
        () => mockBox.get('neighbourhood_bounds'),
      ).thenReturn({
        'sw_lat': 51.4,
        'sw_lng': -0.2,
        'ne_lat': 51.6,
        'ne_lng': 0.0,
      });

      final result = await repository.getNeighbourhoodBounds();

      expect(result, isNotNull);
      expect(result!.southWestLat, closeTo(51.4, 0.0001));
      expect(result.southWestLng, closeTo(-0.2, 0.0001));
      expect(result.northEastLat, closeTo(51.6, 0.0001));
      expect(result.northEastLng, closeTo(0.0, 0.0001));
    });
  });

  group('AppStateRepository — markFirstLaunchComplete / isFirstLaunch', () {
    test('isFirstLaunch returns true when key absent', () async {
      when(() => mockBox.get('first_launch_complete')).thenReturn(null);

      final result = await repository.isFirstLaunch();

      expect(result, isTrue);
    });

    test('isFirstLaunch returns false after markFirstLaunchComplete', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      when(
        () => mockBox.get('first_launch_complete'),
      ).thenReturn(true);

      await repository.markFirstLaunchComplete();
      final result = await repository.isFirstLaunch();

      expect(result, isFalse);
    });

    test('markFirstLaunchComplete stores true under expected key', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      await repository.markFirstLaunchComplete();

      verify(
        () => mockBox.put('first_launch_complete', true),
      ).called(1);
    });

    test('isFirstLaunch returns true when stored value is false', () async {
      when(
        () => mockBox.get('first_launch_complete'),
      ).thenReturn(false);

      final result = await repository.isFirstLaunch();
      // Stored false means launch was NOT completed → still first launch
      // Wait — if completed == false, it IS still first launch
      expect(result, isTrue);
    });
  });
}
