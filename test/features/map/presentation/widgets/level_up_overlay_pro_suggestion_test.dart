import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/subscription/milestone_type.dart';
import 'package:dander/core/zone/level_up_detector.dart';
import 'package:dander/features/map/presentation/widgets/level_up_overlay.dart';
import 'package:dander/features/subscription/presentation/widgets/milestone_pro_suggestion_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

const _event = LevelUpEvent(
  previousLevel: 1,
  newLevel: 2,
  newRadiusMeters: 1500.0,
);

void main() {
  group('LevelUpOverlay — Pro suggestion integration', () {
    group('showProSuggestion: false', () {
      testWidgets(
        'does not render MilestoneProSuggestionCard when showProSuggestion is false',
        (tester) async {
          await tester.pumpWidget(_wrap(
            LevelUpOverlay(
              event: _event,
              showProSuggestion: false,
              milestoneType: MilestoneType.zoneLevelUp,
              onLearnAboutPro: () {},
              onDismissed: () {},
              child: const SizedBox(),
            ),
          ));
          // Advance well past the 600ms delay
          await tester.pump(const Duration(milliseconds: 900));
          expect(find.byType(MilestoneProSuggestionCard), findsNothing);
        },
      );

      testWidgets(
        'does not render MilestoneProSuggestionCard when event is null, regardless of showProSuggestion',
        (tester) async {
          await tester.pumpWidget(_wrap(
            LevelUpOverlay(
              event: null,
              showProSuggestion: true,
              milestoneType: MilestoneType.zoneLevelUp,
              onLearnAboutPro: () {},
              onDismissed: () {},
              child: const SizedBox(),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 900));
          expect(find.byType(MilestoneProSuggestionCard), findsNothing);
        },
      );
    });

    group('showProSuggestion: true — delayed appearance', () {
      testWidgets(
        'MilestoneProSuggestionCard is absent before 600ms delay',
        (tester) async {
          await tester.pumpWidget(_wrap(
            LevelUpOverlay(
              event: _event,
              showProSuggestion: true,
              milestoneType: MilestoneType.zoneLevelUp,
              onLearnAboutPro: () {},
              onDismissed: () {},
              child: const SizedBox(),
            ),
          ));
          // Before timer fires
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(MilestoneProSuggestionCard), findsNothing);
        },
      );

      testWidgets(
        'MilestoneProSuggestionCard appears after 700ms (past the 600ms delay)',
        (tester) async {
          await tester.pumpWidget(_wrap(
            LevelUpOverlay(
              event: _event,
              showProSuggestion: true,
              milestoneType: MilestoneType.zoneLevelUp,
              onLearnAboutPro: () {},
              onDismissed: () {},
              child: const SizedBox(),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 700));
          expect(find.byType(MilestoneProSuggestionCard), findsOneWidget);
        },
      );
    });

    group('Pro card callbacks', () {
      testWidgets(
        '"Continue" in Pro card triggers onDismissed',
        (tester) async {
          var dismissed = false;
          await tester.pumpWidget(_wrap(
            LevelUpOverlay(
              event: _event,
              showProSuggestion: true,
              milestoneType: MilestoneType.zoneLevelUp,
              onLearnAboutPro: () {},
              onDismissed: () => dismissed = true,
              child: const SizedBox(),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 700));

          // Verify the Pro suggestion card is in the widget tree.
          expect(find.byType(MilestoneProSuggestionCard), findsOneWidget);

          // Retrieve the card's onContinue callback directly and invoke it —
          // this avoids tap-position issues caused by the card being scrolled
          // outside the test viewport when combined with the tall level-up banner.
          final card = tester.widget<MilestoneProSuggestionCard>(
            find.byType(MilestoneProSuggestionCard),
          );
          card.onContinue();
          await tester.pump();
          expect(dismissed, isTrue);
        },
      );

      testWidgets(
        '"Learn about Pro" in Pro card triggers onLearnAboutPro callback',
        (tester) async {
          var learnAboutProCalled = false;
          await tester.pumpWidget(_wrap(
            LevelUpOverlay(
              event: _event,
              showProSuggestion: true,
              milestoneType: MilestoneType.zoneLevelUp,
              onLearnAboutPro: () => learnAboutProCalled = true,
              onDismissed: () {},
              child: const SizedBox(),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 700));

          // Verify the Pro suggestion card is in the widget tree.
          expect(find.byType(MilestoneProSuggestionCard), findsOneWidget);

          // Retrieve the card's onLearnAboutPro callback directly and invoke it.
          final card = tester.widget<MilestoneProSuggestionCard>(
            find.byType(MilestoneProSuggestionCard),
          );
          card.onLearnAboutPro();
          await tester.pump();
          expect(learnAboutProCalled, isTrue);
        },
      );
    });

    group('disposal / lifecycle', () {
      testWidgets(
        'disposes timer without error when overlay removed before 600ms',
        (tester) async {
          await tester.pumpWidget(_wrap(
            LevelUpOverlay(
              event: _event,
              showProSuggestion: true,
              milestoneType: MilestoneType.zoneLevelUp,
              onLearnAboutPro: () {},
              onDismissed: () {},
              child: const SizedBox(),
            ),
          ));
          // Remove before timer fires
          await tester.pump(const Duration(milliseconds: 200));
          await tester.pumpWidget(_wrap(const SizedBox()));
          // Advance time past where the timer would have fired
          await tester.pump(const Duration(milliseconds: 600));
          expect(find.byType(LevelUpOverlay), findsNothing);
        },
      );
    });
  });
}
