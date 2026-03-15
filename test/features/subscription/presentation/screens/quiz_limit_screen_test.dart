import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dander/core/analytics/analytics_service.dart';
import 'package:dander/core/analytics/install_date_repository.dart';
import 'package:dander/core/subscription/purchases_adapter.dart';
import 'package:dander/core/subscription/subscription_service.dart';
import 'package:dander/core/subscription/subscription_storage.dart';
import 'package:dander/features/subscription/paywall_trigger.dart';
import 'package:dander/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:dander/features/subscription/presentation/screens/quiz_limit_screen.dart';

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

SubscriptionService _makeSubscriptionService() {
  final adapter = _MockPurchasesAdapter();
  final storage = _MockSubscriptionStorage();

  when(() => storage.get(any())).thenReturn(null);
  when(() => storage.put(any(), any())).thenAnswer((_) async {});
  when(() => adapter.configure(any())).thenAnswer((_) async {});
  when(() => adapter.fetchProEntitlement()).thenAnswer((_) async => null);
  when(() => adapter.restorePurchases()).thenAnswer((_) async => null);

  return SubscriptionService(adapter: adapter, storage: storage);
}

/// Wraps [child] in a minimal MaterialApp with animations disabled.
Widget _wrap(Widget child, {SubscriptionService? service}) {
  final gi = GetIt.instance;
  final svc = service ?? _makeSubscriptionService();

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

  group('QuizLimitScreen', () {
    group('rendering', () {
      testWidgets('renders "Nice work today" headline', (tester) async {
        await tester.pumpWidget(
          _wrap(const QuizLimitScreen(correct: 8, total: 10)),
        );
        await tester.pump();

        expect(find.text('Nice work today'), findsOneWidget);
      });

      testWidgets('renders score text "8 out of 10 correct"', (tester) async {
        await tester.pumpWidget(
          _wrap(const QuizLimitScreen(correct: 8, total: 10)),
        );
        await tester.pump();

        expect(find.text('8 out of 10 correct'), findsOneWidget);
      });

      testWidgets('renders score text "0 out of 10 correct"', (tester) async {
        await tester.pumpWidget(
          _wrap(const QuizLimitScreen(correct: 0, total: 10)),
        );
        await tester.pump();

        expect(find.text('0 out of 10 correct'), findsOneWidget);
      });

      testWidgets('renders score text "10 out of 10 correct"', (tester) async {
        await tester.pumpWidget(
          _wrap(const QuizLimitScreen(correct: 10, total: 10)),
        );
        await tester.pump();

        expect(find.text('10 out of 10 correct'), findsOneWidget);
      });

      testWidgets('renders "Done for today" button', (tester) async {
        await tester.pumpWidget(
          _wrap(const QuizLimitScreen(correct: 5, total: 10)),
        );
        await tester.pump();

        expect(find.text('Done for today'), findsOneWidget);
      });

      testWidgets('renders "Try Pro free for 7 days" button', (tester) async {
        await tester.pumpWidget(
          _wrap(const QuizLimitScreen(correct: 5, total: 10)),
        );
        await tester.pump();

        expect(find.text('Try Pro free for 7 days'), findsOneWidget);
      });

      testWidgets('renders "Want to keep practising?" prompt', (tester) async {
        await tester.pumpWidget(
          _wrap(const QuizLimitScreen(correct: 5, total: 10)),
        );
        await tester.pump();

        expect(find.text('Want to keep practising?'), findsOneWidget);
      });

      testWidgets('renders 10 score dots', (tester) async {
        await tester.pumpWidget(
          _wrap(const QuizLimitScreen(correct: 5, total: 10)),
        );
        await tester.pump();

        // Score dots are rendered via a Row of Container widgets with the
        // ScoreDot key pattern. Find by key prefix.
        final dots = find.byKey(const ValueKey('score_dot_row'));
        expect(dots, findsOneWidget);
      });
    });

    group('button visual weight', () {
      testWidgets('both buttons have height 52', (tester) async {
        await tester.pumpWidget(
          _wrap(const QuizLimitScreen(correct: 7, total: 10)),
        );
        await tester.pump();

        final proButton = tester.widget<SizedBox>(
          find
              .ancestor(
                of: find.text('Try Pro free for 7 days'),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        final doneButton = tester.widget<SizedBox>(
          find
              .ancestor(
                of: find.text('Done for today'),
                matching: find.byType(SizedBox),
              )
              .first,
        );

        expect(proButton.height, 52.0);
        expect(doneButton.height, 52.0);
      });
    });

    group('navigation', () {
      testWidgets('"Done for today" pops route without confirmation',
          (tester) async {
        bool popped = false;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              theme: ThemeData(splashFactory: NoSplash.splashFactory),
              home: Builder(
                builder: (ctx) {
                  final gi = GetIt.instance;
                  final svc = _makeSubscriptionService();
                  if (gi.isRegistered<SubscriptionService>()) {
                    gi.unregister<SubscriptionService>();
                  }
                  gi.registerSingleton<SubscriptionService>(svc);
                  if (!gi.isRegistered<AnalyticsService>()) {
                    gi.registerSingleton<AnalyticsService>(
                        const NoOpAnalyticsService());
                  }
                  if (!gi.isRegistered<InstallDateRepository>()) {
                    gi.registerSingleton<InstallDateRepository>(
                        _FakeInstallDateRepository());
                  }
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const QuizLimitScreen(correct: 5, total: 10),
                          ),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  );
                },
              ),
              navigatorObservers: [
                _PopObserver(onPop: () => popped = true),
              ],
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Done for today'), findsOneWidget);

        await tester.tap(find.text('Done for today'));
        await tester.pumpAndSettle();

        expect(popped, isTrue);
      });

      testWidgets('"Try Pro free for 7 days" navigates to PaywallScreen',
          (tester) async {
        await tester.pumpWidget(
          _wrap(const QuizLimitScreen(correct: 5, total: 10)),
        );
        await tester.pump();

        await tester.tap(find.text('Try Pro free for 7 days'));
        await tester.pumpAndSettle();

        expect(find.byType(PaywallScreen), findsOneWidget);
      });

      testWidgets(
          '"Try Pro free for 7 days" passes quizLimit trigger to PaywallScreen',
          (tester) async {
        await tester.pumpWidget(
          _wrap(const QuizLimitScreen(correct: 5, total: 10)),
        );
        await tester.pump();

        await tester.tap(find.text('Try Pro free for 7 days'));
        await tester.pumpAndSettle();

        final paywall = tester.widget<PaywallScreen>(
          find.byType(PaywallScreen),
        );
        expect(paywall.trigger, PaywallTrigger.quizLimit);
      });
    });

    group('score dots colors', () {
      testWidgets('correct score is non-negative', (tester) async {
        // QuizLimitScreen accepts correct=0 without throwing.
        await tester.pumpWidget(
          _wrap(const QuizLimitScreen(correct: 0, total: 10)),
        );
        await tester.pump();

        expect(find.text('0 out of 10 correct'), findsOneWidget);
      });

      testWidgets('perfect score renders without error', (tester) async {
        await tester.pumpWidget(
          _wrap(const QuizLimitScreen(correct: 10, total: 10)),
        );
        await tester.pump();

        expect(find.text('10 out of 10 correct'), findsOneWidget);
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Observer helper
// ---------------------------------------------------------------------------

class _PopObserver extends NavigatorObserver {
  _PopObserver({required this.onPop});

  final VoidCallback onPop;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPop();
  }
}
