import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dander/core/analytics/analytics_event.dart';
import 'package:dander/core/analytics/analytics_service.dart';
import 'package:dander/core/analytics/install_date_repository.dart';
import 'package:dander/core/subscription/purchase_result.dart';
import 'package:dander/core/subscription/purchases_adapter.dart';
import 'package:dander/core/subscription/subscription_service.dart';
import 'package:dander/core/subscription/subscription_storage.dart';
import 'package:dander/features/subscription/paywall_trigger.dart';
import 'package:dander/features/subscription/presentation/screens/paywall_screen.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockPurchasesAdapter extends Mock implements PurchasesAdapter {}

class _MockSubscriptionStorage extends Mock implements SubscriptionStorage {}

// ---------------------------------------------------------------------------
// Fake InstallDateRepository that returns a fixed date instantly
// ---------------------------------------------------------------------------

class _FakeInstallDateRepository implements InstallDateRepository {
  static final _fixedDate = DateTime(2024, 1, 1);

  @override
  Future<DateTime> getOrCreate() async => _fixedDate;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SubscriptionService _makeService({
  PurchaseResult annualResult = const PurchaseCancelled(),
  PurchaseResult monthlyResult = const PurchaseCancelled(),
}) {
  final adapter = _MockPurchasesAdapter();
  final storage = _MockSubscriptionStorage();

  when(() => storage.get(any())).thenReturn(null);
  when(() => storage.put(any(), any())).thenAnswer((_) async {});
  when(() => adapter.configure(any())).thenAnswer((_) async {});
  when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);
  when(() => adapter.purchaseProduct(DanderProductIds.annual))
      .thenAnswer((_) async => annualResult);
  when(() => adapter.purchaseProduct(DanderProductIds.monthly))
      .thenAnswer((_) async => monthlyResult);
  when(() => adapter.restorePurchases()).thenAnswer((_) async => null);

  return SubscriptionService(adapter: adapter, storage: storage);
}

Widget _wrap(
  Widget child, {
  required InMemoryAnalyticsService analytics,
  SubscriptionService? service,
}) {
  final svc = service ?? _makeService();

  GetIt.instance
    ..registerSingleton<SubscriptionService>(svc)
    ..registerSingleton<AnalyticsService>(analytics)
    ..registerSingleton<InstallDateRepository>(_FakeInstallDateRepository());

  return MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: child,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    // Clean slate for every test
    final gi = GetIt.instance;
    if (gi.isRegistered<SubscriptionService>()) {
      gi.unregister<SubscriptionService>();
    }
    if (gi.isRegistered<AnalyticsService>()) {
      gi.unregister<AnalyticsService>();
    }
    if (gi.isRegistered<InstallDateRepository>()) {
      gi.unregister<InstallDateRepository>();
    }
  });

  tearDown(() {
    final gi = GetIt.instance;
    if (gi.isRegistered<SubscriptionService>()) {
      gi.unregister<SubscriptionService>();
    }
    if (gi.isRegistered<AnalyticsService>()) {
      gi.unregister<AnalyticsService>();
    }
    if (gi.isRegistered<InstallDateRepository>()) {
      gi.unregister<InstallDateRepository>();
    }
  });

  group('PaywallScreen analytics', () {
    testWidgets('PaywallViewed fires when screen is displayed', (tester) async {
      final analytics = InMemoryAnalyticsService();

      await tester.pumpWidget(_wrap(
        const PaywallScreen(trigger: PaywallTrigger.profile),
        analytics: analytics,
      ));
      await tester.pump(); // allow initState microtasks
      await tester.pump(); // allow post-frame callback

      expect(
        analytics.events.whereType<PaywallViewed>(),
        hasLength(1),
        reason: 'PaywallViewed should fire exactly once on screen open',
      );
      final event = analytics.events.whereType<PaywallViewed>().first;
      expect(event.properties['trigger'], equals('profile'));
    });

    testWidgets(
        'PaywallDismissed fires when close button tapped with positive timeOnScreenMs',
        (tester) async {
      final analytics = InMemoryAnalyticsService();

      await tester.pumpWidget(_wrap(
        const PaywallScreen(trigger: PaywallTrigger.quizLimit),
        analytics: analytics,
      ));
      await tester.pump();
      await tester.pump();

      // Tap the close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      final dismissed = analytics.events.whereType<PaywallDismissed>();
      expect(
        dismissed,
        hasLength(1),
        reason: 'PaywallDismissed should fire exactly once on close tap',
      );
      final event = dismissed.first;
      expect(event.properties['trigger'], equals('quizLimit'));
      expect(
        event.properties['time_on_screen_ms'],
        isA<int>(),
        reason: 'timeOnScreenMs should be an integer',
      );
      expect(
        (event.properties['time_on_screen_ms'] as int) >= 0,
        isTrue,
        reason: 'timeOnScreenMs should be non-negative',
      );
    });

    testWidgets(
        'SubscriptionStarted fires on successful annual purchase with plan=annual',
        (tester) async {
      final analytics = InMemoryAnalyticsService();
      final service = _makeService(
        annualResult: const PurchaseSuccess(),
      );

      await tester.pumpWidget(_wrap(
        const PaywallScreen(trigger: PaywallTrigger.stats),
        analytics: analytics,
        service: service,
      ));
      await tester.pump();
      await tester.pump();

      // Scroll to the annual plan button and tap
      await tester.scrollUntilVisible(
        find.text('Start free trial'),
        50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Start free trial'));
      await tester.pump();
      await tester.pump();

      final started = analytics.events.whereType<SubscriptionStarted>();
      expect(
        started,
        hasLength(1),
        reason: 'SubscriptionStarted should fire on PurchaseSuccess',
      );
      final event = started.first;
      expect(event.properties['plan'], equals('annual'));
      expect(event.properties['trigger'], equals('stats'));
    });

    testWidgets(
        'SubscriptionStarted fires on successful monthly purchase with plan=monthly',
        (tester) async {
      final analytics = InMemoryAnalyticsService();
      final service = _makeService(
        monthlyResult: const PurchaseSuccess(),
      );

      await tester.pumpWidget(_wrap(
        const PaywallScreen(trigger: PaywallTrigger.profile),
        analytics: analytics,
        service: service,
      ));
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Subscribe'),
        50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Subscribe'));
      await tester.pump();
      await tester.pump();

      final started = analytics.events.whereType<SubscriptionStarted>();
      expect(started, hasLength(1));
      final event = started.first;
      expect(event.properties['plan'], equals('monthly'));
    });

    testWidgets('SubscriptionStarted does NOT fire on purchase cancel',
        (tester) async {
      final analytics = InMemoryAnalyticsService();
      final service = _makeService(
        annualResult: const PurchaseCancelled(),
      );

      await tester.pumpWidget(_wrap(
        const PaywallScreen(trigger: PaywallTrigger.profile),
        analytics: analytics,
        service: service,
      ));
      await tester.pump();
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Start free trial'),
        50,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Start free trial'));
      await tester.pump();
      await tester.pump();

      expect(analytics.events.whereType<SubscriptionStarted>(), isEmpty);
    });
  });
}
