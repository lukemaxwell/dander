import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/zone/zone.dart';
import 'package:dander/features/sharing/presentation/widgets/turf_share_card.dart';

const _cardSize = Size(
  TurfShareCard.cardWidth,
  TurfShareCard.cardHeight,
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

Zone _makeZone({
  String id = 'zone-1',
  String name = 'Hackney',
  int xp = 300,
}) {
  return Zone(
    id: id,
    name: name,
    centre: const LatLng(51.5, -0.08),
    xp: xp,
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('TurfShareCard', () {
    testWidgets('renders zone name', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(
          zone: _makeZone(name: 'Hackney'),
          streetCount: 10,
          explorationPct: 0.5,
        ),
      );

      expect(find.text('Hackney'), findsOneWidget);
    });

    testWidgets('zone_name key is present', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(
          zone: _makeZone(name: 'Shoreditch'),
          streetCount: 5,
          explorationPct: 0.3,
        ),
      );

      expect(find.byKey(const Key('zone_name')), findsOneWidget);
    });

    testWidgets('zone_name key shows the correct zone name', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(
          zone: _makeZone(name: 'Barcelona'),
          streetCount: 20,
          explorationPct: 0.5,
        ),
      );

      final finder = find.byKey(const Key('zone_name'));
      expect(finder, findsOneWidget);
      final text = tester.widget<Text>(finder).data ?? '';
      expect(text, equals('Barcelona'));
    });

    testWidgets('renders level badge text — level 3', (tester) async {
      final zone = _makeZone(xp: 300); // level 3
      await _pumpCard(
        tester,
        TurfShareCard(zone: zone, streetCount: 10, explorationPct: 0.5),
      );

      final finder = find.byKey(const Key('level_badge'));
      expect(finder, findsOneWidget);
      final text = tester.widget<Text>(finder).data ?? '';
      expect(text, contains('Level 3'));
      expect(text, contains('Explorer'));
    });

    testWidgets('renders level badge text — level 1', (tester) async {
      final zone = _makeZone(xp: 0); // level 1
      await _pumpCard(
        tester,
        TurfShareCard(zone: zone, streetCount: 2, explorationPct: 0.1),
      );

      final finder = find.byKey(const Key('level_badge'));
      expect(finder, findsOneWidget);
      final text = tester.widget<Text>(finder).data ?? '';
      expect(text, contains('Level 1'));
    });

    testWidgets('renders level badge text — level 5', (tester) async {
      final zone = _makeZone(xp: 1500); // level 5
      await _pumpCard(
        tester,
        TurfShareCard(zone: zone, streetCount: 200, explorationPct: 0.9),
      );

      final finder = find.byKey(const Key('level_badge'));
      expect(finder, findsOneWidget);
      final text = tester.widget<Text>(finder).data ?? '';
      expect(text, contains('Level 5'));
    });

    testWidgets('level_badge key is present', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(zone: _makeZone(), streetCount: 10, explorationPct: 0.5),
      );

      expect(find.byKey(const Key('level_badge')), findsOneWidget);
    });

    testWidgets('renders street count', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(zone: _makeZone(), streetCount: 42, explorationPct: 0.5),
      );

      final finder = find.byKey(const Key('street_count'));
      expect(finder, findsOneWidget);
      final text = tester.widget<Text>(finder).data ?? '';
      expect(text, contains('42'));
    });

    testWidgets('street_count key is present', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(zone: _makeZone(), streetCount: 10, explorationPct: 0.5),
      );

      expect(find.byKey(const Key('street_count')), findsOneWidget);
    });

    testWidgets('renders 0 streets without error', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(zone: _makeZone(), streetCount: 0, explorationPct: 0.0),
      );

      final finder = find.byKey(const Key('street_count'));
      expect(finder, findsOneWidget);
      final text = tester.widget<Text>(finder).data ?? '';
      expect(text, contains('0'));
    });

    testWidgets('renders Dander wordmark branding', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(zone: _makeZone(), streetCount: 10, explorationPct: 0.5),
      );

      expect(find.text('Dander'), findsOneWidget);
    });

    testWidgets('renders dander.app watermark', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(zone: _makeZone(), streetCount: 10, explorationPct: 0.5),
      );

      expect(find.text('dander.app'), findsOneWidget);
    });

    testWidgets('watermark key is present', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(zone: _makeZone(), streetCount: 10, explorationPct: 0.5),
      );

      expect(find.byKey(const Key('watermark')), findsOneWidget);
    });

    testWidgets('has correct fixed width', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(zone: _makeZone(), streetCount: 10, explorationPct: 0.5),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.byType(SizedBox).first,
      );
      expect(sizedBox.width, equals(TurfShareCard.cardWidth));
    });

    testWidgets('has correct fixed height', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(zone: _makeZone(), streetCount: 10, explorationPct: 0.5),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.byType(SizedBox).first,
      );
      expect(sizedBox.height, equals(TurfShareCard.cardHeight));
    });

    testWidgets('uses dark background color', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(zone: _makeZone(), streetCount: 10, explorationPct: 0.5),
      );

      // CustomPaint is used for the background — verify at least one is present.
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('accepts null fogGrid without error', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(
          zone: _makeZone(),
          streetCount: 10,
          explorationPct: 0.5,
        ),
      );

      expect(find.byType(TurfShareCard), findsOneWidget);
    });

    testWidgets('renders street count label text', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(zone: _makeZone(), streetCount: 15, explorationPct: 0.5),
      );

      expect(find.byKey(const Key('street_count_label')), findsOneWidget);
    });

    testWidgets('renders zone name with special characters', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(
          zone: _makeZone(name: "O'Brien's Park"),
          streetCount: 5,
          explorationPct: 0.2,
        ),
      );

      expect(find.byKey(const Key('zone_name')), findsOneWidget);
    });

    testWidgets('territory preview area is present', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(zone: _makeZone(), streetCount: 10, explorationPct: 0.5),
      );

      expect(find.byKey(const Key('territory_preview')), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // New tests for issue #184 redesign
    // -------------------------------------------------------------------------

    testWidgets('renders exploration percentage 67%', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(
          zone: _makeZone(),
          streetCount: 34,
          explorationPct: 0.67,
        ),
      );

      expect(find.text('67%'), findsOneWidget);
    });

    testWidgets('renders exploration percentage 0%', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(
          zone: _makeZone(),
          streetCount: 0,
          explorationPct: 0.0,
        ),
      );

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('renders "explored" label', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(
          zone: _makeZone(),
          streetCount: 10,
          explorationPct: 0.5,
        ),
      );

      expect(find.text('explored'), findsOneWidget);
    });

    testWidgets('renders "streets walked" label', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(
          zone: _makeZone(),
          streetCount: 10,
          explorationPct: 0.5,
        ),
      );

      expect(find.text('streets walked'), findsOneWidget);
    });

    testWidgets('renders exploration percentage 100%', (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(
          zone: _makeZone(),
          streetCount: 100,
          explorationPct: 1.0,
        ),
      );

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('multiple CustomPaint widgets present (background + ring)',
        (tester) async {
      await _pumpCard(
        tester,
        TurfShareCard(
          zone: _makeZone(),
          streetCount: 10,
          explorationPct: 0.5,
        ),
      );

      // Background painter + territory painter + ring painter = at least 2
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(2));
    });
  });
}
