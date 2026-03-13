import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/discoveries/presentation/screens/discoveries_screen.dart';

void main() {
  group('DiscoveriesScreen', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DiscoveriesScreen()));
      await tester.pump();
      expect(find.byType(DiscoveriesScreen), findsOneWidget);
    });

    testWidgets('shows a Scaffold', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DiscoveriesScreen()));
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows Discoveries title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DiscoveriesScreen()));
      await tester.pump();
      expect(find.text('Discoveries'), findsOneWidget);
    });

    testWidgets('shows empty state message when no discoveries', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: DiscoveriesScreen()));
      await tester.pump();
      expect(find.textContaining('No discoveries'), findsOneWidget);
    });
  });
}
