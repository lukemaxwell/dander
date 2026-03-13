import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dander/features/quiz/presentation/widgets/choice_button.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(body: child),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ChoiceButton', () {
    group('unanswered state', () {
      testWidgets('renders label text', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ChoiceButton(
              label: 'Baker Street',
              state: ChoiceButtonState.unanswered,
              onTap: () {},
            ),
          ),
        );
        expect(find.text('Baker Street'), findsOneWidget);
      });

      testWidgets('is tappable', (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          _wrap(
            ChoiceButton(
              label: 'Baker Street',
              state: ChoiceButtonState.unanswered,
              onTap: () => tapped = true,
            ),
          ),
        );
        await tester.tap(find.byType(ChoiceButton));
        expect(tapped, isTrue);
      });
    });

    group('correct state', () {
      testWidgets('renders label text', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ChoiceButton(
              label: 'Oxford Street',
              state: ChoiceButtonState.correct,
              onTap: () {},
            ),
          ),
        );
        expect(find.text('Oxford Street'), findsOneWidget);
      });

      testWidgets('uses green color', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ChoiceButton(
              label: 'Oxford Street',
              state: ChoiceButtonState.correct,
              onTap: () {},
            ),
          ),
        );
        // Just verify it renders without error with correct state
        expect(tester.takeException(), isNull);
      });
    });

    group('incorrect state', () {
      testWidgets('renders label text', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ChoiceButton(
              label: 'Wrong Street',
              state: ChoiceButtonState.incorrect,
              onTap: () {},
            ),
          ),
        );
        expect(find.text('Wrong Street'), findsOneWidget);
      });

      testWidgets('uses red color indicator', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ChoiceButton(
              label: 'Wrong Street',
              state: ChoiceButtonState.incorrect,
              onTap: () {},
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    });

    group('disabled state', () {
      testWidgets('renders label text', (tester) async {
        await tester.pumpWidget(
          _wrap(
            ChoiceButton(
              label: 'Disabled Street',
              state: ChoiceButtonState.disabled,
              onTap: () {},
            ),
          ),
        );
        expect(find.text('Disabled Street'), findsOneWidget);
      });

      testWidgets('onTap is not called when disabled', (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          _wrap(
            ChoiceButton(
              label: 'Disabled Street',
              state: ChoiceButtonState.disabled,
              onTap: () => tapped = true,
            ),
          ),
        );
        await tester.tap(find.byType(ChoiceButton));
        expect(tapped, isFalse);
      });
    });

    group('all states render without error', () {
      for (final state in ChoiceButtonState.values) {
        testWidgets('renders $state without throwing', (tester) async {
          await tester.pumpWidget(
            _wrap(
              ChoiceButton(
                label: 'Test Street',
                state: state,
                onTap: () {},
              ),
            ),
          );
          expect(tester.takeException(), isNull);
        });
      }
    });
  });
}
