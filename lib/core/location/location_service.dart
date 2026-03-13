import 'package:geolocator/geolocator.dart';

/// Abstract interface for obtaining device location.
///
/// Decouples business logic from the platform-specific [Geolocator] plugin,
/// enabling straightforward mocking in tests.
abstract class LocationService {
  /// A stream of [Position] updates from the device GPS.
  ///
  /// In active walk mode the stream emits at high accuracy on a short interval
  /// (≈ every 5 s). In background mode it emits significant-change updates only.
  Stream<Position> get positionStream;

  /// Requests the location permission from the OS.
  ///
  /// Returns `true` if permission was granted (either [LocationPermission.always]
  /// or [LocationPermission.whileInUse]), `false` otherwise.
  Future<bool> requestPermission();

  /// Returns `true` if the app already holds a sufficient location permission.
  Future<bool> get hasPermission;

  /// Returns the device's current [Position] at maximum accuracy.
  Future<Position> getCurrentPosition();
}

/// Production implementation backed by the [Geolocator] plugin.
///
/// In tests inject a mock [LocationService] instead of this class to avoid
/// platform-channel calls.
class GeolocatorLocationService implements LocationService {
  late final Stream<Position> _positionStream;

  GeolocatorLocationService() {
    // High-accuracy stream; distanceFilter 0 means purely time-based updates
    // (interval determined by the platform).
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).asBroadcastStream();
  }

  @override
  Stream<Position> get positionStream => _positionStream;

  @override
  Future<bool> requestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> get hasPermission async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<Position> getCurrentPosition() => Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
}
