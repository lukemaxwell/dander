import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:dander/core/di/service_locator.dart';

void main() {
  group('ServiceLocator', () {
    setUp(() async {
      // Reset GetIt before each test to ensure isolation
      await GetIt.instance.reset();
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    test('setupLocator registers services without throwing', () async {
      await setupLocator();
      // If no exception is thrown, the test passes
    });

    test('serviceLocator is the shared GetIt instance', () {
      expect(serviceLocator, same(GetIt.instance));
    });

    test('setupLocator can be called after reset', () async {
      await setupLocator();
      await GetIt.instance.reset();
      await setupLocator();
      // Should complete without error
    });

    test('calling setupLocator twice with reset in between does not throw',
        () async {
      await setupLocator();
      await GetIt.instance.reset();
      await setupLocator();
      // Should complete without error
    });
  });
}
