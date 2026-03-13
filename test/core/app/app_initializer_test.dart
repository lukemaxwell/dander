import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/app/app_initializer.dart';
import 'package:dander/core/storage/app_state_repository.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAppStateRepository extends Mock implements AppStateRepository {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockAppStateRepository mockRepo;

  setUp(() {
    mockRepo = MockAppStateRepository();
  });

  group('AppInitializer — initialize()', () {
    test('returns isFirstLaunch=true on very first run', () async {
      when(() => mockRepo.isFirstLaunch()).thenAnswer((_) async => true);
      when(() => mockRepo.getLastPosition()).thenAnswer((_) async => null);

      final initializer = AppInitializer(appStateRepository: mockRepo);
      final result = await initializer.initialize();

      expect(result.isFirstLaunch, isTrue);
    });

    test('returns isFirstLaunch=false on subsequent runs', () async {
      when(() => mockRepo.isFirstLaunch()).thenAnswer((_) async => false);
      when(
        () => mockRepo.getLastPosition(),
      ).thenAnswer((_) async => const LatLng(51.5, -0.1));

      final initializer = AppInitializer(appStateRepository: mockRepo);
      final result = await initializer.initialize();

      expect(result.isFirstLaunch, isFalse);
    });

    test('returns null lastKnownPosition on first launch', () async {
      when(() => mockRepo.isFirstLaunch()).thenAnswer((_) async => true);
      when(() => mockRepo.getLastPosition()).thenAnswer((_) async => null);

      final initializer = AppInitializer(appStateRepository: mockRepo);
      final result = await initializer.initialize();

      expect(result.lastKnownPosition, isNull);
    });

    test('returns stored lastKnownPosition on subsequent launches', () async {
      const expected = LatLng(51.5074, -0.1278);
      when(() => mockRepo.isFirstLaunch()).thenAnswer((_) async => false);
      when(
        () => mockRepo.getLastPosition(),
      ).thenAnswer((_) async => expected);

      final initializer = AppInitializer(appStateRepository: mockRepo);
      final result = await initializer.initialize();

      expect(result.lastKnownPosition, isNotNull);
      expect(
        result.lastKnownPosition!.latitude,
        closeTo(expected.latitude, 0.0001),
      );
      expect(
        result.lastKnownPosition!.longitude,
        closeTo(expected.longitude, 0.0001),
      );
    });

    test('calls isFirstLaunch exactly once during initialize', () async {
      when(() => mockRepo.isFirstLaunch()).thenAnswer((_) async => false);
      when(() => mockRepo.getLastPosition()).thenAnswer((_) async => null);

      final initializer = AppInitializer(appStateRepository: mockRepo);
      await initializer.initialize();

      verify(() => mockRepo.isFirstLaunch()).called(1);
    });

    test('calls getLastPosition exactly once during initialize', () async {
      when(() => mockRepo.isFirstLaunch()).thenAnswer((_) async => true);
      when(() => mockRepo.getLastPosition()).thenAnswer((_) async => null);

      final initializer = AppInitializer(appStateRepository: mockRepo);
      await initializer.initialize();

      verify(() => mockRepo.getLastPosition()).called(1);
    });
  });

  group('InitResult', () {
    test('isFirstLaunch=true and null lastKnownPosition', () {
      const result = InitResult(isFirstLaunch: true, lastKnownPosition: null);

      expect(result.isFirstLaunch, isTrue);
      expect(result.lastKnownPosition, isNull);
    });

    test('isFirstLaunch=false with a known position', () {
      const result = InitResult(
        isFirstLaunch: false,
        lastKnownPosition: LatLng(48.8566, 2.3522),
      );

      expect(result.isFirstLaunch, isFalse);
      expect(result.lastKnownPosition, isNotNull);
      expect(result.lastKnownPosition!.latitude, closeTo(48.8566, 0.0001));
    });

    test('two equal InitResult instances compare correctly', () {
      const a = InitResult(isFirstLaunch: true, lastKnownPosition: null);
      const b = InitResult(isFirstLaunch: true, lastKnownPosition: null);

      // They should be the same constant (no == override needed for this test)
      expect(a.isFirstLaunch, equals(b.isFirstLaunch));
      expect(a.lastKnownPosition, equals(b.lastKnownPosition));
    });
  });

  group('TileCacheConfig', () {
    test('maxTileAge is 7 days', () {
      expect(
        AppInitializerConstants.maxTileAgeDays,
        equals(7),
      );
    });

    test('maxCacheSizeMb is 100', () {
      expect(
        AppInitializerConstants.maxCacheSizeMb,
        equals(100),
      );
    });
  });
}
