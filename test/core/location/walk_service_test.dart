import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dander/core/location/location_service.dart';
import 'package:dander/core/location/walk_repository.dart';
import 'package:dander/core/location/walk_service.dart';
import 'package:dander/core/location/walk_session.dart';

// ---------------------------------------------------------------------------
// Fakes / Mocks
// ---------------------------------------------------------------------------

class MockLocationService extends Mock implements LocationService {}

class MockWalkRepository extends Mock implements WalkRepository {}

class FakeWalkSession extends Fake implements WalkSession {}

/// Helper: builds a [Position] with minimum required fields.
Position makePosition(double lat, double lng, {DateTime? timestamp}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: timestamp ?? DateTime(2024, 6, 1, 9, 0, 0),
    accuracy: 5.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 1.0,
    speedAccuracy: 0.0,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeWalkSession());
  });

  late MockLocationService mockLocation;
  late MockWalkRepository mockRepo;
  late StreamController<Position> positionController;

  setUp(() {
    mockLocation = MockLocationService();
    mockRepo = MockWalkRepository();
    positionController = StreamController<Position>.broadcast();

    when(() => mockLocation.positionStream)
        .thenAnswer((_) => positionController.stream);
    when(() => mockRepo.saveWalk(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await positionController.close();
  });

  WalkService buildService() =>
      WalkService(locationService: mockLocation, repository: mockRepo);

  group('WalkService.isWalking', () {
    test('is false before any walk is started', () {
      final service = buildService();
      expect(service.isWalking, isFalse);
    });

    test('is true after startWalk', () async {
      when(() => mockLocation.hasPermission).thenAnswer((_) async => true);
      final service = buildService();
      await service.startWalk();
      expect(service.isWalking, isTrue);
    });

    test('is false after stopWalk', () async {
      when(() => mockLocation.hasPermission).thenAnswer((_) async => true);
      final service = buildService();
      await service.startWalk();
      await service.stopWalk();
      expect(service.isWalking, isFalse);
    });
  });

  group('WalkService.currentSession', () {
    test('is null before any walk is started', () {
      expect(buildService().currentSession, isNull);
    });

    test('is non-null after startWalk', () async {
      when(() => mockLocation.hasPermission).thenAnswer((_) async => true);
      final service = buildService();
      await service.startWalk();
      expect(service.currentSession, isNotNull);
    });

    test('is null after stopWalk', () async {
      when(() => mockLocation.hasPermission).thenAnswer((_) async => true);
      final service = buildService();
      await service.startWalk();
      await service.stopWalk();
      expect(service.currentSession, isNull);
    });
  });

  group('WalkService.startWalk', () {
    test('throws when permission is denied', () async {
      when(() => mockLocation.hasPermission).thenAnswer((_) async => false);
      when(() => mockLocation.requestPermission())
          .thenAnswer((_) async => false);
      final service = buildService();
      expect(() => service.startWalk(),
          throwsA(isA<LocationPermissionDeniedException>()));
    });

    test('requests permission when not already granted', () async {
      when(() => mockLocation.hasPermission).thenAnswer((_) async => false);
      when(() => mockLocation.requestPermission())
          .thenAnswer((_) async => true);
      final service = buildService();
      await service.startWalk();
      verify(() => mockLocation.requestPermission()).called(1);
    });

    test('does not request permission when already granted', () async {
      when(() => mockLocation.hasPermission).thenAnswer((_) async => true);
      final service = buildService();
      await service.startWalk();
      verifyNever(() => mockLocation.requestPermission());
    });

    test('throws StateError if called while already walking', () async {
      when(() => mockLocation.hasPermission).thenAnswer((_) async => true);
      final service = buildService();
      await service.startWalk();
      expect(() => service.startWalk(), throwsA(isA<StateError>()));
    });
  });

  group('WalkService.stopWalk', () {
    test('throws StateError when not walking', () {
      final service = buildService();
      expect(() => service.stopWalk(), throwsA(isA<StateError>()));
    });

    test('returns completed WalkSession', () async {
      when(() => mockLocation.hasPermission).thenAnswer((_) async => true);
      final service = buildService();
      await service.startWalk();
      final session = await service.stopWalk();
      expect(session.endTime, isNotNull);
    });

    test('saves the completed session to the repository', () async {
      when(() => mockLocation.hasPermission).thenAnswer((_) async => true);
      final service = buildService();
      await service.startWalk();
      final session = await service.stopWalk();
      verify(() => mockRepo.saveWalk(session)).called(1);
    });

    test('completed session distance reflects collected points', () async {
      when(() => mockLocation.hasPermission).thenAnswer((_) async => true);
      final service = buildService();
      await service.startWalk();

      positionController.add(makePosition(51.5000, -0.1000));
      positionController.add(makePosition(51.5009, -0.1000)); // ~100 m

      // Give stream time to deliver
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final session = await service.stopWalk();
      expect(session.distanceMeters, closeTo(100.0, 10.0));
    });
  });

  group('WalkService.sessionStream', () {
    test('emits an updated session on each position update', () async {
      when(() => mockLocation.hasPermission).thenAnswer((_) async => true);
      final service = buildService();
      await service.startWalk();

      final emitted = <WalkSession>[];
      final sub = service.sessionStream.listen(emitted.add);

      positionController.add(makePosition(51.5000, -0.1000));
      positionController.add(makePosition(51.5009, -0.1000));

      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(emitted.length, equals(2));
    });

    test('each emission has one more point than the previous', () async {
      when(() => mockLocation.hasPermission).thenAnswer((_) async => true);
      final service = buildService();
      await service.startWalk();

      final emitted = <WalkSession>[];
      final sub = service.sessionStream.listen(emitted.add);

      positionController.add(makePosition(51.5000, -0.1000));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      positionController.add(makePosition(51.5009, -0.1000));
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await sub.cancel();

      expect(emitted[0].pointCount, equals(1));
      expect(emitted[1].pointCount, equals(2));
    });

    test('does not emit when not walking', () async {
      final service = buildService();
      final emitted = <WalkSession>[];
      final sub = service.sessionStream.listen(emitted.add);

      positionController.add(makePosition(51.5000, -0.1000));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(emitted, isEmpty);
    });

    test('stream is a broadcast stream — supports multiple subscribers',
        () async {
      when(() => mockLocation.hasPermission).thenAnswer((_) async => true);
      final service = buildService();
      await service.startWalk();

      final a = <WalkSession>[];
      final b = <WalkSession>[];
      final subA = service.sessionStream.listen(a.add);
      final subB = service.sessionStream.listen(b.add);

      positionController.add(makePosition(51.5000, -0.1000));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await subA.cancel();
      await subB.cancel();

      expect(a.length, equals(1));
      expect(b.length, equals(1));
    });
  });

  group('WalkService position processing', () {
    test('position updates increment pointCount on currentSession', () async {
      when(() => mockLocation.hasPermission).thenAnswer((_) async => true);
      final service = buildService();
      await service.startWalk();

      positionController.add(makePosition(51.5000, -0.1000));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(service.currentSession!.pointCount, equals(1));
    });

    test('converts Position to WalkPoint with correct LatLng', () async {
      when(() => mockLocation.hasPermission).thenAnswer((_) async => true);
      final service = buildService();
      await service.startWalk();

      positionController.add(makePosition(51.5000, -0.1000));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final point = service.currentSession!.points.first;
      expect(point.position.latitude, closeTo(51.5000, 0.0001));
      expect(point.position.longitude, closeTo(-0.1000, 0.0001));
    });
  });
}
