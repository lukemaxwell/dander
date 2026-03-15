import 'package:latlong2/latlong.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/discoveries/rarity_classifier.dart';

/// Pure, stateless curator that filters and ranks raw OSM discoveries into a
/// small, high-quality set suitable for presentation in a single zone.
///
/// Pipeline (applied in order):
///   0. Allowlist + business exclusion — reject non-allowlisted categories
///      and commercial businesses.
///   0b. Garden noise filter — reject gardens without wikipedia/wikidata.
///   1. Name filter — reject unnamed / blank POIs.
///   2. Quality scoring — rank by OSM metadata richness.
///   3. Tier budget allocation — prefer rarer tiers within the total budget.
///   4. Category diversity cap — at most 3 POIs per category (5 for worship).
///   5. Minimum spacing — no two curated POIs within 100 m of each other.
class PoiCurator {
  PoiCurator._();

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  static const int _categoryMax = 3;
  static const int _worshipMax = 5;
  static const double _minSpacingMeters = 100.0;

  /// Target slot counts for each tier within the default budget of 20.
  /// Order: legendary → rare → uncommon → common (highest priority first).
  static const Map<RarityTier, int> _tierSlots = {
    RarityTier.legendary: 2,
    RarityTier.rare: 4,
    RarityTier.uncommon: 6,
    RarityTier.common: 8,
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Curates [raw] discoveries into at most [budget] high-quality results.
  ///
  /// The filtering pipeline is:
  ///   1. Reject unnamed POIs.
  ///   2. Score by OSM tag richness.
  ///   3. Allocate slots across rarity tiers.
  ///   4. Apply category diversity cap (≤3 per category).
  ///   5. Apply minimum spacing (≥100 m apart).
  ///
  /// Returns a new list; the original [raw] list is never mutated.
  static List<Discovery> curate(List<Discovery> raw, {int budget = 20}) {
    // Step 0 — allowlist + business exclusion.
    final allowed = raw.where((d) {
      if (RarityClassifier.isBusiness(d.osmTags)) return false;
      if (!RarityClassifier.isAllowlisted(d.category)) return false;
      return true;
    }).toList();

    // Step 0b — garden noise filter: exclude gardens without wikipedia/wikidata.
    final gardenFiltered = allowed.where((d) {
      if (d.category != 'garden') return true;
      return d.osmTags.containsKey('wikipedia') ||
          d.osmTags.containsKey('wikidata');
    }).toList();

    // Step 1 — name filter.
    final named = gardenFiltered.where((d) => d.name.trim().isNotEmpty).toList();

    if (named.isEmpty) return const [];

    // Step 2 — compute quality scores once; sort descending within each tier.
    final scored = named
        .map((d) => _ScoredDiscovery(d, scoreOf(d)))
        .toList();

    // Step 3 — tier budget allocation.
    final tierSelected = _allocateByTier(scored, budget);

    // Step 4 — category diversity cap.
    final diversified = _applyCategoryDiversityCap(tierSelected);

    // Step 5 — minimum spacing.
    final spaced = _applyMinSpacing(diversified);

    return spaced.map((s) => s.discovery).toList();
  }

  /// Returns the quality score for [d] based on its OSM tag richness.
  ///
  /// Scoring rules:
  ///   +3  Has `wikipedia` or `wikidata` tag.
  ///   +2  Has `website` or `contact:website` tag.
  ///   +1  Has `opening_hours` tag.
  ///   +1  Has `phone` or `contact:phone` tag.
  ///   +1  Total OSM tag count > 5.
  ///   -2  Has `brand` tag (chain indicator).
  ///
  /// Exposed as a public helper to allow unit tests to verify scores directly.
  static int scoreOf(Discovery d) {
    final tags = d.osmTags;
    var score = 0;

    if (tags.containsKey('wikipedia') || tags.containsKey('wikidata')) {
      score += 3;
    }
    if (tags.containsKey('website') || tags.containsKey('contact:website')) {
      score += 2;
    }
    if (tags.containsKey('opening_hours')) {
      score += 1;
    }
    if (tags.containsKey('phone') || tags.containsKey('contact:phone')) {
      score += 1;
    }
    if (tags.length > 5) {
      score += 1;
    }
    if (tags.containsKey('brand')) {
      score -= 2;
    }

    return score;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Allocates the [budget] across rarity tiers (rare → uncommon → common),
  /// taking up to [_tierSlots] entries per tier.  Unspent slots from a tier
  /// roll over to the next tier down.
  static List<_ScoredDiscovery> _allocateByTier(
    List<_ScoredDiscovery> scored,
    int budget,
  ) {
    // Scale tier slot targets proportionally when budget differs from 20.
    final tierOrder = [RarityTier.legendary, RarityTier.rare, RarityTier.uncommon, RarityTier.common];
    final totalDefaultSlots =
        _tierSlots.values.fold(0, (sum, v) => sum + v); // = 20

    final scaledSlots = <RarityTier, int>{};
    var allocated = 0;
    for (var i = 0; i < tierOrder.length; i++) {
      final tier = tierOrder[i];
      final isLast = i == tierOrder.length - 1;
      if (isLast) {
        scaledSlots[tier] = budget - allocated;
      } else {
        final raw = (_tierSlots[tier]! * budget / totalDefaultSlots).round();
        scaledSlots[tier] = raw;
        allocated += raw;
      }
    }

    // Group by tier, sorted by score descending.
    final byTier = <RarityTier, List<_ScoredDiscovery>>{};
    for (final tier in tierOrder) {
      final group = scored.where((s) => s.discovery.rarity == tier).toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      byTier[tier] = group;
    }

    final selected = <_ScoredDiscovery>[];
    var remaining = budget;
    var overflow = 0;

    for (var i = 0; i < tierOrder.length; i++) {
      final tier = tierOrder[i];
      final candidates = byTier[tier]!;
      final slotForTier = (scaledSlots[tier]! + overflow).clamp(0, remaining);
      final take = candidates.length < slotForTier
          ? candidates.length
          : slotForTier;
      final unused = slotForTier - take;

      selected.addAll(candidates.take(take));
      remaining -= take;
      overflow = unused;

      if (remaining == 0) break;
    }

    return selected;
  }

  /// Applies the category diversity cap: at most [_categoryMax] POIs per
  /// category string.  Within each category, lowest-scored extras are dropped.
  static List<_ScoredDiscovery> _applyCategoryDiversityCap(
    List<_ScoredDiscovery> input,
  ) {
    final countByCategory = <String, int>{};
    final result = <_ScoredDiscovery>[];

    // Sort by score descending so we keep the best-scored ones within each cat.
    final sorted = [...input]..sort((a, b) => b.score.compareTo(a.score));

    for (final item in sorted) {
      final cat = item.discovery.category;
      final current = countByCategory[cat] ?? 0;
      final cap = cat == 'place_of_worship' ? _worshipMax : _categoryMax;
      if (current < cap) {
        result.add(item);
        countByCategory[cat] = current + 1;
      }
    }

    return result;
  }

  /// Applies minimum spacing: no two curated POIs within [_minSpacingMeters].
  /// When two POIs conflict, the higher-scored one is kept.
  static List<_ScoredDiscovery> _applyMinSpacing(
    List<_ScoredDiscovery> input,
  ) {
    const distanceCalc = Distance();

    // Process in descending score order so higher-scored POIs claim space first.
    final sorted = [...input]..sort((a, b) => b.score.compareTo(a.score));
    final kept = <_ScoredDiscovery>[];

    for (final candidate in sorted) {
      final candidatePos = candidate.discovery.position;
      final tooClose = kept.any((existing) {
        final meters = distanceCalc.as(
          LengthUnit.Meter,
          candidatePos,
          existing.discovery.position,
        );
        return meters < _minSpacingMeters;
      });

      if (!tooClose) {
        kept.add(candidate);
      }
    }

    return kept;
  }
}

// ---------------------------------------------------------------------------
// Internal value type
// ---------------------------------------------------------------------------

/// Pairs a [Discovery] with its pre-computed quality [score].
class _ScoredDiscovery {
  const _ScoredDiscovery(this.discovery, this.score);

  final Discovery discovery;
  final int score;
}
