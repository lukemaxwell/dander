import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/location/compass_heading_service.dart';

void main() {
  group('MockCompassHeadingService', () {
    late MockCompassHeadingService service;

    setUp(() {
      service = MockCompassHeadingService();
    });

    tearDown(() {
      service.dispose();
    });

    test('emits values added via the stream controller', () async {
      final emitted = <double>[];
      final sub = service.headingStream.listen(emitted.add);

      service.add(90.0);
      service.add(180.0);
      service.add(270.0);

      // Yield through the event loop so all pending stream deliveries complete.
      await Future<void>.delayed(Duration.zero);

      expect(emitted, equals([90.0, 180.0, 270.0]));

      await sub.cancel();
    });

    test('headingStream emits valid degree values between 0 and 360', () async {
      double? received;
      final sub = service.headingStream.listen((d) => received = d);

      service.add(45.0);
      await Future<void>.delayed(Duration.zero);

      expect(received, isNotNull);
      expect(received, greaterThanOrEqualTo(0.0));
      expect(received, lessThanOrEqualTo(360.0));

      await sub.cancel();
    });

    test('dispose() closes the stream so new subscriptions receive no events',
        () async {
      service.dispose();

      final emitted = <double>[];
      // After dispose the stream is closed; listen should complete immediately.
      final sub = service.headingStream.listen(emitted.add);

      // Give the stream a tick to close.
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(emitted, isEmpty);
    });

    test('can have multiple listeners simultaneously', () async {
      final list1 = <double>[];
      final list2 = <double>[];

      final sub1 = service.headingStream.listen(list1.add);
      final sub2 = service.headingStream.listen(list2.add);

      service.add(123.0);
      await Future<void>.delayed(Duration.zero);

      expect(list1, equals([123.0]));
      expect(list2, equals([123.0]));

      await sub1.cancel();
      await sub2.cancel();
    });
  });

  group('CompassHeadingService interface contract', () {
    // Ensures MockCompassHeadingService satisfies the abstract interface.
    test('MockCompassHeadingService implements CompassHeadingService', () {
      final CompassHeadingService service = MockCompassHeadingService();
      expect(service.headingStream, isA<Stream<double>>());
      service.dispose();
    });
  });
}
