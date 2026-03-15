import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/subscription/milestone_type.dart';
import 'package:dander/features/subscription/presentation/widgets/milestone_pro_suggestion_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('MilestoneProSuggestionCard', () {
    group('static content', () {
      testWidgets('renders "There\'s more to unlock" header text', (
        tester,
      ) async {
        await tester.pumpWidget(_wrap(
          MilestoneProSuggestionCard(
            milestoneType: MilestoneType.zoneLevelUp,
            onLearnAboutPro: () {},
            onContinue: () {},
          ),
        ));
        expect(find.text("There's more to unlock"), findsOneWidget);
      });

      testWidgets('renders "Continue" button', (tester) async {
        await tester.pumpWidget(_wrap(
          MilestoneProSuggestionCard(
            milestoneType: MilestoneType.zoneLevelUp,
            onLearnAboutPro: () {},
            onContinue: () {},
          ),
        ));
        expect(find.text('Continue'), findsOneWidget);
      });

      testWidgets('renders "Learn about Pro" button', (tester) async {
        await tester.pumpWidget(_wrap(
          MilestoneProSuggestionCard(
            milestoneType: MilestoneType.zoneLevelUp,
            onLearnAboutPro: () {},
            onContinue: () {},
          ),
        ));
        expect(find.textContaining('Learn about Pro'), findsOneWidget);
      });
    });

    group('contextual message — zoneLevelUp', () {
      testWidgets('renders correct message for zoneLevelUp', (tester) async {
        await tester.pumpWidget(_wrap(
          MilestoneProSuggestionCard(
            milestoneType: MilestoneType.zoneLevelUp,
            onLearnAboutPro: () {},
            onContinue: () {},
          ),
        ));
        expect(
          find.text('Unlock weekly challenges to earn exclusive badges'),
          findsOneWidget,
        );
      });
    });

    group('contextual message — fogMilestone', () {
      testWidgets('renders correct message for fogMilestone', (tester) async {
        await tester.pumpWidget(_wrap(
          MilestoneProSuggestionCard(
            milestoneType: MilestoneType.fogMilestone,
            onLearnAboutPro: () {},
            onContinue: () {},
          ),
        ));
        expect(
          find.text('See your exploration heat map with Pro'),
          findsOneWidget,
        );
      });
    });

    group('contextual message — streakMilestone', () {
      testWidgets('renders correct message for streakMilestone', (
        tester,
      ) async {
        await tester.pumpWidget(_wrap(
          MilestoneProSuggestionCard(
            milestoneType: MilestoneType.streakMilestone,
            onLearnAboutPro: () {},
            onContinue: () {},
          ),
        ));
        expect(
          find.text('Track your monthly walking trends with Pro'),
          findsOneWidget,
        );
      });
    });

    group('callbacks', () {
      testWidgets('"Continue" button calls onContinue', (tester) async {
        var called = false;
        await tester.pumpWidget(_wrap(
          MilestoneProSuggestionCard(
            milestoneType: MilestoneType.zoneLevelUp,
            onLearnAboutPro: () {},
            onContinue: () => called = true,
          ),
        ));
        await tester.tap(find.text('Continue'));
        await tester.pump();
        expect(called, isTrue);
      });

      testWidgets('"Learn about Pro" button calls onLearnAboutPro', (
        tester,
      ) async {
        var called = false;
        await tester.pumpWidget(_wrap(
          MilestoneProSuggestionCard(
            milestoneType: MilestoneType.zoneLevelUp,
            onLearnAboutPro: () => called = true,
            onContinue: () {},
          ),
        ));
        await tester.tap(find.textContaining('Learn about Pro'));
        await tester.pump();
        expect(called, isTrue);
      });
    });
  });
}
