import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dander/core/fog/fog_grid.dart';
import 'package:dander/core/fog/fog_repository.dart';

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  const origin = LatLng(51.5, -0.05);

  group('FogRepository', () {
    late MockBox mockBox;
    late FogRepository repository;

    setUp(() {
      mockBox = MockBox();
      repository = FogRepository.withBox(mockBox, origin: origin);
    });

    group('save', () {
      test('writes serialised bytes to Hive box', () async {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);

        when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

        await repository.save(grid);

        verify(() => mockBox.put(FogRepository.boxKey, any())).called(1);
      });

      test('saves empty grid without throwing', () async {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

        expect(() => repository.save(grid), returnsNormally);
      });
    });

    group('load', () {
      test('returns null when no data in box', () async {
        when(() => mockBox.get(FogRepository.boxKey)).thenReturn(null);

        final result = await repository.load();
        expect(result, isNull);
      });

      test('returns restored FogGrid from stored bytes', () async {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 50.0);
        final bytes = grid.toBytes();

        when(() => mockBox.get(FogRepository.boxKey)).thenReturn(bytes);

        final loaded = await repository.load();
        expect(loaded, isNotNull);
        expect(loaded!.exploredCount, equals(grid.exploredCount));
        expect(loaded.isCellExplored(0, 0), isTrue);
      });

      test('round-trip save and load preserves explored cells', () async {
        final grid = FogGrid(origin: origin, cellSizeMeters: 10.0);
        grid.markExplored(origin, 100.0);

        // Capture what was saved
        dynamic savedData;
        when(() => mockBox.put(any(), any())).thenAnswer((invocation) async {
          savedData = invocation.positionalArguments[1];
        });
        when(() => mockBox.get(FogRepository.boxKey))
            .thenAnswer((_) => savedData);

        await repository.save(grid);
        final loaded = await repository.load();

        expect(loaded, isNotNull);
        expect(loaded!.exploredCells, equals(grid.exploredCells));
      });
    });

    group('clear', () {
      test('deletes data from box', () async {
        when(() => mockBox.delete(FogRepository.boxKey))
            .thenAnswer((_) async {});

        await repository.clear();

        verify(() => mockBox.delete(FogRepository.boxKey)).called(1);
      });
    });
  });
}
