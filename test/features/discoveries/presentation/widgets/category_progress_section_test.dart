import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/features/discoveries/presentation/widgets/category_progress_section.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Discovery _disco(String id, String category, {bool discovered = true}) =>
    Discovery(
      id: id,
      name: 'Test $id',
      category: category,
      rarity: RarityTier.common,
      position: const LatLng(51.5, -0.1),
      osmTags: const {},
      discoveredAt: discovered ? DateTime(2024) : null,
    );

void main() {
  group('CategoryProgressSection', () {
    testWidgets('renders without error with no data', (tester) async {
      await tester.pumpWidget(_wrap(
        const CategoryProgressSection(
          discovered: [],
          allPois: [],
        ),
      ));
      expect(find.byType(CategoryProgressSection), findsOneWidget);
    });

    testWidgets('shows category name for a discovered category', (tester) async {
      final d = _disco('1', 'cafe');
      final all = [d, _disco('2', 'cafe', discovered: false)];
      await tester.pumpWidget(_wrap(
        CategoryProgressSection(discovered: [d], allPois: all),
      ));
      await tester.pump();
      expect(find.textContaining('cafe'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows progress count x/y for each category', (tester) async {
      final d1 = _disco('1', 'cafe');
      final all = [d1, _disco('2', 'cafe', discovered: false)];
      await tester.pumpWidget(_wrap(
        CategoryProgressSection(discovered: [d1], allPois: all),
      ));
      await tester.pump();
      // Expects "1/2" for cafe
      expect(find.textContaining('1/2'), findsOneWidget);
    });

    testWidgets('silhouette slot shown for category with 0 discovered',
        (tester) async {
      final undiscovered = _disco('1', 'museum', discovered: false);
      await tester.pumpWidget(_wrap(
        CategoryProgressSection(discovered: const [], allPois: [undiscovered]),
      ));
      await tester.pump();
      // The silhouette should show a "?" text or lock icon
      expect(
        find.byType(CategorySilhouette),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('tapping silhouette shows exploration hint', (tester) async {
      final undiscovered = _disco('1', 'museum', discovered: false);
      await tester.pumpWidget(_wrap(
        CategoryProgressSection(
          discovered: const [],
          allPois: [undiscovered],
          zoneName: 'Hackney',
        ),
      ));
      await tester.pump();
      await tester.tap(find.byType(CategorySilhouette).first);
      await tester.pump();
      expect(find.textContaining('Hackney'), findsAtLeastNWidgets(1));
    });

    testWidgets('fully discovered category does not show silhouette',
        (tester) async {
      final d = _disco('1', 'cafe');
      await tester.pumpWidget(_wrap(
        CategoryProgressSection(discovered: [d], allPois: [d]),
      ));
      await tester.pump();
      expect(find.byType(CategorySilhouette), findsNothing);
    });
  });
}
