import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/map/presentation/widgets/first_walk_contract_overlay.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('FirstWalkContractOverlay', () {
    testWidgets('renders prompt text', (tester) async {
      await tester.pumpWidget(wrap(
        FirstWalkContractOverlay(
          distanceWalked: 0,
          onDismissed: () {},
          onGoalReached: () {},
        ),
      ));

      expect(
        find.textContaining('Walk 200m'),
        findsOneWidget,
      );
    });

    testWidgets('shows distance counter at 0m', (tester) async {
      await tester.pumpWidget(wrap(
        FirstWalkContractOverlay(
          distanceWalked: 0,
          onDismissed: () {},
          onGoalReached: () {},
        ),
      ));

      expect(find.text('0m / 200m'), findsOneWidget);
    });

    testWidgets('updates distance counter as user walks', (tester) async {
      await tester.pumpWidget(wrap(
        FirstWalkContractOverlay(
          distanceWalked: 85,
          onDismissed: () {},
          onGoalReached: () {},
        ),
      ));

      expect(find.text('85m / 200m'), findsOneWidget);
    });

    testWidgets('calls onGoalReached when distance >= 200m', (tester) async {
      var goalReached = false;
      await tester.pumpWidget(wrap(
        FirstWalkContractOverlay(
          distanceWalked: 200,
          onDismissed: () {},
          onGoalReached: () => goalReached = true,
        ),
      ));

      await tester.pump();

      expect(goalReached, isTrue);
    });

    testWidgets('calls onGoalReached when distance exceeds 200m',
        (tester) async {
      var goalReached = false;
      await tester.pumpWidget(wrap(
        FirstWalkContractOverlay(
          distanceWalked: 250,
          onDismissed: () {},
          onGoalReached: () => goalReached = true,
        ),
      ));

      await tester.pump();

      expect(goalReached, isTrue);
    });

    testWidgets('does not call onGoalReached below 200m', (tester) async {
      var goalReached = false;
      await tester.pumpWidget(wrap(
        FirstWalkContractOverlay(
          distanceWalked: 199,
          onDismissed: () {},
          onGoalReached: () => goalReached = true,
        ),
      ));

      await tester.pump();

      expect(goalReached, isFalse);
    });

    testWidgets('dismiss button calls onDismissed', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(wrap(
        FirstWalkContractOverlay(
          distanceWalked: 50,
          onDismissed: () => dismissed = true,
          onGoalReached: () {},
        ),
      ));

      // Tap the close/dismiss button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets('shows progress bar', (tester) async {
      await tester.pumpWidget(wrap(
        FirstWalkContractOverlay(
          distanceWalked: 100,
          onDismissed: () {},
          onGoalReached: () {},
        ),
      ));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('progress bar reflects walked fraction', (tester) async {
      await tester.pumpWidget(wrap(
        FirstWalkContractOverlay(
          distanceWalked: 100,
          onDismissed: () {},
          onGoalReached: () {},
        ),
      ));

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, closeTo(0.5, 0.01));
    });

    testWidgets('progress bar clamps at 1.0 for values over 200m',
        (tester) async {
      await tester.pumpWidget(wrap(
        FirstWalkContractOverlay(
          distanceWalked: 300,
          onDismissed: () {},
          onGoalReached: () {},
        ),
      ));

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressBar.value, 1.0);
    });

    testWidgets('shows subtitle text about discovering first zone',
        (tester) async {
      await tester.pumpWidget(wrap(
        FirstWalkContractOverlay(
          distanceWalked: 0,
          onDismissed: () {},
          onGoalReached: () {},
        ),
      ));

      expect(
        find.textContaining('first zone'),
        findsOneWidget,
      );
    });
  });
}
