import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/subscription/subscription_state.dart';

void main() {
  // ---------------------------------------------------------------------------
  // SubscriptionStateFree
  // ---------------------------------------------------------------------------

  group('SubscriptionStateFree', () {
    test('isPro returns false', () {
      const state = SubscriptionStateFree();
      expect(state.isPro, isFalse);
    });

    test('two instances are equal', () {
      expect(const SubscriptionStateFree(), equals(const SubscriptionStateFree()));
    });

    test('hashCode is consistent', () {
      expect(
        const SubscriptionStateFree().hashCode,
        equals(const SubscriptionStateFree().hashCode),
      );
    });

    test('toString identifies the type', () {
      expect(
        const SubscriptionStateFree().toString(),
        contains('SubscriptionStateFree'),
      );
    });

    test('is a SubscriptionState', () {
      expect(const SubscriptionStateFree(), isA<SubscriptionState>());
    });
  });

  // ---------------------------------------------------------------------------
  // SubscriptionStateTrial
  // ---------------------------------------------------------------------------

  group('SubscriptionStateTrial', () {
    test('isPro returns true', () {
      const state = SubscriptionStateTrial(daysLeft: 3);
      expect(state.isPro, isTrue);
    });

    test('daysLeft is stored correctly', () {
      const state = SubscriptionStateTrial(daysLeft: 7);
      expect(state.daysLeft, 7);
    });

    test('two instances with same daysLeft are equal', () {
      expect(
        const SubscriptionStateTrial(daysLeft: 4),
        equals(const SubscriptionStateTrial(daysLeft: 4)),
      );
    });

    test('two instances with different daysLeft are not equal', () {
      expect(
        const SubscriptionStateTrial(daysLeft: 3),
        isNot(equals(const SubscriptionStateTrial(daysLeft: 4))),
      );
    });

    test('hashCode differs for different daysLeft', () {
      expect(
        const SubscriptionStateTrial(daysLeft: 1).hashCode,
        isNot(equals(const SubscriptionStateTrial(daysLeft: 7).hashCode)),
      );
    });

    test('toString includes daysLeft value', () {
      const state = SubscriptionStateTrial(daysLeft: 5);
      expect(state.toString(), contains('5'));
    });

    test('is a SubscriptionState', () {
      expect(const SubscriptionStateTrial(daysLeft: 1), isA<SubscriptionState>());
    });

    test('daysLeft of 1 is valid (minimum)', () {
      // Should not throw.
      expect(
        () => const SubscriptionStateTrial(daysLeft: 1),
        returnsNormally,
      );
    });

    test('not equal to SubscriptionStateFree', () {
      expect(
        const SubscriptionStateTrial(daysLeft: 3),
        isNot(equals(const SubscriptionStateFree())),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // SubscriptionStatePro
  // ---------------------------------------------------------------------------

  group('SubscriptionStatePro', () {
    test('isPro returns true', () {
      const state = SubscriptionStatePro();
      expect(state.isPro, isTrue);
    });

    test('two instances are equal', () {
      expect(const SubscriptionStatePro(), equals(const SubscriptionStatePro()));
    });

    test('hashCode is consistent', () {
      expect(
        const SubscriptionStatePro().hashCode,
        equals(const SubscriptionStatePro().hashCode),
      );
    });

    test('toString identifies the type', () {
      expect(
        const SubscriptionStatePro().toString(),
        contains('SubscriptionStatePro'),
      );
    });

    test('is a SubscriptionState', () {
      expect(const SubscriptionStatePro(), isA<SubscriptionState>());
    });

    test('not equal to SubscriptionStateFree', () {
      expect(
        const SubscriptionStatePro(),
        isNot(equals(const SubscriptionStateFree())),
      );
    });

    test('not equal to SubscriptionStateTrial', () {
      expect(
        const SubscriptionStatePro(),
        isNot(equals(const SubscriptionStateTrial(daysLeft: 7))),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Pattern matching exhaustiveness (sealed class)
  // ---------------------------------------------------------------------------

  group('sealed class pattern matching', () {
    SubscriptionState makeState(String type) => switch (type) {
          'free' => const SubscriptionStateFree(),
          'trial' => const SubscriptionStateTrial(daysLeft: 3),
          'pro' => const SubscriptionStatePro(),
          _ => throw ArgumentError(type),
        };

    test('pattern matches all three variants without default', () {
      for (final type in ['free', 'trial', 'pro']) {
        final state = makeState(type);
        final label = switch (state) {
          SubscriptionStateFree() => 'free',
          SubscriptionStateTrial() => 'trial',
          SubscriptionStatePro() => 'pro',
        };
        expect(label, type);
      }
    });
  });
}
