# Pixora

Modern cache-first network images for Flutter.

## Features

- Memory LRU cache
- Disk cache
- Cache-first, network-first, cache-only and network-only policies
- SHA-256 cache keys or custom keys
- Retry with incremental delay
- Shimmer placeholder
- Retryable error widget
- Fade-in loading
- Memory-aware image decoding
- Prefetch
- Cache clear and cache-size APIs
- Architecture independent of GetX, Riverpod, Bloc or Provider

## Usage

```dart
PixoraImage(
  url: 'https://example.com/image.jpg',
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(16),
)
```

### Cache policy

```dart
PixoraCachePolicy.cacheFirst
PixoraCachePolicy.networkFirst
PixoraCachePolicy.cacheOnly
PixoraCachePolicy.networkOnly
```

### Prefetch

```dart
await PixoraImage.prefetch(imageUrl);
```

### Cache management

```dart
await PixoraImage.clearCache();
final size = await PixoraImage.cacheSize();
```

### Roadmap

ETag/Last-Modified revalidation, stale-while-revalidate, web persistent caching, cancellation, progress reporting, transformation pipelines, cache namespaces, and background prefetch queues.

## License

MIT
