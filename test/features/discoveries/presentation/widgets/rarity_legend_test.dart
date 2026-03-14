import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dander/features/discoveries/presentation/widgets/rarity_legend.dart';
import 'package:dander/core/theme/rarity_colors.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  group('RarityLegend', () {
    testWidgets('displays all four rarity tier labels', (tester) async {
      await tester.pumpWidget(_wrap(const RarityLegend()));
      expect(find.textContaining('Common'), findsWidgets);
      expect(find.textContaining('Uncommon'), findsWidgets);
      expect(find.textContaining('Rare'), findsWidgets);
      expect(find.textContaining('Legendary'), findsWidgets);
    });

    testWidgets('displays rarity color indicators', (tester) async {
      await tester.pumpWidget(_wrap(const RarityLegend()));
      // Each tier should have a colored circle indicator
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasCommonColor = containers.any((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration) {
          return dec.color == RarityColors.common;
        }
        return false;
      });
      expect(hasCommonColor, isTrue);
    });

    testWidgets('displays legendary Wikipedia mention', (tester) async {
      await tester.pumpWidget(_wrap(const RarityLegend()));
      expect(find.textContaining('Wikipedia'), findsWidgets);
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_wrap(const RarityLegend()));
      expect(tester.takeException(), isNull);
    });
  });
}
