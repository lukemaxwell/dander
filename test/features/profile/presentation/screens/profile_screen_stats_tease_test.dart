import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dander/core/analytics/analytics_service.dart';
import 'package:dander/core/analytics/install_date_repository.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/progress/badge.dart';
import 'package:dander/core/progress/streak_tracker.dart';
import 'package:dander/core/subscription/purchase_result.dart';
import 'package:dander/core/subscription/purchases_adapter.dart';
import 'package:dander/core/subscription/subscription_service.dart';
import 'package:dander/core/subscription/subscription_state.dart';
import 'package:dander/core/subscription/subscription_storage.dart';
import 'package:dander/features/profile/presentation/screens/profile_screen.dart';
import 'package:dander/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:dander/features/subscription/presentation/widgets/stats_tease_card.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockPurchasesAdapter extends Mock implements PurchasesAdapter {}

class _MockSubscriptionStorage extends Mock implements SubscriptionStorage {}

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeInstallDateRepository implements InstallDateRepository {
  @override
  Future<DateTime> getOrCreate() async => DateTime(2024, 1, 1);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SubscriptionService _makeServiceWithState(SubscriptionState initialState) {
  final adapter = _MockPurchasesAdapter();
  final storage = _MockSubscriptionStorage();

  when(() => storage.get(any())).thenReturn(null);
  when(() => storage.put(any(), any())).thenAnswer((_) async {});
  when(() => adapter.configure(any())).thenAnswer((_) async {});
  when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);
  when(() => adapter.purchaseProduct(any()))
      .thenAnswer((_) async => const PurchaseCancelled());
  when(() => adapter.restorePurchases()).thenAnswer((_) async => null);

  final svc = SubscriptionService(adapter: adapter, storage: storage);
  svc.state.value = initialState;
  return svc;
}

void _register(SubscriptionService svc) {
  final gi = GetIt.instance;
  if (gi.isRegistered<SubscriptionService>()) {
    gi.unregister<SubscriptionService>();
  }
  gi.registerSingleton<SubscriptionService>(svc);
  if (!gi.isRegistered<AnalyticsService>()) {
    gi.registerSingleton<AnalyticsService>(const NoOpAnalyticsService());
  }
  if (!gi.isRegistered<InstallDateRepository>()) {
    gi.registerSingleton<InstallDateRepository>(_FakeInstallDateRepository());
  }
}

void _unregister() {
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
}

Widget _wrap(Widget child) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(home: child),
    );

ProfileScreen _buildProfile() => ProfileScreen(
      discoveries: const <Discovery>[],
      explorationPct: 0.1,
      streak: StreakTracker.empty(),
      badges: BadgeDefinitions.badges,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  tearDown(_unregister);

  group('ProfileScreen — stats tease cards', () {
    testWidgets('free user: two StatsTeaseCard widgets are rendered',
        (tester) async {
      _register(_makeServiceWithState(const SubscriptionStateFree()));

      await tester.pumpWidget(_wrap(_buildProfile()));
      await tester.pump();

      // Scroll to the bottom of the list so all lazy items are built.
      await tester.dragFrom(
        tester.getCenter(find.byType(ListView)),
        const Offset(0, -2000),
      );
      await tester.pump();

      expect(find.byType(StatsTeaseCard), findsNWidgets(2));
    });

    testWidgets('pro user: no StatsTeaseCard widgets are rendered',
        (tester) async {
      _register(_makeServiceWithState(const SubscriptionStatePro()));

      await tester.pumpWidget(_wrap(_buildProfile()));
      await tester.pump();

      await tester.dragFrom(
        tester.getCenter(find.byType(ListView)),
        const Offset(0, -2000),
      );
      await tester.pump();

      expect(find.byType(StatsTeaseCard), findsNothing);
    });

    testWidgets('tapping Heat Map card pushes PaywallScreen', (tester) async {
      _register(_makeServiceWithState(const SubscriptionStateFree()));

      await tester.pumpWidget(_wrap(_buildProfile()));
      await tester.pump();

      // Scroll until the Heat Map card is visible using the outer ListView.
      await tester.scrollUntilVisible(
        find.widgetWithText(StatsTeaseCard, 'Heat Map'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(StatsTeaseCard, 'Heat Map'));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsOneWidget);
    });

    testWidgets('tapping Monthly Trends card pushes PaywallScreen',
        (tester) async {
      _register(_makeServiceWithState(const SubscriptionStateFree()));

      await tester.pumpWidget(_wrap(_buildProfile()));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.widgetWithText(StatsTeaseCard, 'Monthly Trends'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      await tester.tap(
          find.widgetWithText(StatsTeaseCard, 'Monthly Trends'));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsOneWidget);
    });
  });
}
