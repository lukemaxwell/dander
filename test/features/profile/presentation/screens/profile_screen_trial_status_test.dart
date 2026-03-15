import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dander/core/progress/badge.dart';
import 'package:dander/core/progress/streak_tracker.dart';
import 'package:dander/core/subscription/purchase_result.dart';
import 'package:dander/core/subscription/purchases_adapter.dart';
import 'package:dander/core/subscription/subscription_service.dart';
import 'package:dander/core/subscription/subscription_state.dart';
import 'package:dander/core/subscription/subscription_storage.dart';
import 'package:dander/features/profile/presentation/screens/profile_screen.dart';

// ---------------------------------------------------------------------------
// Fakes / Mocks
// ---------------------------------------------------------------------------

class _MockPurchasesAdapter extends Mock implements PurchasesAdapter {}

class _MockSubscriptionStorage extends Mock implements SubscriptionStorage {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SubscriptionService _makeService({required SubscriptionState initialState}) {
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

void _registerService(SubscriptionService svc) {
  if (GetIt.instance.isRegistered<SubscriptionService>()) {
    GetIt.instance.unregister<SubscriptionService>();
  }
  GetIt.instance.registerSingleton<SubscriptionService>(svc);
}

void _unregisterService() {
  if (GetIt.instance.isRegistered<SubscriptionService>()) {
    GetIt.instance.unregister<SubscriptionService>();
  }
}

Widget _wrap(Widget child) => MaterialApp(home: child);

ProfileScreen _buildScreen() => ProfileScreen(
      discoveries: const [],
      explorationPct: 0.0,
      streak: StreakTracker.empty(),
      badges: BadgeDefinitions.badges,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  tearDown(_unregisterService);

  group('ProfileScreen — trial status label', () {
    testWidgets(
      'shows "Pro trial · 2 days left" when state is SubscriptionStateTrial(daysLeft: 2)',
      (tester) async {
        _registerService(
          _makeService(initialState: const SubscriptionStateTrial(daysLeft: 2)),
        );

        await tester.pumpWidget(_wrap(_buildScreen()));
        await tester.pump();

        // Appears in both ProBadge (header) and body status label.
        expect(find.text('Pro trial · 2 days left'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'shows correct days count when daysLeft is 5',
      (tester) async {
        _registerService(
          _makeService(initialState: const SubscriptionStateTrial(daysLeft: 5)),
        );

        await tester.pumpWidget(_wrap(_buildScreen()));
        await tester.pump();

        expect(find.text('Pro trial · 5 days left'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'does NOT show trial text when state is SubscriptionStateFree',
      (tester) async {
        _registerService(
          _makeService(initialState: const SubscriptionStateFree()),
        );

        await tester.pumpWidget(_wrap(_buildScreen()));
        await tester.pump();

        expect(find.textContaining('Pro trial'), findsNothing);
      },
    );

    testWidgets(
      'does NOT show trial text when state is SubscriptionStatePro',
      (tester) async {
        _registerService(
          _makeService(initialState: const SubscriptionStatePro()),
        );

        await tester.pumpWidget(_wrap(_buildScreen()));
        await tester.pump();

        expect(find.textContaining('Pro trial'), findsNothing);
      },
    );

    testWidgets(
      'updates displayed text reactively when state changes to Trial',
      (tester) async {
        final svc = _makeService(initialState: const SubscriptionStateFree());
        _registerService(svc);

        await tester.pumpWidget(_wrap(_buildScreen()));
        await tester.pump();

        // No trial label yet
        expect(find.textContaining('Pro trial'), findsNothing);

        // Transition to trial
        svc.state.value = const SubscriptionStateTrial(daysLeft: 3);
        await tester.pump();

        expect(find.text('Pro trial · 3 days left'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'trial text disappears reactively when state transitions from Trial to Pro',
      (tester) async {
        final svc = _makeService(
          initialState: const SubscriptionStateTrial(daysLeft: 1),
        );
        _registerService(svc);

        await tester.pumpWidget(_wrap(_buildScreen()));
        await tester.pump();

        expect(find.text('Pro trial · 1 days left'), findsAtLeastNWidgets(1));

        // Upgrade to full Pro
        svc.state.value = const SubscriptionStatePro();
        await tester.pump();

        expect(find.textContaining('Pro trial'), findsNothing);
      },
    );
  });
}
