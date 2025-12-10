import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  print('Loading Light_Pollution_Map.png...');

  final file = File('/Users/hp/Desktop/Work/Repositories/Astr/assets/maps/Light_Pollution_Map.png');
  final bytes = await file.readAsBytes();
  final image = img.decodePng(bytes);

  if (image == null) {
    print('Failed to load image');
    return;
  }

  print('Map loaded: ${image.width}x${image.height} pixels');
  print('');

  // Test locations
  final locations = [
    {'name': 'New Delhi', 'lat': 28.62137, 'lng': 77.2148},
    {'name': 'Mumbai', 'lat': 19.0760, 'lng': 72.8777},
    {'name': 'Rural India', 'lat': 30.33, 'lng': 78.04},
    {'name': 'Tokyo', 'lat': 35.6762, 'lng': 139.6503},
    {'name': 'Sahara Desert', 'lat': 25.0, 'lng': 10.0},
    {'name': 'Iceland Dark Sky', 'lat': 64.9631, 'lng': -19.0208},
  ];

  for (final loc in locations) {
    final lat = loc['lat'] as double;
    final lng = loc['lng'] as double;

    // Equirectangular projection
    int x = ((lng + 180.0) * (image.width / 360.0)).round();
    int y = ((90.0 - lat) * (image.height / 180.0)).round();

    x = x.clamp(0, image.width - 1);
    y = y.clamp(0, image.height - 1);

    final pixel = image.getPixel(x, y);
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();

    print('${loc['name']}: lat=$lat, lng=$lng');
    print('  Pixel: ($x, $y)');
    print('  RGB: ($r, $g, $b)');
    print('');
  }
}
