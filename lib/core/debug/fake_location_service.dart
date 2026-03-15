import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../location/location_service.dart';

/// A fake [LocationService] that returns a fixed position.
///
/// Used in seed/fixture mode so the app can render a map and walk UI
/// without requiring real GPS or location permissions.
///
/// This class is only used in debug builds behind a seed profile gate.
class FakeLocationService implements LocationService {
  FakeLocationService({required LatLng position}) : _position = position;

  final LatLng _position;

  late final StreamController<Position> _controller =
      StreamController<Position>.broadcast(onListen: _emitInitial);

  void _emitInitial() {
    _controller.add(_toPosition());
  }

  Position _toPosition() {
    return Position(
      latitude: _position.latitude,
      longitude: _position.longitude,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  @override
  Stream<Position> get positionStream => _controller.stream;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> get hasPermission async => true;

  @override
  Future<Position> getCurrentPosition() async => _toPosition();
}
