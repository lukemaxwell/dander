import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dander/core/subscription/purchase_result.dart';
import 'package:dander/core/subscription/purchases_adapter.dart';
import 'package:dander/core/subscription/subscription_service.dart';
import 'package:dander/core/subscription/subscription_state.dart';
import 'package:dander/core/subscription/subscription_storage.dart';

// ---------------------------------------------------------------------------
// Fakes / Mocks
// ---------------------------------------------------------------------------

class MockPurchasesAdapter extends Mock implements PurchasesAdapter {}

/// Minimal in-memory [SubscriptionStorage] for use in tests.
class FakeSubscriptionStorage implements SubscriptionStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic get(String key) => _data[key];

  @override
  Future<void> put(String key, dynamic value) async {
    _data[key] = value;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _fixedNow = DateTime(2026, 3, 15, 12, 0);
DateTime _clock() => _fixedNow;

EntitlementInfo _proEntitlement() => EntitlementInfo(
      isActive: true,
      willRenew: true,
    );

EntitlementInfo _trialEntitlement({int daysLeft = 7}) => EntitlementInfo(
      isActive: true,
      willRenew: false,
      expirationDate: _fixedNow.add(Duration(days: daysLeft)),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockPurchasesAdapter adapter;
  late FakeSubscriptionStorage box;
  late SubscriptionService service;

  setUp(() {
    adapter = MockPurchasesAdapter();
    box = FakeSubscriptionStorage();
    service = SubscriptionService(
      adapter: adapter,
      storage: box,
      revenueCatApiKey: 'test_key',
      clock: _clock,
    );
  });

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  group('initial state', () {
    test('starts as SubscriptionStateFree before initialize()', () {
      expect(service.state.value, equals(const SubscriptionStateFree()));
    });

    test('isPro is false before initialize()', () {
      expect(service.isPro, isFalse);
    });

    test('state is a ValueNotifier<SubscriptionState>', () {
      expect(service.state, isA<ValueNotifier<SubscriptionState>>());
    });
  });

  // ---------------------------------------------------------------------------
  // initialize — no cache, network returns free
  // ---------------------------------------------------------------------------

  group('initialize — no cached state', () {
    test('calls adapter.configure with the api key', () async {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);

      await service.initialize();

      verify(() => adapter.configure('test_key')).called(1);
    });

    test('state is Free when entitlement is null', () async {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);

      await service.initialize();

      expect(service.state.value, equals(const SubscriptionStateFree()));
    });

    test('state becomes Pro when network returns active entitlement', () async {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement())
          .thenAnswer((_) async => _proEntitlement());

      await service.initialize();

      expect(service.state.value, equals(const SubscriptionStatePro()));
    });

    test('state becomes Trial when network returns trial entitlement', () async {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement())
          .thenAnswer((_) async => _trialEntitlement(daysLeft: 5));

      await service.initialize();

      expect(service.state.value, isA<SubscriptionStateTrial>());
      expect(
        (service.state.value as SubscriptionStateTrial).daysLeft,
        5,
      );
    });

    test('isPro is true after initialize returns Pro entitlement', () async {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement())
          .thenAnswer((_) async => _proEntitlement());

      await service.initialize();

      expect(service.isPro, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // initialize — cached state is hydrated immediately
  // ---------------------------------------------------------------------------

  group('initialize — with cached state', () {
    test('hydrates Pro state from cache before network call', () async {
      // Pre-populate box with a Pro state.
      await box.put('subscription_state', {'type': 'pro'});

      // Network is deliberately slow — set up but capture order.
      final callOrder = <String>[];
      when(() => adapter.configure(any())).thenAnswer((_) async {
        callOrder.add('configure');
      });
      when(() => adapter.fetchProEntitlement()).thenAnswer((_) async {
        callOrder.add('fetch');
        return null;
      });

      // Capture state changes.
      SubscriptionState? stateAfterCacheLoad;
      service.state.addListener(() {
        stateAfterCacheLoad ??= service.state.value;
      });

      await service.initialize();

      // The first emitted state should be the cached Pro.
      expect(stateAfterCacheLoad, equals(const SubscriptionStatePro()));
    });

    test('overwrites cached Free with live Pro after network returns', () async {
      await box.put('subscription_state', {'type': 'free'});
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement())
          .thenAnswer((_) async => _proEntitlement());

      await service.initialize();

      expect(service.state.value, equals(const SubscriptionStatePro()));
    });

    test('corrupted cache value is ignored — falls back to live fetch',
        () async {
      await box.put('subscription_state', 'not-a-map');
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);

      // Should not throw.
      await service.initialize();

      expect(service.state.value, equals(const SubscriptionStateFree()));
    });

    test('unknown type in cache map is ignored gracefully', () async {
      await box.put('subscription_state', {'type': 'alien_tier'});
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);

      await service.initialize();

      expect(service.state.value, equals(const SubscriptionStateFree()));
    });

    test('hydrates Trial state from cache with correct daysLeft', () async {
      await box.put('subscription_state', {'type': 'trial', 'daysLeft': 3});
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      // Network returns null so cache trial survives.
      when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);

      SubscriptionState? firstState;
      service.state.addListener(() {
        firstState ??= service.state.value;
      });

      await service.initialize();

      expect(firstState, isA<SubscriptionStateTrial>());
      expect((firstState! as SubscriptionStateTrial).daysLeft, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // initialize — network / SDK errors are handled gracefully
  // ---------------------------------------------------------------------------

  group('initialize — error resilience', () {
    test('does not throw when configure() throws', () async {
      when(() => adapter.configure(any())).thenThrow(Exception('SDK error'));

      await expectLater(service.initialize(), completes);
    });

    test('stays Free when configure() throws', () async {
      when(() => adapter.configure(any())).thenThrow(Exception('SDK error'));

      await service.initialize();

      expect(service.state.value, equals(const SubscriptionStateFree()));
    });

    test('does not throw when fetchProEntitlement() throws', () async {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement())
          .thenThrow(Exception('Network error'));

      await expectLater(service.initialize(), completes);
    });

    test('stays Free when fetchProEntitlement() throws', () async {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement())
          .thenThrow(Exception('Network error'));

      await service.initialize();

      expect(service.state.value, equals(const SubscriptionStateFree()));
    });
  });

  // ---------------------------------------------------------------------------
  // Hive persistence — state is written after live fetch
  // ---------------------------------------------------------------------------

  group('Hive persistence', () {
    test('persists Pro state to Hive after successful network fetch', () async {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement())
          .thenAnswer((_) async => _proEntitlement());

      await service.initialize();

      final saved = box.get('subscription_state');
      expect(saved, isA<Map>());
      expect((saved as Map)['type'], 'pro');
    });

    test('persists Trial state to Hive with daysLeft', () async {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement())
          .thenAnswer((_) async => _trialEntitlement(daysLeft: 4));

      await service.initialize();

      final saved = box.get('subscription_state') as Map;
      expect(saved['type'], 'trial');
      expect(saved['daysLeft'], 4);
    });

    test('persists Free state to Hive when entitlement is null', () async {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);

      await service.initialize();

      final saved = box.get('subscription_state') as Map;
      expect(saved['type'], 'free');
    });
  });

  // ---------------------------------------------------------------------------
  // purchaseAnnual
  // ---------------------------------------------------------------------------

  group('purchaseAnnual', () {
    setUp(() {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);
    });

    test('returns PurchaseSuccess and updates state to Pro on success',
        () async {
      await service.initialize();

      when(() => adapter.purchaseProduct(DanderProductIds.annual))
          .thenAnswer((_) async => const PurchaseSuccess());
      when(() => adapter.fetchProEntitlement())
          .thenAnswer((_) async => _proEntitlement());

      final result = await service.purchaseAnnual();

      expect(result, isA<PurchaseSuccess>());
      expect(service.state.value, equals(const SubscriptionStatePro()));
    });

    test('returns PurchaseCancelled and does not change state', () async {
      await service.initialize();

      when(() => adapter.purchaseProduct(DanderProductIds.annual))
          .thenAnswer((_) async => const PurchaseCancelled());

      final result = await service.purchaseAnnual();

      expect(result, isA<PurchaseCancelled>());
      expect(service.state.value, equals(const SubscriptionStateFree()));
    });

    test('returns PurchaseError and does not change state', () async {
      await service.initialize();

      when(() => adapter.purchaseProduct(DanderProductIds.annual))
          .thenAnswer((_) async => const PurchaseError('payment failed'));

      final result = await service.purchaseAnnual();

      expect(result, isA<PurchaseError>());
      expect(service.state.value, equals(const SubscriptionStateFree()));
    });

    test('returns PurchaseError when adapter throws unexpectedly', () async {
      await service.initialize();

      when(() => adapter.purchaseProduct(DanderProductIds.annual))
          .thenThrow(Exception('unexpected crash'));

      final result = await service.purchaseAnnual();

      expect(result, isA<PurchaseError>());
    });

    test('does not call fetchProEntitlement after cancel', () async {
      await service.initialize();
      // Reset interactions after initialize.
      clearInteractions(adapter);

      when(() => adapter.purchaseProduct(DanderProductIds.annual))
          .thenAnswer((_) async => const PurchaseCancelled());

      await service.purchaseAnnual();

      verifyNever(() => adapter.fetchProEntitlement());
    });

    test('calls purchaseProduct with annual product id', () async {
      await service.initialize();
      clearInteractions(adapter);

      when(() => adapter.purchaseProduct(DanderProductIds.annual))
          .thenAnswer((_) async => const PurchaseCancelled());

      await service.purchaseAnnual();

      verify(() => adapter.purchaseProduct(DanderProductIds.annual)).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // purchaseMonthly
  // ---------------------------------------------------------------------------

  group('purchaseMonthly', () {
    setUp(() {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);
    });

    test('calls purchaseProduct with monthly product id', () async {
      await service.initialize();
      clearInteractions(adapter);

      when(() => adapter.purchaseProduct(DanderProductIds.monthly))
          .thenAnswer((_) async => const PurchaseCancelled());

      await service.purchaseMonthly();

      verify(() => adapter.purchaseProduct(DanderProductIds.monthly)).called(1);
    });

    test('returns PurchaseSuccess and updates state to Pro on success',
        () async {
      await service.initialize();

      when(() => adapter.purchaseProduct(DanderProductIds.monthly))
          .thenAnswer((_) async => const PurchaseSuccess());
      when(() => adapter.fetchProEntitlement())
          .thenAnswer((_) async => _proEntitlement());

      final result = await service.purchaseMonthly();

      expect(result, isA<PurchaseSuccess>());
      expect(service.state.value, equals(const SubscriptionStatePro()));
    });

    test('returns PurchaseError when adapter throws', () async {
      await service.initialize();

      when(() => adapter.purchaseProduct(DanderProductIds.monthly))
          .thenThrow(Exception('crash'));

      final result = await service.purchaseMonthly();

      expect(result, isA<PurchaseError>());
    });
  });

  // ---------------------------------------------------------------------------
  // restorePurchases
  // ---------------------------------------------------------------------------

  group('restorePurchases', () {
    setUp(() {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);
    });

    test('updates state to Pro when restore returns active entitlement',
        () async {
      await service.initialize();

      when(() => adapter.restorePurchases())
          .thenAnswer((_) async => _proEntitlement());

      await service.restorePurchases();

      expect(service.state.value, equals(const SubscriptionStatePro()));
    });

    test('state remains Free when restore returns null', () async {
      await service.initialize();

      when(() => adapter.restorePurchases()).thenAnswer((_) async => null);

      await service.restorePurchases();

      expect(service.state.value, equals(const SubscriptionStateFree()));
    });

    test('persists restored Pro state to Hive', () async {
      await service.initialize();

      when(() => adapter.restorePurchases())
          .thenAnswer((_) async => _proEntitlement());

      await service.restorePurchases();

      final saved = box.get('subscription_state') as Map;
      expect(saved['type'], 'pro');
    });

    test('does not throw when restorePurchases adapter throws', () async {
      await service.initialize();

      when(() => adapter.restorePurchases())
          .thenThrow(Exception('restore error'));

      await expectLater(service.restorePurchases(), completes);
    });

    test('state unchanged when restorePurchases adapter throws', () async {
      await service.initialize();

      when(() => adapter.restorePurchases())
          .thenThrow(Exception('restore error'));

      await service.restorePurchases();

      expect(service.state.value, equals(const SubscriptionStateFree()));
    });
  });

  // ---------------------------------------------------------------------------
  // ValueNotifier notifications
  // ---------------------------------------------------------------------------

  group('ValueNotifier change notifications', () {
    test('listeners are notified when state transitions from Free to Pro',
        () async {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement())
          .thenAnswer((_) async => _proEntitlement());

      var notified = false;
      service.state.addListener(() => notified = true);

      await service.initialize();

      expect(notified, isTrue);
    });

    test('no notification when state does not change (Free → Free)', () async {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);

      // ValueNotifier only fires when value changes — Free → Free is same.
      var notifyCount = 0;
      service.state.addListener(() => notifyCount++);

      await service.initialize();

      // No change from initial Free → computed Free.
      expect(notifyCount, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // isPro convenience getter
  // ---------------------------------------------------------------------------

  group('isPro convenience getter', () {
    test('returns false when state is Free', () {
      expect(service.isPro, isFalse);
    });

    test('returns true when state is Pro', () async {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement())
          .thenAnswer((_) async => _proEntitlement());
      await service.initialize();
      expect(service.isPro, isTrue);
    });

    test('returns true when state is Trial', () async {
      when(() => adapter.configure(any())).thenAnswer((_) async {});
      when(() => adapter.fetchProEntitlement())
          .thenAnswer((_) async => _trialEntitlement());
      await service.initialize();
      expect(service.isPro, isTrue);
    });
  });
}
