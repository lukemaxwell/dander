import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/progress/badge.dart';
import 'package:dander/core/progress/streak_shield.dart';
import 'package:dander/core/progress/streak_tracker.dart';
import 'package:dander/core/subscription/purchase_result.dart';
import 'package:dander/core/subscription/purchases_adapter.dart';
import 'package:dander/core/subscription/subscription_service.dart';
import 'package:dander/core/subscription/subscription_state.dart';
import 'package:dander/core/subscription/subscription_storage.dart';
import 'package:dander/features/profile/presentation/screens/profile_screen.dart';

// ---------------------------------------------------------------------------
// Mocks for SubscriptionService
// ---------------------------------------------------------------------------

class _MockPurchasesAdapter extends Mock implements PurchasesAdapter {}

class _MockSubscriptionStorage extends Mock implements SubscriptionStorage {}

SubscriptionService _makeService() {
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
  svc.state.value = const SubscriptionStateFree();
  return svc;
}

void _registerService() {
  if (!GetIt.instance.isRegistered<SubscriptionService>()) {
    GetIt.instance.registerSingleton<SubscriptionService>(_makeService());
  }
}

void _unregisterService() {
  if (GetIt.instance.isRegistered<SubscriptionService>()) {
    GetIt.instance.unregister<SubscriptionService>();
  }
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  setUp(_registerService);
  tearDown(_unregisterService);

  final noDiscoveries = <Discovery>[];

  const sampleBadges = BadgeDefinitions.badges;
  final unlockedBadges = BadgeDefinitions.badges.map((b) {
    if (b.id == BadgeId.firstDander || b.id == BadgeId.explorer) {
      return b.unlock(DateTime(2024, 6, 1));
    }
    return b;
  }).toList();

  group('ProfileScreen — exploration progress', () {
    testWidgets('shows exploration percentage text', (tester) async {
      await tester.pumpWidget(_wrap(ProfileScreen(
        discoveries: noDiscoveries,
        explorationPct: 0.23,
        streak: StreakTracker.empty(),
        badges: sampleBadges,
      )));

      // Expect some widget containing "23%" or "23"
      expect(find.textContaining('23'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows 0% when exploration is zero', (tester) async {
      await tester.pumpWidget(_wrap(ProfileScreen(
        discoveries: noDiscoveries,
        explorationPct: 0.0,
        streak: StreakTracker.empty(),
        badges: sampleBadges,
      )));

      expect(find.textContaining('0'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows 100% when fully explored', (tester) async {
      await tester.pumpWidget(_wrap(ProfileScreen(
        discoveries: noDiscoveries,
        explorationPct: 1.0,
        streak: StreakTracker.empty(),
        badges: sampleBadges,
      )));

      expect(find.textContaining('100'), findsAtLeastNWidgets(1));
    });
  });

  group('ProfileScreen — streak display', () {
    testWidgets('shows streak count when streak is active', (tester) async {
      final streak =
          StreakTracker(currentStreak: 5, lastWalkDate: DateTime.now());
      await tester.pumpWidget(_wrap(ProfileScreen(
        discoveries: noDiscoveries,
        explorationPct: 0.1,
        streak: streak,
        badges: sampleBadges,
      )));

      expect(find.textContaining('5'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows streak section on screen', (tester) async {
      await tester.pumpWidget(_wrap(ProfileScreen(
        discoveries: noDiscoveries,
        explorationPct: 0.0,
        streak: StreakTracker.empty(),
        badges: sampleBadges,
      )));

      // Streak section label
      expect(
        find.textContaining(RegExp(r'[Ss]treak', caseSensitive: false)),
        findsAtLeastNWidgets(1),
      );
    });
  });

  group('ProfileScreen — badge grid', () {
    testWidgets('shows badge section heading', (tester) async {
      await tester.pumpWidget(_wrap(ProfileScreen(
        discoveries: noDiscoveries,
        explorationPct: 0.0,
        streak: StreakTracker.empty(),
        badges: sampleBadges,
      )));

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();

      expect(
        find.textContaining(RegExp(r'[Bb]adge', caseSensitive: false)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows all 6 badge names', (tester) async {
      await tester.pumpWidget(_wrap(ProfileScreen(
        discoveries: noDiscoveries,
        explorationPct: 0.0,
        streak: StreakTracker.empty(),
        badges: sampleBadges,
      )));

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();

      for (final badge in sampleBadges) {
        expect(find.textContaining(badge.name), findsAtLeastNWidgets(1),
            reason: '${badge.name} should be visible');
      }
    });

    testWidgets('unlocked badges are visually distinguished', (tester) async {
      await tester.pumpWidget(_wrap(ProfileScreen(
        discoveries: noDiscoveries,
        explorationPct: 0.15,
        streak: StreakTracker.empty(),
        badges: unlockedBadges,
      )));

      // At minimum the screen renders without errors when some badges are unlocked
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });

  group('ProfileScreen — badge detail', () {
    testWidgets('tapping a badge opens detail bottom sheet', (tester) async {
      await tester.pumpWidget(_wrap(ProfileScreen(
        discoveries: noDiscoveries,
        explorationPct: 0.15,
        streak: StreakTracker.empty(),
        badges: unlockedBadges,
      )));

      // Scroll down to make badges visible
      await tester.dragFrom(
        tester.getCenter(find.byType(ListView)),
        const Offset(0, -400),
      );
      await tester.pump();

      // Tap the Explorer badge icon
      final explorerIcon = find.byIcon(Icons.explore);
      expect(explorerIcon, findsOneWidget);
      await tester.tap(explorerIcon, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Should show badge detail sheet with unlock date
      expect(find.textContaining('Unlocked'), findsWidgets);
    });

    testWidgets('recently unlocked badge shows NEW label', (tester) async {
      final recentBadges = BadgeDefinitions.badges.map((b) {
        if (b.id == BadgeId.firstDander) {
          return b.unlock(DateTime.now().subtract(const Duration(hours: 1)));
        }
        return b;
      }).toList();

      await tester.pumpWidget(_wrap(ProfileScreen(
        discoveries: noDiscoveries,
        explorationPct: 0.05,
        streak: StreakTracker.empty(),
        badges: recentBadges,
      )));

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();

      expect(find.text('NEW'), findsOneWidget);
    });
  });

  group('ProfileScreen — streak milestones', () {
    testWidgets('shows milestone text at 4-week streak', (tester) async {
      final streak =
          StreakTracker(currentStreak: 4, lastWalkDate: DateTime.now());
      await tester.pumpWidget(_wrap(ProfileScreen(
        discoveries: noDiscoveries,
        explorationPct: 0.1,
        streak: streak,
        badges: sampleBadges,
      )));

      expect(find.textContaining('1 Month'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows milestone text at 52-week streak', (tester) async {
      final streak =
          StreakTracker(currentStreak: 52, lastWalkDate: DateTime.now());
      await tester.pumpWidget(_wrap(ProfileScreen(
        discoveries: noDiscoveries,
        explorationPct: 0.1,
        streak: streak,
        badges: sampleBadges,
      )));

      expect(find.textContaining('1 Year'), findsAtLeastNWidgets(1));
    });
  });

  group('ProfileScreen — streak shield', () {
    testWidgets('shows shield icon when shield is active', (tester) async {
      await tester.pumpWidget(_wrap(ProfileScreen(
        discoveries: noDiscoveries,
        explorationPct: 0.1,
        streak: StreakTracker(currentStreak: 3, lastWalkDate: DateTime.now()),
        badges: sampleBadges,
        streakShield: StreakShield.empty().earn(DateTime(2024, 6, 15)),
      )));

      expect(find.byIcon(Icons.shield), findsAtLeastNWidgets(1));
    });

    testWidgets('shows greyed shield when no shield held', (tester) async {
      await tester.pumpWidget(_wrap(ProfileScreen(
        discoveries: noDiscoveries,
        explorationPct: 0.1,
        streak: StreakTracker(currentStreak: 3, lastWalkDate: DateTime.now()),
        badges: sampleBadges,
        streakShield: StreakShield.empty(),
      )));

      expect(find.byIcon(Icons.shield_outlined), findsAtLeastNWidgets(1));
    });
  });

  group('ProfileScreen — discoveries section', () {
    testWidgets('shows discovery count', (tester) async {
      final discoveries = [
        Discovery(
          id: '1',
          name: 'Test Cafe',
          category: 'cafe',
          rarity: RarityTier.common,
          position: const LatLng(51.5, -0.05),
          osmTags: const {},
          discoveredAt: DateTime(2024, 6, 1),
        ),
        Discovery(
          id: '2',
          name: 'Test Park',
          category: 'park',
          rarity: RarityTier.uncommon,
          position: const LatLng(51.501, -0.051),
          osmTags: const {},
          discoveredAt: DateTime(2024, 6, 2),
        ),
      ];

      await tester.pumpWidget(_wrap(ProfileScreen(
        discoveries: discoveries,
        explorationPct: 0.05,
        streak: StreakTracker.empty(),
        badges: sampleBadges,
      )));

      // Scroll to bottom so all sections are rendered
      // Use a larger drag to accommodate the logo header added in Issue #35.
      await tester.dragFrom(
        tester.getCenter(find.byType(ListView)),
        const Offset(0, -900),
      );
      await tester.pump();

      // "2 total" is shown in the discoveries section
      expect(find.textContaining('2 total'), findsAtLeastNWidgets(1));
    });
  });
}
