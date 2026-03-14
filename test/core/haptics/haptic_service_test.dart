import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/haptics/haptic_service.dart';

void main() {
  group('HapticService — API', () {
    test('walkStarted() returns normally', () {
      // The real implementation calls HapticFeedback.heavyImpact();
      // in a test environment it simply no-ops.
      expect(() => HapticService.walkStarted(), returnsNormally);
    });

    test('walkEnded() returns normally', () {
      expect(() => HapticService.walkEnded(), returnsNormally);
    });

    test('quizAnswerCorrect() returns normally', () {
      expect(() => HapticService.quizAnswerCorrect(), returnsNormally);
    });

    test('quizAnswerIncorrect() returns normally', () {
      expect(() => HapticService.quizAnswerIncorrect(), returnsNormally);
    });

    test('badgeEarned() returns normally', () {
      expect(() => HapticService.badgeEarned(), returnsNormally);
    });

    test('discoveryFound() returns normally', () {
      expect(() => HapticService.discoveryFound(), returnsNormally);
    });

    test('navTabSwitch() returns normally', () {
      expect(() => HapticService.navTabSwitch(), returnsNormally);
    });

    test('levelUp() returns normally', () {
      expect(() => HapticService.levelUp(), returnsNormally);
    });

    test('rareDiscovery() returns normally', () {
      expect(() => HapticService.rareDiscovery(), returnsNormally);
    });

    test('streakMilestone() returns normally', () {
      expect(() => HapticService.streakMilestone(), returnsNormally);
    });

    test('discoveryCardTap() returns normally', () {
      expect(() => HapticService.discoveryCardTap(), returnsNormally);
    });
  });
}
