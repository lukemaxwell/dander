import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:dander/core/progress/badge.dart';
import 'package:dander/features/profile/presentation/widgets/badge_detail_sheet.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  group('BadgeDetailSheet', () {
    group('unlocked badge', () {
      testWidgets('displays badge name', (tester) async {
        final badge = BadgeDefinitions.badges
            .firstWhere((b) => b.id == BadgeId.explorer)
            .unlock(DateTime(2024, 6, 10));
        await tester.pumpWidget(_wrap(BadgeDetailSheet(
          badge: badge,
          currentExplorationPct: 0.15,
        )));
        expect(find.text('Explorer'), findsOneWidget);
      });

      testWidgets('displays badge description', (tester) async {
        final badge = BadgeDefinitions.badges
            .firstWhere((b) => b.id == BadgeId.explorer)
            .unlock(DateTime(2024, 6, 10));
        await tester.pumpWidget(_wrap(BadgeDetailSheet(
          badge: badge,
          currentExplorationPct: 0.15,
        )));
        expect(find.textContaining('10%'), findsWidgets);
      });

      testWidgets('displays unlock date', (tester) async {
        final badge = BadgeDefinitions.badges
            .firstWhere((b) => b.id == BadgeId.explorer)
            .unlock(DateTime(2024, 6, 10));
        await tester.pumpWidget(_wrap(BadgeDetailSheet(
          badge: badge,
          currentExplorationPct: 0.15,
        )));
        expect(find.textContaining('10 Jun 2024'), findsOneWidget);
      });

      testWidgets('displays badge icon', (tester) async {
        final badge = BadgeDefinitions.badges
            .firstWhere((b) => b.id == BadgeId.explorer)
            .unlock(DateTime(2024, 6, 10));
        await tester.pumpWidget(_wrap(BadgeDetailSheet(
          badge: badge,
          currentExplorationPct: 0.15,
        )));
        expect(find.byIcon(Icons.explore), findsOneWidget);
      });
    });

    group('locked badge', () {
      testWidgets('shows progress toward unlock', (tester) async {
        final badge = BadgeDefinitions.badges
            .firstWhere((b) => b.id == BadgeId.pathfinder);
        // 15% explored, need 25%
        await tester.pumpWidget(_wrap(BadgeDetailSheet(
          badge: badge,
          currentExplorationPct: 0.15,
        )));
        expect(find.textContaining('15'), findsWidgets);
        expect(find.textContaining('25'), findsWidgets);
      });

      testWidgets('shows locked status', (tester) async {
        final badge = BadgeDefinitions.badges
            .firstWhere((b) => b.id == BadgeId.cartographer);
        await tester.pumpWidget(_wrap(BadgeDetailSheet(
          badge: badge,
          currentExplorationPct: 0.10,
        )));
        expect(find.textContaining('Locked'), findsWidgets);
      });

      testWidgets('shows progress bar', (tester) async {
        final badge = BadgeDefinitions.badges
            .firstWhere((b) => b.id == BadgeId.pathfinder);
        await tester.pumpWidget(_wrap(BadgeDetailSheet(
          badge: badge,
          currentExplorationPct: 0.15,
        )));
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });
    });

    group('edge cases', () {
      testWidgets('renders without error for firstDander badge',
          (tester) async {
        final badge = BadgeDefinitions.badges
            .firstWhere((b) => b.id == BadgeId.firstDander);
        await tester.pumpWidget(_wrap(BadgeDetailSheet(
          badge: badge,
          currentExplorationPct: 0.0,
        )));
        expect(tester.takeException(), isNull);
      });
    });
  });
}
