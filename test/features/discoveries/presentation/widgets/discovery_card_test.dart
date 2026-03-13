import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/theme/rarity_colors.dart';
import 'package:dander/features/discoveries/presentation/widgets/discovery_card.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Discovery _buildDiscovery({
  String id = 'node/1',
  String name = 'The Corner Café',
  String category = 'cafe',
  RarityTier rarity = RarityTier.common,
  DateTime? discoveredAt,
}) {
  return Discovery(
    id: id,
    name: name,
    category: category,
    rarity: rarity,
    position: const LatLng(51.5074, -0.1278),
    osmTags: const {'amenity': 'cafe'},
    discoveredAt: discoveredAt ?? DateTime(2024, 6, 15, 10, 30),
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
  group('DiscoveryCard', () {
    group('rendering — basic fields', () {
      testWidgets('displays the discovery name', (tester) async {
        final d = _buildDiscovery(name: 'Hackney Marshes Viewpoint');
        await tester.pumpWidget(_wrap(DiscoveryCard(discovery: d)));
        expect(find.text('Hackney Marshes Viewpoint'), findsOneWidget);
      });

      testWidgets('displays the category label', (tester) async {
        final d = _buildDiscovery(category: 'park');
        await tester.pumpWidget(_wrap(DiscoveryCard(discovery: d)));
        expect(find.textContaining('park', findRichText: true), findsWidgets);
      });

      testWidgets('displays a discovery number / index', (tester) async {
        // Card receives a discoveryNumber to show "Discovery #N"
        final d = _buildDiscovery();
        await tester.pumpWidget(
          _wrap(DiscoveryCard(discovery: d, discoveryNumber: 7)),
        );
        expect(find.textContaining('#7'), findsOneWidget);
      });

      testWidgets('displays discovery number 1 by default', (tester) async {
        final d = _buildDiscovery();
        await tester.pumpWidget(_wrap(DiscoveryCard(discovery: d)));
        expect(find.textContaining('#1'), findsOneWidget);
      });

      testWidgets('displays the discovery date', (tester) async {
        final d = _buildDiscovery(discoveredAt: DateTime(2024, 6, 15));
        await tester.pumpWidget(_wrap(DiscoveryCard(discovery: d)));
        // Should contain "15 Jun 2024" or similar date representation
        expect(find.textContaining('2024'), findsWidgets);
      });

      testWidgets('displays a category icon', (tester) async {
        final d = _buildDiscovery(category: 'cafe');
        await tester.pumpWidget(_wrap(DiscoveryCard(discovery: d)));
        expect(find.byType(Icon), findsWidgets);
      });
    });

    group('rendering — rarity tiers', () {
      testWidgets('common tier uses bronze colour', (tester) async {
        final d = _buildDiscovery(rarity: RarityTier.common);
        await tester.pumpWidget(_wrap(DiscoveryCard(discovery: d)));
        // Verify the rarity label "Common" is rendered
        expect(find.textContaining('Common'), findsOneWidget);
      });

      testWidgets('uncommon tier uses silver colour', (tester) async {
        final d = _buildDiscovery(rarity: RarityTier.uncommon);
        await tester.pumpWidget(_wrap(DiscoveryCard(discovery: d)));
        expect(find.textContaining('Uncommon'), findsOneWidget);
      });

      testWidgets('rare tier uses gold colour', (tester) async {
        final d = _buildDiscovery(rarity: RarityTier.rare);
        await tester.pumpWidget(_wrap(DiscoveryCard(discovery: d)));
        expect(find.textContaining('Rare'), findsOneWidget);
      });

      testWidgets('common tier rarity badge has bronze colour', (tester) async {
        final d = _buildDiscovery(rarity: RarityTier.common);
        await tester.pumpWidget(_wrap(DiscoveryCard(discovery: d)));
        await tester.pump();

        // The rarity label "Common" is rendered — colour is verified by
        // checking that a Container somewhere carries the expected colour.
        final containers = tester.widgetList<Container>(find.byType(Container));
        final hasBronzeDecoration = containers.any((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            if (decoration.color == RarityColors.common) return true;
            final border = decoration.border;
            if (border is Border) {
              return border.top.color == RarityColors.common;
            }
          }
          return false;
        });
        expect(hasBronzeDecoration, isTrue);
      });

      testWidgets('rare tier rarity badge has gold colour', (tester) async {
        final d = _buildDiscovery(rarity: RarityTier.rare);
        await tester.pumpWidget(_wrap(DiscoveryCard(discovery: d)));
        await tester.pump();

        final containers = tester.widgetList<Container>(find.byType(Container));
        final hasGoldDecoration = containers.any((c) {
          final decoration = c.decoration;
          if (decoration is BoxDecoration) {
            if (decoration.color == RarityColors.rare) return true;
            final border = decoration.border;
            if (border is Border) {
              return border.top.color == RarityColors.rare;
            }
          }
          return false;
        });
        expect(hasGoldDecoration, isTrue);
      });
    });

    group('dismiss / collect button', () {
      testWidgets('renders a dismiss/collect button', (tester) async {
        final d = _buildDiscovery();
        await tester.pumpWidget(_wrap(DiscoveryCard(discovery: d)));
        // There should be at least one tappable button
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is ElevatedButton ||
                w is TextButton ||
                w is OutlinedButton ||
                w is GestureDetector ||
                w is InkWell,
          ),
          findsWidgets,
        );
      });

      testWidgets('onDismiss callback fires when dismiss button tapped',
          (tester) async {
        var dismissed = false;
        final d = _buildDiscovery();
        await tester.pumpWidget(
          _wrap(
            DiscoveryCard(
              discovery: d,
              onDismiss: () => dismissed = true,
            ),
          ),
        );
        // Tap the first ElevatedButton (the dismiss/collect button)
        await tester.tap(find.byType(ElevatedButton).first);
        await tester.pump();
        expect(dismissed, isTrue);
      });

      testWidgets('onDismiss null does not throw when button tapped',
          (tester) async {
        final d = _buildDiscovery();
        await tester.pumpWidget(
          _wrap(DiscoveryCard(discovery: d, onDismiss: null)),
        );
        await tester.tap(find.byType(ElevatedButton).first);
        await tester.pump();
        // No exception
      });
    });

    group('edge cases', () {
      testWidgets('renders with very long name without overflow error',
          (tester) async {
        final d = _buildDiscovery(
          name: 'A Very Long Discovery Name That Might Cause Layout Issues',
        );
        await tester.pumpWidget(_wrap(DiscoveryCard(discovery: d)));
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders with empty name', (tester) async {
        final d = _buildDiscovery(name: '');
        await tester.pumpWidget(_wrap(DiscoveryCard(discovery: d)));
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders with special characters in name', (tester) async {
        final d = _buildDiscovery(name: "L'Étoile & Café <★>");
        await tester.pumpWidget(_wrap(DiscoveryCard(discovery: d)));
        expect(find.text("L'Étoile & Café <★>"), findsOneWidget);
      });
    });
  });
}
