import 'dart:math';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../../../../features/context/domain/entities/geo_location.dart';
import '../../domain/entities/light_pollution.dart';

class PngMapService {
  img.Image? _mapImage;

  Future<void> loadMap() async {
    if (_mapImage != null) return;
    try {
      final ByteData data = await rootBundle.load('assets/maps/world2024_low3.png');
      final Uint8List bytes = data.buffer.asUint8List();
      _mapImage = img.decodePng(bytes);
    } catch (e) {
      print('Error loading map: $e');
    }
  }

  Future<LightPollution?> getLightPollution(GeoLocation location) async {
    if (_mapImage == null) await loadMap();
    if (_mapImage == null) return null;

    final lat = location.latitude;
    final lng = location.longitude;

    // Equirectangular Projection
    // Map dimensions: 4000x2000 (assumed for world2024_low3.png, need to verify)
    // Actually, let's check the image size dynamically.
    final width = _mapImage!.width;
    final height = _mapImage!.height;

    // x = (lng + 180) * (width / 360)
    // y = (90 - lat) * (height / 180)
    
    int x = ((lng + 180.0) * (width / 360.0)).round();
    int y = ((90.0 - lat) * (height / 180.0)).round();

    // Clamp
    x = x.clamp(0, width - 1);
    y = y.clamp(0, height - 1);

    final pixel = _mapImage!.getPixel(x, y);
    
    // Map Color to Value
    // We need the color mapping table.
    // For now, let's use a simplified heuristic based on brightness/hue if exact mapping is complex.
    // Or just map the R/G/B values to the zones if we know the palette.
    // The palette is likely specific.
    // Let's assume a rough mapping for the fallback.
    // Darker = Better.
    
    // TODO: Implement exact color mapping from colors.html
    // For this MVP fallback, we will return an estimated value based on pixel luminance.
    
    final r = pixel.r;
    final g = pixel.g;
    final b = pixel.b;
    
    // Very rough heuristic for fallback
    // 0 (black) -> Zone 1
    // High values -> Zone 8/9
    final luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    
    // Map 0-255 to 0-9
    int index = (luminance / 28.0).round().clamp(1, 9);
    
    // If it's pure black (ocean/remote), it's 1
    if (luminance < 5) index = 1;

    return LightPollution(
      visibilityIndex: index,
      brightnessRatio: 0.0, // Unknown in fallback
      mpsas: 0.0, // Unknown in fallback
      source: LightPollutionSource.fallback,
      zone: index.toString(),
    );
  }
}
