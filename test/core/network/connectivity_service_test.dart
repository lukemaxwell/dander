import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dander/core/network/connectivity_service.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockConnectivityService extends Mock implements ConnectivityService {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ConnectivityService contract', () {
    late MockConnectivityService service;

    setUp(() {
      service = MockConnectivityService();
    });

    test('isOnline returns true when connected', () async {
      when(() => service.isOnline).thenAnswer((_) async => true);

      final result = await service.isOnline;

      expect(result, isTrue);
    });

    test('isOnline returns false when disconnected', () async {
      when(() => service.isOnline).thenAnswer((_) async => false);

      final result = await service.isOnline;

      expect(result, isFalse);
    });

    test('isOnlineStream emits true when online', () async {
      final controller = StreamController<bool>.broadcast();
      when(() => service.isOnlineStream).thenAnswer((_) => controller.stream);

      final values = <bool>[];
      service.isOnlineStream.listen(values.add);

      controller.add(true);
      await Future<void>.delayed(Duration.zero);

      expect(values, contains(true));
      await controller.close();
    });

    test('isOnlineStream emits false when offline', () async {
      final controller = StreamController<bool>.broadcast();
      when(() => service.isOnlineStream).thenAnswer((_) => controller.stream);

      final values = <bool>[];
      service.isOnlineStream.listen(values.add);

      controller.add(false);
      await Future<void>.delayed(Duration.zero);

      expect(values, contains(false));
      await controller.close();
    });

    test('isOnlineStream emits connectivity transitions', () async {
      final controller = StreamController<bool>.broadcast();
      when(() => service.isOnlineStream).thenAnswer((_) => controller.stream);

      final values = <bool>[];
      service.isOnlineStream.listen(values.add);

      controller.add(true);
      controller.add(false);
      controller.add(true);
      await Future<void>.delayed(Duration.zero);

      expect(values, equals([true, false, true]));
      await controller.close();
    });
  });

  group('AlwaysOnlineConnectivityService', () {
    test('isOnline always returns true', () async {
      final service = AlwaysOnlineConnectivityService();

      expect(await service.isOnline, isTrue);
    });

    test('isOnlineStream emits a single true event', () async {
      final service = AlwaysOnlineConnectivityService();

      final first = await service.isOnlineStream.first;

      expect(first, isTrue);
    });
  });

  group('AlwaysOfflineConnectivityService', () {
    test('isOnline always returns false', () async {
      final service = AlwaysOfflineConnectivityService();

      expect(await service.isOnline, isFalse);
    });

    test('isOnlineStream emits a single false event', () async {
      final service = AlwaysOfflineConnectivityService();

      final first = await service.isOnlineStream.first;

      expect(first, isFalse);
    });
  });
}
