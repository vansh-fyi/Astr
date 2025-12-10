import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final file = File('/Users/hp/Desktop/Work/Repositories/Astr/assets/maps/world_atlas_2015_bortle.png');
  final bytes = await file.readAsBytes();
  final image = img.decodePng(bytes)!;

  print('New map loaded: ${image.width}x${image.height}');
  print('');

  final cities = [
    {'name': 'New Delhi', 'lat': 28.6139, 'lng': 77.2090, 'expected': 'Bortle 8-9'},
    {'name': 'New York City', 'lat': 40.7128, 'lng': -74.0060, 'expected': 'Bortle 8-9'},
    {'name': 'Tokyo', 'lat': 35.6762, 'lng': 139.6503, 'expected': 'Bortle 8-9'},
    {'name': 'London', 'lat': 51.5074, 'lng': -0.1278, 'expected': 'Bortle 7-8'},
    {'name': 'Sahara Desert', 'lat': 25.0, 'lng': 10.0, 'expected': 'Bortle 1-2'},
    {'name': 'Rural India', 'lat': 30.33, 'lng': 78.04, 'expected': 'Bortle 3-4'},
  ];

  for (final city in cities) {
    final lat = city['lat'] as double;
    final lng = city['lng'] as double;

    int x = ((lng + 180.0) * (image.width / 360.0)).round().clamp(0, image.width - 1);
    int y = ((90.0 - lat) * (image.height / 180.0)).round().clamp(0, image.height - 1);

    final pixel = image.getPixel(x, y);
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();

    // Map RGB back to Bortle value
    final rgbToBortle = {
      '20,47,114': 1,    // Dark blue
      '33,84,216': 2,    // Blue
      '15,87,20': 3,     // Dark green
      '31,161,42': 4,    // Green
      '110,100,30': 5,   // Olive
      '184,166,37': 6,   // Yellow
      '191,100,30': 7,   // Dark orange
      '253,150,80': 8,   // Orange
      '251,90,73': 9,    // Red/salmon
      '0,0,0': 0,        // Black (no data/water)
    };

    final rgbKey = '$r,$g,$b';
    final bortleValue = rgbToBortle[rgbKey] ?? -1;

    final expected = city['expected'] as String;

    print('${city['name']} (expected: $expected):');
    print('  Pixel: ($x, $y)');
    print('  RGB: ($r, $g, $b)');
    print('  Bortle: $bortleValue');

    if (bortleValue >= 0 && expected.contains(bortleValue.toString())) {
      print('  ✓ CORRECT');
    } else {
      print('  ⚠️  UNEXPECTED');
    }
    print('');
  }
}
