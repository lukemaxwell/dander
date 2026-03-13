/// Configuration constants for offline map tile caching.
///
/// flutter_map supports tile caching via the [flutter_map_tile_caching]
/// package.  These constants define sensible defaults for Dander's offline
/// use-case without requiring a separate package in the MVP.
abstract final class TileCacheConfig {
  /// Maximum age of a cached tile before it is re-fetched when online.
  static const Duration maxTileAge = Duration(days: 7);

  /// Maximum on-disk size of the tile cache in megabytes.
  static const int maxCacheSizeMb = 100;
}
