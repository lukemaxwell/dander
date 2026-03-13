import 'package:latlong2/latlong.dart';

/// The disclosure state of a [MysteryPoi].
///
/// - [unrevealed]: The POI exists but nothing has been shared with the user.
/// - [hinted]: The user has received a clue but has not yet arrived.
/// - [revealed]: The user has arrived; the full name is now visible.
enum PoiState { unrevealed, hinted, revealed }

/// An immutable mystery point of interest that is hidden until the user arrives.
///
/// The [state] field drives disclosure:
/// - [PoiState.unrevealed] — default; [name] is typically `null`.
/// - [PoiState.hinted]     — a clue has been shown; use [hint] to transition.
/// - [PoiState.revealed]   — user arrived; [name] is set via [reveal].
///
/// Valid categories: 'pub', 'park', 'historic', 'street_art', 'viewpoint',
/// 'cafe', 'library'.
class MysteryPoi {
  const MysteryPoi({
    required this.id,
    required this.position,
    required this.category,
    this.name,
    this.state = PoiState.unrevealed,
  });

  /// Unique identifier for this POI (typically matches the OSM node id).
  final String id;

  /// Geographic position of the POI.
  final LatLng position;

  /// Category of the POI (e.g. 'pub', 'park', 'historic').
  final String category;

  /// Display name — typically `null` while the POI is unrevealed or hinted.
  final String? name;

  /// Current disclosure state.
  final PoiState state;

  /// Whether this POI is in the [PoiState.hinted] state.
  bool get isHinted => state == PoiState.hinted;

  /// Whether this POI has been fully revealed ([PoiState.revealed]).
  bool get isRevealed => state == PoiState.revealed;

  /// Returns a new [MysteryPoi] with [state] set to [PoiState.hinted].
  ///
  /// The original is never mutated.
  MysteryPoi hint() => MysteryPoi(
        id: id,
        position: position,
        category: category,
        name: name,
        state: PoiState.hinted,
      );

  /// Returns a new [MysteryPoi] with [name] set to [revealedName] and
  /// [state] set to [PoiState.revealed].
  ///
  /// The original is never mutated.
  MysteryPoi reveal(String revealedName) => MysteryPoi(
        id: id,
        position: position,
        category: category,
        name: revealedName,
        state: PoiState.revealed,
      );

  /// Serialises to a JSON-compatible [Map].
  ///
  /// The 'name' key is omitted when [name] is null. The 'state' key is always
  /// included so that all three states survive a round-trip.
  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': position.latitude,
        'lng': position.longitude,
        'category': category,
        'state': state.name,
        if (name != null) 'name': name,
      };

  /// Restores a [MysteryPoi] from the map produced by [toJson].
  ///
  /// Backward-compatible: if no 'state' key is present the state is inferred
  /// from [name] — null → [PoiState.unrevealed], non-null → [PoiState.revealed].
  factory MysteryPoi.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;

    final PoiState state;
    if (json.containsKey('state')) {
      state = PoiState.values.byName(json['state'] as String);
    } else {
      state = name != null ? PoiState.revealed : PoiState.unrevealed;
    }

    return MysteryPoi(
      id: json['id'] as String,
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      category: json['category'] as String,
      name: name,
      state: state,
    );
  }
}
