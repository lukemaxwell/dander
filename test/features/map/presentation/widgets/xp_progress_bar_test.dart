import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/map/presentation/widgets/xp_progress_bar.dart';

void main() {
  Widget buildSubject({
    required int currentXp,
    int? nextLevelXp,
    int level = 1,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: XpProgressBar(
          currentXp: currentXp,
          nextLevelXp: nextLevelXp,
          level: level,
        ),
      ),
    );
  }

  group('XpProgressBar', () {
    testWidgets('shows current level label', (tester) async {
      await tester.pumpWidget(buildSubject(
        currentXp: 50,
        nextLevelXp: 100,
        level: 1,
      ));
      expect(find.text('L1'), findsOneWidget);
    });

    testWidgets('shows XP remaining to next level', (tester) async {
      await tester.pumpWidget(buildSubject(
        currentXp: 37,
        nextLevelXp: 100,
        level: 1,
      ));
      expect(find.text('63 XP to L2'), findsOneWidget);
    });

    testWidgets('shows MAX when at max level', (tester) async {
      await tester.pumpWidget(buildSubject(
        currentXp: 2000,
        nextLevelXp: null,
        level: 5,
      ));
      expect(find.text('L5'), findsOneWidget);
      expect(find.text('MAX'), findsOneWidget);
    });

    testWidgets('shows progress bar', (tester) async {
      await tester.pumpWidget(buildSubject(
        currentXp: 50,
        nextLevelXp: 100,
        level: 1,
      ));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('progress bar fraction is correct for mid-level', (
      tester,
    ) async {
      // L2 starts at 100, L3 at 300. currentXp=200 means 50% through L2.
      await tester.pumpWidget(buildSubject(
        currentXp: 200,
        nextLevelXp: 300,
        level: 2,
      ));
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      // 200 XP, L2 starts at 100, L3 at 300. Progress = (200-100)/(300-100) = 0.5
      expect(indicator.value, closeTo(0.5, 0.01));
    });

    testWidgets('progress bar is full at max level', (tester) async {
      await tester.pumpWidget(buildSubject(
        currentXp: 2000,
        nextLevelXp: null,
        level: 5,
      ));
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 1.0);
    });
  });
}
