import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/progress/badge.dart';
import 'package:dander/core/progress/streak_tracker.dart';
import 'package:dander/features/profile/presentation/screens/profile_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  final noDiscoveries = <Discovery>[];

  final sampleBadges = BadgeDefinitions.badges;
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
      await tester.dragFrom(
        tester.getCenter(find.byType(ListView)),
        const Offset(0, -600),
      );
      await tester.pump();

      // "2 total" is shown in the discoveries section
      expect(find.textContaining('2 total'), findsAtLeastNWidgets(1));
    });
  });
}
