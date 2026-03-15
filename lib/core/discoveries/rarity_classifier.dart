import 'discovery.dart';

/// Stateless classifier that derives a [RarityTier] from a set of OSM tags.
///
/// Rules are applied in priority order: [RarityTier.legendary] takes highest
/// precedence, followed by [RarityTier.rare], [RarityTier.uncommon], and
/// finally [RarityTier.common].
class RarityClassifier {
  RarityClassifier._();

  // ---------------------------------------------------------------------------
  // Allowlist
  // ---------------------------------------------------------------------------

  /// Categories vetted as stable, interesting, and unlikely to be
  /// miscategorised.  Commercial businesses are excluded entirely.
  static const Set<String> allowlist = {
    // Historic & heritage
    'monument', 'memorial', 'castle', 'ruins', 'archaeological_site',
    'battlefield', 'manor', 'city_gate', 'wayside_cross', 'wayside_shrine',
    // Art & culture
    'artwork', 'museum', 'gallery', 'sculpture',
    // Scenic & nature
    'viewpoint', 'nature_reserve', 'park', 'garden',
    // Community & civic
    'community_centre', 'library', 'public_bookcase', 'place_of_worship',
    'fountain', 'clock', 'drinking_water',
    // Information
    'information',
  };

  /// Returns `true` if [category] is in the curated allowlist.
  static bool isAllowlisted(String category) => allowlist.contains(category);

  /// Returns `true` if [tags] indicate a commercial business (cafe,
  /// restaurant, pub, shop, bank, etc.).
  static bool isBusiness(Map<String, String> tags) {
    const businessAmenities = {
      'cafe', 'restaurant', 'pub', 'bar', 'fast_food', 'food_court',
      'ice_cream', 'bank', 'pharmacy', 'clinic', 'doctors', 'dentist',
      'veterinary', 'fuel', 'car_wash', 'car_rental',
    };
    final amenity = tags['amenity'];
    if (amenity != null && businessAmenities.contains(amenity)) return true;
    if (tags.containsKey('shop')) return true;
    if (tags.containsKey('brand')) return true;
    if (tags['tourism'] == 'hotel' || tags['tourism'] == 'guest_house') {
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Determines the [RarityTier] for a node with the given [tags].
  ///
  /// Priority: legendary > rare > uncommon > common.
  /// Unknown / unrecognised tag combinations default to [RarityTier.common].
  static RarityTier classify(Map<String, String> tags) {
    if (_isLegendary(tags)) return RarityTier.legendary;
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

  static bool _isLegendary(Map<String, String> tags) {
    // Has a Wikipedia article
    if (tags.containsKey('wikipedia')) return true;

    // Has a Wikidata entry
    if (tags.containsKey('wikidata')) return true;

    // Has a heritage designation
    if (tags.containsKey('heritage')) return true;
    if (tags.containsKey('heritage:operator')) return true;

    // Historic site with a name AND a linked knowledge-base entry
    final hasHistoric = tags.containsKey('historic');
    final hasName = tags.containsKey('name');
    final hasKnowledgeLink =
        tags.containsKey('wikipedia') || tags.containsKey('wikidata');
    if (hasHistoric && hasName && hasKnowledgeLink) return true;

    return false;
  }

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
