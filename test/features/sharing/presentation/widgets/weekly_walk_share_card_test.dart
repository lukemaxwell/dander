import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/sharing/presentation/widgets/weekly_walk_share_card.dart';
import 'package:dander/features/walk/domain/models/weekly_summary.dart';

void main() {
  final testSummary = WeeklySummary(
    weekStart: DateTime(2026, 3, 9),
    totalWalks: 5,
    totalDistanceMetres: 8200,
    totalDuration: const Duration(hours: 2, minutes: 15),
    totalDiscoveries: 7,
    fogClearedPercent: 3.2,
    activeDays: 4,
    currentStreak: 3,
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

  group('WeeklyWalkShareCard', () {
    testWidgets('renders with correct dimensions', (tester) async {
      await tester.pumpWidget(wrap(
        WeeklyWalkShareCard(summary: testSummary),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, WeeklyWalkShareCard.cardWidth);
      expect(sizedBox.height, WeeklyWalkShareCard.cardHeight);
    });

    testWidgets('shows "Weekly Walk" title', (tester) async {
      await tester.pumpWidget(wrap(
        WeeklyWalkShareCard(summary: testSummary),
      ));

      expect(find.textContaining('Weekly'), findsWidgets);
    });

    testWidgets('shows distance walked', (tester) async {
      await tester.pumpWidget(wrap(
        WeeklyWalkShareCard(summary: testSummary),
      ));

      // 8200m = 8.2km
      expect(find.text('8.2 km'), findsOneWidget);
    });

    testWidgets('shows walk count', (tester) async {
      await tester.pumpWidget(wrap(
        WeeklyWalkShareCard(summary: testSummary),
      ));

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows active days', (tester) async {
      await tester.pumpWidget(wrap(
        WeeklyWalkShareCard(summary: testSummary),
      ));

      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('shows fog cleared percentage', (tester) async {
      await tester.pumpWidget(wrap(
        WeeklyWalkShareCard(summary: testSummary),
      ));

      expect(find.text('3.2%'), findsOneWidget);
    });

    testWidgets('shows dander.app watermark', (tester) async {
      await tester.pumpWidget(wrap(
        WeeklyWalkShareCard(summary: testSummary),
      ));

      expect(find.text('dander.app'), findsOneWidget);
    });

    testWidgets('shows week date range', (tester) async {
      await tester.pumpWidget(wrap(
        WeeklyWalkShareCard(summary: testSummary),
      ));

      // Should show "9 Mar – 15 Mar 2026" or similar
      expect(find.textContaining('Mar'), findsWidgets);
    });

    testWidgets('shows streak count', (tester) async {
      await tester.pumpWidget(wrap(
        WeeklyWalkShareCard(summary: testSummary),
      ));

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows CTA question for viewers', (tester) async {
      await tester.pumpWidget(wrap(
        WeeklyWalkShareCard(summary: testSummary),
      ));

      expect(
        find.byKey(const Key('tagline')),
        findsOneWidget,
      );
    });
  });
}
