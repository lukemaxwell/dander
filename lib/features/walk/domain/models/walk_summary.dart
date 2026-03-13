class WalkSummary {
  const WalkSummary({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.distanceMetres,
    required this.fogClearedPercent,
    required this.discoveriesFound,
  });

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceMetres;
  final double fogClearedPercent;
  final int discoveriesFound;

  Duration get duration => endedAt.difference(startedAt);

  double get distanceKm => distanceMetres / 1000.0;
}
