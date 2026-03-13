import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/features/profile/presentation/screens/profile_screen.dart';

void main() {
  group('ProfileScreen', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pump();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('shows a Scaffold', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows Profile title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pump();
      expect(find.text('Profile'), findsOneWidget);
    });
  });
}
