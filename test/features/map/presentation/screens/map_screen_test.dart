import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:dander/core/location/location_service.dart';
import 'package:dander/features/map/presentation/screens/map_screen.dart';
import 'package:dander/features/map/presentation/widgets/compass_button.dart';

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

Widget _screen({Key? key}) => MaterialApp(
      home: MapScreen(
        key: key,
        locationService: _StubLocationService(),
      ),
    );

void main() {
  group('MapScreen', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_screen());
      await tester.pump();
      expect(find.byType(MapScreen), findsOneWidget);
    });

    testWidgets('shows a Scaffold', (tester) async {
      await tester.pumpWidget(_screen());
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows exploration progress text', (tester) async {
      await tester.pumpWidget(_screen());
      await tester.pump();
      expect(find.textContaining('explored'), findsOneWidget);
    });

    testWidgets('contains a Stack for layering map and fog', (tester) async {
      await tester.pumpWidget(_screen());
      await tester.pump();
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('has key set correctly', (tester) async {
      await tester.pumpWidget(_screen(key: const Key('map_screen')));
      await tester.pump();
      expect(find.byKey(const Key('map_screen')), findsOneWidget);
    });

    testWidgets('renders CompassButton in the overlay', (tester) async {
      await tester.pumpWidget(_screen());
      await tester.pump();
      expect(find.byType(CompassButton), findsOneWidget);
    });

    testWidgets('CompassButton shows one charge initially (lead-in)',
        (tester) async {
      await tester.pumpWidget(_screen());
      await tester.pump();
      final btn = tester.widget<CompassButton>(find.byType(CompassButton));
      expect(btn.charges, 1);
    });
  });
}
