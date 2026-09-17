import 'dart:collection';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Manages memory and disk caching for Pixora images.
class PixoraCacheManager {
  PixoraCacheManager._();

  /// The singleton instance of [PixoraCacheManager].
  static final PixoraCacheManager instance = PixoraCacheManager._();

  final LinkedHashMap<String, Uint8List> _memory = LinkedHashMap();
  Directory? _directory;

  /// Generates a cache key for a given [url].
  ///
  /// If [customKey] is provided, it will be used instead of the SHA-256 hash.
  String keyFor(String url, String? customKey) =>
      customKey ?? sha256.convert(url.codeUnits).toString();

  Future<Directory> _getDirectory() async {
    if (_directory != null) return _directory!;
    final base = await getTemporaryDirectory();
    final directory = Directory('${base.path}/pixora');
    if (!await directory.exists()) await directory.create(recursive: true);
    _directory = directory;
    return directory;
  }

  /// Retrieves an image from memory cache by its [key].
  Future<Uint8List?> getMemory(String key) async {
    final value = _memory.remove(key);
    if (value != null) _memory[key] = value;
    return value;
  }

  /// Puts an image into memory cache with the given [key].
  ///
  /// Evicts the least recently used entries if the cache size exceeds [maxEntries].
  Future<void> putMemory(
    String key,
    Uint8List bytes, {
    int maxEntries = 100,
  }) async {
    _memory.remove(key);
    _memory[key] = bytes;
    while (_memory.length > maxEntries) {
      _memory.remove(_memory.keys.first);
    }
  }

  /// Retrieves an image from disk cache by its [key].
  ///
  /// If [maxAge] is provided, it will check if the cache entry has expired.
  Future<Uint8List?> getDisk(String key, {Duration? maxAge}) async {
    if (kIsWeb) return null;
    final directory = await _getDirectory();
    final file = File('${directory.path}/$key.img');
    if (!await file.exists()) return null;
    if (maxAge != null) {
      final age = DateTime.now().difference(await file.lastModified());
      if (age > maxAge) {
        await file.delete().catchError((_) => file);
        return null;
      }
    }
    return file.readAsBytes();
  }

  /// Puts an image into disk cache with the given [key].
  Future<void> putDisk(String key, Uint8List bytes) async {
    if (kIsWeb) return;
    final directory = await _getDirectory();
    final temporary = File('${directory.path}/$key.tmp');
    final target = File('${directory.path}/$key.img');
    await temporary.writeAsBytes(bytes, flush: true);
    await temporary.rename(target.path);
  }

  /// Clears both memory and disk caches.
  Future<void> clear() async {
    _memory.clear();
    if (kIsWeb) return;
    final directory = await _getDirectory();
    if (await directory.exists()) await directory.delete(recursive: true);
    _directory = null;
  }

  /// Returns the total size of the disk cache in bytes.
  Future<int> diskSizeBytes() async {
    if (kIsWeb) return 0;
    final directory = await _getDirectory();
    var total = 0;
    if (!await directory.exists()) return total;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}
