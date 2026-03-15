import 'dart:async';

import 'package:flutter_compass/flutter_compass.dart';

/// Provides a continuous stream of compass headings in degrees (0–360,
/// measured clockwise from magnetic north).
///
/// The abstract interface is the seam used by [MapScreen] so that tests can
/// inject [MockCompassHeadingService] without pulling in the native
/// flutter_compass plugin.
abstract class CompassHeadingService {
  /// Continuous stream of heading values in degrees (0–360).
  Stream<double> get headingStream;

  /// Releases any underlying resources (stream subscriptions, controllers).
  void dispose();
}

/// Production implementation backed by the [flutter_compass] plugin.
///
/// [FlutterCompass.events] emits a [CompassEvent] roughly every sensor tick.
/// The nullable [heading] is coerced to `0.0` when the platform returns null
/// (e.g. in a simulator) so downstream consumers always receive a [double].
class FlutterCompassHeadingService implements CompassHeadingService {
  FlutterCompassHeadingService()
      : headingStream = FlutterCompass.events!
            .map((event) => event.heading ?? 0.0)
            .asBroadcastStream();

  @override
  final Stream<double> headingStream;

  @override
  void dispose() {
    // flutter_compass manages its own native resources; no explicit teardown
    // is required from the Dart side.
  }
}

/// Test double for [CompassHeadingService].
///
/// Backed by a [StreamController] so tests can inject arbitrary heading values
/// via [add] without depending on native platform plugins.
class MockCompassHeadingService implements CompassHeadingService {
  MockCompassHeadingService()
      : _controller = StreamController<double>.broadcast();

  final StreamController<double> _controller;

  @override
  Stream<double> get headingStream => _controller.stream;

  /// Emits [degrees] on [headingStream].
  void add(double degrees) => _controller.add(degrees);

  @override
  void dispose() => _controller.close();
}
