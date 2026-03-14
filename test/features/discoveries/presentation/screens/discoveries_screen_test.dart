import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/features/discoveries/presentation/screens/discoveries_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Discovery _makeDiscovery({
  required String id,
  required String name,
  required String category,
  required RarityTier rarity,
}) {
  return Discovery(
    id: id,
    name: name,
    category: category,
    rarity: rarity,
    position: const LatLng(51.5, -0.1),
    osmTags: const {},
    discoveredAt: DateTime(2024, 6, 1),
  );
}

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: child,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DiscoveriesScreen', () {
    group('empty state', () {
      testWidgets('shows empty-state message when discoveries list is empty',
          (tester) async {
        await tester.pumpWidget(
          _wrap(const DiscoveriesScreen(discoveries: [])),
        );
        expect(
          find.textContaining('No discoveries'),
          findsOneWidget,
        );
      });

      testWidgets('empty state message mentions going for a walk',
          (tester) async {
        await tester.pumpWidget(
          _wrap(const DiscoveriesScreen(discoveries: [])),
        );
        expect(
          find.textContaining('walk', findRichText: true),
          findsWidgets,
        );
      });
    });

    group('count header', () {
      testWidgets('shows total discovery count', (tester) async {
        final discoveries = [
          _makeDiscovery(
            id: '1',
            name: 'Cafe A',
            category: 'cafe',
            rarity: RarityTier.common,
          ),
          _makeDiscovery(
            id: '2',
            name: 'Park B',
            category: 'park',
            rarity: RarityTier.uncommon,
          ),
          _makeDiscovery(
            id: '3',
            name: 'Viewpoint C',
            category: 'viewpoint',
            rarity: RarityTier.rare,
          ),
        ];
        await tester.pumpWidget(
          _wrap(DiscoveriesScreen(discoveries: discoveries)),
        );
        expect(find.textContaining('3'), findsWidgets);
      });

      testWidgets('header shows rare count breakdown', (tester) async {
        final discoveries = [
          _makeDiscovery(
            id: '1',
            name: 'Rare One',
            category: 'viewpoint',
            rarity: RarityTier.rare,
          ),
          _makeDiscovery(
            id: '2',
            name: 'Rare Two',
            category: 'historic',
            rarity: RarityTier.rare,
          ),
          _makeDiscovery(
            id: '3',
            name: 'Common One',
            category: 'cafe',
            rarity: RarityTier.common,
          ),
        ];
        await tester.pumpWidget(
          _wrap(DiscoveriesScreen(discoveries: discoveries)),
        );
        expect(find.textContaining('Rare'), findsWidgets);
      });
    });

    group('discovery list', () {
      testWidgets('renders a card for each discovery', (tester) async {
        final discoveries = List.generate(
          3,
          (i) => _makeDiscovery(
            id: 'node/$i',
            name: 'POI $i',
            category: 'cafe',
            rarity: RarityTier.common,
          ),
        );
        await tester.pumpWidget(
          _wrap(DiscoveriesScreen(discoveries: discoveries)),
        );
        expect(find.textContaining('POI'), findsWidgets);
      });

      testWidgets('shows discovery names in list', (tester) async {
        final discoveries = [
          _makeDiscovery(
            id: '1',
            name: 'London Eye',
            category: 'viewpoint',
            rarity: RarityTier.rare,
          ),
          _makeDiscovery(
            id: '2',
            name: 'Borough Market',
            category: 'cafe',
            rarity: RarityTier.common,
          ),
        ];
        await tester.pumpWidget(
          _wrap(DiscoveriesScreen(discoveries: discoveries)),
        );
        expect(find.text('London Eye'), findsOneWidget);
        expect(find.text('Borough Market'), findsOneWidget);
      });
    });

    group('filter chips — rarity', () {
      testWidgets('shows rarity filter chips', (tester) async {
        final discoveries = [
          _makeDiscovery(
            id: '1',
            name: 'A',
            category: 'cafe',
            rarity: RarityTier.common,
          ),
        ];
        await tester.pumpWidget(
          _wrap(DiscoveriesScreen(discoveries: discoveries)),
        );
        expect(find.byType(FilterChip), findsWidgets);
      });

      testWidgets('tapping Rare filter chip shows only rare discoveries',
          (tester) async {
        final discoveries = [
          _makeDiscovery(
            id: '1',
            name: 'Common Place',
            category: 'cafe',
            rarity: RarityTier.common,
          ),
          _makeDiscovery(
            id: '2',
            name: 'Rare Gem',
            category: 'viewpoint',
            rarity: RarityTier.rare,
          ),
        ];
        await tester.pumpWidget(
          _wrap(DiscoveriesScreen(discoveries: discoveries)),
        );

        // Find and tap the Rare filter chip
        final rareChip = find.widgetWithText(FilterChip, 'Rare');
        expect(rareChip, findsOneWidget);
        await tester.tap(rareChip);
        await tester.pumpAndSettle();

        expect(find.text('Rare Gem'), findsOneWidget);
        expect(find.text('Common Place'), findsNothing);
      });

      testWidgets('tapping Common filter chip shows only common discoveries',
          (tester) async {
        final discoveries = [
          _makeDiscovery(
            id: '1',
            name: 'Coffee Shop',
            category: 'cafe',
            rarity: RarityTier.common,
          ),
          _makeDiscovery(
            id: '2',
            name: 'Historic Mansion',
            category: 'historic',
            rarity: RarityTier.rare,
          ),
        ];
        await tester.pumpWidget(
          _wrap(DiscoveriesScreen(discoveries: discoveries)),
        );

        final commonChip = find.widgetWithText(FilterChip, 'Common');
        await tester.tap(commonChip);
        await tester.pumpAndSettle();

        expect(find.text('Coffee Shop'), findsOneWidget);
        expect(find.text('Historic Mansion'), findsNothing);
      });

      testWidgets('tapping selected rarity chip again removes filter',
          (tester) async {
        final discoveries = [
          _makeDiscovery(
            id: '1',
            name: 'Coffee Shop',
            category: 'cafe',
            rarity: RarityTier.common,
          ),
          _makeDiscovery(
            id: '2',
            name: 'Rare Spot',
            category: 'viewpoint',
            rarity: RarityTier.rare,
          ),
        ];
        await tester.pumpWidget(
          _wrap(DiscoveriesScreen(discoveries: discoveries)),
        );

        final rareChip = find.widgetWithText(FilterChip, 'Rare');
        await tester.tap(rareChip);
        await tester.pumpAndSettle();

        // All should be hidden except rare
        expect(find.text('Coffee Shop'), findsNothing);

        // Tap again to deselect
        await tester.tap(rareChip);
        await tester.pumpAndSettle();

        // All should now be visible
        expect(find.text('Coffee Shop'), findsOneWidget);
        expect(find.text('Rare Spot'), findsOneWidget);
      });
    });

    group('filter chips — category', () {
      testWidgets('tapping a category chip shows only matching discoveries',
          (tester) async {
        final discoveries = [
          _makeDiscovery(
            id: '1',
            name: 'Pret a Manger',
            category: 'cafe',
            rarity: RarityTier.common,
          ),
          _makeDiscovery(
            id: '2',
            name: 'Hyde Park',
            category: 'park',
            rarity: RarityTier.uncommon,
          ),
        ];
        await tester.pumpWidget(
          _wrap(DiscoveriesScreen(discoveries: discoveries)),
        );

        final cafeChip = find.widgetWithText(FilterChip, 'cafe');
        expect(cafeChip, findsOneWidget);
        await tester.tap(cafeChip);
        await tester.pumpAndSettle();

        expect(find.text('Pret a Manger'), findsOneWidget);
        expect(find.text('Hyde Park'), findsNothing);
      });
    });

    group('combined filters', () {
      testWidgets('rarity and category filters combine (AND logic)',
          (tester) async {
        final discoveries = [
          _makeDiscovery(
            id: '1',
            name: 'Common Cafe',
            category: 'cafe',
            rarity: RarityTier.common,
          ),
          _makeDiscovery(
            id: '2',
            name: 'Rare Cafe',
            category: 'cafe',
            rarity: RarityTier.rare,
          ),
          _makeDiscovery(
            id: '3',
            name: 'Rare Park',
            category: 'park',
            rarity: RarityTier.rare,
          ),
        ];
        await tester.pumpWidget(
          _wrap(DiscoveriesScreen(discoveries: discoveries)),
        );

        // Select Rare rarity filter
        await tester.tap(find.widgetWithText(FilterChip, 'Rare'));
        await tester.pumpAndSettle();

        // Also select cafe category filter
        await tester.tap(find.widgetWithText(FilterChip, 'cafe'));
        await tester.pumpAndSettle();

        expect(find.text('Rare Cafe'), findsOneWidget);
        expect(find.text('Common Cafe'), findsNothing);
        expect(find.text('Rare Park'), findsNothing);
      });
    });

    group('rarity legend', () {
      testWidgets('shows rarity legend when discoveries exist',
          (tester) async {
        final discoveries = [
          _makeDiscovery(
            id: '1',
            name: 'A',
            category: 'cafe',
            rarity: RarityTier.common,
          ),
        ];
        await tester.pumpWidget(
          _wrap(DiscoveriesScreen(discoveries: discoveries)),
        );
        expect(find.textContaining('Common'), findsWidgets);
        expect(find.textContaining('Legendary'), findsWidgets);
      });
    });

    group('collection progress', () {
      testWidgets('shows per-category discovery counts', (tester) async {
        final discoveries = [
          _makeDiscovery(
            id: '1',
            name: 'Cafe A',
            category: 'cafe',
            rarity: RarityTier.common,
          ),
          _makeDiscovery(
            id: '2',
            name: 'Cafe B',
            category: 'cafe',
            rarity: RarityTier.uncommon,
          ),
          _makeDiscovery(
            id: '3',
            name: 'Park A',
            category: 'park',
            rarity: RarityTier.common,
          ),
        ];
        await tester.pumpWidget(
          _wrap(DiscoveriesScreen(discoveries: discoveries)),
        );
        // Should show category counts like "cafe: 2" and "park: 1"
        expect(find.textContaining('cafe'), findsWidgets);
        expect(find.textContaining('park'), findsWidgets);
      });
    });

    group('detail bottom sheet', () {
      testWidgets('tapping a discovery card opens detail sheet',
          (tester) async {
        final discoveries = [
          _makeDiscovery(
            id: '1',
            name: 'London Eye',
            category: 'viewpoint',
            rarity: RarityTier.rare,
          ),
        ];
        await tester.pumpWidget(
          _wrap(DiscoveriesScreen(discoveries: discoveries)),
        );
        // Tap the discovery card
        await tester.tap(find.text('London Eye'));
        await tester.pumpAndSettle();

        // Bottom sheet should show detail fields
        expect(find.textContaining('50 XP'), findsWidgets);
      });
    });

    group('large list performance', () {
      testWidgets('handles 50 discoveries without error', (tester) async {
        final discoveries = List.generate(
          50,
          (i) => _makeDiscovery(
            id: 'node/$i',
            name: 'Discovery $i',
            category: i.isEven ? 'cafe' : 'park',
            rarity: RarityTier.values[i % 3],
          ),
        );
        await tester.pumpWidget(
          _wrap(DiscoveriesScreen(discoveries: discoveries)),
        );
        expect(tester.takeException(), isNull);
      });
    });
  });
}
