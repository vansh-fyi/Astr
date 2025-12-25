import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() async {
  final File file = File('/Users/hp/Desktop/Work/Repositories/Astr/assets/maps/world_atlas_2015_bortle.png');
  final Uint8List bytes = await file.readAsBytes();
  final img.Image image = img.decodePng(bytes)!;

  print('New map loaded: ${image.width}x${image.height}');
  print('');

  final List<Map<String, Object>> cities = <Map<String, Object>>[
    <String, Object>{'name': 'New Delhi', 'lat': 28.6139, 'lng': 77.2090, 'expected': 'Bortle 8-9'},
    <String, Object>{'name': 'New York City', 'lat': 40.7128, 'lng': -74.0060, 'expected': 'Bortle 8-9'},
    <String, Object>{'name': 'Tokyo', 'lat': 35.6762, 'lng': 139.6503, 'expected': 'Bortle 8-9'},
    <String, Object>{'name': 'London', 'lat': 51.5074, 'lng': -0.1278, 'expected': 'Bortle 7-8'},
    <String, Object>{'name': 'Sahara Desert', 'lat': 25.0, 'lng': 10.0, 'expected': 'Bortle 1-2'},
    <String, Object>{'name': 'Rural India', 'lat': 30.33, 'lng': 78.04, 'expected': 'Bortle 3-4'},
  ];

  for (final Map<String, Object> city in cities) {
    final double lat = city['lat']! as double;
    final double lng = city['lng']! as double;

    final int x = ((lng + 180.0) * (image.width / 360.0)).round().clamp(0, image.width - 1);
    final int y = ((90.0 - lat) * (image.height / 180.0)).round().clamp(0, image.height - 1);

    final img.Pixel pixel = image.getPixel(x, y);
    final int r = pixel.r.toInt();
    final int g = pixel.g.toInt();
    final int b = pixel.b.toInt();

    // Map RGB back to Bortle value
    final Map<String, int> rgbToBortle = <String, int>{
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

    final String rgbKey = '$r,$g,$b';
    final int bortleValue = rgbToBortle[rgbKey] ?? -1;

    final String expected = city['expected']! as String;

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
