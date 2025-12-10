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
  print('Format: ${image.format}');
  print('Num channels: ${image.numChannels}');
  print('');

  // Sample unique colors from the map
  final colorSet = <String>{};

  print('Sampling colors from different regions...');

  // Sample from various regions
  for (var x = 0; x < image.width; x += 1000) {
    for (var y = 0; y < image.height; y += 1000) {
      final pixel = image.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      colorSet.add('($r, $g, $b)');
    }
  }

  print('Found ${colorSet.length} unique colors:');
  final sortedColors = colorSet.toList()..sort();
  for (final color in sortedColors) {
    print('  RGB: $color');
  }
}
