import 'package:latlong2/latlong.dart';

import 'distance_calculator.dart' as dc;

/// A single GPS-tagged point recorded during a walk.
///
/// Immutable value object.
class WalkPoint {
  const WalkPoint({
    required this.position,
    required this.timestamp,
  });

  final LatLng position;
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalkPoint &&
          runtimeType == other.runtimeType &&
          position.latitude == other.position.latitude &&
          position.longitude == other.position.longitude &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
        position.latitude,
        position.longitude,
        timestamp,
      );

  Map<String, dynamic> toJson() => {
        'lat': position.latitude,
        'lng': position.longitude,
        'ts': timestamp.toIso8601String(),
      };

  factory WalkPoint.fromJson(Map<String, dynamic> json) => WalkPoint(
        position: LatLng(
          (json['lat'] as num).toDouble(),
          (json['lng'] as num).toDouble(),
        ),
        timestamp: DateTime.parse(json['ts'] as String),
      );
}

/// An immutable record of a single walk session.
///
/// All mutation methods return a new [WalkSession] instance; the original
/// is never modified.
class WalkSession {
  const WalkSession._({
    required this.id,
    required this.startTime,
    required this.endTime,
    required List<WalkPoint> points,
  }) : _points = points;

  /// Creates a fresh session at [startTime] with no points.
  factory WalkSession.start({
    required String id,
    required DateTime startTime,
  }) {
    return WalkSession._(
      id: id,
      startTime: startTime,
      endTime: null,
      points: const [],
    );
  }

  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final List<WalkPoint> _points;

  /// An unmodifiable view of the recorded points.
  List<WalkPoint> get points => List.unmodifiable(_points);

  int get pointCount => _points.length;

  /// Total distance in metres computed via Haversine over all point segments.
  double get distanceMeters => dc.DistanceCalculator.totalDistance(_points);

  /// Walk duration.
  ///
  /// If [endTime] is set, returns [endTime] − [startTime]; otherwise returns
  /// the elapsed time from [startTime] to now.
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  // ---------------------------------------------------------------------------
  // Immutable update helpers
  // ---------------------------------------------------------------------------

  /// Returns a new [WalkSession] with [point] appended.
  WalkSession addPoint(WalkPoint point) => WalkSession._(
        id: id,
        startTime: startTime,
        endTime: endTime,
        points: [..._points, point],
      );

  /// Returns a new completed [WalkSession] with [endTime] set to [DateTime.now()].
  WalkSession complete() => completeAt(DateTime.now());

  /// Returns a new completed [WalkSession] with [endTime] set to the given time.
  WalkSession completeAt(DateTime end) => WalkSession._(
        id: id,
        startTime: startTime,
        endTime: end,
        points: List.of(_points),
      );

  // ---------------------------------------------------------------------------
  // JSON serialisation
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        if (endTime != null) 'endTime': endTime!.toIso8601String(),
        'points': _points.map((p) => p.toJson()).toList(),
      };

  factory WalkSession.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? [];
    return WalkSession._(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      points: rawPoints
          .map((p) => WalkPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
