import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dander/core/subscription/purchase_result.dart';
import 'package:dander/core/subscription/purchases_adapter.dart';
import 'package:dander/core/subscription/subscription_service.dart';
import 'package:dander/core/subscription/subscription_state.dart';
import 'package:dander/core/subscription/subscription_storage.dart';
import 'package:dander/core/theme/dander_colors.dart';
import 'package:dander/features/subscription/paywall_trigger.dart';
import 'package:dander/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:dander/features/subscription/presentation/widgets/pro_badge.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockPurchasesAdapter extends Mock implements PurchasesAdapter {}

class _MockSubscriptionStorage extends Mock implements SubscriptionStorage {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SubscriptionService _makeService(SubscriptionState initialState) {
  final adapter = _MockPurchasesAdapter();
  final storage = _MockSubscriptionStorage();

  when(() => storage.get(any())).thenReturn(null);
  when(() => storage.put(any(), any())).thenAnswer((_) async {});
  when(() => adapter.configure(any())).thenAnswer((_) async {});
  when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);
  when(() => adapter.purchaseProduct(any()))
      .thenAnswer((_) async => const PurchaseCancelled());
  when(() => adapter.restorePurchases()).thenAnswer((_) async => null);

  final service = SubscriptionService(adapter: adapter, storage: storage);
  service.state.value = initialState;
  return service;
}

