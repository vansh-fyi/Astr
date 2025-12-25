import 'dart:math';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../../../../core/utils/bortle_mpsas_converter.dart';
import '../../../../features/context/domain/entities/geo_location.dart';
import '../../domain/entities/light_pollution.dart';

class PngMapService {
  img.Image? _mapImage;

  Future<void> loadMap() async {
    if (_mapImage != null) return;
    try {
      final ByteData data = await rootBundle.load('assets/maps/Light_Pollution_Map.png');
      final Uint8List bytes = data.buffer.asUint8List();
      _mapImage = img.decodePng(bytes);
      print('Light pollution map loaded: ${_mapImage!.width}x${_mapImage!.height} pixels');
    } catch (e) {
      print('Error loading map: $e');
    }
  }

  Future<LightPollution?> getLightPollution(GeoLocation location) async {
    if (_mapImage == null) await loadMap();
    if (_mapImage == null) return null;

    final double lat = location.latitude;
    final double lng = location.longitude;

    // Equirectangular Projection
    // Map dimensions: 4000x2000 (assumed for world2024_low3.png, need to verify)
    // Actually, let's check the image size dynamically.
    final int width = _mapImage!.width;
    final int height = _mapImage!.height;

    // x = (lng + 180) * (width / 360)
    // y = (90 - lat) * (height / 180)
    
    int x = ((lng + 180.0) * (width / 360.0)).round();
    int y = ((90.0 - lat) * (height / 180.0)).round();

    // Clamp
    x = x.clamp(0, width - 1);
    y = y.clamp(0, height - 1);

    final img.Pixel pixel = _mapImage!.getPixel(x, y);

    // Map Color to Bortle using Light Pollution Atlas color scheme
    // Color progression: Dark Blue → Light Blue → Green → Yellow → Orange → Red → White
    // Based on David Lorenz's Light Pollution Atlas
    final int r = pixel.r.toInt();
    final int g = pixel.g.toInt();
    final int b = pixel.b.toInt();

    final int bortleClass = _colorToBortleClass(r, g, b);
    
    // Debug logging for troubleshooting
    print('PngMapService: lat=$lat, lng=$lng, pixel=($x,$y), RGB=($r,$g,$b) → Bortle $bortleClass');

    // Convert Bortle to MPSAS using standard astronomical conversion
    final double mpsas = BortleMpsasConverter.bortleToMpsas(bortleClass);

    return LightPollution(
      visibilityIndex: bortleClass,
      brightnessRatio: 0, // Unknown in fallback
      mpsas: mpsas,
      source: LightPollutionSource.fallback,
      zone: bortleClass.toString(),
    );
  }

  /// Maps RGB pixel color to Bortle class using the actual palette from Light_Pollution_Map.png
  ///
  /// This map is a 4-bit indexed color PNG (43200×16800px) with 13 discrete colors.
  /// Mapping based on the standard Light Pollution Atlas color scheme.
  int _colorToBortleClass(int r, int g, int b) {
    // Black/dark gray is typically water/oceans - treat as Bortle 1
    if (r == 0 && g == 0 && b == 0) return 1; // Black (water)
    if (r == 34 && g == 34 && b == 34) return 1; // Dark gray (dark sky/water)
    if (r == 66 && g == 66 && b == 66) return 2; // Gray (typical dark sky)

    // Blues - Excellent dark skies (Bortle 1-2)
    if (r == 20 && g == 47 && b == 114) return 1; // Dark blue
    if (r == 33 && g == 84 && b == 216) return 1; // Blue

    // Greens - Rural dark skies (Bortle 2-4)
    if (r == 15 && g == 87 && b == 20) return 2; // Dark green
    if (r == 31 && g == 161 && b == 42) return 3; // Light green

    // Yellows/Olive - Suburban transition (Bortle 5-7)
    if (r == 110 && g == 100 && b == 30) return 5; // Dark olive
    if (r == 184 && g == 166 && b == 37) return 7; // Yellow (suburban/urban transition)

    // Orange/Red - Urban/City (Bortle 7-9)
    if (r == 191 && g == 100 && b == 30) return 7; // Dark orange
    if (r == 253 && g == 150 && b == 80) return 8; // Orange
    if (r == 251 && g == 90 && b == 73) return 8; // Red/salmon
    if (r == 251 && g == 153 && b == 138) return 9; // Light pink

    // Fallback: use nearest color matching
    final List<_ZoneColor> zoneColors = <_ZoneColor>[
      const _ZoneColor(rgb: <int>[0, 0, 0], bortle: 1),
      const _ZoneColor(rgb: <int>[34, 34, 34], bortle: 1),
      const _ZoneColor(rgb: <int>[66, 66, 66], bortle: 2),
      const _ZoneColor(rgb: <int>[20, 47, 114], bortle: 1),
      const _ZoneColor(rgb: <int>[33, 84, 216], bortle: 1),
      const _ZoneColor(rgb: <int>[15, 87, 20], bortle: 2),
      const _ZoneColor(rgb: <int>[31, 161, 42], bortle: 3),
      const _ZoneColor(rgb: <int>[110, 100, 30], bortle: 5),
      const _ZoneColor(rgb: <int>[184, 166, 37], bortle: 7),
      const _ZoneColor(rgb: <int>[191, 100, 30], bortle: 7),
      const _ZoneColor(rgb: <int>[253, 150, 80], bortle: 8),
      const _ZoneColor(rgb: <int>[251, 90, 73], bortle: 8),
      const _ZoneColor(rgb: <int>[251, 153, 138], bortle: 9),
    ];

    // Find nearest color using Euclidean distance in RGB space
    double minDist = double.infinity;
    int bestBortle = 5; // Default to mid-range

    for (final _ZoneColor zone in zoneColors) {
      final int dr = r - zone.rgb[0];
      final int dg = g - zone.rgb[1];
      final int db = b - zone.rgb[2];
      final double dist = sqrt(dr * dr + dg * dg + db * db);

      if (dist < minDist) {
        minDist = dist;
        bestBortle = zone.bortle;
      }
    }

    return bestBortle;
  }
}

/// Helper class for color-to-Bortle mapping
class _ZoneColor {

  const _ZoneColor({required this.rgb, required this.bortle});
  final List<int> rgb;
  final int bortle;
}
