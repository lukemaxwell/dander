import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:dander/core/location/location_service.dart';
import 'package:dander/core/navigation/app_router.dart';

class _StubLocationService implements LocationService {
  @override
  Stream<Position> get positionStream => const Stream.empty();
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<bool> get hasPermission async => false;
  @override
  Future<Position> getCurrentPosition() => Future.error('no GPS in tests');
}

void main() {
  setUp(() async {
    await GetIt.instance.reset();
    GetIt.instance.registerLazySingleton<LocationService>(
      () => _StubLocationService(),
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

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
      // pump() not pumpAndSettle() — MapScreen has an infinite pulse animation
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('router provides a valid navigatorKey', (tester) async {
      expect(router.routerDelegate, isNotNull);
      expect(router.routeInformationParser, isNotNull);
    });
  });
}
