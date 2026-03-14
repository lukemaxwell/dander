import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/progress/badge.dart';
import 'package:dander/features/sharing/presentation/widgets/badge_share_card.dart';

void main() {
  final testBadge = Badge(
    id: BadgeId.explorer,
    name: 'Explorer',
    description: 'Explore 10% of your neighbourhood',
    requiredExplorationPct: 0.10,
    icon: Icons.explore,
    unlockedAt: DateTime(2026, 3, 14, 15, 30),
  );

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  group('BadgeShareCard', () {
    testWidgets('renders with correct dimensions', (tester) async {
      await tester.pumpWidget(wrap(
        BadgeShareCard(badge: testBadge, explorationPercent: 10.0),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, BadgeShareCard.cardWidth);
      expect(sizedBox.height, BadgeShareCard.cardHeight);
    });

    testWidgets('shows badge name', (tester) async {
      await tester.pumpWidget(wrap(
        BadgeShareCard(badge: testBadge, explorationPercent: 10.0),
      ));

      expect(find.text('Explorer'), findsOneWidget);
    });

    testWidgets('shows badge description', (tester) async {
      await tester.pumpWidget(wrap(
        BadgeShareCard(badge: testBadge, explorationPercent: 10.0),
      ));

      expect(
        find.textContaining('10%'),
        findsWidgets,
      );
    });

    testWidgets('shows badge icon', (tester) async {
      await tester.pumpWidget(wrap(
        BadgeShareCard(badge: testBadge, explorationPercent: 10.0),
      ));

      expect(find.byIcon(Icons.explore), findsOneWidget);
    });

    testWidgets('shows unlock date', (tester) async {
      await tester.pumpWidget(wrap(
        BadgeShareCard(badge: testBadge, explorationPercent: 10.0),
      ));

      expect(find.textContaining('14 Mar 2026'), findsOneWidget);
    });

    testWidgets('shows exploration percentage', (tester) async {
      await tester.pumpWidget(wrap(
        BadgeShareCard(badge: testBadge, explorationPercent: 10.0),
      ));

      expect(find.text('10.0%'), findsOneWidget);
    });

    testWidgets('shows dander.app watermark', (tester) async {
      await tester.pumpWidget(wrap(
        BadgeShareCard(badge: testBadge, explorationPercent: 10.0),
      ));

      expect(find.text('dander.app'), findsOneWidget);
    });

    testWidgets('shows CTA question', (tester) async {
      await tester.pumpWidget(wrap(
        BadgeShareCard(badge: testBadge, explorationPercent: 10.0),
      ));

      expect(find.byKey(const Key('tagline')), findsOneWidget);
    });
  });
}
