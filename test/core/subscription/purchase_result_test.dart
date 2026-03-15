import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/subscription/purchase_result.dart';

void main() {
  // ---------------------------------------------------------------------------
  // PurchaseSuccess
  // ---------------------------------------------------------------------------

  group('PurchaseSuccess', () {
    test('two instances are equal', () {
      expect(const PurchaseSuccess(), equals(const PurchaseSuccess()));
    });

    test('hashCode is consistent', () {
      expect(
        const PurchaseSuccess().hashCode,
        equals(const PurchaseSuccess().hashCode),
      );
    });

    test('toString identifies the type', () {
      expect(const PurchaseSuccess().toString(), contains('PurchaseSuccess'));
    });

    test('is a PurchaseResult', () {
      expect(const PurchaseSuccess(), isA<PurchaseResult>());
    });
  });

  // ---------------------------------------------------------------------------
  // PurchaseCancelled
  // ---------------------------------------------------------------------------

  group('PurchaseCancelled', () {
    test('two instances are equal', () {
      expect(const PurchaseCancelled(), equals(const PurchaseCancelled()));
    });

    test('hashCode is consistent', () {
      expect(
        const PurchaseCancelled().hashCode,
        equals(const PurchaseCancelled().hashCode),
      );
    });

    test('toString identifies the type', () {
      expect(const PurchaseCancelled().toString(), contains('PurchaseCancelled'));
    });

    test('is a PurchaseResult', () {
      expect(const PurchaseCancelled(), isA<PurchaseResult>());
    });

    test('not equal to PurchaseSuccess', () {
      expect(
        const PurchaseCancelled(),
        isNot(equals(const PurchaseSuccess())),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // PurchaseError
  // ---------------------------------------------------------------------------

  group('PurchaseError', () {
    test('stores message', () {
      const error = PurchaseError('Network timeout');
      expect(error.message, 'Network timeout');
    });

    test('two instances with same message are equal', () {
      expect(
        const PurchaseError('oops'),
        equals(const PurchaseError('oops')),
      );
    });

    test('two instances with different messages are not equal', () {
      expect(
        const PurchaseError('A'),
        isNot(equals(const PurchaseError('B'))),
      );
    });

    test('hashCode differs for different messages', () {
      expect(
        const PurchaseError('x').hashCode,
        isNot(equals(const PurchaseError('y').hashCode)),
      );
    });

    test('toString contains message', () {
      const error = PurchaseError('Store unavailable');
      expect(error.toString(), contains('Store unavailable'));
    });

    test('is a PurchaseResult', () {
      expect(const PurchaseError('e'), isA<PurchaseResult>());
    });

    test('not equal to PurchaseSuccess', () {
      expect(
        const PurchaseError('e'),
        isNot(equals(const PurchaseSuccess())),
      );
    });

    test('not equal to PurchaseCancelled', () {
      expect(
        const PurchaseError('e'),
        isNot(equals(const PurchaseCancelled())),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Pattern matching exhaustiveness
  // ---------------------------------------------------------------------------

  group('sealed class pattern matching', () {
    test('matches all three variants', () {
      final results = <PurchaseResult>[
        const PurchaseSuccess(),
        const PurchaseCancelled(),
        const PurchaseError('fail'),
      ];
      final labels = results.map((r) => switch (r) {
            PurchaseSuccess() => 'success',
            PurchaseCancelled() => 'cancelled',
            PurchaseError() => 'error',
          }).toList();

      expect(labels, ['success', 'cancelled', 'error']);
    });
  });
}
