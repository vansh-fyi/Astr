import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() async {
  print('Loading Light_Pollution_Map.png...');

  final File file = File('/Users/hp/Desktop/Work/Repositories/Astr/assets/maps/Light_Pollution_Map.png');
  final Uint8List bytes = await file.readAsBytes();
  final img.Image? image = img.decodePng(bytes);

  if (image == null) {
    print('Failed to load image');
    return;
  }

  print('Map loaded: ${image.width}x${image.height} pixels');
  print('');

  // Test locations
  final List<Map<String, Object>> locations = <Map<String, Object>>[
    <String, Object>{'name': 'New Delhi', 'lat': 28.62137, 'lng': 77.2148},
    <String, Object>{'name': 'Mumbai', 'lat': 19.0760, 'lng': 72.8777},
    <String, Object>{'name': 'Rural India', 'lat': 30.33, 'lng': 78.04},
    <String, Object>{'name': 'Tokyo', 'lat': 35.6762, 'lng': 139.6503},
    <String, Object>{'name': 'Sahara Desert', 'lat': 25.0, 'lng': 10.0},
    <String, Object>{'name': 'Iceland Dark Sky', 'lat': 64.9631, 'lng': -19.0208},
  ];

  for (final Map<String, Object> loc in locations) {
    final double lat = loc['lat']! as double;
    final double lng = loc['lng']! as double;

    // Equirectangular projection
    int x = ((lng + 180.0) * (image.width / 360.0)).round();
    int y = ((90.0 - lat) * (image.height / 180.0)).round();

    x = x.clamp(0, image.width - 1);
    y = y.clamp(0, image.height - 1);

    final img.Pixel pixel = image.getPixel(x, y);
    final int r = pixel.r.toInt();
    final int g = pixel.g.toInt();
    final int b = pixel.b.toInt();

    print('${loc['name']}: lat=$lat, lng=$lng');
    print('  Pixel: ($x, $y)');
    print('  RGB: ($r, $g, $b)');
    print('');
  }
}
