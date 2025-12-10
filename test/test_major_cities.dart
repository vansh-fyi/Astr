import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final file = File('/Users/hp/Desktop/Work/Repositories/Astr/assets/maps/Light_Pollution_Map.png');
  final bytes = await file.readAsBytes();
  final image = img.decodePng(bytes)!;

  final cities = [
    {'name': 'New York City', 'lat': 40.7128, 'lng': -74.0060, 'expected': 'Bortle 8-9'},
    {'name': 'London', 'lat': 51.5074, 'lng': -0.1278, 'expected': 'Bortle 8'},
    {'name': 'Tokyo', 'lat': 35.6762, 'lng': 139.6503, 'expected': 'Bortle 8-9'},
    {'name': 'Shanghai', 'lat': 31.2304, 'lng': 121.4737, 'expected': 'Bortle 9'},
    {'name': 'New Delhi', 'lat': 28.6139, 'lng': 77.2090, 'expected': 'Bortle 9'},
    {'name': 'Los Angeles', 'lat': 34.0522, 'lng': -118.2437, 'expected': 'Bortle 8'},
    {'name': 'Sahara Desert', 'lat': 25.0, 'lng': 10.0, 'expected': 'Bortle 1'},
    {'name': 'Rural Montana', 'lat': 47.0, 'lng': -110.0, 'expected': 'Bortle 2-3'},
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

    print('${city['name']} (expected: ${city['expected']}):');
    print('  RGB: ($r, $g, $b)');

    // Interpret color
    if (r == 251 && g >= 90 && g <= 153) {
      print('  → Bortle 8-9 (RED/PINK - Major city) ✓');
    } else if (r >= 184 && g >= 100) {
      print('  → Bortle 7 (YELLOW/ORANGE - Urban) ⚠️');
    } else if (r <= 66 && g <= 66 && b <= 66) {
      print('  → Bortle 1-2 (BLACK/GRAY - Dark sky) ✓');
    } else if (g > r && b < 100) {
      print('  → Bortle 2-3 (GREEN - Rural) ✓');
    } else {
      print('  → Unknown/Moderate');
    }
    print('');
  }
}
