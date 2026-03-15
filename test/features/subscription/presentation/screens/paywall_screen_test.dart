import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dander/core/subscription/purchase_result.dart';
import 'package:dander/core/subscription/subscription_service.dart';
import 'package:dander/core/subscription/purchases_adapter.dart';
import 'package:dander/core/subscription/subscription_storage.dart';
import 'package:dander/features/subscription/paywall_trigger.dart';
import 'package:dander/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:dander/features/subscription/presentation/widgets/plan_card.dart';
import 'package:dander/features/subscription/presentation/widgets/benefit_row.dart';
import 'package:dander/features/subscription/presentation/widgets/paywall_hero.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockPurchasesAdapter extends Mock implements PurchasesAdapter {}

class _MockSubscriptionStorage extends Mock implements SubscriptionStorage {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SubscriptionService _makeService({
  PurchaseResult annualResult = const PurchaseCancelled(),
  PurchaseResult monthlyResult = const PurchaseCancelled(),
  bool throwOnPurchase = false,
}) {
  final adapter = _MockPurchasesAdapter();
  final storage = _MockSubscriptionStorage();

  when(() => storage.get(any())).thenReturn(null);
  when(() => storage.put(any(), any())).thenAnswer((_) async {});
  when(() => adapter.configure(any())).thenAnswer((_) async {});
  when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);

  if (throwOnPurchase) {
    when(() => adapter.purchaseProduct(any()))
        .thenThrow(Exception('Store error'));
  } else {
    when(() => adapter.purchaseProduct(DanderProductIds.annual))
        .thenAnswer((_) async => annualResult);
    when(() => adapter.purchaseProduct(DanderProductIds.monthly))
        .thenAnswer((_) async => monthlyResult);
  }

  when(() => adapter.restorePurchases()).thenAnswer((_) async => null);

  return SubscriptionService(adapter: adapter, storage: storage);
}

/// Wraps in a MediaQuery that disables animations (eliminates looping
/// AnimationController issues in pumpAndSettle).
Widget _wrap(
  Widget child, {
  SubscriptionService? service,
}) {
  final svc = service ?? _makeService();
  if (GetIt.instance.isRegistered<SubscriptionService>()) {
    GetIt.instance.unregister<SubscriptionService>();
  }
  GetIt.instance.registerSingleton<SubscriptionService>(svc);

  return MediaQuery(
    // Disable animations so pumpAndSettle can settle looping heroes.
    data: const MediaQueryData(disableAnimations: true),
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: child,
    ),
  );
}

