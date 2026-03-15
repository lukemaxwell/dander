import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import 'purchase_result.dart';
import 'purchases_adapter.dart';

/// Thin wrapper around the `purchases_flutter` static SDK so it can be
/// replaced with a fake in tests.
///
/// Only the methods called by [RevenueCatPurchasesAdapter] are exposed.
abstract interface class RevenueCatSdkClient {
  Future<void> configure(String apiKey);
  Future<rc.CustomerInfo> getCustomerInfo();
  Future<rc.CustomerInfo> purchaseProduct(String productId);
  Future<rc.CustomerInfo> restorePurchases();
}

/// Default implementation that delegates to the real RevenueCat SDK.
class LiveRevenueCatSdkClient implements RevenueCatSdkClient {
  @override
  Future<void> configure(String apiKey) =>
      rc.Purchases.configure(rc.PurchasesConfiguration(apiKey));

  @override
  Future<rc.CustomerInfo> getCustomerInfo() => rc.Purchases.getCustomerInfo();

  @override
  // ignore: deprecated_member_use
  Future<rc.CustomerInfo> purchaseProduct(String productId) =>
      // ignore: deprecated_member_use
      rc.Purchases.purchaseProduct(productId);

  @override
  Future<rc.CustomerInfo> restorePurchases() => rc.Purchases.restorePurchases();
}

/// Concrete [PurchasesAdapter] that delegates to the `purchases_flutter` SDK
/// via an injectable [RevenueCatSdkClient].
///
/// In production, [RevenueCatPurchasesAdapter()] uses [LiveRevenueCatSdkClient].
/// In tests, inject a [FakeRevenueCatSdkClient] (or mocktail mock) to avoid
/// platform channel calls.
///
/// ## Idempotent configure
/// [configure] is a no-op after the first successful call — the RevenueCat SDK
/// must only be initialised once per app lifetime.
class RevenueCatPurchasesAdapter implements PurchasesAdapter {
  RevenueCatPurchasesAdapter({RevenueCatSdkClient? sdkClient})
      : _sdkClient = sdkClient ?? LiveRevenueCatSdkClient();

  final RevenueCatSdkClient _sdkClient;

  /// Stores the in-flight or completed configure future so concurrent callers
  /// await the same operation rather than racing to call the SDK twice.
  /// Reset to null on failure so the caller can retry.
  Future<void>? _configFuture;

  // ---------------------------------------------------------------------------
  // PurchasesAdapter interface
  // ---------------------------------------------------------------------------

  @override
  Future<void> configure(String apiKey) {
    return _configFuture ??= _sdkClient.configure(apiKey).catchError((Object e) {
      _configFuture = null; // allow retry after failure
      throw e;
    });
  }

  @override
  Future<EntitlementInfo?> fetchProEntitlement() async {
    final customerInfo = await _sdkClient.getCustomerInfo();
    return _extractProEntitlement(customerInfo);
  }

  @override
  Future<PurchaseResult> purchaseProduct(String productId) async {
    try {
      // SDK returns post-purchase CustomerInfo — use it directly to avoid a
      // second network round-trip and eliminate the stale-state window.
      final customerInfo = await _sdkClient.purchaseProduct(productId);
      final entitlement = _extractProEntitlement(customerInfo);
      return PurchaseSuccess(entitlement: entitlement);
    } on PlatformException catch (e) {
      final code = rc.PurchasesErrorHelper.getErrorCode(e);
      if (code == rc.PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseCancelled();
      }
      return PurchaseError(e.message ?? e.code);
    } catch (e) {
      return PurchaseError(e.toString());
    }
  }

  @override
  Future<EntitlementInfo?> restorePurchases() async {
    final customerInfo = await _sdkClient.restorePurchases();
    return _extractProEntitlement(customerInfo);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  EntitlementInfo? _extractProEntitlement(rc.CustomerInfo customerInfo) {
    final sdkInfo = customerInfo.entitlements.all[DanderEntitlements.pro];
    if (sdkInfo == null || !sdkInfo.isActive) return null;
    return _mapEntitlementInfo(sdkInfo);
  }

  EntitlementInfo _mapEntitlementInfo(rc.EntitlementInfo sdkInfo) {
    return EntitlementInfo(
      isActive: sdkInfo.isActive,
      willRenew: sdkInfo.willRenew,
      expirationDate: _parseDate(sdkInfo.expirationDate),
    );
  }

  /// Parses an ISO-8601 date string from the RevenueCat SDK into a UTC [DateTime].
  ///
  /// Returns `null` when [raw] is null or cannot be parsed — the SDK can
  /// return unexpected formats in edge cases and we must never throw here.
  static DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw).toUtc();
    } catch (_) {
      return null;
    }
  }
}
