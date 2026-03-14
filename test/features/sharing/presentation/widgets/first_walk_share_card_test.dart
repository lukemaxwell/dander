import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/sharing/presentation/widgets/first_walk_share_card.dart';
import 'package:dander/features/walk/domain/models/walk_summary.dart';

void main() {
  final testSummary = WalkSummary(
    id: 'test-walk-1',
    startedAt: DateTime(2026, 3, 14, 10, 0),
    endedAt: DateTime(2026, 3, 14, 10, 15),
    distanceMetres: 450,
    fogClearedPercent: 0.3,
    discoveriesFound: 2,
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

  group('FirstWalkShareCard', () {
    testWidgets('renders with correct dimensions', (tester) async {
      await tester.pumpWidget(wrap(
        FirstWalkShareCard(walkSummary: testSummary),
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, FirstWalkShareCard.cardWidth);
      expect(sizedBox.height, FirstWalkShareCard.cardHeight);
    });

    testWidgets('shows "First Exploration" title', (tester) async {
      await tester.pumpWidget(wrap(
        FirstWalkShareCard(walkSummary: testSummary),
      ));

      expect(find.text('First Exploration'), findsOneWidget);
    });

    testWidgets('shows distance walked', (tester) async {
      await tester.pumpWidget(wrap(
        FirstWalkShareCard(walkSummary: testSummary),
      ));

      expect(find.text('450 m'), findsOneWidget);
    });

    testWidgets('shows distance in km when >= 1km', (tester) async {
      final longWalk = WalkSummary(
        id: 'long-walk',
        startedAt: DateTime(2026, 3, 14, 10, 0),
        endedAt: DateTime(2026, 3, 14, 10, 30),
        distanceMetres: 1500,
        fogClearedPercent: 1.2,
        discoveriesFound: 5,
      );
      await tester.pumpWidget(wrap(
        FirstWalkShareCard(walkSummary: longWalk),
      ));

      expect(find.text('1.5 km'), findsOneWidget);
    });

    testWidgets('shows duration', (tester) async {
      await tester.pumpWidget(wrap(
        FirstWalkShareCard(walkSummary: testSummary),
      ));

      expect(find.byKey(const Key('walk_duration')), findsOneWidget);
    });

    testWidgets('shows discoveries count', (tester) async {
      await tester.pumpWidget(wrap(
        FirstWalkShareCard(walkSummary: testSummary),
      ));

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows dander.app watermark', (tester) async {
      await tester.pumpWidget(wrap(
        FirstWalkShareCard(walkSummary: testSummary),
      ));

      expect(find.text('dander.app'), findsOneWidget);
    });

    testWidgets('does not contain GPS coordinates or street names',
        (tester) async {
      await tester.pumpWidget(wrap(
        FirstWalkShareCard(walkSummary: testSummary),
      ));

      // Should not contain any lat/lng-like numbers
      expect(find.textContaining('51.'), findsNothing);
      expect(find.textContaining('-0.'), findsNothing);
    });

    testWidgets('shows motivational tagline', (tester) async {
      await tester.pumpWidget(wrap(
        FirstWalkShareCard(walkSummary: testSummary),
      ));

      expect(find.byKey(const Key('tagline')), findsOneWidget);
    });
  });
}
