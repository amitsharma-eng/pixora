/// Defines the caching strategies for loading images in Pixora.
enum PixoraCachePolicy {
  /// Tries to load from cache first. If not found, fetches from network.
  cacheFirst,

  /// Tries to fetch from network first. If fails, falls back to cache.
  networkFirst,

  /// Only loads from cache. Fails if the image is not cached.
  cacheOnly,

  /// Only fetches from network. Does not use or update the cache.
  networkOnly,
}
