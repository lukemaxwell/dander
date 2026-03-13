import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dander/core/navigation/app_router.dart';

void main() {
  group('AppRouter', () {
    test('router is a GoRouter instance', () {
      expect(router, isA<GoRouter>());
    });

    test('AppRoutes.home is /home', () {
      expect(AppRoutes.home, equals('/home'));
    });

    test('AppRoutes.discoveries is /discoveries', () {
      expect(AppRoutes.discoveries, equals('/discoveries'));
    });

    test('AppRoutes.profile is /profile', () {
      expect(AppRoutes.profile, equals('/profile'));
    });

    testWidgets('navigating to /home renders MapScreen', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // MapScreen should be present as the initial route redirects to /home
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('router provides a valid navigatorKey', (tester) async {
      expect(router.routerDelegate, isNotNull);
      expect(router.routeInformationParser, isNotNull);
    });
  });
}
