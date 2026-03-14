import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/features/discoveries/presentation/widgets/discovery_reveal_overlay.dart';

Discovery _disco(RarityTier rarity) => Discovery(
      id: 'test',
      name: 'Corner Café',
      category: 'cafe',
      rarity: rarity,
      position: const LatLng(51.5, -0.1),
      osmTags: const {},
      discoveredAt: DateTime(2024),
    );

Widget _wrap(Widget child, {bool reduced = false}) => MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Stack(children: [child]),
        ),
      ),
    );

void main() {
  group('DiscoveryRevealOverlay — rendering', () {
    testWidgets('renders for common rarity', (tester) async {
      await tester.pumpWidget(_wrap(
        DiscoveryRevealOverlay(
          discovery: _disco(RarityTier.common),
          onComplete: () {},
        ),
      ));
      expect(find.byType(DiscoveryRevealOverlay), findsOneWidget);
    });

    testWidgets('renders for rare rarity', (tester) async {
      await tester.pumpWidget(_wrap(
        DiscoveryRevealOverlay(
          discovery: _disco(RarityTier.rare),
          onComplete: () {},
        ),
      ));
      expect(find.byType(DiscoveryRevealOverlay), findsOneWidget);
    });

    testWidgets('shows discovery name during reveal', (tester) async {
      await tester.pumpWidget(_wrap(
        DiscoveryRevealOverlay(
          discovery: _disco(RarityTier.common),
          onComplete: () {},
        ),
      ));
      // Pump to let animations start.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Corner Café'), findsAtLeastNWidgets(1));
    });
  });

  group('DiscoveryRevealOverlay — reduced motion', () {
    testWidgets('calls onComplete immediately in reduced-motion mode',
        (tester) async {
      var completed = false;
      await tester.pumpWidget(_wrap(
        DiscoveryRevealOverlay(
          discovery: _disco(RarityTier.common),
          onComplete: () => completed = true,
        ),
        reduced: true,
      ));
      await tester.pump(); // flush postFrameCallback
      expect(completed, isTrue);
    });

    testWidgets('no AnimatedBuilder inside overlay in reduced-motion',
        (tester) async {
      await tester.pumpWidget(_wrap(
        DiscoveryRevealOverlay(
          discovery: _disco(RarityTier.rare),
          onComplete: () {},
        ),
        reduced: true,
      ));
      await tester.pump();
      final inOverlay = find.descendant(
        of: find.byType(DiscoveryRevealOverlay),
        matching: find.byType(AnimatedBuilder),
      );
      expect(inOverlay, findsNothing);
    });
  });

  group('DiscoveryRevealOverlay — rarity durations', () {
    testWidgets('common reveal uses shorter animation than rare',
        (tester) async {
      // Both should complete — we just verify the durations are accessible.
      final common = DiscoveryRevealOverlay.durationFor(RarityTier.common);
      final rare = DiscoveryRevealOverlay.durationFor(RarityTier.rare);
      expect(common.inMilliseconds, lessThan(rare.inMilliseconds));
    });

    testWidgets('uncommon duration is between common and rare', (tester) async {
      final common = DiscoveryRevealOverlay.durationFor(RarityTier.common);
      final uncommon = DiscoveryRevealOverlay.durationFor(RarityTier.uncommon);
      final rare = DiscoveryRevealOverlay.durationFor(RarityTier.rare);
      expect(uncommon.inMilliseconds,
          greaterThanOrEqualTo(common.inMilliseconds));
      expect(uncommon.inMilliseconds, lessThanOrEqualTo(rare.inMilliseconds));
    });
  });
}
