import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:pixora/pixora.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockClient extends Mock implements http.Client {}

class FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  FakePathProvider(this.path);
  final String path;
  @override
  Future<String?> getTemporaryPath() async => path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getLibraryPath() async => path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
  @override
  Future<String?> getExternalStoragePath() async => path;
  @override
  Future<List<String>?> getExternalCachePaths() async => [path];
  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async => [path];
  @override
  Future<String?> getDownloadsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockClient mockClient;
  late Directory tempDir;
  final url = 'https://example.com/image.png';
  final transparentPixel = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  setUpAll(() {
    registerFallbackValue(Uri.parse(url));
  });

  setUp(() async {
    mockClient = MockClient();
    tempDir = await Directory.systemTemp.createTemp('pixora_image_test');
    PathProviderPlatform.instance = FakePathProvider(tempDir.path);
    await PixoraCacheManager.instance.clear();
  });

  tearDown(() async {
    await PixoraCacheManager.instance.clear();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PixoraImage network and cache logic', () {
    testWidgets('shows placeholder then image on success', (tester) async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response.bytes(transparentPixel, 200));

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PixoraImage(
                url: url,
                httpClient: mockClient,
                fadeInDuration: Duration.zero,
              ),
            ),
          ),
        );

        // Initially shows placeholder
        expect(find.byType(PixoraPlaceholder), findsOneWidget);

        await Future.delayed(Duration(milliseconds: 100));
        await tester.pump();
      });

      // Finally shows Image.memory
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('shows error widget on failure', (tester) async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PixoraImage(
                url: url,
                httpClient: mockClient,
                maxRetries: 0,
              ),
            ),
          ),
        );

        await Future.delayed(Duration(milliseconds: 100));
        await tester.pump();
      });

      expect(find.byType(PixoraErrorWidget), findsOneWidget);
    });

    testWidgets('retries on failure', (tester) async {
      var calls = 0;
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        calls++;
        if (calls == 1) return http.Response('Error', 500);
        return http.Response.bytes(transparentPixel, 200);
      });

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PixoraImage(
                url: url,
                httpClient: mockClient,
                maxRetries: 1,
                retryDelay: Duration.zero,
                fadeInDuration: Duration.zero,
              ),
            ),
          ),
        );

        await Future.delayed(Duration(milliseconds: 100));
        await tester.pump();
      });

      expect(calls, 2);
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('PixoraCachePolicy', () {
    testWidgets('cacheFirst: uses cache if available', (tester) async {
      final cache = PixoraCacheManager.instance;
      final key = cache.keyFor(url, null);
      await cache.putMemory(key, transparentPixel);

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PixoraImage(
                url: url,
                httpClient: mockClient,
                cachePolicy: PixoraCachePolicy.cacheFirst,
                fadeInDuration: Duration.zero,
              ),
            ),
          ),
        );

        await Future.delayed(Duration(milliseconds: 50));
        await tester.pump();
      });

      expect(find.byType(Image), findsOneWidget);
      verifyNever(() => mockClient.get(any(), headers: any(named: 'headers')));
    });

    testWidgets('networkOnly: ignores cache', (tester) async {
      final cache = PixoraCacheManager.instance;
      final key = cache.keyFor(url, null);
      await cache.putMemory(key, transparentPixel);

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response.bytes(transparentPixel, 200));

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PixoraImage(
                url: url,
                httpClient: mockClient,
                cachePolicy: PixoraCachePolicy.networkOnly,
                fadeInDuration: Duration.zero,
              ),
            ),
          ),
        );

        await Future.delayed(Duration(milliseconds: 100));
        await tester.pump();
      });

      verify(() => mockClient.get(any(), headers: any(named: 'headers'))).called(1);
    });

    testWidgets('cacheOnly: throws error if not in cache', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PixoraImage(
                url: url,
                httpClient: mockClient,
                cachePolicy: PixoraCachePolicy.cacheOnly,
              ),
            ),
          ),
        );

        await Future.delayed(Duration(milliseconds: 100));
        await tester.pump();
      });

      expect(find.byType(PixoraErrorWidget), findsOneWidget);
      verifyNever(() => mockClient.get(any(), headers: any(named: 'headers')));
    });

    testWidgets('networkFirst: tries network then cache', (tester) async {
      final cache = PixoraCacheManager.instance;
      final key = cache.keyFor(url, null);
      await cache.putMemory(key, transparentPixel);

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Error', 500));

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PixoraImage(
                url: url,
                httpClient: mockClient,
                cachePolicy: PixoraCachePolicy.networkFirst,
                maxRetries: 0,
                fadeInDuration: Duration.zero,
              ),
            ),
          ),
        );

        await Future.delayed(Duration(milliseconds: 100));
        await tester.pump();
      });

      expect(find.byType(Image), findsOneWidget); // Loaded from cache after network failure
      verify(() => mockClient.get(any(), headers: any(named: 'headers'))).called(1);
    });

    test('prefetch stores image in cache', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response.bytes(transparentPixel, 200));

      await PixoraImage.prefetch(url, httpClient: mockClient);

      final cache = PixoraCacheManager.instance;
      final key = cache.keyFor(url, null);
      expect(await cache.getMemory(key), isNotNull);
      expect(await cache.getDisk(key), isNotNull);
    });
  });
}
