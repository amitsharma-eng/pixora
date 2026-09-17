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
    tempDir = await Directory.systemTemp.createTemp('pixora_widgets_test');
    PathProviderPlatform.instance = FakePathProvider(tempDir.path);
    await PixoraCacheManager.instance.clear();
  });

  tearDown(() async {
    await PixoraCacheManager.instance.clear();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PixoraImage custom widgets', () {
    testWidgets('uses custom placeholder', (tester) async {
      final mockClient = MockClient();
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response.bytes(transparentPixel, 200));

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PixoraImage(
                url: url,
                httpClient: mockClient,
                placeholder: Text('Custom Placeholder'),
                fadeInDuration: Duration.zero,
              ),
            ),
          ),
        );
        // Initial frame shows placeholder
        expect(find.text('Custom Placeholder'), findsOneWidget);
        
        await Future.delayed(Duration(milliseconds: 100));
        await tester.pump();
      });

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('uses custom error widget', (tester) async {
      final mockClient = MockClient();
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Error', 500));

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PixoraImage(
                url: url,
                httpClient: mockClient,
                maxRetries: 0,
                errorWidget: Text('Custom Error'),
              ),
            ),
          ),
        );
        await Future.delayed(Duration(milliseconds: 100));
        await tester.pump();
      });

      expect(find.text('Custom Error'), findsOneWidget);
    });

    testWidgets('retry button triggers reload', (tester) async {
      final mockClient = MockClient();
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
                maxRetries: 0,
                fadeInDuration: Duration.zero,
              ),
            ),
          ),
        );
        await Future.delayed(Duration(milliseconds: 100));
        await tester.pump();
        
        expect(find.byType(PixoraErrorWidget), findsOneWidget);
        expect(calls, 1);

        // Tap retry
        await tester.tap(find.text('Retry'));
        await Future.delayed(Duration(milliseconds: 200));
        await tester.pump();
        await tester.pump(Duration(milliseconds: 100));
      });

      expect(calls, 2);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
