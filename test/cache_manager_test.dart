import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixora/pixora.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pixora_test');
    
    // Mock path_provider
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getTemporaryDirectory') {
        return tempDir.path;
      }
      return null;
    });

    await PixoraCacheManager.instance.clear();
  });

  tearDown(() async {
    await PixoraCacheManager.instance.clear();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PixoraCacheManager', () {
    test('keyFor generates consistent keys', () {
      final cache = PixoraCacheManager.instance;
      final url = 'https://example.com/image.png';
      final key1 = cache.keyFor(url, null);
      final key2 = cache.keyFor(url, null);
      final customKey = cache.keyFor(url, 'custom');

      expect(key1, key2);
      expect(key1, isNot(customKey));
      expect(customKey, 'custom');
    });

    test('memory cache LRU eviction', () async {
      final cache = PixoraCacheManager.instance;
      final bytes = Uint8List.fromList([1]);
      
      // Put 3 entries, maxEntries = 2
      await cache.putMemory('1', bytes, maxEntries: 2);
      await cache.putMemory('2', bytes, maxEntries: 2);
      await cache.putMemory('3', bytes, maxEntries: 2);

      expect(await cache.getMemory('1'), isNull);
      expect(await cache.getMemory('2'), isNotNull);
      expect(await cache.getMemory('3'), isNotNull);
    });

    test('memory cache hit and miss', () async {
      final cache = PixoraCacheManager.instance;
      final bytes = Uint8List.fromList([1, 2, 3]);

      expect(await cache.getMemory('missing'), isNull);
      
      await cache.putMemory('hit', bytes);
      expect(await cache.getMemory('hit'), orderedEquals(bytes));
    });

    test('disk cache hit and miss', () async {
      final cache = PixoraCacheManager.instance;
      final bytes = Uint8List.fromList([4, 5, 6]);

      expect(await cache.getDisk('missing_disk'), isNull);

      await cache.putDisk('hit_disk', bytes);
      final retrieved = await cache.getDisk('hit_disk');
      expect(retrieved, orderedEquals(bytes));
    });

    test('disk cache expiration', () async {
      final cache = PixoraCacheManager.instance;
      final bytes = Uint8List.fromList([7, 8, 9]);
      final key = 'expiring';

      await cache.putDisk(key, bytes);
      
      // Hit with no maxAge
      expect(await cache.getDisk(key), isNotNull);

      // Hit with long maxAge
      expect(await cache.getDisk(key, maxAge: Duration(hours: 1)), isNotNull);

      // We can't easily mock file modification time without more work, 
      // but we can check if it returns null for a very short duration if we wait.
      // Or just check that it handles maxAge logic.
      
      // Note: getDisk deletes the file if expired.
      expect(await cache.getDisk(key, maxAge: Duration(microseconds: 1)), isNull);
      expect(await cache.getDisk(key), isNull); // Should be deleted
    });

    test('clear removes all entries', () async {
      final cache = PixoraCacheManager.instance;
      final bytes = Uint8List.fromList([0]);

      await cache.putMemory('m', bytes);
      await cache.putDisk('d', bytes);

      expect(await cache.getMemory('m'), isNotNull);
      expect(await cache.getDisk('d'), isNotNull);

      await cache.clear();

      expect(await cache.getMemory('m'), isNull);
      expect(await cache.getDisk('d'), isNull);
      expect(await cache.diskSizeBytes(), 0);
    });

    test('diskSizeBytes calculates correctly', () async {
      final cache = PixoraCacheManager.instance;
      final bytes = Uint8List.fromList([1, 2, 3]); // 3 bytes

      await cache.putDisk('s1', bytes);
      await cache.putDisk('s2', bytes);

      expect(await cache.diskSizeBytes(), 6);
    });
  });
}
