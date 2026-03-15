import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/subscription/purchases_adapter.dart';
import 'package:dander/core/subscription/subscription_state.dart';

void main() {
  // ---------------------------------------------------------------------------
  // entitlementToState — the pure mapping function
  // ---------------------------------------------------------------------------

  final now = DateTime(2026, 3, 15, 12, 0);

  group('entitlementToState — null entitlement', () {
    test('returns Free when info is null', () {
      expect(
        entitlementToState(null, now: now),
        equals(const SubscriptionStateFree()),
      );
    });
  });

  group('entitlementToState — inactive entitlement', () {
    test('returns Free when isActive is false', () {
      final info = EntitlementInfo(
        isActive: false,
        willRenew: false,
        expirationDate: now.add(const Duration(days: 10)),
      );
      expect(
        entitlementToState(info, now: now),
        equals(const SubscriptionStateFree()),
      );
    });
  });

  group('entitlementToState — active, renewing (paid subscription)', () {
    test('returns Pro when active with willRenew true and no expiry', () {
      final info = EntitlementInfo(
        isActive: true,
        willRenew: true,
      );
      expect(
        entitlementToState(info, now: now),
        equals(const SubscriptionStatePro()),
      );
    });

    test('returns Pro when active with willRenew true and future expiry', () {
      final info = EntitlementInfo(
        isActive: true,
        willRenew: true,
        expirationDate: now.add(const Duration(days: 365)),
      );
      expect(
        entitlementToState(info, now: now),
        equals(const SubscriptionStatePro()),
      );
    });
  });

  group('entitlementToState — trial (active, non-renewing)', () {
    test('returns Trial with correct daysLeft when willRenew is false', () {
      final info = EntitlementInfo(
        isActive: true,
        willRenew: false,
        expirationDate: now.add(const Duration(days: 7)),
      );
      final result = entitlementToState(info, now: now);
      expect(result, isA<SubscriptionStateTrial>());
      expect((result as SubscriptionStateTrial).daysLeft, 7);
    });

    test('returns Trial(daysLeft: 3) with 3 days remaining', () {
      final info = EntitlementInfo(
        isActive: true,
        willRenew: false,
        expirationDate: now.add(const Duration(days: 3)),
      );
      final result = entitlementToState(info, now: now);
      expect((result as SubscriptionStateTrial).daysLeft, 3);
    });

    test('returns Trial(daysLeft: 1) when expiry is same day', () {
      // expirationDate is later today — inDays rounds down to 0, safe to 1.
      final info = EntitlementInfo(
        isActive: true,
        willRenew: false,
        expirationDate: now.add(const Duration(hours: 6)),
      );
      final result = entitlementToState(info, now: now);
      expect(result, isA<SubscriptionStateTrial>());
      expect((result as SubscriptionStateTrial).daysLeft, 1);
    });

    test('returns Free when trial expiry is in the past', () {
      final info = EntitlementInfo(
        isActive: true,
        willRenew: false,
        expirationDate: now.subtract(const Duration(days: 1)),
      );
      expect(
        entitlementToState(info, now: now),
        equals(const SubscriptionStateFree()),
      );
    });
  });

  group('entitlementToState — active with no expiry (lifetime)', () {
    test('returns Pro when active, willRenew true, and no expiration', () {
      final info = EntitlementInfo(isActive: true, willRenew: true);
      expect(
        entitlementToState(info, now: now),
        equals(const SubscriptionStatePro()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // DanderProductIds constants
  // ---------------------------------------------------------------------------

  group('DanderProductIds', () {
    test('annual product id is dander_pro_annual', () {
      expect(DanderProductIds.annual, 'dander_pro_annual');
    });

    test('monthly product id is dander_pro_monthly', () {
      expect(DanderProductIds.monthly, 'dander_pro_monthly');
    });
  });

  // ---------------------------------------------------------------------------
  // DanderEntitlements constants
  // ---------------------------------------------------------------------------

  group('DanderEntitlements', () {
    test('pro entitlement id is pro', () {
      expect(DanderEntitlements.pro, 'pro');
    });
  });
}
