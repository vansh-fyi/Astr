import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:astr/features/dashboard/data/datasources/png_map_service.dart';
import 'package:astr/features/context/domain/entities/geo_location.dart';
import 'package:astr/features/dashboard/domain/entities/light_pollution.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PngMapService service;

  setUp(() {
    service = PngMapService();
  });

  // Helper to create a simple 2x2 PNG
  // Top-Left (0,0): Black (0,0,0) -> Zone 1
  // Top-Right (1,0): White (255,255,255) -> Zone 9
  // Bottom-Left (0,1): Gray (128,128,128) -> Zone ~5
  // Bottom-Right (1,1): Red (255,0,0) -> Zone ?
  List<int> createMockPng() {
    final image = img.Image(width: 2, height: 2);
    image.setPixelRgb(0, 0, 0, 0, 0);       // Black
    image.setPixelRgb(1, 0, 255, 255, 255); // White
    image.setPixelRgb(0, 1, 128, 128, 128); // Gray
    image.setPixelRgb(1, 1, 255, 0, 0);     // Red
    return img.encodePng(image);
  }

  test('should return correct LightPollution from mock PNG', () async {
    // Arrange
    final mockPng = createMockPng();
    final ByteData data = ByteData.sublistView(Uint8List.fromList(mockPng));

    // Mock rootBundle
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async {
        return data.buffer.asByteData();
      },
    );
    
    // We need to intercept the specific asset load.
    // The standard way to mock rootBundle in unit tests is tricky if not using a wrapper.
    // However, since we are in a test environment, we can use `ServicesBinding.instance.defaultBinaryMessenger`.
    // But `rootBundle.load` sends a message to 'flutter/assets'.
    // The message is the asset key.
    
    // Let's try to inject the image directly if possible, or use a simpler approach:
    // We can't easily inject into `PngMapService` without refactoring.
    // Let's try the `setMockMessageHandler` approach.
    
    // Actually, `rootBundle.load` calls `PlatformAssetBundle.load`.
    // Let's assume the mock works for now.
    
    // Act & Assert
    
    // 1. Test Black Pixel (Zone 1)
    // Map is 2x2.
    // (0,0) corresponds to Lat ~90, Lng ~-180.
    // Let's pick a location that maps to 0,0.
    // x = (lng + 180) * (2/360) -> 0
    // y = (90 - lat) * (2/180) -> 0
    // Lat=89, Lng=-179
    
    // We need to ensure the service loads the map.
    // Since we can't easily mock the specific asset path check, we'll just return the data for ANY asset request.
    
    // Wait, `PngMapService` uses `rootBundle.load('assets/maps/world2024_low3.png')`.
    
    // Let's try to run it.
    
    // Note: In recent Flutter versions, `setMockMessageHandler` might be deprecated or behave differently.
    // Using `tester.runAsync` might be needed if we were in a widget test.
    // But this is a unit test.
    
    // Let's try to mock the channel.
    const channel = MethodChannel('flutter/assets');
    // This is not a method channel, it's a BasicMessageChannel usually?
    // Actually `rootBundle` uses `BinaryMessages`.
    
    // Let's use the standard `setMockMessageHandler` on the default binary messenger.
    
    // Override the handler
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        // The message contains the asset key string encoded in UTF-8?
        // Actually, `rootBundle` uses `AssetBundle.load` which might use a specific channel.
        // For `rootBundle`, it's usually handled by the flutter loader.
        
        // Let's just return our mock data regardless of the key for this test.
        return data; 
      },
    );

    // Act
    final result = await service.getLightPollution(GeoLocation(latitude: 89, longitude: -179));

    // Assert
    expect(result, isNotNull);
    expect(result!.source, LightPollutionSource.fallback);
    // Black -> Zone 1
    expect(result.visibilityIndex, 1);
    
    // 2. Test White Pixel (Zone 9)
    // (1,0) -> Lat ~90, Lng ~0
    // x = (0 + 180) * (2/360) = 1
    // y = 0
    final result2 = await service.getLightPollution(GeoLocation(latitude: 89, longitude: 0));
    expect(result2!.visibilityIndex, 9); // Luminance 255 / 28 = 9.1 -> 9
  });
}
