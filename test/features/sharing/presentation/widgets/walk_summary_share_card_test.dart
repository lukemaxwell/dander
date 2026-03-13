import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/walk/domain/models/walk_summary.dart';
import 'package:dander/features/sharing/presentation/widgets/walk_summary_share_card.dart';

const _cardSize = Size(
  WalkSummaryShareCard.cardWidth,
  WalkSummaryShareCard.cardHeight,
);

Widget _wrap(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: child,
    );

Future<void> _pumpCard(WidgetTester tester, Widget card) async {
  tester.view.physicalSize = _cardSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_wrap(card));
}

WalkSummary _makeWalkSummary({
  DateTime? startedAt,
  DateTime? endedAt,
  double distanceMetres = 3500,
  double fogClearedPercent = 8.5,
  int discoveriesFound = 3,
}) {
  final start = startedAt ?? DateTime(2024, 9, 14, 8, 30);
  final end = endedAt ?? start.add(const Duration(minutes: 45));
  return WalkSummary(
    id: 'walk-test',
    startedAt: start,
    endedAt: end,
    distanceMetres: distanceMetres,
    fogClearedPercent: fogClearedPercent,
    discoveriesFound: discoveriesFound,
  );
}

void main() {
  group('WalkSummaryShareCard', () {
    testWidgets('renders Dander wordmark branding', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(walkSummary: _makeWalkSummary()),
      );

      expect(find.text('Dander'), findsOneWidget);
    });

    testWidgets('renders walk date', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(
          walkSummary: _makeWalkSummary(
            startedAt: DateTime(2024, 9, 14, 8, 30),
          ),
        ),
      );

      final dateFinder = find.byKey(const Key('walk_date'));
      expect(dateFinder, findsOneWidget);
      final text = tester.widget<Text>(dateFinder).data ?? '';
      expect(text, contains('14'));
    });

    testWidgets('walk_date key is present', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(walkSummary: _makeWalkSummary()),
      );

      expect(find.byKey(const Key('walk_date')), findsOneWidget);
    });

    testWidgets('renders duration stat', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(
          walkSummary: _makeWalkSummary(
            startedAt: DateTime(2024, 1, 1, 9, 0),
            endedAt: DateTime(2024, 1, 1, 9, 45),
          ),
        ),
      );

      final durationFinder = find.byKey(const Key('walk_duration'));
      expect(durationFinder, findsOneWidget);
      final text = tester.widget<Text>(durationFinder).data ?? '';
      expect(text, contains('45'));
    });

    testWidgets('walk_duration key is present', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(walkSummary: _makeWalkSummary()),
      );

      expect(find.byKey(const Key('walk_duration')), findsOneWidget);
    });

    testWidgets('renders distance in km when >= 1000m', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(
          walkSummary: _makeWalkSummary(distanceMetres: 3500),
        ),
      );

      final distanceFinder = find.byKey(const Key('walk_distance'));
      expect(distanceFinder, findsOneWidget);
      final text = tester.widget<Text>(distanceFinder).data ?? '';
      expect(text, contains('km'));
    });

    testWidgets('renders distance in metres when < 1000m', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(
          walkSummary: _makeWalkSummary(distanceMetres: 800),
        ),
      );

      final distanceFinder = find.byKey(const Key('walk_distance'));
      expect(distanceFinder, findsOneWidget);
      final text = tester.widget<Text>(distanceFinder).data ?? '';
      expect(text, contains('m'));
      expect(text, isNot(contains('km')));
    });

    testWidgets('walk_distance key is present', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(walkSummary: _makeWalkSummary()),
      );

      expect(find.byKey(const Key('walk_distance')), findsOneWidget);
    });

    testWidgets('renders fog cleared percentage', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(
          walkSummary: _makeWalkSummary(fogClearedPercent: 12.3),
        ),
      );

      final fogFinder = find.byKey(const Key('fog_cleared'));
      expect(fogFinder, findsOneWidget);
      final text = tester.widget<Text>(fogFinder).data ?? '';
      expect(text, contains('12.3%'));
    });

    testWidgets('fog_cleared key is present', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(walkSummary: _makeWalkSummary()),
      );

      expect(find.byKey(const Key('fog_cleared')), findsOneWidget);
    });

    testWidgets('renders discoveries found count', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(
          walkSummary: _makeWalkSummary(discoveriesFound: 7),
        ),
      );

      final discoveriesFinder = find.byKey(const Key('discoveries_found'));
      expect(discoveriesFinder, findsOneWidget);
      final text = tester.widget<Text>(discoveriesFinder).data ?? '';
      expect(text, equals('7'));
    });

    testWidgets('discoveries_found key is present', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(walkSummary: _makeWalkSummary()),
      );

      expect(find.byKey(const Key('discoveries_found')), findsOneWidget);
    });

    testWidgets('renders motivational tagline', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(walkSummary: _makeWalkSummary()),
      );

      expect(find.byKey(const Key('tagline')), findsOneWidget);
    });

    testWidgets('renders dander.app watermark', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(walkSummary: _makeWalkSummary()),
      );

      expect(find.text('dander.app'), findsOneWidget);
    });

    testWidgets('watermark key is present', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(walkSummary: _makeWalkSummary()),
      );

      expect(find.byKey(const Key('watermark')), findsOneWidget);
    });

    testWidgets('renders Walk Summary header', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(walkSummary: _makeWalkSummary()),
      );

      expect(find.text('Walk Summary'), findsOneWidget);
    });

    testWidgets('renders 0 discoveries without error', (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(
          walkSummary: _makeWalkSummary(discoveriesFound: 0),
        ),
      );

      final discoveriesFinder = find.byKey(const Key('discoveries_found'));
      final text = tester.widget<Text>(discoveriesFinder).data ?? '';
      expect(text, equals('0'));
    });

    testWidgets('duration shows hours when walk is over 60 minutes',
        (tester) async {
      await _pumpCard(
        tester,
        WalkSummaryShareCard(
          walkSummary: _makeWalkSummary(
            startedAt: DateTime(2024, 1, 1, 8, 0),
            endedAt: DateTime(2024, 1, 1, 9, 30),
          ),
        ),
      );

      final durationFinder = find.byKey(const Key('walk_duration'));
      final text = tester.widget<Text>(durationFinder).data ?? '';
      expect(text, contains('h'));
    });
  });
}
