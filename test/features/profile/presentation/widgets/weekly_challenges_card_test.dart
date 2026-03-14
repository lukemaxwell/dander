import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/challenges/challenge.dart';
import 'package:dander/features/profile/presentation/widgets/weekly_challenges_card.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  final sampleChallenges = [
    const Challenge(
      id: 'walk-1km',
      title: 'Walk 1 kilometre',
      type: ChallengeType.distance,
      targetValue: 1000,
      currentValue: 600,
      xpReward: 50,
    ),
    const Challenge(
      id: 'discover-3',
      title: 'Discover 3 POIs',
      type: ChallengeType.discoveries,
      targetValue: 3,
      currentValue: 3,
      xpReward: 30,
    ),
    const Challenge(
      id: 'quiz-5',
      title: 'Get 5 quiz answers right',
      type: ChallengeType.quizStreak,
      targetValue: 5,
      currentValue: 0,
      xpReward: 25,
    ),
    const Challenge(
      id: 'fog-1',
      title: 'Clear 1% fog',
      type: ChallengeType.fogCleared,
      targetValue: 1,
      currentValue: 1,
      xpReward: 20,
    ),
  ];

  group('WeeklyChallengesCard', () {
    testWidgets('shows Weekly Challenges title', (tester) async {
      await tester.pumpWidget(wrap(
        WeeklyChallengesCard(challenges: sampleChallenges),
      ));

      expect(find.text('Weekly Challenges'), findsOneWidget);
    });

    testWidgets('shows all challenge titles', (tester) async {
      await tester.pumpWidget(wrap(
        WeeklyChallengesCard(challenges: sampleChallenges),
      ));

      expect(find.text('Walk 1 kilometre'), findsOneWidget);
      expect(find.text('Discover 3 POIs'), findsOneWidget);
      expect(find.text('Get 5 quiz answers right'), findsOneWidget);
      expect(find.text('Clear 1% fog'), findsOneWidget);
    });

    testWidgets('shows completion count', (tester) async {
      await tester.pumpWidget(wrap(
        WeeklyChallengesCard(challenges: sampleChallenges),
      ));

      // 2 of 4 completed
      expect(find.text('2 / 4'), findsOneWidget);
    });

    testWidgets('shows XP reward for each challenge', (tester) async {
      await tester.pumpWidget(wrap(
        WeeklyChallengesCard(challenges: sampleChallenges),
      ));

      expect(find.text('+50 XP'), findsOneWidget);
      expect(find.text('+30 XP'), findsOneWidget);
      expect(find.text('+25 XP'), findsOneWidget);
      expect(find.text('+20 XP'), findsOneWidget);
    });

    testWidgets('completed challenges show check icon', (tester) async {
      await tester.pumpWidget(wrap(
        WeeklyChallengesCard(challenges: sampleChallenges),
      ));

      // 2 completed challenges should have check icons
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    });

    testWidgets('shows progress indicator for incomplete challenges',
        (tester) async {
      await tester.pumpWidget(wrap(
        WeeklyChallengesCard(challenges: sampleChallenges),
      ));

      // Incomplete challenges show LinearProgressIndicator
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    });

    testWidgets('renders with empty challenge list', (tester) async {
      await tester.pumpWidget(wrap(
        const WeeklyChallengesCard(challenges: []),
      ));

      expect(find.text('Weekly Challenges'), findsOneWidget);
      expect(find.text('0 / 0'), findsOneWidget);
    });
  });
}
