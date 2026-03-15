import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import 'package:dander/core/subscription/purchase_result.dart';
import 'package:dander/core/subscription/purchases_adapter.dart';
import 'package:dander/core/subscription/revenuecat_purchases_adapter.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _MockSdkClient extends Mock implements RevenueCatSdkClient {}

// ---------------------------------------------------------------------------
// Builder helpers — construct rc.CustomerInfo from JSON so we never depend
// on the freezed factory directly (which requires all mandatory fields).
// ---------------------------------------------------------------------------

rc.CustomerInfo _buildCustomerInfo({
  required Map<String, rc.EntitlementInfo> allEntitlements,
  Map<String, rc.EntitlementInfo>? activeEntitlements,
}) {
  // Build via the fromJson constructor so we don't need to satisfy all
  // positional freezed parameters directly.
  final entitlementInfosJson = {
    'all': {
      for (final e in allEntitlements.entries) e.key: e.value.toJson(),
    },
    'active': {
      for (final e in (activeEntitlements ?? allEntitlements).entries)
        e.key: e.value.toJson(),
    },
    'verification': 'NOT_REQUESTED',
  };

  return rc.CustomerInfo.fromJson({
    'entitlements': entitlementInfosJson,
    'allPurchaseDates': <String, dynamic>{},
    'activeSubscriptions': <String>[],
    'allPurchasedProductIdentifiers': <String>[],
    'nonSubscriptionTransactions': <dynamic>[],
    'firstSeen': '2024-01-01T00:00:00Z',
    'originalAppUserId': 'test-user',
    'allExpirationDates': <String, dynamic>{},
    'requestDate': '2026-03-15T12:00:00Z',
  });
}

rc.EntitlementInfo _buildEntitlementInfo({
  required bool isActive,
  required bool willRenew,
  String? expirationDate,
}) {
  return rc.EntitlementInfo.fromJson({
    'identifier': 'pro',
    'isActive': isActive,
    'willRenew': willRenew,
    'latestPurchaseDate': '2024-01-01T00:00:00Z',
    'originalPurchaseDate': '2024-01-01T00:00:00Z',
    'productIdentifier': 'dander_pro_annual',
    'isSandbox': false,
    'expirationDate': expirationDate,
    'store': 'APP_STORE',
    'periodType': 'NORMAL',
    'ownershipType': 'PURCHASED',
    'verification': 'NOT_REQUESTED',
  });
}

// Pre-built fixtures.
rc.CustomerInfo _noEntitlementCustomerInfo() => _buildCustomerInfo(
      allEntitlements: {},
      activeEntitlements: {},
    );

rc.CustomerInfo _inactiveEntitlementCustomerInfo() => _buildCustomerInfo(
      allEntitlements: {
        'pro': _buildEntitlementInfo(
          isActive: false,
          willRenew: false,
        ),
      },
      activeEntitlements: {},
    );

