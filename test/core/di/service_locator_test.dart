import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:dander/core/di/service_locator.dart';

void main() {
  group('ServiceLocator', () {
    setUp(() {
      // Reset GetIt before each test to ensure isolation
      GetIt.instance.reset();
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    test('setupLocator registers services without throwing', () {
      expect(() => setupLocator(), returnsNormally);
    });

    test('serviceLocator is the shared GetIt instance', () {
      expect(serviceLocator, same(GetIt.instance));
    });

    test('setupLocator can be called after reset', () {
      setupLocator();
      GetIt.instance.reset();
      expect(() => setupLocator(), returnsNormally);
    });

    test('calling setupLocator twice with reset in between does not throw', () {
      setupLocator();
      GetIt.instance.reset();
      setupLocator();
      // Should complete without error
    });
  });
}
