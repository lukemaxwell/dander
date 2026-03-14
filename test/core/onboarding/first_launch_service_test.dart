import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/onboarding/first_launch_service.dart';

void main() {
  group('FirstLaunchService', () {
    test('isFirstLaunch is true initially', () {
      final service = FirstLaunchService(isFirstLaunch: true);
      expect(service.isFirstLaunch, isTrue);
    });

    test('isFirstLaunch is false when not first launch', () {
      final service = FirstLaunchService(isFirstLaunch: false);
      expect(service.isFirstLaunch, isFalse);
    });

    test('microRevealCompleted starts false on first launch', () {
      final service = FirstLaunchService(isFirstLaunch: true);
      expect(service.microRevealCompleted, isFalse);
    });

    test('completeMicroReveal sets flag to true', () {
      final service = FirstLaunchService(isFirstLaunch: true);
      final updated = service.completeMicroReveal();
      expect(updated.microRevealCompleted, isTrue);
    });

    test('completeMicroReveal preserves isFirstLaunch', () {
      final service = FirstLaunchService(isFirstLaunch: true);
      final updated = service.completeMicroReveal();
      expect(updated.isFirstLaunch, isTrue);
    });

    test('microRevealCompleted is false when not first launch', () {
      final service = FirstLaunchService(isFirstLaunch: false);
      expect(service.microRevealCompleted, isFalse);
    });

    test('firstLaunchExplorationRadius is 100m', () {
      expect(FirstLaunchService.firstLaunchExplorationRadius, 100.0);
    });

    test('defaultExplorationRadius is 50m', () {
      expect(FirstLaunchService.defaultExplorationRadius, 50.0);
    });

    test('explorationRadius returns 100m on first launch', () {
      final service = FirstLaunchService(isFirstLaunch: true);
      expect(service.explorationRadius, 100.0);
    });

    test('explorationRadius returns 50m on returning launch', () {
      final service = FirstLaunchService(isFirstLaunch: false);
      expect(service.explorationRadius, 50.0);
    });
  });
}