/// Wraps a widget in a MaterialApp with MediaQuery (animations disabled).
/// Registers [service] in GetIt so ProBadge can read it.
Widget _wrap(Widget child, SubscriptionService service) {
  if (GetIt.instance.isRegistered<SubscriptionService>()) {
    GetIt.instance.unregister<SubscriptionService>();
  }
  GetIt.instance.registerSingleton<SubscriptionService>(service);

  return MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  tearDown(() {
    if (GetIt.instance.isRegistered<SubscriptionService>()) {
      GetIt.instance.unregister<SubscriptionService>();
    }
  });

  // -------------------------------------------------------------------------
  // Free user state
  // -------------------------------------------------------------------------

  group('ProBadge — free state', () {
    testWidgets('renders "Pro ›" text', (tester) async {
      final service = _makeService(const SubscriptionStateFree());

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      expect(find.text('Pro ›'), findsOneWidget);
    });

    testWidgets('does not render sparkle icon', (tester) async {
      final service = _makeService(const SubscriptionStateFree());

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('does not show trial days text', (tester) async {
      final service = _makeService(const SubscriptionStateFree());

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      expect(find.textContaining('days left'), findsNothing);
    });

    testWidgets('touch target is at least 44x44', (tester) async {
      final service = _makeService(const SubscriptionStateFree());

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      final sizeBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      // The outer touch-target SizedBox must be >= 44x44
      final touchTargets = sizeBoxes.where(
        (b) =>
            b.width != null &&
            b.height != null &&
            b.width! >= 44 &&
            b.height! >= 44,
      );
      expect(touchTargets, isNotEmpty);
    });

    testWidgets('tapping navigates to PaywallScreen with profile trigger',
        (tester) async {
      final service = _makeService(const SubscriptionStateFree());

      // Use a navigator so we can verify the push
      bool navigated = false;

      if (GetIt.instance.isRegistered<SubscriptionService>()) {
        GetIt.instance.unregister<SubscriptionService>();
      }
      GetIt.instance.registerSingleton<SubscriptionService>(service);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: ThemeData(splashFactory: NoSplash.splashFactory),
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: GestureDetector(
                    // Intercept navigation to verify trigger
                    onTap: () {},
                    child: ProBadge(
                      onNavigate: (trigger) {
                        navigated = true;
                        expect(trigger, PaywallTrigger.profile);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ProBadge));
      await tester.pump();

      expect(navigated, isTrue);
    });

    testWidgets('navigates to PaywallScreen when tapped (integration)',
        (tester) async {
      final service = _makeService(const SubscriptionStateFree());

      if (GetIt.instance.isRegistered<SubscriptionService>()) {
        GetIt.instance.unregister<SubscriptionService>();
      }
      GetIt.instance.registerSingleton<SubscriptionService>(service);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: ThemeData(splashFactory: NoSplash.splashFactory),
            home: Scaffold(
              body: Center(child: const ProBadge()),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ProBadge));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Trial state
  // -------------------------------------------------------------------------

  group('ProBadge — trial state', () {
    testWidgets('renders "Pro ›" text', (tester) async {
      final service =
          _makeService(const SubscriptionStateTrial(daysLeft: 4));

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      expect(find.text('Pro ›'), findsOneWidget);
    });

    testWidgets('shows trial days remaining text', (tester) async {
      final service =
          _makeService(const SubscriptionStateTrial(daysLeft: 4));

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      expect(find.text('Pro trial · 4 days left'), findsOneWidget);
    });

    testWidgets('shows correct day count for 1 day remaining', (tester) async {
      final service =
          _makeService(const SubscriptionStateTrial(daysLeft: 1));

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      expect(find.text('Pro trial · 1 days left'), findsOneWidget);
    });

    testWidgets('shows correct day count for 7 days remaining', (tester) async {
      final service =
          _makeService(const SubscriptionStateTrial(daysLeft: 7));

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      expect(find.text('Pro trial · 7 days left'), findsOneWidget);
    });

    testWidgets('trial days text is rendered in DanderColors.secondary color',
        (tester) async {
      final service =
          _makeService(const SubscriptionStateTrial(daysLeft: 3));

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      final textWidget = tester.widget<Text>(
        find.text('Pro trial · 3 days left'),
      );
      expect(textWidget.style?.color, DanderColors.secondary);
    });
  });

  // -------------------------------------------------------------------------
  // Pro subscriber state
  // -------------------------------------------------------------------------

  group('ProBadge — pro state', () {
    testWidgets('renders "Pro" text', (tester) async {
      final service = _makeService(const SubscriptionStatePro());

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      expect(find.text('Pro'), findsOneWidget);
    });

    testWidgets('renders auto_awesome (sparkle) icon', (tester) async {
      final service = _makeService(const SubscriptionStatePro());

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('does not render "›" chevron', (tester) async {
      final service = _makeService(const SubscriptionStatePro());

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      // The free/trial state text is "Pro ›"; pro state is just "Pro"
      expect(find.text('Pro ›'), findsNothing);
    });

    testWidgets('does not show trial days text', (tester) async {
      final service = _makeService(const SubscriptionStatePro());

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      expect(find.textContaining('days left'), findsNothing);
    });

    testWidgets('tap is a no-op — does not navigate to PaywallScreen',
        (tester) async {
      final service = _makeService(const SubscriptionStatePro());

      if (GetIt.instance.isRegistered<SubscriptionService>()) {
        GetIt.instance.unregister<SubscriptionService>();
      }
      GetIt.instance.registerSingleton<SubscriptionService>(service);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: ThemeData(splashFactory: NoSplash.splashFactory),
            home: Scaffold(
              body: Center(child: const ProBadge()),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ProBadge));
      await tester.pumpAndSettle();

      expect(find.byType(PaywallScreen), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Reactive updates
  // -------------------------------------------------------------------------

  group('ProBadge — reactive updates', () {
    testWidgets('updates when subscription state changes from free to pro',
        (tester) async {
      final service = _makeService(const SubscriptionStateFree());

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      expect(find.text('Pro ›'), findsOneWidget);
      expect(find.text('Pro'), findsNothing);

      // Simulate upgrade
      service.state.value = const SubscriptionStatePro();
      await tester.pump();

      expect(find.text('Pro'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('updates when subscription state changes from free to trial',
        (tester) async {
      final service = _makeService(const SubscriptionStateFree());

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      expect(find.textContaining('days left'), findsNothing);

      service.state.value = const SubscriptionStateTrial(daysLeft: 5);
      await tester.pump();

      expect(find.text('Pro trial · 5 days left'), findsOneWidget);
    });

    testWidgets('updates when trial expires to free', (tester) async {
      final service =
          _makeService(const SubscriptionStateTrial(daysLeft: 2));

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      expect(find.text('Pro trial · 2 days left'), findsOneWidget);

      service.state.value = const SubscriptionStateFree();
      await tester.pump();

      expect(find.text('Pro ›'), findsOneWidget);
      expect(find.textContaining('days left'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Gradient border (structural checks)
  // -------------------------------------------------------------------------

  group('ProBadge — visual structure', () {
    testWidgets('uses ShaderMask or outer gradient Container for gradient border',
        (tester) async {
      final service = _makeService(const SubscriptionStateFree());

      await tester.pumpWidget(_wrap(const ProBadge(), service));
      await tester.pump();

      // The gradient border is achieved via a Container with gradient decoration
      // wrapping an inner Container. We verify at least one Container exists
      // with a BoxDecoration (the outer gradient layer).
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration)
          .toList();
      expect(containers, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // onNavigate callback (unit tests for internal navigation contract)
  // -------------------------------------------------------------------------

  group('ProBadge — onNavigate callback', () {
    testWidgets('free state: onNavigate called with profile trigger on tap',
        (tester) async {
      final service = _makeService(const SubscriptionStateFree());

      PaywallTrigger? receivedTrigger;

      await tester.pumpWidget(_wrap(
        ProBadge(onNavigate: (t) => receivedTrigger = t),
        service,
      ));
      await tester.pump();

      await tester.tap(find.byType(ProBadge));
      await tester.pump();

      expect(receivedTrigger, PaywallTrigger.profile);
    });

    testWidgets('trial state: onNavigate called with profile trigger on tap',
        (tester) async {
      final service =
          _makeService(const SubscriptionStateTrial(daysLeft: 3));

      PaywallTrigger? receivedTrigger;

      await tester.pumpWidget(_wrap(
        ProBadge(onNavigate: (t) => receivedTrigger = t),
        service,
      ));
      await tester.pump();

      await tester.tap(find.byType(ProBadge));
      await tester.pump();

      expect(receivedTrigger, PaywallTrigger.profile);
    });

    testWidgets('pro state: onNavigate is NOT called on tap', (tester) async {
      final service = _makeService(const SubscriptionStatePro());

      PaywallTrigger? receivedTrigger;

      await tester.pumpWidget(_wrap(
        ProBadge(onNavigate: (t) => receivedTrigger = t),
        service,
      ));
      await tester.pump();

      await tester.tap(find.byType(ProBadge));
      await tester.pump();

      expect(receivedTrigger, isNull);
    });
  });
}
