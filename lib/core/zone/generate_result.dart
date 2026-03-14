import 'mystery_poi.dart';

/// The result of a [MysteryPoiService.generatePois] call.
///
/// [activePois] contains up to 3 unrevealed [MysteryPoi] selected from the
/// Overpass response.  [totalCount] is the count of all filtered candidates
/// before the cap was applied, giving callers insight into how many POIs are
/// in the area.
class GenerateResult {
  const GenerateResult({
    required this.activePois,
    required this.totalCount,
  });

  /// The selected (capped) list of unrevealed mystery POIs.
  final List<MysteryPoi> activePois;

  /// Total number of filtered Overpass candidates before the cap was applied.
  final int totalCount;
}
