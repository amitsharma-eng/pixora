import 'package:flutter_test/flutter_test.dart';
import 'package:pixora/pixora.dart';

void main() {
  group('PixoraConfig', () {
    test('default values', () {
      const config = PixoraConfig();
      expect(config.cachePolicy, PixoraCachePolicy.cacheFirst);
      expect(config.maxRetries, 2);
      expect(config.retryDelay, const Duration(milliseconds: 500));
      expect(config.maxMemoryEntries, 100);
      expect(config.maxDiskAge, const Duration(days: 7));
      expect(config.connectTimeout, const Duration(seconds: 10));
      expect(config.fadeInDuration, const Duration(milliseconds: 220));
    });

    test('custom values', () {
      const config = PixoraConfig(
        cachePolicy: PixoraCachePolicy.networkOnly,
        maxRetries: 5,
        retryDelay: Duration(seconds: 1),
        maxMemoryEntries: 50,
        maxDiskAge: Duration(hours: 1),
        connectTimeout: Duration(seconds: 5),
        fadeInDuration: Duration(milliseconds: 100),
      );
      expect(config.cachePolicy, PixoraCachePolicy.networkOnly);
      expect(config.maxRetries, 5);
      expect(config.retryDelay, const Duration(seconds: 1));
      expect(config.maxMemoryEntries, 50);
      expect(config.maxDiskAge, const Duration(hours: 1));
      expect(config.connectTimeout, const Duration(seconds: 5));
      expect(config.fadeInDuration, const Duration(milliseconds: 100));
    });

    test('assertions', () {
      expect(() => PixoraConfig(maxRetries: -1), throwsAssertionError);
      expect(() => PixoraConfig(maxMemoryEntries: 0), throwsAssertionError);
    });
  });

  group('PixoraCachePolicy', () {
    test('values exist', () {
      expect(PixoraCachePolicy.values.length, 4);
      expect(PixoraCachePolicy.cacheFirst.index, 0);
      expect(PixoraCachePolicy.networkFirst.index, 1);
      expect(PixoraCachePolicy.cacheOnly.index, 2);
      expect(PixoraCachePolicy.networkOnly.index, 3);
    });
  });
}
