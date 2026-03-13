import 'discovery.dart';

/// Stateless classifier that derives a [RarityTier] from a set of OSM tags.
///
/// Rules are applied in priority order: [RarityTier.rare] takes precedence
/// over [RarityTier.uncommon], which takes precedence over [RarityTier.common].
class RarityClassifier {
  RarityClassifier._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Determines the [RarityTier] for a node with the given [tags].
  ///
  /// Priority: rare > uncommon > common.
  /// Unknown / unrecognised tag combinations default to [RarityTier.common].
  static RarityTier classify(Map<String, String> tags) {
    if (_isRare(tags)) return RarityTier.rare;
    if (_isUncommon(tags)) return RarityTier.uncommon;
    return RarityTier.common;
  }

  /// Infers a short category string from [tags].
  ///
  /// Priority for category selection: amenity > tourism > historic > leisure.
  /// Returns `"unknown"` if no recognised tag is present.
  static String inferCategory(Map<String, String> tags) {
    if (tags.containsKey('amenity')) return tags['amenity']!;
    if (tags.containsKey('tourism')) return tags['tourism']!;
    if (tags.containsKey('historic')) return tags['historic']!;
    if (tags.containsKey('leisure')) return tags['leisure']!;
    return 'unknown';
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static bool _isRare(Map<String, String> tags) {
    // tourism=viewpoint
    if (tags['tourism'] == 'viewpoint') return true;

    // historic=* (any value)
    if (tags.containsKey('historic')) return true;

    // tourism=artwork
    if (tags['tourism'] == 'artwork') return true;

    // amenity=place_of_worship with a name tag
    if (tags['amenity'] == 'place_of_worship' && tags.containsKey('name')) {
      return true;
    }

    // leisure=nature_reserve
    if (tags['leisure'] == 'nature_reserve') return true;

    return false;
  }

  static bool _isUncommon(Map<String, String> tags) {
    // amenity=cafe that is NOT a branded chain
    if (tags['amenity'] == 'cafe' && !tags.containsKey('brand')) return true;

    // amenity=library
    if (tags['amenity'] == 'library') return true;

    // amenity=community_centre
    if (tags['amenity'] == 'community_centre') return true;

    // leisure=park
    if (tags['leisure'] == 'park') return true;

    // tourism=museum
    if (tags['tourism'] == 'museum') return true;

    return false;
  }
}