void main() {
  tearDown(() {
    if (GetIt.instance.isRegistered<SubscriptionService>()) {
      GetIt.instance.unregister<SubscriptionService>();
    }
  });

  group('PaywallScreen', () {
    group('rendering', () {
      testWidgets('renders DANDER PRO headline', (tester) async {
        await tester.pumpWidget(_wrap(
          const PaywallScreen(trigger: PaywallTrigger.profile),
        ));
        await tester.pump();

        expect(find.text('DANDER PRO'), findsOneWidget);
      });

      testWidgets('renders subtitle text', (tester) async {
        await tester.pumpWidget(_wrap(
          const PaywallScreen(trigger: PaywallTrigger.profile),
        ));
        await tester.pump();

        expect(
          find.text('Take your exploration further'),
          findsOneWidget,
        );
      });

      testWidgets('renders three BenefitRow widgets', (tester) async {
        await tester.pumpWidget(_wrap(
          const PaywallScreen(trigger: PaywallTrigger.profile),
        ));
        await tester.pump();

        expect(find.byType(BenefitRow), findsNWidgets(3));
      });

      testWidgets('renders two PlanCard widgets', (tester) async {
        await tester.pumpWidget(_wrap(
          const PaywallScreen(trigger: PaywallTrigger.profile),
        ));
        await tester.pump();

        expect(find.byType(PlanCard), findsNWidgets(2));
      });

      testWidgets('renders PaywallHero', (tester) async {
        await tester.pumpWidget(_wrap(
          const PaywallScreen(trigger: PaywallTrigger.profile),
        ));
        await tester.pump();

        expect(find.byType(PaywallHero), findsOneWidget);
      });

      testWidgets('renders close button', (tester) async {
        await tester.pumpWidget(_wrap(
          const PaywallScreen(trigger: PaywallTrigger.profile),
        ));
        await tester.pump();

        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('renders restore purchases link', (tester) async {
        await tester.pumpWidget(_wrap(
          const PaywallScreen(trigger: PaywallTrigger.profile),
        ));
        await tester.pump();

        // Scroll to bottom to ensure footer is visible
        await tester.scrollUntilVisible(find.text('Restore purchases'), 50);
        expect(find.text('Restore purchases'), findsOneWidget);
      });

      testWidgets('renders Terms link', (tester) async {
        await tester.pumpWidget(_wrap(
          const PaywallScreen(trigger: PaywallTrigger.profile),
        ));
        await tester.pump();

        await tester.scrollUntilVisible(find.text('Terms'), 50);
        expect(find.text('Terms'), findsOneWidget);
      });

      testWidgets('renders Privacy link', (tester) async {
        await tester.pumpWidget(_wrap(
          const PaywallScreen(trigger: PaywallTrigger.profile),
        ));
        await tester.pump();

        await tester.scrollUntilVisible(find.text('Privacy'), 50);
        expect(find.text('Privacy'), findsOneWidget);
      });

      testWidgets('renders for each trigger variant', (tester) async {
        for (final trigger in PaywallTrigger.values) {
          await tester.pumpWidget(_wrap(
            PaywallScreen(trigger: trigger),
          ));
          await tester.pump();

          expect(find.byType(PaywallScreen), findsOneWidget);
        }
      });
    });

    group('close button', () {
      testWidgets('close button pops the screen', (tester) async {
        if (GetIt.instance.isRegistered<SubscriptionService>()) {
          GetIt.instance.unregister<SubscriptionService>();
        }
        GetIt.instance
            .registerSingleton<SubscriptionService>(_makeService());

        await tester.pumpWidget(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              home: _CloseTester(),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump();

        expect(find.byIcon(Icons.close), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();
        await tester.pump();

        // Back at the launch screen
        expect(find.text('Open'), findsOneWidget);
      });
    });

    group('annual purchase flow', () {
      testWidgets('shows loading indicator while processing annual purchase',
          (tester) async {
        final completer = Completer<PurchaseResult>();
        final adapter = _MockPurchasesAdapter();
        final storage = _MockSubscriptionStorage();

        when(() => storage.get(any())).thenReturn(null);
        when(() => storage.put(any(), any())).thenAnswer((_) async {});
        when(() => adapter.configure(any())).thenAnswer((_) async {});
        when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);
        when(() => adapter.purchaseProduct(DanderProductIds.annual))
            .thenAnswer((_) => completer.future);
        when(() => adapter.purchaseProduct(DanderProductIds.monthly))
            .thenAnswer((_) async => const PurchaseCancelled());
        when(() => adapter.restorePurchases()).thenAnswer((_) async => null);

        final service = SubscriptionService(
          adapter: adapter,
          storage: storage,
        );

        await tester.pumpWidget(_wrap(
          const PaywallScreen(trigger: PaywallTrigger.profile),
          service: service,
        ));
        await tester.pump();

        // Scroll the "Start free trial" button into view
        await tester.scrollUntilVisible(
          find.text('Start free trial'),
          50,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Start free trial'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsWidgets);

        completer.complete(const PurchaseCancelled());
        await tester.pump();
      });

      testWidgets('re-enables button on cancel', (tester) async {
        final service = _makeService(
          annualResult: const PurchaseCancelled(),
        );

        await tester.pumpWidget(_wrap(
          const PaywallScreen(trigger: PaywallTrigger.profile),
          service: service,
        ));
        await tester.pump();

        await tester.scrollUntilVisible(
          find.text('Start free trial'),
          50,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Start free trial'));
        await tester.pump();
        await tester.pump();

        // Button should be re-enabled: text visible, no spinner
        expect(find.text('Start free trial'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('shows inline error on purchase error', (tester) async {
        final service = _makeService(throwOnPurchase: true);

        await tester.pumpWidget(_wrap(
          const PaywallScreen(trigger: PaywallTrigger.profile),
          service: service,
        ));
        await tester.pump();

        await tester.scrollUntilVisible(
          find.text('Start free trial'),
          50,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Start free trial'));
        await tester.pump();
        await tester.pump();

        expect(
          find.text('Something went wrong. Try again.'),
          findsOneWidget,
        );
      });
    });

    group('monthly purchase flow', () {
      testWidgets('shows loading on monthly subscribe tap', (tester) async {
        final completer = Completer<PurchaseResult>();
        final adapter = _MockPurchasesAdapter();
        final storage = _MockSubscriptionStorage();

        when(() => storage.get(any())).thenReturn(null);
        when(() => storage.put(any(), any())).thenAnswer((_) async {});
        when(() => adapter.configure(any())).thenAnswer((_) async {});
        when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);
        when(() => adapter.purchaseProduct(DanderProductIds.monthly))
            .thenAnswer((_) => completer.future);
        when(() => adapter.purchaseProduct(DanderProductIds.annual))
            .thenAnswer((_) async => const PurchaseCancelled());
        when(() => adapter.restorePurchases()).thenAnswer((_) async => null);

        final service = SubscriptionService(
          adapter: adapter,
          storage: storage,
        );

        await tester.pumpWidget(_wrap(
          const PaywallScreen(trigger: PaywallTrigger.quizLimit),
          service: service,
        ));
        await tester.pump();

        await tester.scrollUntilVisible(
          find.text('Subscribe'),
          50,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Subscribe'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsWidgets);

        completer.complete(const PurchaseCancelled());
        await tester.pump();
      });

      testWidgets('shows error on monthly error', (tester) async {
        final adapter = _MockPurchasesAdapter();
        final storage = _MockSubscriptionStorage();

        when(() => storage.get(any())).thenReturn(null);
        when(() => storage.put(any(), any())).thenAnswer((_) async {});
        when(() => adapter.configure(any())).thenAnswer((_) async {});
        when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);
        when(() => adapter.purchaseProduct(any()))
            .thenThrow(Exception('error'));
        when(() => adapter.restorePurchases()).thenAnswer((_) async => null);

        final service = SubscriptionService(
          adapter: adapter,
          storage: storage,
        );

        await tester.pumpWidget(_wrap(
          const PaywallScreen(trigger: PaywallTrigger.quizLimit),
          service: service,
        ));
        await tester.pump();

        await tester.scrollUntilVisible(
          find.text('Subscribe'),
          50,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Subscribe'));
        await tester.pump();
        await tester.pump();

        expect(
          find.text('Something went wrong. Try again.'),
          findsOneWidget,
        );
      });
    });

    group('accessibility', () {
      testWidgets('close button is present', (tester) async {
        await tester.pumpWidget(_wrap(
          const PaywallScreen(trigger: PaywallTrigger.profile),
        ));
        await tester.pump();

        expect(find.byIcon(Icons.close), findsOneWidget);
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Helper widget for testing Navigator.pop
// ---------------------------------------------------------------------------

class _CloseTester extends StatelessWidget {
  const _CloseTester();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PaywallScreen(
                trigger: PaywallTrigger.profile,
              ),
            ),
          );
        },
        child: const Text('Open'),
      ),
    );
  }
}
