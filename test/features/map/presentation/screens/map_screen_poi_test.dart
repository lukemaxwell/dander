import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:dander/core/location/location_service.dart';
import 'package:dander/features/map/presentation/screens/map_screen.dart';
import 'package:dander/features/map/presentation/widgets/mystery_poi_marker_layer.dart';

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

Widget _screen() => MaterialApp(
      home: MapScreen(locationService: _StubLocationService()),
    );

void main() {
  group('MapScreen — mystery POI integration', () {
    testWidgets('renders with empty mystery pois (no crash)', (tester) async {
      await tester.pumpWidget(_screen());
      await tester.pump();

      expect(find.byType(MapScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'MysteryPoiMarkerLayer is present in the widget tree after build',
        (tester) async {
      await tester.pumpWidget(_screen());
      await tester.pump();

      // The layer must appear inside the FlutterMap children stack.
      expect(find.byType(MysteryPoiMarkerLayer), findsOneWidget);
    });
  });
}
