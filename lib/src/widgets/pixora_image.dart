import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../cache/pixora_cache_manager.dart';
import '../core/pixora_cache_policy.dart';
import 'pixora_error.dart';
import 'pixora_placeholder.dart';

/// A widget that displays a network image with advanced caching and retry logic.
class PixoraImage extends StatefulWidget {
  /// Creates a [PixoraImage] widget.
  const PixoraImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.cachePolicy = PixoraCachePolicy.cacheFirst,
    this.cacheKey,
    this.maxRetries = 2,
    this.retryDelay = const Duration(milliseconds: 500),
    this.maxMemoryEntries = 100,
    this.maxDiskAge = const Duration(days: 7),
    this.fadeInDuration = const Duration(milliseconds: 220),
    this.memCacheWidth,
    this.memCacheHeight,
    this.httpClient,
    this.headers,
    this.backgroundColor,
    this.gaplessPlayback = true,
    this.onLoadStart,
    this.onLoadComplete,
    this.onError,
  });

  /// The URL of the image to load.
  final String url;

  /// The width of the widget.
  final double? width;

  /// The height of the widget.
  final double? height;

  /// How to inscribe the image into the space allocated during layout.
  final BoxFit fit;

  /// How to align the image within its bounds.
  final Alignment alignment;

  /// The border radius to apply to the image.
  final BorderRadius? borderRadius;

  /// The widget to display while the image is loading.
  final Widget? placeholder;

  /// The widget to display if an error occurs.
  final Widget? errorWidget;

  /// The caching policy to use.
  final PixoraCachePolicy cachePolicy;

  /// An optional custom key to identify the image in the cache.
  final String? cacheKey;

  /// Maximum number of retry attempts for network failures.
  final int maxRetries;

  /// Delay between retry attempts.
  final Duration retryDelay;

  /// Maximum number of images to keep in memory cache.
  final int maxMemoryEntries;

  /// Maximum age for disk cache entries.
  final Duration maxDiskAge;

  /// Duration of the fade-in animation.
  final Duration fadeInDuration;

  /// The width to use for memory caching.
  final int? memCacheWidth;

  /// The height to use for memory caching.
  final int? memCacheHeight;

  /// Custom HTTP client for the network request.
  final http.Client? httpClient;

  /// Custom HTTP headers for the network request.
  final Map<String, String>? headers;

  /// Background color of the image container.
  final Color? backgroundColor;

  /// Whether to keep the old image while a new one is loading.
  final bool gaplessPlayback;

  /// Callback when image loading starts.
  final VoidCallback? onLoadStart;

  /// Callback when image loading completes successfully.
  final VoidCallback? onLoadComplete;

  /// Callback when an error occurs during image loading.
  final void Function(Object error)? onError;

  /// Prefetches an image and stores it in the cache.
  static Future<void> prefetch(
    String url, {
    String? cacheKey,
    PixoraCachePolicy cachePolicy = PixoraCachePolicy.cacheFirst,
    int maxRetries = 2,
    http.Client? httpClient,
  }) => _ImageRepository()
      .load(
        url,
        customKey: cacheKey,
        policy: cachePolicy,
        maxRetries: maxRetries,
        maxMemoryEntries: 100,
        maxDiskAge: const Duration(days: 7),
        httpClient: httpClient,
      )
      .then((_) {});

  /// Clears both memory and disk caches for all Pixora images.
  static Future<void> clearCache() => PixoraCacheManager.instance.clear();

  /// Returns the total size of the disk cache in bytes.
  static Future<int> cacheSize() => PixoraCacheManager.instance.diskSizeBytes();

  @override
  State<PixoraImage> createState() => _PixoraImageState();
}

