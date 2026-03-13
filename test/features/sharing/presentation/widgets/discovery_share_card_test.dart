import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/discoveries/domain/models/discovery.dart';
import 'package:dander/features/sharing/presentation/widgets/discovery_share_card.dart';

const _cardSize = Size(
  DiscoveryShareCard.cardWidth,
  DiscoveryShareCard.cardHeight,
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

Discovery _makeDiscovery({
  String name = 'Hidden Garden',
  String category = 'Park',
  Rarity rarity = Rarity.rare,
}) {
  return Discovery(
    id: 'test-id',
    name: name,
    category: category,
    rarity: rarity,
    latitude: 51.5,
    longitude: -0.08,
    discoveredAt: DateTime(2024, 6, 15),
  );
}

void main() {
  group('DiscoveryShareCard', () {
    testWidgets('renders discovery name', (tester) async {
      final discovery = _makeDiscovery(name: 'The Secret Courtyard');

      await _pumpCard(tester, DiscoveryShareCard(discovery: discovery));

      expect(find.text('The Secret Courtyard'), findsOneWidget);
    });

    testWidgets('discovery_name key is present', (tester) async {
      final discovery = _makeDiscovery(name: 'Mosaic Mural');

      await _pumpCard(tester, DiscoveryShareCard(discovery: discovery));

      expect(find.byKey(const Key('discovery_name')), findsOneWidget);
    });

    testWidgets('renders discovery category', (tester) async {
      final discovery = _makeDiscovery(category: 'Street Art');

      await _pumpCard(tester, DiscoveryShareCard(discovery: discovery));

      expect(find.text('Street Art'), findsOneWidget);
    });

    testWidgets('renders rarity label for Rare', (tester) async {
      final discovery = _makeDiscovery(rarity: Rarity.rare);

      await _pumpCard(tester, DiscoveryShareCard(discovery: discovery));

      expect(find.text('RARE'), findsOneWidget);
    });

    testWidgets('renders rarity label for Common', (tester) async {
      final discovery = _makeDiscovery(rarity: Rarity.common);

      await _pumpCard(tester, DiscoveryShareCard(discovery: discovery));

      expect(find.text('COMMON'), findsOneWidget);
    });

    testWidgets('renders rarity label for Uncommon', (tester) async {
      final discovery = _makeDiscovery(rarity: Rarity.uncommon);

      await _pumpCard(tester, DiscoveryShareCard(discovery: discovery));

      expect(find.text('UNCOMMON'), findsOneWidget);
    });

    testWidgets('renders Dander wordmark branding', (tester) async {
      final discovery = _makeDiscovery();

      await _pumpCard(tester, DiscoveryShareCard(discovery: discovery));

      expect(find.text('Dander'), findsOneWidget);
    });

    testWidgets('renders dander.app watermark', (tester) async {
      final discovery = _makeDiscovery();

      await _pumpCard(tester, DiscoveryShareCard(discovery: discovery));

      expect(find.text('dander.app'), findsOneWidget);
    });

    testWidgets('watermark key is present', (tester) async {
      final discovery = _makeDiscovery();

      await _pumpCard(tester, DiscoveryShareCard(discovery: discovery));

      expect(find.byKey(const Key('watermark')), findsOneWidget);
    });

    testWidgets('rarity_label key is present', (tester) async {
      final discovery = _makeDiscovery(rarity: Rarity.uncommon);

      await _pumpCard(tester, DiscoveryShareCard(discovery: discovery));

      expect(find.byKey(const Key('rarity_label')), findsOneWidget);
    });

    testWidgets('renders "New Discovery!" label', (tester) async {
      final discovery = _makeDiscovery();

      await _pumpCard(tester, DiscoveryShareCard(discovery: discovery));

      expect(find.text('New Discovery!'), findsOneWidget);
    });

    testWidgets('renders special characters in name', (tester) async {
      const specialName = "O'Brien's & Co. – A Caf\u00e9";
      final discovery = _makeDiscovery(
        name: specialName,
        category: 'Caf\u00e9',
      );

      await _pumpCard(tester, DiscoveryShareCard(discovery: discovery));

      // discovery_name widget must be present with special chars
      expect(find.byKey(const Key('discovery_name')), findsOneWidget);
    });

    testWidgets('discovery_category key is present', (tester) async {
      final discovery = _makeDiscovery(category: 'Viewpoint');

      await _pumpCard(tester, DiscoveryShareCard(discovery: discovery));

      expect(find.byKey(const Key('discovery_category')), findsOneWidget);
    });
  });
}
