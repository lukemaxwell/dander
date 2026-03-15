import 'subscription_state.dart';
import 'purchase_result.dart';

/// RevenueCat product identifiers for Dander Pro plans.
abstract final class DanderProductIds {
  static const String annual = 'dander_pro_annual';
  static const String monthly = 'dander_pro_monthly';
}

/// RevenueCat entitlement identifier for Pro access.
abstract final class DanderEntitlements {
  static const String pro = 'pro';
}

/// Describes the entitlement info returned by RevenueCat for a single
/// entitlement.
///
/// This mirrors the relevant fields of `EntitlementInfo` from
/// `purchases_flutter`, keeping the adapter layer thin.
class EntitlementInfo {
  const EntitlementInfo({
    required this.isActive,
    required this.willRenew,
    this.expirationDate,
  });

  /// Whether the entitlement is currently active.
  final bool isActive;

  /// Whether the subscription will auto-renew.
  final bool willRenew;

  /// UTC expiration date, or `null` for lifetime / non-expiring entitlements.
  final DateTime? expirationDate;
}

/// Abstract interface over the RevenueCat SDK.
///
/// The real implementation delegates to `purchases_flutter`. Tests inject a
/// [MockPurchasesAdapter] so the SDK is never invoked in unit tests.
abstract interface class PurchasesAdapter {
  /// Configures the SDK with the platform [apiKey].
  ///
  /// Must be called once before any other method. Calling it more than once
  /// on the same adapter is a no-op.
  Future<void> configure(String apiKey);

  /// Fetches the current entitlement info for the [pro] entitlement.
  ///
  /// Returns `null` if the user has no active entitlement.
  Future<EntitlementInfo?> fetchProEntitlement();

  /// Triggers a purchase flow for [productId].
  ///
  /// Returns a [PurchaseResult] regardless of outcome — never throws.
  Future<PurchaseResult> purchaseProduct(String productId);

  /// Restores previous purchases and refreshes entitlements.
  ///
  /// Returns the updated entitlement info, or `null` if still not entitled.
  Future<EntitlementInfo?> restorePurchases();
}

/// Converts a [EntitlementInfo] (from RevenueCat) into a [SubscriptionState].
///
/// Trial detection: RevenueCat marks trials as active entitlements whose
/// underlying subscription is in a trial period. We compute [daysLeft] from
/// the [expirationDate] relative to [now].
///
/// If [info] is null or not active → [SubscriptionStateFree].
/// If active with an expiry within 7 days of now → [SubscriptionStateTrial].
/// Otherwise active → [SubscriptionStatePro].
SubscriptionState entitlementToState(
  EntitlementInfo? info, {
  required DateTime now,
}) {
  if (info == null || !info.isActive) {
    return const SubscriptionStateFree();
  }

  final expiry = info.expirationDate;
  if (expiry != null) {
    final daysLeft = expiry.difference(now).inDays;
    // A daysLeft of 0 means the trial expires today but has not yet lapsed
    // (same-day): treat as 1 day left to avoid the SubscriptionStateTrial
    // assert firing. If already expired (daysLeft < 0) fall through to Free.
    if (daysLeft < 0) return const SubscriptionStateFree();
    if (!info.willRenew) {
      // Non-renewing active entitlement with future expiry = trial.
      final safeDays = daysLeft < 1 ? 1 : daysLeft;
      return SubscriptionStateTrial(daysLeft: safeDays);
    }
  }

  return const SubscriptionStatePro();
}
