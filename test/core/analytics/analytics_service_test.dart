import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/analytics/analytics_event.dart';
import 'package:dander/core/analytics/analytics_service.dart';
import 'package:dander/features/subscription/paywall_trigger.dart';

void main() {
  const testEvent = PaywallViewed(
    trigger: PaywallTrigger.profile,
    sessionDay: 1,
  );

  group('NoOpAnalyticsService', () {
    test('track does not throw', () {
      const service = NoOpAnalyticsService();
      expect(() => service.track(testEvent), returnsNormally);
    });
  });

  group('DebugAnalyticsService', () {
    test('track does not throw', () {
      final service = DebugAnalyticsService();
      expect(() => service.track(testEvent), returnsNormally);
    });
  });

  group('InMemoryAnalyticsService', () {
    test('starts with empty events list', () {
      final service = InMemoryAnalyticsService();
      expect(service.events, isEmpty);
    });

    test('track appends event to events list', () {
      final service = InMemoryAnalyticsService();
      service.track(testEvent);
      expect(service.events, hasLength(1));
      expect(service.events.first, same(testEvent));
    });

    test('track appends multiple events in order', () {
      final service = InMemoryAnalyticsService();
      const second = QuizLimitReached(correct: 5, total: 10);
      service.track(testEvent);
      service.track(second);
      expect(service.events, hasLength(2));
      expect(service.events[0], same(testEvent));
      expect(service.events[1], same(second));
    });

    test('events list is mutable (can be cleared for assertions)', () {
      final service = InMemoryAnalyticsService();
      service.track(testEvent);
      service.events.clear();
      expect(service.events, isEmpty);
    });
  });
}
