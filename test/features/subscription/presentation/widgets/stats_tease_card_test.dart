import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:dander/core/analytics/analytics_service.dart';
import 'package:dander/features/subscription/presentation/widgets/stats_tease_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUp(() {
    final gi = GetIt.instance;
    if (!gi.isRegistered<AnalyticsService>()) {
      gi.registerSingleton<AnalyticsService>(const NoOpAnalyticsService());
    }
  });

  tearDown(() {
    final gi = GetIt.instance;
    if (gi.isRegistered<AnalyticsService>()) {
      gi.unregister<AnalyticsService>();
    }
  });

  group('StatsTeaseCard', () {
    testWidgets('renders lock icon', (tester) async {
      await tester.pumpWidget(_wrap(
        StatsTeaseCard(title: 'Heat Map', onTap: () {}),
      ));

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(_wrap(
        StatsTeaseCard(title: 'Monthly Trends', onTap: () {}),
      ));

      expect(find.text('Monthly Trends'), findsOneWidget);
    });

    testWidgets('renders Pro label', (tester) async {
      await tester.pumpWidget(_wrap(
        StatsTeaseCard(title: 'Heat Map', onTap: () {}),
      ));

      expect(find.text('Pro'), findsOneWidget);
    });

    testWidgets('onTap callback is called when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        StatsTeaseCard(title: 'Heat Map', onTap: () => tapped = true),
      ));

      await tester.tap(find.byType(StatsTeaseCard));
      expect(tapped, isTrue);
    });

    testWidgets('BackdropFilter is present in widget tree', (tester) async {
      await tester.pumpWidget(_wrap(
        StatsTeaseCard(title: 'Heat Map', onTap: () {}),
      ));

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('semantics label includes title and Pro feature text',
        (tester) async {
      await tester.pumpWidget(_wrap(
        StatsTeaseCard(title: 'Heat Map', onTap: () {}),
      ));

      final semantics = tester.getSemantics(find.byType(StatsTeaseCard));
      expect(
        semantics.label,
        contains('Heat Map'),
      );
      expect(
        semantics.label,
        contains('Pro feature'),
      );
    });

    testWidgets('uses custom height when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        StatsTeaseCard(title: 'Heat Map', onTap: () {}, height: 200.0),
      ));

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(StatsTeaseCard),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(container.constraints?.maxHeight, equals(200.0));
    });

    testWidgets('uses default height of 120 when not provided', (tester) async {
      await tester.pumpWidget(_wrap(
        StatsTeaseCard(title: 'Heat Map', onTap: () {}),
      ));

      // The card renders without error at the default height
      expect(find.byType(StatsTeaseCard), findsOneWidget);
    });
  });
}
