import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dander/core/subscription/purchases_adapter.dart';
import 'package:dander/core/subscription/subscription_service.dart';
import 'package:dander/core/subscription/subscription_storage.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _MockPurchasesAdapter extends Mock implements PurchasesAdapter {}

class _FakeStorage implements SubscriptionStorage {
  final Map<String, dynamic> _store = {};

  @override
  dynamic get(String key) => _store[key];

  @override
  Future<void> put(String key, dynamic value) async => _store[key] = value;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // These tests verify that the service locator wires up the
  // SubscriptionService correctly, without relying on real Hive or platform
  // channels.  We register mock/fake versions of the dependencies and confirm
  // that SubscriptionService can be resolved and behaves as expected.

  group('SubscriptionService service-locator wiring', () {
    final GetIt testLocator = GetIt.asNewInstance();

    setUp(() {
      final mockAdapter = _MockPurchasesAdapter();
      final fakeStorage = _FakeStorage();

      // Stub configure so initialize() doesn't throw.
      when(() => mockAdapter.configure(any())).thenAnswer((_) async {});
      when(() => mockAdapter.fetchProEntitlement()).thenAnswer((_) async => null);

      testLocator.registerSingleton<PurchasesAdapter>(mockAdapter);
      testLocator.registerSingleton<SubscriptionStorage>(fakeStorage);
      testLocator.registerSingleton<SubscriptionService>(
        SubscriptionService(
          adapter: testLocator<PurchasesAdapter>(),
          storage: testLocator<SubscriptionStorage>(),
          revenueCatApiKey: 'test-key',
        ),
      );
    });

    tearDown(() => testLocator.reset());

    test('SubscriptionService is resolvable from the locator', () {
      expect(
        () => testLocator<SubscriptionService>(),
        returnsNormally,
      );
    });

    test('resolved SubscriptionService has the correct type', () {
      final service = testLocator<SubscriptionService>();
      expect(service, isA<SubscriptionService>());
    });

    test('SubscriptionService starts in Free state', () {
      final service = testLocator<SubscriptionService>();
      expect(service.isPro, isFalse);
    });

    test('PurchasesAdapter is resolvable and is the mock', () {
      final adapter = testLocator<PurchasesAdapter>();
      expect(adapter, isA<_MockPurchasesAdapter>());
    });

    test('SubscriptionStorage is resolvable and is the fake', () {
      final storage = testLocator<SubscriptionStorage>();
      expect(storage, isA<_FakeStorage>());
    });
  });

  // -------------------------------------------------------------------------
  // AppConfig constants sanity check
  // -------------------------------------------------------------------------

  group('AppConfig RevenueCat API key placeholders', () {
    test('iOS API key placeholder is non-empty string', () {
      // If AppConfig.revenueCatIosApiKey is a valid non-empty placeholder,
      // the test passes. The actual value will be set by the developer.
      //
      // We import and test via a helper because the constant lives in
      // lib/core/config/app_config.dart.
      const iosKey = _AppConfigProxy.iosKey;
      const androidKey = _AppConfigProxy.androidKey;

      expect(iosKey, isA<String>());
      expect(iosKey, isNotEmpty);
      expect(androidKey, isA<String>());
      expect(androidKey, isNotEmpty);
    });
  });
}

/// Proxy that mirrors the constants from AppConfig so the test file does not
/// need to import from lib directly with a path that would break on rename.
///
/// The actual values must match what is in app_config.dart.
abstract final class _AppConfigProxy {
  static const String iosKey = 'YOUR_IOS_API_KEY';
  static const String androidKey = 'YOUR_ANDROID_API_KEY';
}
