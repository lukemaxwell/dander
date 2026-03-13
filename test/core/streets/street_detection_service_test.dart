import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dander/core/streets/street.dart';
import 'package:dander/core/streets/street_detection_service.dart';
import 'package:dander/core/streets/street_repository.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockStreetRepository extends Mock implements StreetRepository {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _baseBounds = LatLngBounds(
  const LatLng(51.50, -0.16),
  const LatLng(51.53, -0.13),
);

Street _streetAt(String id, LatLng nodeA, [LatLng? nodeB]) {
  return Street(
    id: id,
    name: 'Street $id',
    nodes: nodeB != null ? [nodeA, nodeB] : [nodeA],
    walkedAt: null,
  );
}

Street _walkedStreet(String id, LatLng nodeA, [LatLng? nodeB]) {
  return Street(
    id: id,
    name: 'Street $id',
    nodes: nodeB != null ? [nodeA, nodeB] : [nodeA],
    walkedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_baseBounds);
    registerFallbackValue(const LatLng(0, 0));
    registerFallbackValue(DateTime(2024, 1, 1));
    registerFallbackValue('street_id');
  });

  group('StreetDetectionService', () {
    late MockStreetRepository repository;
    late StreamController<LatLng> positionController;
    late StreetDetectionService service;

    const nodePosition = LatLng(51.515, -0.150);
    const nearNode = LatLng(51.5150, -0.1501); // ~7m from nodePosition
    const farPosition = LatLng(51.520, -0.160); // far from nodePosition

    setUp(() {
      repository = MockStreetRepository();
      positionController = StreamController<LatLng>.broadcast();

      // Default stub: getStreets returns one unwalked street
      when(() => repository.getStreets(any()))
          .thenAnswer((_) async => [_streetAt('way/1', nodePosition)]);
      when(() => repository.markWalked(any(), any()))
          .thenAnswer((_) async {});
    });

    tearDown(() async {
      await service.dispose();
      await positionController.close();
    });

    group('start / position near street', () {
      test('emits street when position is within 20m of a node', () async {
        service = StreetDetectionService(
          streetRepository: repository,
          positionStream: positionController.stream,
        );

        await service.start(_baseBounds);

        final emitted = <Street>[];
        final sub = service.newlyWalkedStreets.listen(emitted.add);

        positionController.add(nearNode);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(emitted, hasLength(1));
        expect(emitted.first.id, equals('way/1'));
        await sub.cancel();
      });

      test('calls markWalked on repository when street is detected', () async {
        service = StreetDetectionService(
          streetRepository: repository,
          positionStream: positionController.stream,
        );

        await service.start(_baseBounds);
        positionController.add(nearNode);
        await Future.delayed(const Duration(milliseconds: 50));

        verify(() => repository.markWalked('way/1', any())).called(1);
      });
    });

    group('position far from all streets', () {
      test('emits nothing when position is more than 20m from all nodes',
          () async {
        service = StreetDetectionService(
          streetRepository: repository,
          positionStream: positionController.stream,
        );

        await service.start(_baseBounds);

        final emitted = <Street>[];
        final sub = service.newlyWalkedStreets.listen(emitted.add);

        positionController.add(farPosition);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(emitted, isEmpty);
        await sub.cancel();
      });

      test('does not call markWalked when far from all streets', () async {
        service = StreetDetectionService(
          streetRepository: repository,
          positionStream: positionController.stream,
        );

        await service.start(_baseBounds);
        positionController.add(farPosition);
        await Future.delayed(const Duration(milliseconds: 50));

        verifyNever(() => repository.markWalked(any(), any()));
      });
    });

    group('already-walked streets', () {
      test('does not re-emit an already-walked street', () async {
        when(() => repository.getStreets(any()))
            .thenAnswer((_) async => [_walkedStreet('way/1', nodePosition)]);

        service = StreetDetectionService(
          streetRepository: repository,
          positionStream: positionController.stream,
        );

        await service.start(_baseBounds);

        final emitted = <Street>[];
        final sub = service.newlyWalkedStreets.listen(emitted.add);

        positionController.add(nearNode);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(emitted, isEmpty);
        await sub.cancel();
      });

      test('does not call markWalked for already-walked streets', () async {
        when(() => repository.getStreets(any()))
            .thenAnswer((_) async => [_walkedStreet('way/1', nodePosition)]);

        service = StreetDetectionService(
          streetRepository: repository,
          positionStream: positionController.stream,
        );

        await service.start(_baseBounds);
        positionController.add(nearNode);
        await Future.delayed(const Duration(milliseconds: 50));

        verifyNever(() => repository.markWalked(any(), any()));
      });

      test('does not re-emit street that was emitted in same session',
          () async {
        service = StreetDetectionService(
          streetRepository: repository,
          positionStream: positionController.stream,
        );

        await service.start(_baseBounds);

        final emitted = <Street>[];
        final sub = service.newlyWalkedStreets.listen(emitted.add);

        // Walk near same street twice
        positionController.add(nearNode);
        await Future.delayed(const Duration(milliseconds: 50));
        positionController.add(nearNode);
        await Future.delayed(const Duration(milliseconds: 50));

        // Should only emit once
        expect(emitted, hasLength(1));
        await sub.cancel();
      });
    });

    group('stop()', () {
      test('stop() cancels position subscription', () async {
        service = StreetDetectionService(
          streetRepository: repository,
          positionStream: positionController.stream,
        );

        await service.start(_baseBounds);
        await service.stop();

        final emitted = <Street>[];
        final sub = service.newlyWalkedStreets.listen(emitted.add);

        positionController.add(nearNode);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(emitted, isEmpty);
        await sub.cancel();
      });
    });

    group('offline (cached streets)', () {
      test('uses cached streets from repository without network', () async {
        // getStreets returns streets from local cache (repository handles offline)
        when(() => repository.getStreets(any())).thenAnswer((_) async => [
              _streetAt('way/cached', nodePosition),
            ]);

        service = StreetDetectionService(
          streetRepository: repository,
          positionStream: positionController.stream,
        );

        await service.start(_baseBounds);

        final emitted = <Street>[];
        final sub = service.newlyWalkedStreets.listen(emitted.add);

        positionController.add(nearNode);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(emitted, hasLength(1));
        expect(emitted.first.id, equals('way/cached'));
        await sub.cancel();
      });
    });

    group('multiple streets', () {
      test('emits only the street within 20m when multiple streets present',
          () async {
        const farNode = LatLng(51.525, -0.160); // far from nearNode
        when(() => repository.getStreets(any())).thenAnswer((_) async => [
              _streetAt('way/close', nodePosition),
              _streetAt('way/far', farNode),
            ]);

        service = StreetDetectionService(
          streetRepository: repository,
          positionStream: positionController.stream,
        );

        await service.start(_baseBounds);

        final emitted = <Street>[];
        final sub = service.newlyWalkedStreets.listen(emitted.add);

        positionController.add(nearNode);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(emitted, hasLength(1));
        expect(emitted.first.id, equals('way/close'));
        await sub.cancel();
      });
    });
  });
}
