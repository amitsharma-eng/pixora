import 'pixora_cache_policy.dart';

/// Global configuration for Pixora image loading and caching behavior.
class PixoraConfig {
  /// Creates a [PixoraConfig] with the specified settings.
  const PixoraConfig({
    this.cachePolicy = PixoraCachePolicy.cacheFirst,
    this.maxRetries = 2,
    this.retryDelay = const Duration(milliseconds: 500),
    this.maxMemoryEntries = 100,
    this.maxDiskAge = const Duration(days: 7),
    this.connectTimeout = const Duration(seconds: 10),
    this.fadeInDuration = const Duration(milliseconds: 220),
  }) : assert(maxRetries >= 0),
       assert(maxMemoryEntries > 0);

  /// The default [PixoraCachePolicy] to use.
  final PixoraCachePolicy cachePolicy;

  /// Maximum number of network retry attempts.
  final int maxRetries;

  /// Delay between retry attempts.
  final Duration retryDelay;

  /// Maximum number of images to keep in memory cache.
  final int maxMemoryEntries;

  /// Maximum age for disk cache entries.
  final Duration maxDiskAge;

  /// Timeout for network connections.
  final Duration connectTimeout;

  /// Duration of the fade-in animation when an image is loaded.
  final Duration fadeInDuration;
}
