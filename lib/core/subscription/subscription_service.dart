import 'package:flutter/foundation.dart';

import 'purchase_result.dart';
import 'purchases_adapter.dart';
import 'subscription_state.dart';
import 'subscription_storage.dart';

/// Hive box key for the persisted [SubscriptionState] JSON blob.
const _kStateKey = 'subscription_state';

/// Hive key constants for serialising [SubscriptionState] variants.
const _kTypeFree = 'free';
const _kTypeTrial = 'trial';
const _kTypePro = 'pro';

/// Service that manages the user's subscription state.
///
/// Wraps [PurchasesAdapter] (RevenueCat) and exposes a
/// [ValueNotifier<SubscriptionState>] so that the UI can reactively rebuild
/// when state changes.
///
/// Persists the last-known state to [SubscriptionStorage] so the app can
/// start offline with a cached result while the live fetch completes in the
/// background.
class SubscriptionService {
  SubscriptionService({
    required PurchasesAdapter adapter,
    required SubscriptionStorage storage,
    String? revenueCatApiKey,
    DateTime Function()? clock,
  })  : _adapter = adapter,
        _storage = storage,
        _apiKey = revenueCatApiKey ?? '',
        _clock = clock ?? DateTime.now;

  final PurchasesAdapter _adapter;
  final SubscriptionStorage _storage;
  final String _apiKey;
  final DateTime Function() _clock;

  /// Current subscription state, updated whenever [initialize] or a purchase
  /// method completes.
  ///
  /// Starts as [SubscriptionStateFree] and is immediately overwritten with
  /// the cached value (if any) during [initialize].
  final ValueNotifier<SubscriptionState> state =
      ValueNotifier(const SubscriptionStateFree());

  /// `true` when the user has active Pro access (paid or trial).
  bool get isPro => state.value.isPro;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initialises the SDK, hydrates state from cache, then fetches live.
  ///
  /// Call once at app startup. Safe to await; will not throw — errors are
  /// logged and result in [SubscriptionStateFree].
  Future<void> initialize() async {
    // 1. Load cached state immediately so UI is non-blocking.
    final cached = _loadCachedState();
    if (cached != null) {
      state.value = cached;
    }

    // 2. Configure the SDK.
    try {
      await _adapter.configure(_apiKey);
    } catch (e) {
      // SDK configure failed — continue with cached state.
      debugPrint('SubscriptionService: configure error: $e');
      return;
    }

    // 3. Fetch live entitlement.
    await _refreshFromNetwork();
  }

  // ---------------------------------------------------------------------------
  // Purchase actions
  // ---------------------------------------------------------------------------

  /// Triggers the StoreKit / Play purchase flow for the annual Pro plan.
  ///
  /// Updates [state] on success. Always returns a [PurchaseResult]; never
  /// throws.
  Future<PurchaseResult> purchaseAnnual() =>
      _purchase(DanderProductIds.annual);

  /// Triggers the StoreKit / Play purchase flow for the monthly Pro plan.
  ///
  /// Updates [state] on success. Always returns a [PurchaseResult]; never
  /// throws.
  Future<PurchaseResult> purchaseMonthly() =>
      _purchase(DanderProductIds.monthly);

  /// Restores prior purchases and refreshes [state].
  ///
  /// Never throws — errors result in no state change.
  Future<void> restorePurchases() async {
    try {
      final entitlement = await _adapter.restorePurchases();
      final newState = entitlementToState(entitlement, now: _clock());
      _updateState(newState);
    } catch (e) {
      debugPrint('SubscriptionService: restorePurchases error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<PurchaseResult> _purchase(String productId) async {
    try {
      final result = await _adapter.purchaseProduct(productId);
      if (result is PurchaseSuccess) {
        await _refreshFromNetwork();
      }
      return result;
    } catch (e) {
      debugPrint('SubscriptionService: purchase error: $e');
      return PurchaseError(e.toString());
    }
  }

  Future<void> _refreshFromNetwork() async {
    try {
      final entitlement = await _adapter.fetchProEntitlement();
      final newState = entitlementToState(entitlement, now: _clock());
      _updateState(newState);
    } catch (e) {
      debugPrint('SubscriptionService: fetchProEntitlement error: $e');
    }
  }

  void _updateState(SubscriptionState newState) {
    state.value = newState;
    _persistState(newState);
  }

  // ---------------------------------------------------------------------------
  // Storage persistence
  // ---------------------------------------------------------------------------

  void _persistState(SubscriptionState s) {
    final map = _stateToMap(s);
    _storage.put(_kStateKey, map);
  }

  SubscriptionState? _loadCachedState() {
    final raw = _storage.get(_kStateKey);
    if (raw == null) return null;
    try {
      final map = Map<String, dynamic>.from(raw as Map);
      return _stateFromMap(map);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _stateToMap(SubscriptionState s) =>
      switch (s) {
        SubscriptionStateFree() => {'type': _kTypeFree},
        SubscriptionStateTrial(:final daysLeft) => {
            'type': _kTypeTrial,
            'daysLeft': daysLeft,
          },
        SubscriptionStatePro() => {'type': _kTypePro},
      };

  static SubscriptionState? _stateFromMap(Map<String, dynamic> map) {
    return switch (map['type'] as String?) {
      _kTypeFree => const SubscriptionStateFree(),
      _kTypeTrial => SubscriptionStateTrial(
          daysLeft: (map['daysLeft'] as num).toInt(),
        ),
      _kTypePro => const SubscriptionStatePro(),
      _ => null,
    };
  }
}
