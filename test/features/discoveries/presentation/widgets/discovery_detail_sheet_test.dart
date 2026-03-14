import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/features/discoveries/presentation/widgets/discovery_detail_sheet.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Discovery _makeDiscovery({
  String name = 'The Old Ship',
  String category = 'pub',
  RarityTier rarity = RarityTier.rare,
  DateTime? discoveredAt,
}) {
  return Discovery(
    id: 'node/123',
    name: name,
    category: category,
    rarity: rarity,
    position: const LatLng(51.5, -0.1),
    osmTags: const {},
    discoveredAt: discoveredAt ?? DateTime(2024, 6, 15),
  );
}

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: Scaffold(body: child),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DiscoveryDetailSheet', () {
    group('basic fields', () {
      testWidgets('displays discovery name', (tester) async {
        final d = _makeDiscovery(name: 'Borough Market');
        await tester.pumpWidget(_wrap(DiscoveryDetailSheet(discovery: d)));
        expect(find.text('Borough Market'), findsOneWidget);
      });

      testWidgets('displays category label', (tester) async {
        final d = _makeDiscovery(category: 'cafe');
        await tester.pumpWidget(_wrap(DiscoveryDetailSheet(discovery: d)));
        expect(find.textContaining('cafe'), findsWidgets);
      });

      testWidgets('displays rarity label', (tester) async {
        final d = _makeDiscovery(rarity: RarityTier.legendary);
        await tester.pumpWidget(_wrap(DiscoveryDetailSheet(discovery: d)));
        expect(find.textContaining('Legendary'), findsWidgets);
      });

      testWidgets('displays rarity explanation for rare', (tester) async {
        final d = _makeDiscovery(rarity: RarityTier.rare);
        await tester.pumpWidget(_wrap(DiscoveryDetailSheet(discovery: d)));
        expect(find.textContaining('uncommon'), findsWidgets);
      });

      testWidgets('displays discovered date', (tester) async {
        final d = _makeDiscovery(discoveredAt: DateTime(2024, 3, 10));
        await tester.pumpWidget(_wrap(DiscoveryDetailSheet(discovery: d)));
        expect(find.textContaining('10 Mar 2024'), findsOneWidget);
      });

      testWidgets('displays XP earned', (tester) async {
        final d = _makeDiscovery();
        await tester.pumpWidget(_wrap(DiscoveryDetailSheet(discovery: d)));
        expect(find.textContaining('50 XP'), findsOneWidget);
      });

      testWidgets('displays category icon', (tester) async {
        final d = _makeDiscovery(category: 'pub');
        await tester.pumpWidget(_wrap(DiscoveryDetailSheet(discovery: d)));
        expect(find.byIcon(Icons.sports_bar), findsOneWidget);
      });
    });

    group('rarity explanations', () {
      testWidgets('common explanation', (tester) async {
        final d = _makeDiscovery(rarity: RarityTier.common);
        await tester.pumpWidget(_wrap(DiscoveryDetailSheet(discovery: d)));
        expect(find.textContaining('Common'), findsWidgets);
      });

      testWidgets('uncommon explanation', (tester) async {
        final d = _makeDiscovery(rarity: RarityTier.uncommon);
        await tester.pumpWidget(_wrap(DiscoveryDetailSheet(discovery: d)));
        expect(find.textContaining('Uncommon'), findsWidgets);
      });

      testWidgets('legendary explanation mentions Wikipedia', (tester) async {
        final d = _makeDiscovery(rarity: RarityTier.legendary);
        await tester.pumpWidget(_wrap(DiscoveryDetailSheet(discovery: d)));
        expect(find.textContaining('Wikipedia'), findsWidgets);
      });
    });

    group('edge cases', () {
      testWidgets('handles unnamed discovery', (tester) async {
        final d = _makeDiscovery(name: '');
        await tester.pumpWidget(_wrap(DiscoveryDetailSheet(discovery: d)));
        expect(find.text('(Unnamed)'), findsOneWidget);
      });

      testWidgets('handles null discoveredAt', (tester) async {
        final d = Discovery(
          id: 'node/1',
          name: 'Test',
          category: 'cafe',
          rarity: RarityTier.common,
          position: const LatLng(51.5, -0.1),
          osmTags: const {},
          discoveredAt: null,
        );
        await tester.pumpWidget(_wrap(DiscoveryDetailSheet(discovery: d)));
        expect(tester.takeException(), isNull);
      });
    });
  });
}
