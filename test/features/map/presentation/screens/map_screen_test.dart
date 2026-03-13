import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/map/presentation/screens/map_screen.dart';

void main() {
  group('MapScreen', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MapScreen()));
      // Allow any initial async tasks to settle
      await tester.pump();
      expect(find.byType(MapScreen), findsOneWidget);
    });

    testWidgets('shows a Scaffold', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MapScreen()));
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows exploration progress text', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MapScreen()));
      await tester.pump();
      // The map screen should show an exploration percentage indicator
      expect(find.textContaining('explored'), findsOneWidget);
    });

    testWidgets('contains a Stack for layering map and fog', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MapScreen()));
      await tester.pump();
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('has key set correctly', (tester) async {
      const screen = MapScreen(key: Key('map_screen'));
      await tester.pumpWidget(const MaterialApp(home: screen));
      await tester.pump();
      expect(find.byKey(const Key('map_screen')), findsOneWidget);
    });
  });
}