rc.CustomerInfo _activeEntitlementCustomerInfo({
  String expirationDate = '2030-01-01T00:00:00Z',
}) =>
    _buildCustomerInfo(
      allEntitlements: {
        'pro': _buildEntitlementInfo(
          isActive: true,
          willRenew: true,
          expirationDate: expirationDate,
        ),
      },
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _MockSdkClient sdkClient;
  late RevenueCatPurchasesAdapter adapter;

  setUp(() {
    sdkClient = _MockSdkClient();
    adapter = RevenueCatPurchasesAdapter(sdkClient: sdkClient);
  });

  // -------------------------------------------------------------------------
  // configure
  // -------------------------------------------------------------------------

  group('configure', () {
    test('delegates to sdkClient.configure with the given api key', () async {
      when(() => sdkClient.configure(any())).thenAnswer((_) async {});

      await adapter.configure('test-api-key');

      verify(() => sdkClient.configure('test-api-key')).called(1);
    });

    test('second call is a no-op — sdkClient.configure called only once',
        () async {
      when(() => sdkClient.configure(any())).thenAnswer((_) async {});

      await adapter.configure('key-1');
      await adapter.configure('key-2');

      verify(() => sdkClient.configure('key-1')).called(1);
      verifyNever(() => sdkClient.configure('key-2'));
    });

    test('propagates exceptions from sdkClient.configure', () async {
      when(() => sdkClient.configure(any()))
          .thenThrow(PlatformException(code: '1', message: 'init failed'));

      await expectLater(
        () => adapter.configure('bad-key'),
        throwsA(isA<PlatformException>()),
      );
    });

    test('does not set configured flag when configure throws', () async {
      when(() => sdkClient.configure(any()))
          .thenThrow(PlatformException(code: '1', message: 'fail'));

      // First call — throws.
      await expectLater(
        () => adapter.configure('key-1'),
        throwsA(isA<PlatformException>()),
      );

      // Second call should retry sdkClient.configure.
      when(() => sdkClient.configure(any())).thenAnswer((_) async {});
      await adapter.configure('key-2');
      verify(() => sdkClient.configure('key-2')).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // fetchProEntitlement
  // -------------------------------------------------------------------------

  group('fetchProEntitlement', () {
    setUp(() {
      when(() => sdkClient.configure(any())).thenAnswer((_) async {});
    });

    test('returns null when customer has no pro entitlement', () async {
      when(() => sdkClient.getCustomerInfo())
          .thenAnswer((_) async => _noEntitlementCustomerInfo());

      await adapter.configure('k');
      final result = await adapter.fetchProEntitlement();

      expect(result, isNull);
    });

    test('returns null when pro entitlement is inactive', () async {
      when(() => sdkClient.getCustomerInfo())
          .thenAnswer((_) async => _inactiveEntitlementCustomerInfo());

      await adapter.configure('k');
      final result = await adapter.fetchProEntitlement();

      expect(result, isNull);
    });

    test('returns EntitlementInfo with correct fields for active entitlement',
        () async {
      when(() => sdkClient.getCustomerInfo()).thenAnswer(
        (_) async => _activeEntitlementCustomerInfo(
          expirationDate: '2030-01-01T00:00:00Z',
        ),
      );

      await adapter.configure('k');
      final result = await adapter.fetchProEntitlement();

      expect(result, isNotNull);
      expect(result!.isActive, isTrue);
      expect(result.willRenew, isTrue);
      expect(result.expirationDate, equals(DateTime.utc(2030)));
    });

    test('returns EntitlementInfo with null expirationDate for lifetime access',
        () async {
      final lifetimeInfo = _buildCustomerInfo(
        allEntitlements: {
          'pro': _buildEntitlementInfo(
            isActive: true,
            willRenew: false,
            expirationDate: null,
          ),
        },
      );
      when(() => sdkClient.getCustomerInfo())
          .thenAnswer((_) async => lifetimeInfo);

      await adapter.configure('k');
      final result = await adapter.fetchProEntitlement();

      expect(result, isNotNull);
      expect(result!.expirationDate, isNull);
    });

    test('propagates exceptions from sdkClient.getCustomerInfo', () async {
      when(() => sdkClient.getCustomerInfo())
          .thenThrow(PlatformException(code: '5', message: 'network error'));

      await adapter.configure('k');

      await expectLater(
        () => adapter.fetchProEntitlement(),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // purchaseProduct
  // -------------------------------------------------------------------------

  group('purchaseProduct', () {
    setUp(() {
      when(() => sdkClient.configure(any())).thenAnswer((_) async {});
    });

    test('returns PurchaseSuccess with entitlement when sdk purchase succeeds',
        () async {
      when(() => sdkClient.purchaseProduct(any())).thenAnswer(
        (_) async => _activeEntitlementCustomerInfo(),
      );

      await adapter.configure('k');
      final result = await adapter.purchaseProduct(DanderProductIds.annual);

      expect(result, isA<PurchaseSuccess>());
      // SDK returned an active entitlement — it should be threaded through.
      expect((result as PurchaseSuccess).entitlement, isNotNull);
      expect(result.entitlement!.isActive, isTrue);
    });

    test('passes the correct productId to sdkClient.purchaseProduct', () async {
      when(() => sdkClient.purchaseProduct(any())).thenAnswer(
        (_) async => _activeEntitlementCustomerInfo(),
      );

      await adapter.configure('k');
      await adapter.purchaseProduct(DanderProductIds.monthly);

      verify(() => sdkClient.purchaseProduct(DanderProductIds.monthly))
          .called(1);
    });

    test('returns PurchaseCancelled on purchaseCancelledError', () async {
      when(() => sdkClient.purchaseProduct(any())).thenThrow(
        PlatformException(
          code: '1', // PurchasesErrorCode.purchaseCancelledError index
          message: 'User cancelled',
        ),
      );

      await adapter.configure('k');
      final result = await adapter.purchaseProduct(DanderProductIds.annual);

      expect(result, equals(const PurchaseCancelled()));
    });

    test('returns PurchaseError on store problem error', () async {
      when(() => sdkClient.purchaseProduct(any())).thenThrow(
        PlatformException(
          code: '2', // storeProblemError index
          message: 'Store unavailable',
        ),
      );

      await adapter.configure('k');
      final result = await adapter.purchaseProduct(DanderProductIds.annual);

      expect(result, isA<PurchaseError>());
      expect((result as PurchaseError).message, isNotEmpty);
    });

    test('returns PurchaseError with message from PlatformException', () async {
      when(() => sdkClient.purchaseProduct(any())).thenThrow(
        PlatformException(code: '2', message: 'Billing unavailable'),
      );

      await adapter.configure('k');
      final result = await adapter.purchaseProduct(DanderProductIds.annual);

      expect((result as PurchaseError).message, contains('Billing unavailable'));
    });

    test('returns PurchaseError on non-PlatformException', () async {
      when(() => sdkClient.purchaseProduct(any()))
          .thenThrow(Exception('unexpected failure'));

      await adapter.configure('k');
      final result = await adapter.purchaseProduct(DanderProductIds.annual);

      expect(result, isA<PurchaseError>());
    });
  });

  // -------------------------------------------------------------------------
  // restorePurchases
  // -------------------------------------------------------------------------

  group('restorePurchases', () {
    setUp(() {
      when(() => sdkClient.configure(any())).thenAnswer((_) async {});
    });

    test('returns EntitlementInfo when restore finds active entitlement',
        () async {
      when(() => sdkClient.restorePurchases()).thenAnswer(
        (_) async => _activeEntitlementCustomerInfo(),
      );

      await adapter.configure('k');
      final result = await adapter.restorePurchases();

      expect(result, isNotNull);
      expect(result!.isActive, isTrue);
    });

    test('returns null when restore finds no active entitlement', () async {
      when(() => sdkClient.restorePurchases())
          .thenAnswer((_) async => _noEntitlementCustomerInfo());

      await adapter.configure('k');
      final result = await adapter.restorePurchases();

      expect(result, isNull);
    });

    test('propagates exceptions from sdkClient.restorePurchases', () async {
      when(() => sdkClient.restorePurchases())
          .thenThrow(PlatformException(code: '0', message: 'restore failed'));

      await adapter.configure('k');

      await expectLater(
        () => adapter.restorePurchases(),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // expirationDate parsing (via fetchProEntitlement)
  // -------------------------------------------------------------------------

  group('expirationDate parsing', () {
    setUp(() {
      when(() => sdkClient.configure(any())).thenAnswer((_) async {});
    });

    test('parses ISO-8601 UTC date string correctly', () async {
      when(() => sdkClient.getCustomerInfo()).thenAnswer(
        (_) async =>
            _activeEntitlementCustomerInfo(expirationDate: '2027-06-15T10:30:00Z'),
      );

      await adapter.configure('k');
      final result = await adapter.fetchProEntitlement();

      expect(
        result!.expirationDate,
        equals(DateTime.utc(2027, 6, 15, 10, 30)),
      );
    });

    test('returns null expirationDate when string is malformed', () async {
      final info = _buildCustomerInfo(
        allEntitlements: {
          'pro': _buildEntitlementInfo(
            isActive: true,
            willRenew: true,
            expirationDate: 'not-a-valid-date',
          ),
        },
      );
      when(() => sdkClient.getCustomerInfo()).thenAnswer((_) async => info);

      await adapter.configure('k');
      final result = await adapter.fetchProEntitlement();

      // Malformed date → null rather than crash.
      expect(result!.expirationDate, isNull);
    });
  });
}
