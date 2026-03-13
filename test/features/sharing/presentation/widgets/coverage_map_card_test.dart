import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/sharing/presentation/widgets/coverage_map_card.dart';

// The card is 1080x1080. Set the test surface to exactly that size so the
// card renders without overflow.
const _cardSize = Size(
  CoverageMapCard.cardWidth,
  CoverageMapCard.cardHeight,
);

// Renders the card without Scaffold so the full 1080x1080 is available.
Widget _wrap(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: child,
    );

Future<void> _pumpCard(WidgetTester tester, Widget card) async {
  // Give the test viewport exactly the card's logical size.
  tester.view.physicalSize = _cardSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_wrap(card));
}

void main() {
  group('CoverageMapCard', () {
    testWidgets('renders exploration percentage', (tester) async {
      await _pumpCard(
        tester,
        const CoverageMapCard(
          explorationPercent: 42.0,
          neighbourhoodName: 'Shoreditch',
        ),
      );

      expect(find.text('42% explored'), findsOneWidget);
    });

    testWidgets('renders neighbourhood name', (tester) async {
      await _pumpCard(
        tester,
        const CoverageMapCard(
          explorationPercent: 10.0,
          neighbourhoodName: 'Hackney',
        ),
      );

      expect(find.text('Hackney'), findsOneWidget);
    });

    testWidgets('renders Dander wordmark branding', (tester) async {
      await _pumpCard(
        tester,
        const CoverageMapCard(
          explorationPercent: 55.0,
          neighbourhoodName: 'Bethnal Green',
        ),
      );

      expect(find.text('Dander'), findsOneWidget);
    });

    testWidgets('renders dander.app watermark', (tester) async {
      await _pumpCard(
        tester,
        const CoverageMapCard(
          explorationPercent: 30.0,
          neighbourhoodName: 'Dalston',
        ),
      );

      expect(find.text('dander.app'), findsOneWidget);
    });

    testWidgets('exploration_percent key is present', (tester) async {
      await _pumpCard(
        tester,
        const CoverageMapCard(
          explorationPercent: 75.0,
          neighbourhoodName: 'Peckham',
        ),
      );

      expect(find.byKey(const Key('exploration_percent')), findsOneWidget);
    });

    testWidgets('neighbourhood_name key is present', (tester) async {
      await _pumpCard(
        tester,
        const CoverageMapCard(
          explorationPercent: 10.0,
          neighbourhoodName: 'Brixton',
        ),
      );

      expect(find.byKey(const Key('neighbourhood_name')), findsOneWidget);
    });

    testWidgets('watermark key is present', (tester) async {
      await _pumpCard(
        tester,
        const CoverageMapCard(
          explorationPercent: 0.0,
          neighbourhoodName: 'Islington',
        ),
      );

      expect(find.byKey(const Key('watermark')), findsOneWidget);
    });

    testWidgets('renders 0% explored without errors', (tester) async {
      await _pumpCard(
        tester,
        const CoverageMapCard(
          explorationPercent: 0.0,
          neighbourhoodName: 'Anywhere',
        ),
      );

      expect(find.text('0% explored'), findsOneWidget);
    });

    testWidgets('renders 100% explored without errors', (tester) async {
      await _pumpCard(
        tester,
        const CoverageMapCard(
          explorationPercent: 100.0,
          neighbourhoodName: 'Everywhere',
        ),
      );

      expect(find.text('100% explored'), findsOneWidget);
    });

    testWidgets('renders long neighbourhood name text', (tester) async {
      const longName = 'Stoke Newington & Stamford Hill';
      await _pumpCard(
        tester,
        const CoverageMapCard(
          explorationPercent: 20.0,
          neighbourhoodName: longName,
        ),
      );

      // The neighbourhood name key must be present regardless of overflow
      expect(find.byKey(const Key('neighbourhood_name')), findsOneWidget);
    });
  });
}
