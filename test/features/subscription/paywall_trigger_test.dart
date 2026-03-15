import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/subscription/paywall_trigger.dart';

void main() {
  group('PaywallTrigger', () {
    test('has five values', () {
      expect(PaywallTrigger.values.length, equals(5));
    });

    test('contains profile', () {
      expect(PaywallTrigger.values, contains(PaywallTrigger.profile));
    });

    test('contains quizLimit', () {
      expect(PaywallTrigger.values, contains(PaywallTrigger.quizLimit));
    });

    test('contains zoneExpansion', () {
      expect(PaywallTrigger.values, contains(PaywallTrigger.zoneExpansion));
    });

    test('contains stats', () {
      expect(PaywallTrigger.values, contains(PaywallTrigger.stats));
    });

    test('contains milestone', () {
      expect(PaywallTrigger.values, contains(PaywallTrigger.milestone));
    });
  });
}
