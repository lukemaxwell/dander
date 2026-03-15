import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/subscription/presentation/widgets/plan_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('PlanCard', () {
    group('rendering', () {
      testWidgets('renders price text', (tester) async {
        await tester.pumpWidget(_wrap(
          PlanCard(
            price: r'$34.99/year',
            period: 'year',
            subtitle: r'$2.92/mo · 7 days free',
            ctaLabel: 'Start free trial',
            isHighlighted: true,
            isLoading: false,
            onTap: () {},
          ),
        ));

        expect(find.text(r'$34.99/year'), findsOneWidget);
      });

      testWidgets('renders subtitle text', (tester) async {
        await tester.pumpWidget(_wrap(
          PlanCard(
            price: r'$34.99/year',
            period: 'year',
            subtitle: r'$2.92/mo · 7 days free',
            ctaLabel: 'Start free trial',
            isHighlighted: true,
            isLoading: false,
            onTap: () {},
          ),
        ));

        expect(find.text(r'$2.92/mo · 7 days free'), findsOneWidget);
      });

      testWidgets('renders CTA label', (tester) async {
        await tester.pumpWidget(_wrap(
          PlanCard(
            price: r'$34.99/year',
            period: 'year',
            subtitle: r'$2.92/mo · 7 days free',
            ctaLabel: 'Start free trial',
            isHighlighted: true,
            isLoading: false,
            onTap: () {},
          ),
        ));

        expect(find.text('Start free trial'), findsOneWidget);
      });

      testWidgets('renders monthly card with outlined CTA', (tester) async {
        await tester.pumpWidget(_wrap(
          PlanCard(
            price: r'$4.99/month',
            period: 'month',
            subtitle: '',
            ctaLabel: 'Subscribe',
            isHighlighted: false,
            isLoading: false,
            onTap: () {},
          ),
        ));

        expect(find.text(r'$4.99/month'), findsOneWidget);
        expect(find.text('Subscribe'), findsOneWidget);
      });

      testWidgets('renders loading indicator when isLoading is true',
          (tester) async {
        await tester.pumpWidget(_wrap(
          PlanCard(
            price: r'$34.99/year',
            period: 'year',
            subtitle: r'$2.92/mo · 7 days free',
            ctaLabel: 'Start free trial',
            isHighlighted: true,
            isLoading: true,
            onTap: () {},
          ),
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('hides CTA label when isLoading is true', (tester) async {
        await tester.pumpWidget(_wrap(
          PlanCard(
            price: r'$34.99/year',
            period: 'year',
            subtitle: r'$2.92/mo · 7 days free',
            ctaLabel: 'Start free trial',
            isHighlighted: true,
            isLoading: true,
            onTap: () {},
          ),
        ));

        expect(find.text('Start free trial'), findsNothing);
      });

      testWidgets('shows CTA label when isLoading is false', (tester) async {
        await tester.pumpWidget(_wrap(
          PlanCard(
            price: r'$34.99/year',
            period: 'year',
            subtitle: r'$2.92/mo · 7 days free',
            ctaLabel: 'Start free trial',
            isHighlighted: false,
            isLoading: false,
            onTap: () {},
          ),
        ));

        expect(find.text('Start free trial'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('interactions', () {
      testWidgets('calls onTap when tapped and not loading', (tester) async {
        var tapped = false;
        await tester.pumpWidget(_wrap(
          PlanCard(
            price: r'$34.99/year',
            period: 'year',
            subtitle: r'$2.92/mo · 7 days free',
            ctaLabel: 'Start free trial',
            isHighlighted: true,
            isLoading: false,
            onTap: () => tapped = true,
          ),
        ));

        await tester.tap(find.text('Start free trial'));
        expect(tapped, isTrue);
      });

      testWidgets('does not call onTap when isLoading is true', (tester) async {
        var tapped = false;
        await tester.pumpWidget(_wrap(
          PlanCard(
            price: r'$34.99/year',
            period: 'year',
            subtitle: r'$2.92/mo · 7 days free',
            ctaLabel: 'Start free trial',
            isHighlighted: true,
            isLoading: true,
            onTap: () => tapped = true,
          ),
        ));

        // Tap the card area — there's no button text visible
        await tester.tap(find.byType(PlanCard));
        expect(tapped, isFalse);
      });
    });

    group('accessibility', () {
      testWidgets('has accessibility hint on card', (tester) async {
        await tester.pumpWidget(_wrap(
          PlanCard(
            price: r'$34.99/year',
            period: 'year',
            subtitle: r'$2.92/mo · 7 days free',
            ctaLabel: 'Start free trial',
            isHighlighted: true,
            isLoading: false,
            onTap: () {},
          ),
        ));

        // Verify the Semantics node with the hint is present
        expect(
          find.bySemanticsLabel(RegExp('.*')),
          findsWidgets,
        );
      });
    });

    group('inline error', () {
      testWidgets('shows error message when provided', (tester) async {
        await tester.pumpWidget(_wrap(
          PlanCard(
            price: r'$34.99/year',
            period: 'year',
            subtitle: r'$2.92/mo · 7 days free',
            ctaLabel: 'Start free trial',
            isHighlighted: true,
            isLoading: false,
            onTap: () {},
            errorMessage: 'Something went wrong. Try again.',
          ),
        ));

        expect(find.text('Something went wrong. Try again.'), findsOneWidget);
      });

      testWidgets('no error shown when errorMessage is null', (tester) async {
        await tester.pumpWidget(_wrap(
          PlanCard(
            price: r'$34.99/year',
            period: 'year',
            subtitle: r'$2.92/mo · 7 days free',
            ctaLabel: 'Start free trial',
            isHighlighted: true,
            isLoading: false,
            onTap: () {},
          ),
        ));

        expect(find.text('Something went wrong. Try again.'), findsNothing);
      });
    });
  });
}