class _PixoraImageState extends State<PixoraImage> {
  late Future<Uint8List> _future;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    widget.onLoadStart?.call();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant PixoraImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.cacheKey != widget.cacheKey ||
        oldWidget.cachePolicy != widget.cachePolicy) {
      widget.onLoadStart?.call();
      _future = _load();
    }
  }

  Future<Uint8List> _load() async {
    try {
      final bytes = await _ImageRepository().load(
        widget.url,
        customKey: widget.cacheKey,
        policy: widget.cachePolicy,
        maxRetries: widget.maxRetries,
        retryDelay: widget.retryDelay,
        maxMemoryEntries: widget.maxMemoryEntries,
        maxDiskAge: widget.maxDiskAge,
        headers: widget.headers,
        httpClient: widget.httpClient,
      );
      if (mounted) widget.onLoadComplete?.call();
      return bytes;
    } catch (e) {
      if (mounted) widget.onError?.call(e);
      rethrow;
    }
  }

  void _retry() => setState(() {
    _attempt++;
    _future = _load();
  });

  @override
  Widget build(BuildContext context) {
    final placeholder =
        widget.placeholder ??
        PixoraPlaceholder.shimmer(borderRadius: widget.borderRadius);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: ColoredBox(
          color: widget.backgroundColor ?? Colors.transparent,
          child: FutureBuilder<Uint8List>(
            key: ValueKey(_attempt),
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return placeholder;
              }
              if (snapshot.hasError) {
                return widget.errorWidget ??
                    PixoraErrorWidget.retry(onRetry: _retry);
              }
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: widget.fadeInDuration,
                builder: (_, opacity, child) =>
                    Opacity(opacity: opacity, child: child),
                child: Image.memory(
                  snapshot.data!,
                  fit: widget.fit,
                  alignment: widget.alignment,
                  width: widget.width,
                  height: widget.height,
                  gaplessPlayback: widget.gaplessPlayback,
                  cacheWidth: widget.memCacheWidth,
                  cacheHeight: widget.memCacheHeight,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ImageRepository {
  final PixoraCacheManager _cache = PixoraCacheManager.instance;

  Future<Uint8List> load(
    String url, {
    String? customKey,
    required PixoraCachePolicy policy,
    required int maxRetries,
    Duration retryDelay = const Duration(milliseconds: 500),
    required int maxMemoryEntries,
    required Duration maxDiskAge,
    Map<String, String>? headers,
    http.Client? httpClient,
  }) async {
    final key = _cache.keyFor(url, customKey);

    Future<Uint8List?> cached() async {
      final memory = await _cache.getMemory(key);
      if (memory != null) return memory;
      final disk = await _cache.getDisk(key, maxAge: maxDiskAge);
      if (disk != null) {
        await _cache.putMemory(key, disk, maxEntries: maxMemoryEntries);
        return disk;
      }
      return null;
    }

    Future<Uint8List> network() async {
      Object? lastError;
      StackTrace? lastStack;
      final client = httpClient ?? http.Client();
      try {
        for (var attempt = 0; attempt <= maxRetries; attempt++) {
          try {
            final response = await client
                .get(Uri.parse(url), headers: headers)
                .timeout(const Duration(seconds: 10));
            if (response.statusCode < 200 || response.statusCode >= 300) {
              throw HttpException(
                'Pixora request failed: ${response.statusCode}',
                uri: Uri.parse(url),
              );
            }
            final bytes = response.bodyBytes;
            await _cache.putMemory(key, bytes, maxEntries: maxMemoryEntries);
            await _cache.putDisk(key, bytes);
            return bytes;
          } catch (e, s) {
            lastError = e;
            lastStack = s;
            if (attempt < maxRetries) {
              await Future<void>.delayed(retryDelay * (attempt + 1));
            }
          }
        }
      } finally {
        if (httpClient == null) client.close();
      }
      Error.throwWithStackTrace(
        lastError ?? StateError('Pixora failed to load image'),
        lastStack ?? StackTrace.current,
      );
    }

    switch (policy) {
      case PixoraCachePolicy.cacheFirst:
        return await cached() ?? await network();
      case PixoraCachePolicy.networkFirst:
        try {
          return await network();
        } catch (_) {
          final value = await cached();
          if (value != null) return value;
          rethrow;
        }
      case PixoraCachePolicy.cacheOnly:
        final value = await cached();
        if (value != null) return value;
        throw StateError('Pixora cache miss: $url');
      case PixoraCachePolicy.networkOnly:
        return network();
    }
  }
}
